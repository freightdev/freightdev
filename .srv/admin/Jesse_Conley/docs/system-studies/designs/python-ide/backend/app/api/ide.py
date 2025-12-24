import logging
from typing import List, Dict, Any, Optional

import json
import asyncio
from pydantic import BaseModel
from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect

from ...ide.file_manager import file_manager
from ...ide.github_client import github_client
from ...ide.terminal import terminal_manager

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/ide", tags=["ide"])

# Models
class FileReadRequest(BaseModel):
    path: str
    encoding: str = "utf-8"

class FileWriteRequest(BaseModel):
    path: str
    content: str
    encoding: str = "utf-8"

class FileCreateRequest(BaseModel):
    path: str
    content: str = ""
    type: str = "file"  # file or directory

class FileRenameRequest(BaseModel):
    old_path: str
    new_name: str

class GitCommitRequest(BaseModel):
    repo_path: str
    message: str
    files: Optional[List[str]] = None

class GitCloneRequest(BaseModel):
    repo_url: str
    target_dir: Optional[str] = None

class CommandRequest(BaseModel):
    command: str
    cwd: str = ""
    timeout: int = 30

class TerminalInputRequest(BaseModel):
    session_id: str
    data: str

class TerminalResizeRequest(BaseModel):
    session_id: str
    rows: int
    cols: int

# File Management Endpoints
@router.get("/files/tree")
async def get_file_tree(path: str = "", max_depth: int = 3):
    try:
        return file_manager.get_file_tree(path, max_depth)
    except Exception as e:
        logger.error(f"Error getting file tree: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/files/read")
async def read_file(request: FileReadRequest):
    try:
        result = file_manager.read_file(request.path, request.encoding)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error reading file: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/files/write")
async def write_file(request: FileWriteRequest):
    try:
        result = file_manager.write_file(request.path, request.content, request.encoding)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error writing file: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/files/create")
async def create_file_or_directory(request: FileCreateRequest):
    try:
        if request.type == "directory":
            result = file_manager.create_directory(request.path)
        else:
            result = file_manager.create_file(request.path, request.content)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error creating {request.type}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/files/delete")
async def delete_file_or_directory(path: str):
    try:
        result = file_manager.delete_path(path)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error deleting path: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/files/rename")
async def rename_file_or_directory(request: FileRenameRequest):
    try:
        result = file_manager.rename_path(request.old_path, request.new_name)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error renaming: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Git Endpoints
@router.get("/git/status")
async def get_git_status(repo_path: str = ""):
    try:
        result = github_client.get_git_status(repo_path)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error getting git status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/git/clone")
async def clone_repository(request: GitCloneRequest):
    try:
        result = github_client.clone_repository(request.repo_url, request.target_dir)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error cloning repository: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/git/commit")
async def commit_changes(request: GitCommitRequest):
    try:
        result = github_client.commit_changes(request.repo_path, request.message, request.files)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error committing changes: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/git/push")
async def push_changes(repo_path: str, branch: Optional[str] = None):
    try:
        result = github_client.push_changes(repo_path, branch)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error pushing changes: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/git/pull")
async def pull_changes(repo_path: str):
    try:
        result = github_client.pull_changes(repo_path)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error pulling changes: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/git/history")
async def get_commit_history(repo_path: str, limit: int = 10):
    try:
        result = github_client.get_commit_history(repo_path, limit)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error getting commit history: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/git/branch/create")
async def create_branch(repo_path: str, branch_name: str):
    try:
        result = github_client.create_branch(repo_path, branch_name)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error creating branch: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/git/branch/switch")
async def switch_branch(repo_path: str, branch_name: str):
    try:
        result = github_client.switch_branch(repo_path, branch_name)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error switching branch: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Terminal Endpoints
@router.post("/terminal/create")
async def create_terminal_session(cwd: str = "", shell: Optional[str] = None):
    try:
        result = terminal_manager.create_session(cwd, shell)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error creating terminal session: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/terminal/sessions")
async def list_terminal_sessions():
    try:
        return terminal_manager.list_sessions()
    except Exception as e:
        logger.error(f"Error listing terminal sessions: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/terminal/input")
async def send_terminal_input(request: TerminalInputRequest):
    try:
        result = terminal_manager.send_input(request.session_id, request.data)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error sending terminal input: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/terminal/resize")
async def resize_terminal(request: TerminalResizeRequest):
    try:
        result = terminal_manager.resize_session(request.session_id, request.rows, request.cols)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error resizing terminal: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/terminal/{session_id}")
async def close_terminal_session(session_id: str):
    try:
        result = terminal_manager.close_session(session_id)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error closing terminal session: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/terminal/execute")
async def execute_command(request: CommandRequest):
    try:
        result = terminal_manager.execute_command(request.command, request.cwd, request.timeout)
        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        return result
    except Exception as e:
        logger.error(f"Error executing command: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Terminal WebSocket
@router.websocket("/terminal/ws/{session_id}")
async def terminal_websocket(websocket: WebSocket, session_id: str):
    await websocket.accept()
    session = terminal_manager.get_session(session_id)
    if not session:
        await websocket.close(code=4004, reason="Session not found")
        return

    async def send_output(data: str):
        try:
            await websocket.send_text(json.dumps({"type": "output", "data": data}))
        except Exception as e:
            logger.error(f"Error sending terminal output: {e}")

    session.set_output_callback(lambda data: asyncio.create_task(send_output(data)))

    try:
        while True:
            message = await websocket.receive_text()
            data = json.loads(message)

            if data.get("type") == "input":
                session.write_input(data.get("data", ""))
            elif data.get("type") == "resize":
                session.resize(data.get("rows", 24), data.get("cols", 80))

            if not session.is_alive():
                await websocket.send_text(json.dumps({"type": "exit", "message": "Terminal session ended"}))
                break

    except WebSocketDisconnect:
        logger.info(f"Terminal WebSocket disconnected: {session_id}")
    except Exception as e:
        logger.error(f"Terminal WebSocket error: {e}")
    finally:
        session.set_output_callback(None)
