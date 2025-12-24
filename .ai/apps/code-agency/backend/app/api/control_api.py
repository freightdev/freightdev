"""
Agency Control API
Manage services, agents, view logs, upload/download files
"""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import FileResponse, StreamingResponse
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import subprocess
import psutil
import os
from pathlib import Path
import json
from datetime import datetime

from .auth_api import get_current_user
from ..auth.jwt_handler import User

router = APIRouter(prefix="/api/control", tags=["control"], dependencies=[Depends(get_current_user)])

# Paths
AGENCY_ROOT = Path("/home/admin/WORKSPACE/.ai/agency-forge")
LOGS_DIR = AGENCY_ROOT / "logs"
PIDS_DIR = AGENCY_ROOT / "pids"


class ServiceInfo(BaseModel):
    name: str
    port: int
    status: str  # running, stopped, error
    pid: Optional[int] = None
    uptime: Optional[str] = None
    memory_mb: Optional[float] = None
    cpu_percent: Optional[float] = None


class ServiceAction(BaseModel):
    action: str  # start, stop, restart
    service: str


class LogRequest(BaseModel):
    service: str
    lines: int = 100


@router.get("/services", response_model=List[ServiceInfo])
async def list_services(current_user: User = Depends(get_current_user)):
    """List all agency services with their status"""

    services_config = [
        {"name": "api-gateway", "port": 9013, "pid_file": "api-gateway.pid"},
        {"name": "command-coordinator", "port": 9015, "pid_file": "command-coordinator.pid"},
        {"name": "file-ops", "port": 9014, "pid_file": "file-ops.pid"},
        {"name": "web-search", "port": 9002, "pid_file": "web-search.pid"},
        {"name": "web-scraper", "port": 9003, "pid_file": "web-scraper.pid"},
        {"name": "trading-agent", "port": 9007, "pid_file": "trading-agent.pid"},
        {"name": "data-collector", "port": 9006, "pid_file": "data-collector.pid"},
        {"name": "openvino-vision", "port": 9017, "pid_file": "openvino-vision.pid"},
        {"name": "ui-builder", "port": 9018, "pid_file": "ui-builder.pid"},
        {"name": "codriver-ide", "port": 8001, "pid_file": "codriver-ide.pid"},
    ]

    results = []

    for svc in services_config:
        pid_file = PIDS_DIR / svc["pid_file"]
        service_info = ServiceInfo(name=svc["name"], port=svc["port"], status="stopped")

        if pid_file.exists():
            try:
                pid = int(pid_file.read_text().strip())
                if psutil.pid_exists(pid):
                    process = psutil.Process(pid)
                    service_info.status = "running"
                    service_info.pid = pid

                    # Get process stats
                    try:
                        service_info.memory_mb = round(process.memory_info().rss / 1024 / 1024, 2)
                        service_info.cpu_percent = round(process.cpu_percent(interval=0.1), 2)

                        # Calculate uptime
                        create_time = datetime.fromtimestamp(process.create_time())
                        uptime_seconds = (datetime.now() - create_time).total_seconds()

                        if uptime_seconds < 60:
                            service_info.uptime = f"{int(uptime_seconds)}s"
                        elif uptime_seconds < 3600:
                            service_info.uptime = f"{int(uptime_seconds / 60)}m"
                        else:
                            hours = int(uptime_seconds / 3600)
                            minutes = int((uptime_seconds % 3600) / 60)
                            service_info.uptime = f"{hours}h {minutes}m"

                    except (psutil.NoSuchProcess, psutil.AccessDenied):
                        pass

            except (ValueError, FileNotFoundError, psutil.NoSuchProcess):
                service_info.status = "error"

        results.append(service_info)

    return results


@router.post("/service/action")
async def control_service(action: ServiceAction, current_user: User = Depends(get_current_user)):
    """Start, stop, or restart a service"""

    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Admin access required")

    service_name = action.service
    pid_file = PIDS_DIR / f"{service_name}.pid"

    try:
        if action.action == "stop":
            if not pid_file.exists():
                return {"success": False, "message": "Service not running"}

            pid = int(pid_file.read_text().strip())

            if psutil.pid_exists(pid):
                process = psutil.Process(pid)
                process.terminate()
                process.wait(timeout=10)

            pid_file.unlink(missing_ok=True)

            return {"success": True, "message": f"{service_name} stopped"}

        elif action.action == "start":
            # Execute start script
            start_script = AGENCY_ROOT / "start-agency.sh"

            if not start_script.exists():
                raise HTTPException(status_code=404, detail="Start script not found")

            # This will start all services - in production, have individual start scripts
            subprocess.Popen([str(start_script)], cwd=str(AGENCY_ROOT))

            return {"success": True, "message": "Services starting..."}

        elif action.action == "restart":
            # Stop then start
            await control_service(ServiceAction(action="stop", service=service_name), current_user)
            await control_service(ServiceAction(action="start", service=service_name), current_user)

            return {"success": True, "message": f"{service_name} restarted"}

        else:
            raise HTTPException(status_code=400, detail=f"Unknown action: {action.action}")

    except Exception as e:
        return {"success": False, "message": str(e)}


@router.post("/logs", response_model=Dict[str, Any])
async def get_service_logs(request: LogRequest, current_user: User = Depends(get_current_user)):
    """Get logs for a specific service"""

    log_file = LOGS_DIR / f"{request.service}.log"

    if not log_file.exists():
        return {"success": False, "message": "Log file not found", "logs": []}

    try:
        # Read last N lines
        with open(log_file, 'r') as f:
            lines = f.readlines()
            last_lines = lines[-request.lines:] if len(lines) > request.lines else lines

        return {
            "success": True,
            "service": request.service,
            "lines_returned": len(last_lines),
            "logs": [line.strip() for line in last_lines]
        }

    except Exception as e:
        return {"success": False, "message": str(e), "logs": []}


@router.post("/file/upload")
async def upload_file(file: UploadFile = File(...), current_user: User = Depends(get_current_user)):
    """Upload a file to the agency workspace"""

    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Admin access required")

    upload_dir = Path("/home/admin/.ai/uploads")
    upload_dir.mkdir(parents=True, exist_ok=True)

    file_path = upload_dir / file.filename

    # Save file
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)

    return {
        "success": True,
        "filename": file.filename,
        "size_bytes": len(content),
        "path": str(file_path)
    }


@router.get("/file/download/{filename}")
async def download_file(filename: str, current_user: User = Depends(get_current_user)):
    """Download a file from the agency workspace"""

    file_path = Path("/home/admin/.ai/uploads") / filename

    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File not found")

    return FileResponse(
        path=str(file_path),
        filename=filename,
        media_type='application/octet-stream'
    )


@router.get("/stats")
async def get_system_stats(current_user: User = Depends(get_current_user)):
    """Get system resource usage"""

    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')

    return {
        "cpu_percent": round(cpu_percent, 2),
        "memory_percent": round(memory.percent, 2),
        "memory_used_gb": round(memory.used / (1024**3), 2),
        "memory_total_gb": round(memory.total / (1024**3), 2),
        "disk_percent": round(disk.percent, 2),
        "disk_used_gb": round(disk.used / (1024**3), 2),
        "disk_total_gb": round(disk.total / (1024**3), 2),
    }
