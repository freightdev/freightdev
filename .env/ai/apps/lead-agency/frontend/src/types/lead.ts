export interface Lead {
  id: number;
  source: string;
  title: string;
  description: string | null;
  url: string | null;
  budget_min: number | null;
  budget_max: number | null;
  tech_stack: string[];
  score: number;
  qualified: boolean;
  status: string;
  found_at: string;
}

export interface LeadDetail extends Lead {
  company_name: string | null;
  contact_email: string | null;
  score_breakdown: Record<string, any> | null;
  research_notes: string | null;
  estimated_hours: number | null;
  outreach_draft: string | null;
}

export interface Stats {
  total_leads: number;
  qualified_leads: number;
  average_score: number;
  by_source: Record<string, number>;
}
