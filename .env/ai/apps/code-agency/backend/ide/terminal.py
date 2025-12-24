import os
import logging
import signal
import select
import termios
import struct
import fcntl
import uuid
import subprocess
import threading
import queue
import pty
from typing import Dict, Optional, Callable
from pathlib import Path



logger = logging.getLogger(__name__)

class TerminalSession:
    def __init__(self, session_id: str, cwd: str, shell: str = "/bin/bash"):
        self.session_id = session_id
        self.cwd = Path(cwd).resolve()
        self.shell = shell
        self.process = None
        self.master_fd = None
        self.slave_fd = None
        self.output_queue = queue.Queue()
        self.input_queue = queue.Queue()
        self.running = False
        self.output_callback: Optional[Callable[[str], None]] = None
        
    def start(self) -> bool:
        try:
            self.master_fd, self.slave_fd = pty.openpty()
            self._set_winsize(24, 80)
            env = os.environ.copy()
            env['TERM'] = 'xterm-256color'
            env['PS1'] = r'\u@\h:\w$ '

            self.process = subprocess.Popen(
                [self.shell],
                stdin=self.slave_fd,
                stdout=self.slave_fd,
                stderr=self.slave_fd,
                cwd=self.cwd,
                env=env,
                preexec_fn=os.setsid
            )

            os.close(self.slave_fd)
            self.slave_fd = None

            flags = fcntl.fcntl(self.master_fd, fcntl.F_GETFL)
            fcntl.fcntl(self.master_fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)

            self.running = True

            self.output_thread = threading.Thread(target=self._output_loop)
            self.output_thread.daemon = True
            self.output_thread.start()
            logger.info(f"Terminal session {self.session_id} started")
            return True
        except Exception as e:
            logger.error(f"Failed to start terminal session: {e}")
            self.cleanup()
            return False

    def write_input(self, data: str):
        if self.running and self.master_fd:
            try:
                os.write(self.master_fd, data.encode('utf-8'))
            except Exception as e:
                logger.error(f"Error writing to terminal: {e}")

    def set_output_callback(self, callback: Callable[[str], None]):
        self.output_callback = callback

    def resize(self, rows: int, cols: int):
        if self.master_fd:
            self._set_winsize(rows, cols)

    def _set_winsize(self, rows: int, cols: int):
        try:
            winsize = struct.pack('HHHH', rows, cols, 0, 0)
            fcntl.ioctl(self.master_fd, termios.TIOCSWINSZ, winsize)
        except Exception as e:
            logger.error(f"Error setting window size: {e}")

    def _output_loop(self):
        while self.running:
            try:
                if self.master_fd:
                    ready, _, _ = select.select([self.master_fd], [], [], 0.1)
                    if ready:
                        data = os.read(self.master_fd, 4096)
                        if data:
                            output = data.decode('utf-8', errors='ignore')
                            if self.output_callback:
                                self.output_callback(output)
                        else:
                            break
            except OSError:
                break
            except Exception as e:
                logger.error(f"Error in output loop: {e}")
                break
        self.running = False

    def is_alive(self) -> bool:
        return self.process and self.process.poll() is None

    def cleanup(self):
        self.running = False
        if self.process:
            try:
                os.killpg(os.getpgid(self.process.pid), signal.SIGTERM)
                try:
                    self.process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    os.killpg(os.getpgid(self.process.pid), signal.SIGKILL)
                    self.process.wait()
            except Exception as e:
                logger.error(f"Error terminating process: {e}")
        if self.master_fd:
            try: os.close(self.master_fd)
            except: pass
            self.master_fd = None
        if self.slave_fd:
            try: os.close(self.slave_fd)
            except: pass
            self.slave_fd = None
        logger.info(f"Terminal session {self.session_id} cleaned up")


class TerminalManager:
    def __init__(self, workspace_root: str = "../workspace"):
        self.workspace_root = Path(workspace_root).resolve()
        self.sessions: Dict[str, TerminalSession] = {}
        self.default_shell = os.getenv('SHELL', '/bin/bash')

    def create_session(self, cwd: str = "", shell: str = None) -> Dict:
        try:
            session_id = str(uuid.uuid4())
            work_dir = self.workspace_root / cwd.lstrip('/') if cwd else self.workspace_root
            if not work_dir.exists():
                work_dir = self.workspace_root
            session_shell = shell or self.default_shell
            session = TerminalSession(session_id, str(work_dir), session_shell)
            if session.start():
                self.sessions[session_id] = session
                return {"success": True, "session_id": session_id, "cwd": str(work_dir.relative_to(self.workspace_root)), "shell": session_shell}
            else:
                return {"error": "Failed to start terminal session"}
        except Exception as e:
            logger.error(f"Error creating terminal session: {e}")
            return {"error": str(e)}

    def get_session(self, session_id: str) -> Optional[TerminalSession]:
        return self.sessions.get(session_id)

    def execute_command(self, command: str, cwd: str = "", timeout: int = 30) -> Dict:
        try:
            work_dir = self.workspace_root / cwd.lstrip('/') if cwd else self.workspace_root
            if not work_dir.exists():
                work_dir = self.workspace_root
            result = subprocess.run(command, shell=True, cwd=work_dir, capture_output=True, text=True, timeout=timeout)
            return {"success": result.returncode == 0, "stdout": result.stdout, "stderr": result.stderr, "returncode": result.returncode, "command": command, "cwd": str(work_dir.relative_to(self.workspace_root))}
        except subprocess.TimeoutExpired:
            return {"error": f"Command timed out after {timeout} seconds", "command": command}
        except Exception as e:
            logger.error(f"Error executing command: {e}")
            return {"error": str(e), "command": command}

    def send_input(self, session_id: str, data: str) -> Dict:
        session = self.sessions.get(session_id)
        if not session: return {"error": "Session not found"}
        if not session.is_alive(): return {"error": "Session is not active"}
        try:
            session.write_input(data)
            return {"success": True}
        except Exception as e:
            return {"error": str(e)}

    def resize_session(self, session_id: str, rows: int, cols: int) -> Dict:
        session = self.sessions.get(session_id)
        if not session: return {"error": "Session not found"}
        try:
            session.resize(rows, cols)
            return {"success": True}
        except Exception as e:
            return {"error": str(e)}

    def close_session(self, session_id: str) -> Dict:
        session = self.sessions.get(session_id)
        if not session: return {"error": "Session not found"}
        try:
            session.cleanup()
            del self.sessions[session_id]
            return {"success": True}
        except Exception as e:
            return {"error": str(e)}

    def list_sessions(self) -> Dict:
        sessions = []
        for session_id, session in list(self.sessions.items()):
            if session.is_alive():
                sessions.append({"session_id": session_id, "cwd": str(Path(session.cwd).relative_to(self.workspace_root)), "shell": session.shell, "running": session.running})
            else:
                session.cleanup()
                del self.sessions[session_id]
        return {"sessions": sessions}

    def cleanup_all(self):
        for session in list(self.sessions.values()):
            session.cleanup()
        self.sessions.clear()


# Global terminal manager instance
terminal_manager = TerminalManager()
