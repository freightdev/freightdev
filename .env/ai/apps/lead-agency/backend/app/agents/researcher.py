"""
Researcher Agent - Enriches leads with context using Ollama
"""
from typing import Dict
from app.core.ollama_client import ollama_cluster


class ResearcherAgent:
    """Enriches leads with research and context"""

    def __init__(self):
        self.model = "gemma3:12b"
        self.node = "hostbox"  # Use L2 for reasoning

    def research_lead(self, lead: Dict) -> Dict:
        """
        Research and enrich a lead

        Args:
            lead: Lead dictionary

        Returns:
            Dictionary with research_notes, similar_projects, estimated_hours
        """
        prompt = self._build_research_prompt(lead)

        try:
            response = ollama_cluster.generate(
                model=self.model,
                prompt=prompt,
                node=self.node,
                temperature=0.7,
                max_tokens=800
            )

            research = self._parse_research_response(response)

            return research

        except Exception as e:
            print(f"Error researching lead: {e}")
            return {
                "research_notes": f"Research failed: {str(e)}",
                "similar_projects": [],
                "estimated_hours": None
            }

    def _build_research_prompt(self, lead: Dict) -> str:
        """Build research prompt"""

        tech_stack = ", ".join(lead.get('tech_stack', [])) if lead.get('tech_stack') else "Not specified"

        prompt = f"""You are a technical project analyst. Research this development lead and provide insights.

LEAD INFORMATION:
Title: {lead.get('title', 'N/A')}
Description: {lead.get('description', 'N/A')[:500]}
Company: {lead.get('company_name', 'Unknown')}
Tech Stack: {tech_stack}
Budget: ${lead.get('budget_min', 'Unknown')}-${lead.get('budget_max', 'Unknown')}

PROVIDE:

1. Company/Client Background (2-3 sentences)
   - What does the company do?
   - Size and maturity?
   - Any notable information?

2. Similar Projects (list 2-3 examples)
   - What similar projects exist?
   - What technologies were used?
   - What was the outcome?

3. Estimated Hours
   - Based on the description, estimate hours needed
   - Consider complexity and scope

4. Potential Challenges
   - Technical challenges
   - Timeline concerns
   - Resource requirements

Keep response concise and actionable. Total response should be 200-300 words.
"""

        return prompt

    def _parse_research_response(self, response: str) -> Dict:
        """Parse research response into structured data"""

        # Extract estimated hours if mentioned
        estimated_hours = None
        import re
        hours_match = re.search(r'(\d+)\s*hours', response, re.IGNORECASE)
        if hours_match:
            estimated_hours = int(hours_match.group(1))

        # For now, return as notes
        # TODO: Parse into structured fields
        return {
            "research_notes": response.strip(),
            "similar_projects": [],  # TODO: Extract from response
            "estimated_hours": estimated_hours
        }
