import os
import requests
import subprocess
import logging
from typing import Dict, List, Optional
from pathlib import Path
from dataclasses import dataclass

logger = logging.getLogger(__name__)

@dataclass
class GitStatus:
    branch: str
    staged: List[str]
    modified: List[str]
    untracked: List[str]
    ahead: int = 0
    behind: int = 0

@dataclass
class GitCommit:
    hash: str
    message: str
    author: str
    date: str

class GitHubClient:
    def __init__(self, workspace_root: str = "workspace", github_token: str = None):
        self.workspace_root = Path(workspace_root).resolve()
        self.github_token = github_token or os.getenv("GITHUB_TOKEN")
        self.headers = {
            "Authorization": f"token {self.github_token}" if self.github_token else "",
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": "AI-Assistant-IDE/1.0"
        }

    def git_command(self, args: List[str], cwd: str = None) -> Dict:
        try:
            work_dir = Path(cwd) if cwd else self.workspace_root
            if not str(work_dir.resolve()).startswith(str(self.workspace_root)):
                return {"error": "Path outside workspace not allowed"}
            result = subprocess.run(
                ["git"] + args,
                cwd=work_dir,
                capture_output=True,
                text=True,
                timeout=30
            )
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout.strip(),
                "stderr": result.stderr.strip(),
                "returncode": result.returncode
            }
        except subprocess.TimeoutExpired:
            return {"error": "Git command timed out"}
        except Exception as e:
            logger.error(f"Git command failed: {e}")
            return {"error": str(e)}

    def get_git_status(self, repo_path: str = "") -> Dict:
        try:
            work_dir = self.workspace_root / repo_path.lstrip('/')
            if not (work_dir / ".git").exists():
                return {"error": "Not a git repository"}

            branch_result = self.git_command(["branch", "--show-current"], cwd=work_dir)
            if not branch_result["success"]:
                return {"error": "Failed to get current branch"}
            branch = branch_result["stdout"] or "HEAD"

            status_result = self.git_command(["status", "--porcelain"], cwd=work_dir)
            if not status_result["success"]:
                return {"error": "Failed to get git status"}

            staged, modified, untracked = [], [], []
            for line in status_result["stdout"].splitlines():
                if len(line) < 3: continue
                status_code, filename = line[:2], line[3:]
                if status_code[0] in "MARC": staged.append(filename)
                if status_code[1] in "M": modified.append(filename)
                if status_code == "??": untracked.append(filename)

            ahead, behind = self._get_ahead_behind(work_dir, branch)
            return {
                "success": True,
                "status": {
                    "branch": branch,
                    "staged": staged,
                    "modified": modified,
                    "untracked": untracked,
                    "ahead": ahead,
                    "behind": behind,
                    "clean": len(staged) == 0 and len(modified) == 0 and len(untracked) == 0
                }
            }
        except Exception as e:
            logger.error(f"Error getting git status: {e}")
            return {"error": str(e)}

    def clone_repository(self, repo_url: str, target_dir: str = None) -> Dict:
        try:
            if not target_dir:
                repo_name = repo_url.split("/")[-1].replace(".git", "")
                target_dir = repo_name
            target_path = self.workspace_root / target_dir
            if target_path.exists():
                return {"error": f"Directory {target_dir} already exists"}
            result = self.git_command(["clone", repo_url, target_dir])
            if result["success"]:
                return {"success": True, "path": target_dir, "message": f"Repository cloned to {target_dir}"}
            return {"error": f"Clone failed: {result['stderr']}"}
        except Exception as e:
            logger.error(f"Error cloning repository: {e}")
            return {"error": str(e)}

    def commit_changes(self, repo_path: str, message: str, files: List[str] = None) -> Dict:
        try:
            work_dir = self.workspace_root / repo_path.lstrip('/')
            if not (work_dir / ".git").exists():
                return {"error": "Not a git repository"}

            if files:
                for file in files:
                    result = self.git_command(["add", file], cwd=work_dir)
                    if not result["success"]:
                        return {"error": f"Failed to stage {file}: {result['stderr']}"}
            else:
                result = self.git_command(["add", "."], cwd=work_dir)
                if not result["success"]:
                    return {"error": f"Failed to stage changes: {result['stderr']}"}

            result = self.git_command(["commit", "-m", message], cwd=work_dir)
            if result["success"]:
                return {"success": True, "message": "Changes committed successfully"}
            return {"error": f"Commit failed: {result['stderr']}"}
        except Exception as e:
            logger.error(f"Error committing changes: {e}")
            return {"error": str(e)}

    def push_changes(self, repo_path: str, branch: str = None) -> Dict:
        try:
            work_dir = self.workspace_root / repo_path.lstrip('/')
            result = self.git_command(["push", "origin", branch] if branch else ["push"], cwd=work_dir)
            if result["success"]:
                return {"success": True, "message": "Changes pushed successfully"}
            return {"error": f"Push failed: {result['stderr']}"}
        except Exception as e:
            logger.error(f"Error pushing changes: {e}")
            return {"error": str(e)}

    def pull_changes(self, repo_path: str) -> Dict:
        try:
            work_dir = self.workspace_root / repo_path.lstrip('/')
            result = self.git_command(["pull"], cwd=work_dir)
            if result["success"]:
                return {"success": True, "message": "Changes pulled successfully", "output": result["stdout"]}
            return {"error": f"Pull failed: {result['stderr']}"}
        except Exception as e:
            logger.error(f"Error pulling changes: {e}")
            return {"error": str(e)}

    def get_commit_history(self, repo_path: str, limit: int = 10) -> Dict:
        try:
            work_dir = self.workspace_root / repo_path.lstrip('/')
            result = self.git_command([
                "log", f"--max-count={limit}", "--pretty=format:%H|%s|%an|%ad", "--date=iso"
            ], cwd=work_dir)
            if not result["success"]:
                return {"error": f"Failed to get commit history: {result['stderr']}"}
            commits = []
            for line in result["stdout"].splitlines():
                parts = line.split("|", 3)
                if len(parts) == 4:
                    commits.append({"hash": parts[0][:8], "message": parts[1], "author": parts[2], "date": parts[3]})
            return {"success": True, "commits": commits}
        except Exception as e:
            logger.error(f"Error getting commit history: {e}")
            return {"error": str(e)}

    def create_branch(self, repo_path: str, branch_name: str) -> Dict:
        try:
            work_dir = self.workspace_root / repo_path.lstrip('/')
            result = self.git_command(["checkout", "-b", branch_name], cwd=work_dir)
            if result["success"]:
                return {"success": True, "branch": branch_name, "message": f"Created and switched to branch {branch_name}"}
            return {"error": f"Failed to create branch: {result['stderr']}"}
        except Exception as e:
            logger.error(f"Error creating branch: {e}")
            return {"error": str(e)}

    def switch_branch(self, repo_path: str, branch_name: str) -> Dict:
        try:
            work_dir = self.workspace_root / repo_path.lstrip('/')
            result = self.git_command(["checkout", branch_name], cwd=work_dir)
            if result["success"]:
                return {"success": True, "branch": branch_name, "message": f"Switched to branch {branch_name}"}
            return {"error": f"Failed to switch branch: {result['stderr']}"}
        except Exception as e:
            logger.error(f"Error switching branch: {e}")
            return {"error": str(e)}

    def _get_ahead_behind(self, work_dir: Path, branch: str) -> tuple:
        try:
            result = self.git_command(["rev-list", "--left-right", "--count", f"{branch}...origin/{branch}"], cwd=work_dir)
            if result["success"] and result["stdout"]:
                parts = result["stdout"].split()
                if len(parts) == 2:
                    return int(parts[0]), int(parts[1])
            return 0, 0
        except Exception:
            return 0, 0

# Global GitHub client instance
github_client = GitHubClient()
