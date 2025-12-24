"""
Agency Bridge - Connect Python IDE to Rust Agency Agents
Provides unified interface to call Rust agents through API Gateway
"""

import httpx
import logging
from typing import Dict, List, Optional, Any
import json

logger = logging.getLogger(__name__)

class AgencyBridge:
    """Bridge to communicate with Rust agency agents via API Gateway"""

    def __init__(self, gateway_url: str = "http://127.0.0.1:9013"):
        self.gateway_url = gateway_url
        self.client = httpx.AsyncClient(timeout=30.0)
        logger.info(f"Agency Bridge initialized with gateway: {gateway_url}")

    async def close(self):
        """Close the HTTP client"""
        await self.client.aclose()

    async def check_gateway_health(self) -> bool:
        """Check if API gateway is available"""
        try:
            response = await self.client.get(f"{self.gateway_url}/health")
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Gateway health check failed: {e}")
            return False

    async def list_services(self) -> List[Dict[str, Any]]:
        """Get list of available agency services"""
        try:
            response = await self.client.get(f"{self.gateway_url}/services")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to list services: {e}")
            return []

    async def call_agent(
        self,
        service_name: str,
        endpoint: str,
        method: str = "POST",
        data: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Call a Rust agent through the API gateway

        Args:
            service_name: Name of the service (e.g., 'file-ops', 'web-search')
            endpoint: Endpoint path (e.g., 'read', 'search')
            method: HTTP method (GET, POST, etc.)
            data: Request data/payload

        Returns:
            Response from the agent
        """
        url = f"{self.gateway_url}/api/{service_name}/{endpoint}"

        try:
            if method.upper() == "GET":
                response = await self.client.get(url, params=data)
            elif method.upper() == "POST":
                response = await self.client.post(url, json=data)
            elif method.upper() == "PUT":
                response = await self.client.put(url, json=data)
            elif method.upper() == "DELETE":
                response = await self.client.delete(url)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")

            response.raise_for_status()
            return response.json()

        except httpx.HTTPStatusError as e:
            logger.error(f"Agent call failed ({service_name}/{endpoint}): {e}")
            return {"error": f"HTTP {e.response.status_code}", "detail": str(e)}
        except Exception as e:
            logger.error(f"Agent call error ({service_name}/{endpoint}): {e}")
            return {"error": "Request failed", "detail": str(e)}

    # === File Operations ===

    async def read_file(self, file_path: str) -> Dict[str, Any]:
        """Read a file using file-ops agent"""
        return await self.call_agent(
            "file-ops",
            "read",
            data={"path": file_path}
        )

    async def write_file(self, file_path: str, content: str) -> Dict[str, Any]:
        """Write to a file using file-ops agent"""
        return await self.call_agent(
            "file-ops",
            "write",
            data={"path": file_path, "content": content}
        )

    async def execute_command(self, command: str, working_dir: Optional[str] = None) -> Dict[str, Any]:
        """Execute a shell command using file-ops agent"""
        data = {"command": command}
        if working_dir:
            data["working_dir"] = working_dir
        return await self.call_agent(
            "file-ops",
            "execute",
            data=data
        )

    # === Web Search ===

    async def web_search(self, query: str, max_results: int = 10) -> Dict[str, Any]:
        """Search the web using web-search agent"""
        return await self.call_agent(
            "web-search",
            "search",
            data={"query": query, "max_results": max_results}
        )

    async def scrape_url(self, url: str, extract_links: bool = True) -> Dict[str, Any]:
        """Scrape a webpage using web-search agent"""
        return await self.call_agent(
            "web-search",
            "scrape",
            data={"url": url, "extract_links": extract_links}
        )

    # === Data Collection ===

    async def collect_data(self, source: str, config: Dict[str, Any]) -> Dict[str, Any]:
        """Trigger data collection using data-collector agent"""
        return await self.call_agent(
            "data-collector",
            "collect",
            data={"source": source, "config": config}
        )

    # === Code Assistant ===

    async def analyze_code(self, code: str, language: str = "python") -> Dict[str, Any]:
        """Analyze code using code-assistant agent"""
        return await self.call_agent(
            "code-assistant",
            "analyze",
            data={"code": code, "language": language}
        )

    # === Command Coordinator (Natural Language Processing) ===

    async def execute_natural_language(self, instruction: str) -> Dict[str, Any]:
        """
        Execute natural language instruction through command-coordinator
        Uses Ollama to parse intent and route to appropriate agents
        """
        try:
            # Command coordinator is on port 9015 directly
            url = "http://127.0.0.1:9015/execute"
            response = await self.client.post(url, json={"command": instruction})
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Natural language execution failed: {e}")
            return {"error": "Execution failed", "detail": str(e)}


# Global instance
_bridge = None

def get_bridge() -> AgencyBridge:
    """Get or create the global agency bridge instance"""
    global _bridge
    if _bridge is None:
        _bridge = AgencyBridge()
    return _bridge

async def close_bridge():
    """Close the global bridge instance"""
    global _bridge
    if _bridge:
        await _bridge.close()
        _bridge = None
