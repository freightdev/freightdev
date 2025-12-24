#!/usr/bin/env python3
"""
Simple webhook server to trigger data collection
Useful for CoDriver or external automation
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess
import json
from urllib.parse import urlparse, parse_qs

ORCHESTRATOR = "/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/srv/agent.todo/src/scripts/data-collector-orchestrator.py"
TRUCKING_CONFIG = "/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/etc/agentd/config/trucking-sources.yaml"
HOUSING_CONFIG = "/home/admin/WORKSPACE/projects/ACTIVE/codriver/.codriver.d/etc/agentd/config/housing-sources.yaml"

class WebhookHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Health check"""
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Data Collection Webhook: ONLINE")
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        """Trigger collection"""
        parsed = urlparse(self.path)

        if parsed.path == "/trigger/trucking":
            self._run_collection(TRUCKING_CONFIG, "Trucking")
        elif parsed.path == "/trigger/housing":
            self._run_collection(HOUSING_CONFIG, "Housing")
        elif parsed.path == "/trigger/both":
            self._run_collection(TRUCKING_CONFIG, "Trucking")
            self._run_collection(HOUSING_CONFIG, "Housing")
        else:
            self.send_response(404)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "error": "Not found",
                "available_endpoints": [
                    "/trigger/trucking",
                    "/trigger/housing",
                    "/trigger/both"
                ]
            }).encode())

    def _run_collection(self, config, name):
        """Run collection script"""
        try:
            result = subprocess.run(
                ["python3", ORCHESTRATOR, config],
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()

            response = {
                "success": result.returncode == 0,
                "collection": name,
                "output": result.stdout,
                "error": result.stderr if result.returncode != 0 else None
            }

            self.wfile.write(json.dumps(response, indent=2).encode())

        except Exception as e:
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "error": str(e),
                "collection": name
            }).encode())

    def log_message(self, format, *args):
        """Custom logging"""
        print(f"[{self.log_date_time_string()}] {format % args}")

if __name__ == "__main__":
    PORT = 9007
    server = HTTPServer(("127.0.0.1", PORT), WebhookHandler)
    print(f"🌐 Data Collection Webhook running on http://127.0.0.1:{PORT}")
    print(f"")
    print(f"Endpoints:")
    print(f"  GET  /health              - Health check")
    print(f"  POST /trigger/trucking    - Trigger trucking collection")
    print(f"  POST /trigger/housing     - Trigger housing collection")
    print(f"  POST /trigger/both        - Trigger both collections")
    print(f"")
    print(f"Example: curl -X POST http://127.0.0.1:{PORT}/trigger/trucking")
    print(f"")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n👋 Shutting down webhook server")
        server.shutdown()
