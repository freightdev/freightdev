"""
Qualifier Agent - Scores and filters leads using config-based rules
"""
import re
from typing import Dict, Tuple, List
from app.config.settings import config


class QualifierAgent:
    """Scores leads 0-100 using rules from config/scoring.yaml"""

    def __init__(self):
        self.config = config

    def qualify_lead(self, lead: Dict) -> Tuple[int, Dict, str]:
        """
        Score a lead 0-100 using config-based scoring rules

        Args:
            lead: Lead dictionary with title, description, budget, etc.

        Returns:
            Tuple of (score, breakdown, notes)
        """
        breakdown = {}
        notes = []

        # Get lead data
        title = lead.get('title', '')
        description = lead.get('description', '')
        full_text = (title + " " + description).lower()
        budget_min = lead.get('budget_min', 0)
        tech_stack = lead.get('tech_stack', [])

        # 1. Budget Scoring (30 points max)
        budget_score = self._score_budget(budget_min)
        breakdown['budget'] = budget_score

        # 2. Description Scoring (20 points max)
        desc_score = self._score_description(description, full_text)
        breakdown['description'] = desc_score

        # 3. Tech Stack Scoring (15 points max)
        tech_score = self._score_tech_stack(tech_stack, full_text)
        breakdown['tech_stack'] = tech_score

        # 4. Client Quality Scoring (20 points max)
        client_score = self._score_client_quality(full_text)
        breakdown['client_quality'] = client_score

        # 5. Timeline Scoring (10 points max)
        timeline_score = self._score_timeline(full_text)
        breakdown['timeline'] = timeline_score

        # 6. Engagement Scoring (5 points max)
        engagement_score = self._score_engagement(full_text)
        breakdown['engagement'] = engagement_score

        # 7. Apply Penalties
        penalties_score = self._apply_penalties(full_text)
        breakdown['penalties'] = penalties_score

        # Calculate total score
        total_score = (
            budget_score +
            desc_score +
            tech_score +
            client_score +
            timeline_score +
            engagement_score +
            penalties_score
        )

        # Clamp to 0-100
        total_score = max(0, min(100, total_score))

        # Build notes
        notes_list = []
        if budget_min:
            notes_list.append(f"Budget: ${budget_min:,}")
        if tech_stack:
            notes_list.append(f"Tech: {', '.join(tech_stack[:3])}")
        if penalties_score < 0:
            notes_list.append(f"⚠️ Penalties: {penalties_score}")

        notes_str = " | ".join(notes_list) if notes_list else "No details available"

        return int(total_score), breakdown, notes_str

    def _score_budget(self, budget_min: int) -> int:
        """Score based on budget ranges from config"""
        if not budget_min:
            return 0

        for budget_range in self.config.scoring.budget_scoring['ranges']:
            min_val = budget_range['min']
            max_val = budget_range.get('max')

            if max_val is None:
                # No upper limit
                if budget_min >= min_val:
                    return budget_range['points']
            else:
                # Has upper limit
                if min_val <= budget_min <= max_val:
                    return budget_range['points']

        return 0

    def _score_description(self, description: str, full_text: str) -> int:
        """Score based on description quality from config"""
        if not description:
            return 0

        score = 0
        word_count = len(description.split())

        # Score based on word count
        for wc_range in self.config.scoring.description_scoring['word_count']:
            if word_count >= wc_range['min']:
                score = wc_range['points']
                break

        # Bonus for requirements
        if any(word in full_text for word in ['require', 'requirement', 'specification', 'feature', 'must have']):
            score += self.config.scoring.description_scoring['has_requirements']

        # Bonus for timeline
        if any(word in full_text for word in ['timeline', 'deadline', 'delivery', 'week', 'month']):
            score += self.config.scoring.description_scoring['has_timeline']

        # Bonus for formatting (bullets, numbers)
        if re.search(r'[-*•]\s+|\d+\.\s+', description):
            score += self.config.scoring.description_scoring['well_formatted']

        # Cap at 20 points
        return min(20, score)

    def _score_tech_stack(self, tech_stack: List[str], full_text: str) -> int:
        """Score based on tech stack match from config"""
        score = 0
        preferred_tech = [t.lower() for t in self.config.filters.tech_stack.preferred]
        avoided_tech = [t.lower() for t in self.config.filters.tech_stack.avoid]

        # Count preferred tech matches
        preferred_count = 0
        for tech in tech_stack:
            if tech.lower() in preferred_tech:
                preferred_count += 1

        score += preferred_count * self.config.scoring.tech_stack_scoring['preferred_tech_points']

        # Penalty for avoided tech
        for tech in tech_stack:
            if tech.lower() in avoided_tech:
                score += self.config.scoring.tech_stack_scoring['avoided_tech_penalty']

        # Cap at 15 points (can go negative)
        return max(-15, min(15, score))

    def _score_client_quality(self, full_text: str) -> int:
        """Score based on client quality indicators from config"""
        score = 0

        # Check for company indicators
        company_indicators = self.config.scoring.client_quality_scoring['company_indicators']
        points_per_company = self.config.scoring.client_quality_scoring['points_per_indicator']

        for indicator in company_indicators:
            if indicator.lower() in full_text:
                score += points_per_company
                break  # Only count once

        # Check for startup indicators (higher value)
        startup_indicators = self.config.scoring.client_quality_scoring['startup_indicators']
        points_per_startup = self.config.scoring.client_quality_scoring.get('points_per_indicator', 5)

        for indicator in startup_indicators:
            if indicator.lower() in full_text:
                score += points_per_startup
                break  # Only count once

        # Default individual points if no company/startup found
        if score == 0:
            score = self.config.scoring.client_quality_scoring['individual_points']

        # Cap at 20 points
        return min(20, score)

    def _score_timeline(self, full_text: str) -> int:
        """Score based on timeline reasonableness from config"""
        score = 0

        # Check for reasonable timeline
        if any(word in full_text for word in ['timeline', 'deadline', 'delivery date']):
            score += self.config.scoring.timeline_scoring['has_timeline']

        # Check for realistic timeline (not ASAP)
        if 'asap' not in full_text and 'urgent' not in full_text and 'immediately' not in full_text:
            score += self.config.scoring.timeline_scoring['realistic']

        # Bonus for long-term/ongoing work
        if any(word in full_text for word in ['ongoing', 'long-term', 'maintenance', 'retainer']):
            score += self.config.scoring.timeline_scoring['ongoing']

        # Cap at 10 points
        return min(10, score)

    def _score_engagement(self, full_text: str) -> int:
        """Score based on engagement indicators from config"""
        score = 0

        # Check for portfolio/examples
        if any(word in full_text for word in ['portfolio', 'examples', 'previous work', 'samples']):
            score += self.config.scoring.engagement_scoring['has_examples']

        # Check for detailed communication
        if len(full_text.split()) > 100:  # Detailed post
            score += self.config.scoring.engagement_scoring['detailed']

        # Cap at 5 points
        return min(5, score)

    def _apply_penalties(self, full_text: str) -> int:
        """Apply penalties for red flags from config"""
        penalty = 0

        # Check quality red flags from filters config
        red_flags = [rf.lower() for rf in self.config.filters.quality_indicators['red_flags']]
        for flag in red_flags:
            if flag in full_text:
                penalty += self.config.scoring.penalties['red_flag']
                break  # Apply penalty once

        # Check for urgent/desperate
        if 'asap' in full_text or 'urgent' in full_text or 'immediately' in full_text:
            penalty += self.config.scoring.penalties['urgent']

        # Check for unrealistic expectations
        if any(word in full_text for word in ['like facebook', 'like uber', 'like amazon', 'clone']):
            penalty += self.config.scoring.penalties['unrealistic']

        return penalty
