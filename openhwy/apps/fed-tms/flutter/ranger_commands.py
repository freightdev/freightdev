# Ranger Commands for OpenHWY
# Add to ~/.config/ranger/commands.py

from ranger.api.commands import Command

class marketeer(Command):
    """Launch Marketeer Dashboard"""
    def execute(self):
        self.fm.execute_console("shell ~/bin/marketeer-dashboard ~/marketeer-workbox.toml")

class agent(Command):
    """Launch Agent Builder"""
    def execute(self):
        self.fm.execute_console("shell ~/bin/agent-builder")

class moon(Command):
    """Run agent in Moon Environment
    Usage: moon <config> [script]
    Example: moon codriver.toml codriver.lua
    """
    def execute(self):
        if not self.arg(1):
            self.fm.notify("Usage: moon <config> [script]", bad=True)
            return
        
        config = self.arg(1)
        script = self.arg(2) if self.arg(2) else ""
        
        cmd = f"~/bin/moon-env {config} {script}"
        self.fm.execute_console(f"shell {cmd}")

class openhwy(Command):
    """OpenHWY quick launcher
    Usage: openhwy <command>
    Commands: marketeer, agent, status
    """
    def execute(self):
        cmd = self.arg(1)
        if not cmd:
            self.fm.notify("Usage: openhwy <command>", bad=True)
            return
        
        self.fm.execute_console(f"shell openhwy {cmd}")

class sshbox(Command):
    """SSH to OpenHWY box
    Usage: sshbox <system>
    Systems: helpbox, hostbox, callbox, safebox
    """
    def execute(self):
        box = self.arg(1)
        if not box:
            self.fm.notify("Usage: sshbox <system>", bad=True)
            return
        
        self.fm.execute_console(f"shell ssh admin@{box}")
