from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ARRAY, JSON
from sqlalchemy.sql import func
from app.core.database import Base


class Lead(Base):
    __tablename__ = "leads"

    id = Column(Integer, primary_key=True, index=True)

    # Source info
    source = Column(String(50), index=True)  # 'reddit', 'indeed', 'hackernews', etc.
    title = Column(Text, nullable=False)
    description = Column(Text)
    url = Column(Text)

    # Budget
    budget_min = Column(Integer)
    budget_max = Column(Integer)

    # Technical details
    tech_stack = Column(ARRAY(String), default=[])

    # Contact info
    company_name = Column(String(255))
    contact_email = Column(String(255))
    contact_name = Column(String(255))

    # Scoring
    score = Column(Integer, default=0, index=True)
    score_breakdown = Column(JSON)  # Detailed scoring
    qualified = Column(Boolean, default=False, index=True)

    # Enrichment
    research_notes = Column(Text)
    similar_projects = Column(JSON)
    estimated_hours = Column(Integer)

    # Outreach
    outreach_draft = Column(Text)
    outreach_sent = Column(Boolean, default=False)

    # Status tracking
    status = Column(String(50), default='new', index=True)
    # Status values: 'new', 'qualified', 'reached_out', 'responded', 'won', 'lost'

    # Timestamps
    found_at = Column(DateTime(timezone=True), server_default=func.now())
    qualified_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    def __repr__(self):
        return f"<Lead(id={self.id}, title='{self.title[:50]}', score={self.score})>"
