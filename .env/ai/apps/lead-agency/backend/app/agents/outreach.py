"""
Outreach Agent - Drafts personalized messages using Ollama
"""
from typing import Dict
from app.core.ollama_client import ollama_cluster


class OutreachAgent:
    """Drafts outreach messages for qualified leads"""

    def __init__(self):
        self.model = "qwen2.5:14b"
        self.node = "hostbox"  # Use L2 for reasoning

    def draft_outreach(self, lead: Dict) -> str:
        """
        Draft a personalized outreach message

        Args:
            lead: Lead dictionary

        Returns:
            Draft outreach message
        """
        prompt = self._build_outreach_prompt(lead)

        try:
            draft = ollama_cluster.generate(
                model=self.model,
                prompt=prompt,
                node=self.node,
                temperature=0.8,  # Higher temp for more creative writing
                max_tokens=600
            )

            return draft.strip()

        except Exception as e:
            print(f"Error drafting outreach: {e}")
            return f"[Draft failed: {str(e)}]"

    def _build_outreach_prompt(self, lead: Dict) -> str:
        """Build outreach prompt"""

        tech_stack = ", ".join(lead.get('tech_stack', [])) if lead.get('tech_stack') else "various technologies"
        budget_str = f"${lead.get('budget_min', 'N/A')}-${lead.get('budget_max', 'N/A')}"

        prompt = f"""You are drafting a professional outreach email for a freelance development opportunity.

LEAD INFORMATION:
Title: {lead.get('title', 'N/A')}
Description: {lead.get('description', 'N/A')[:300]}
Company: {lead.get('company_name', 'Unknown')}
Tech Stack: {tech_stack}
Budget: {budget_str}

YOUR BACKGROUND (Jesse E.E.W. Conley):
- 10+ years experience in trucking industry
- Full-stack developer (React, TypeScript, Next.js, Node.js, Go, Rust, Python)
- Specialized in logistics software and SaaS platforms
- Built multiple successful projects for trucking companies
- Strong focus on performance, reliability, and user experience

TONE:
- Professional but friendly
- Confident without being arrogant
- Show genuine interest in the project
- Demonstrate you understand their needs

EMAIL STRUCTURE:
1. Brief introduction (1-2 sentences)
2. Highlight relevant experience (2-3 sentences)
3. Show you understand their project (1-2 sentences)
4. Call to action - suggest a quick call (1 sentence)

CONSTRAINTS:
- Max 200 words
- No generic templates
- Personalize based on the project description
- Don't mention specific rates (budget is already known)
- End with your name and email

Draft the email now:
"""

        return prompt
