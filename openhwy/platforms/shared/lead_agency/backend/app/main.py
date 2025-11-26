"""
Lead Agency FastAPI Application
"""
from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from app.core.database import get_db, init_db
from app.models.lead import Lead
from app.agents.scout import ScoutAgent
from app.agents.qualifier import QualifierAgent
from app.agents.researcher import ResearcherAgent
from app.agents.outreach import OutreachAgent

# FastAPI app
app = FastAPI(title="Lead Agency API", version="2.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database on startup
@app.on_event("startup")
async def startup():
    init_db()
    print("✅ Database initialized")


# ============================================================================
# Pydantic Models (Request/Response schemas)
# ============================================================================

class SearchRequest(BaseModel):
    categories: List[str] = ["web_development"]
    min_budget: int = 1000
    max_budget: Optional[int] = None
    sources: List[str] = ["reddit", "hackernews"]
    min_score: int = 70


class LeadResponse(BaseModel):
    id: int
    source: str
    title: str
    description: Optional[str]
    url: Optional[str]
    budget_min: Optional[int]
    budget_max: Optional[int]
    tech_stack: List[str]
    score: int
    qualified: bool
    status: str
    found_at: datetime

    class Config:
        from_attributes = True


class LeadDetailResponse(LeadResponse):
    company_name: Optional[str]
    contact_email: Optional[str]
    score_breakdown: Optional[dict]
    research_notes: Optional[str]
    estimated_hours: Optional[int]
    outreach_draft: Optional[str]

    class Config:
        from_attributes = True


# ============================================================================
# API Endpoints
# ============================================================================

@app.get("/")
async def root():
    """Health check"""
    return {
        "service": "Lead Agency API",
        "version": "2.0.0",
        "status": "running"
    }


@app.post("/api/search")
async def start_search(
    request: SearchRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Start a lead search campaign

    This runs in the background and processes leads through all agents
    """
    search_id = f"search_{int(datetime.now().timestamp())}"

    # Add background task
    background_tasks.add_task(
        run_lead_search,
        db=db,
        search_id=search_id,
        categories=request.categories,
        min_budget=request.min_budget,
        sources=request.sources,
        min_score=request.min_score
    )

    return {
        "search_id": search_id,
        "status": "running",
        "sources_count": len(request.sources),
        "estimated_time": "5-10 minutes"
    }


@app.get("/api/leads", response_model=List[LeadResponse])
async def get_leads(
    min_score: int = 0,
    status: Optional[str] = None,
    source: Optional[str] = None,
    limit: int = 50,
    skip: int = 0,
    db: Session = Depends(get_db)
):
    """Get list of leads with filters"""

    query = db.query(Lead)

    # Apply filters
    if min_score > 0:
        query = query.filter(Lead.score >= min_score)

    if status:
        query = query.filter(Lead.status == status)

    if source:
        query = query.filter(Lead.source == source)

    # Order by score descending
    query = query.order_by(Lead.score.desc())

    # Pagination
    leads = query.offset(skip).limit(limit).all()

    return leads


@app.get("/api/leads/{lead_id}", response_model=LeadDetailResponse)
async def get_lead(lead_id: int, db: Session = Depends(get_db)):
    """Get full lead details"""

    lead = db.query(Lead).filter(Lead.id == lead_id).first()

    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")

    return lead


@app.get("/api/stats")
async def get_stats(db: Session = Depends(get_db)):
    """Get statistics about leads"""

    total = db.query(Lead).count()
    qualified = db.query(Lead).filter(Lead.qualified == True).count()
    avg_score = db.query(Lead).with_entities(Lead.score).all()

    # Calculate average
    if avg_score:
        avg = sum([s[0] for s in avg_score if s[0]]) / len([s for s in avg_score if s[0]])
    else:
        avg = 0

    # By source
    sources = db.query(Lead.source, func.count(Lead.id)).group_by(Lead.source).all()

    return {
        "total_leads": total,
        "qualified_leads": qualified,
        "average_score": round(avg, 1),
        "by_source": {source: count for source, count in sources}
    }


# ============================================================================
# Background Task - Lead Search Pipeline
# ============================================================================

def run_lead_search(
    db: Session,
    search_id: str,
    categories: List[str],
    min_budget: int,
    sources: List[str],
    min_score: int
):
    """
    Run the full lead search pipeline

    1. Scout finds raw leads
    2. Qualifier scores them
    3. Researcher enriches top leads
    4. Outreach drafts messages
    """
    print(f"\n🔍 Starting search: {search_id}")

    # Initialize agents
    scout = ScoutAgent()
    qualifier = QualifierAgent()
    researcher = ResearcherAgent()
    outreach = OutreachAgent()

    # Step 1: Scout finds leads
    print("📡 Scout: Finding leads...")
    raw_leads = scout.search_all(categories=categories, min_budget=min_budget)
    print(f"   Found {len(raw_leads)} raw leads")

    qualified_count = 0

    for lead_data in raw_leads:
        # Step 2: Qualifier scores lead
        print(f"   Scoring: {lead_data['title'][:50]}...")
        score, breakdown, notes = qualifier.qualify_lead(lead_data)

        # Skip if below minimum score
        if score < min_score:
            print(f"   ❌ Score {score} < {min_score}, skipping")
            continue

        print(f"   ✅ Score {score} - QUALIFIED")
        qualified_count += 1

        # Create lead in database
        lead = Lead(
            source=lead_data['source'],
            title=lead_data['title'],
            description=lead_data.get('description'),
            url=lead_data.get('url'),
            budget_min=lead_data.get('budget_min'),
            budget_max=lead_data.get('budget_max'),
            tech_stack=lead_data.get('tech_stack', []),
            score=score,
            score_breakdown=breakdown,
            qualified=True,
            status='qualified'
        )

        db.add(lead)
        db.commit()
        db.refresh(lead)

        # Step 3: Research lead (for top scores only)
        if score >= 80:
            print(f"   🔬 Researching high-value lead...")
            research = researcher.research_lead(lead_data)

            lead.research_notes = research.get('research_notes')
            lead.estimated_hours = research.get('estimated_hours')

            # Step 4: Draft outreach
            print(f"   ✉️  Drafting outreach...")
            draft = outreach.draft_outreach(lead_data)

            lead.outreach_draft = draft

            db.commit()

    print(f"\n✅ Search complete: {qualified_count}/{len(raw_leads)} leads qualified")
    print(f"   Min score: {min_score}")
