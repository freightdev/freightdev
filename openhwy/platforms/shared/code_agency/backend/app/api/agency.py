"""
Agency API - Endpoints for interacting with Rust agency agents
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
import logging

from ...agents.agency_bridge import get_bridge

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/agency", tags=["agency"])


class FileReadRequest(BaseModel):
    path: str


class FileWriteRequest(BaseModel):
    path: str
    content: str


class CommandRequest(BaseModel):
    command: str
    working_dir: Optional[str] = None


class SearchRequest(BaseModel):
    query: str
    max_results: int = 10


class ScrapeRequest(BaseModel):
    url: str
    extract_links: bool = True


class NaturalLanguageRequest(BaseModel):
    instruction: str


@router.get("/health")
async def check_agency_health():
    """Check if agency API gateway is available"""
    bridge = get_bridge()
    is_healthy = await bridge.check_gateway_health()

    if is_healthy:
        return {"status": "online", "gateway": bridge.gateway_url}
    else:
        return {"status": "offline", "gateway": bridge.gateway_url}


@router.get("/services")
async def list_services():
    """Get list of available agency services"""
    bridge = get_bridge()
    services = await bridge.list_services()
    return {"services": services}


@router.post("/file/read")
async def read_file(request: FileReadRequest):
    """Read a file using file-ops agent"""
    bridge = get_bridge()
    result = await bridge.read_file(request.path)

    if "error" in result:
        raise HTTPException(status_code=500, detail=result.get("error"))

    return result


@router.post("/file/write")
async def write_file(request: FileWriteRequest):
    """Write to a file using file-ops agent"""
    bridge = get_bridge()
    result = await bridge.write_file(request.path, request.content)

    if "error" in result:
        raise HTTPException(status_code=500, detail=result.get("error"))

    return result


@router.post("/command/execute")
async def execute_command(request: CommandRequest):
    """Execute a shell command using file-ops agent"""
    bridge = get_bridge()
    result = await bridge.execute_command(request.command, request.working_dir)

    if "error" in result:
        raise HTTPException(status_code=500, detail=result.get("error"))

    return result


@router.post("/web/search")
async def web_search(request: SearchRequest):
    """Search the web using web-search agent"""
    bridge = get_bridge()
    result = await bridge.web_search(request.query, request.max_results)

    if "error" in result:
        raise HTTPException(status_code=500, detail=result.get("error"))

    return result


@router.post("/web/scrape")
async def scrape_url(request: ScrapeRequest):
    """Scrape a webpage using web-search agent"""
    bridge = get_bridge()
    result = await bridge.scrape_url(request.url, request.extract_links)

    if "error" in result:
        raise HTTPException(status_code=500, detail=result.get("error"))

    return result


@router.post("/nl/execute")
async def execute_natural_language(request: NaturalLanguageRequest):
    """
    Execute natural language instruction through command-coordinator
    This uses Ollama to parse intent and route to appropriate agents
    """
    bridge = get_bridge()
    result = await bridge.execute_natural_language(request.instruction)

    if "error" in result:
        raise HTTPException(status_code=500, detail=result.get("error"))

    return result


@router.post("/agent/call")
async def call_custom_agent(
    service_name: str,
    endpoint: str,
    method: str = "POST",
    data: Optional[Dict[str, Any]] = None
):
    """
    Generic endpoint to call any agency agent

    Args:
        service_name: Name of the service (e.g., 'file-ops', 'web-search')
        endpoint: Endpoint path
        method: HTTP method
        data: Request payload
    """
    bridge = get_bridge()
    result = await bridge.call_agent(service_name, endpoint, method, data)

    if "error" in result:
        raise HTTPException(status_code=500, detail=result.get("error"))

    return result
