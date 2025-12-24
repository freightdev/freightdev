-- Lead Generation Agency Database Schema
-- PostgreSQL 15+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Leads table - stores all potential leads
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    company_name VARCHAR(255),
    website VARCHAR(500),
    linkedin_url VARCHAR(500),
    industry VARCHAR(100),
    company_size VARCHAR(50),
    location VARCHAR(255),
    source VARCHAR(100) NOT NULL, -- linkedin, web_scraper, csv_import, etc.
    source_url VARCHAR(500),
    lead_score INTEGER DEFAULT 0, -- 0-100 AI qualification score
    status VARCHAR(50) DEFAULT 'new', -- new, contacted, replied, interested, not_interested, converted
    qualification_data JSONB, -- AI analysis results
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_contacted_at TIMESTAMP WITH TIME ZONE
);

-- Campaigns table
CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    target_sources TEXT[], -- Array of source names
    prompt_template VARCHAR(255),
    enabled BOOLEAN DEFAULT true,
    campaign_type VARCHAR(100), -- cold_outreach, job_application, etc.
    settings JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Outreach table - tracks all communications
CREATE TABLE outreach (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES campaigns(id),
    channel VARCHAR(50) NOT NULL, -- email, linkedin, sms
    type VARCHAR(50) NOT NULL, -- initial, follow_up, response
    subject VARCHAR(500),
    content TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, sent, failed, replied
    sent_at TIMESTAMP WITH TIME ZONE,
    replied BOOLEAN DEFAULT false,
    reply_content TEXT,
    reply_received_at TIMESTAMP WITH TIME ZONE,
    ai_response_sent BOOLEAN DEFAULT false,
    ai_response_content TEXT,
    ai_response_sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Calls table - tracks scheduled/completed calls
CREATE TABLE calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    outreach_id UUID REFERENCES outreach(id),
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, completed, cancelled, no_show
    duration_minutes INTEGER,
    notes TEXT,
    outcome VARCHAR(100), -- interested, not_interested, follow_up_needed, closed_won
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Scraping jobs table - tracks scraping activities
CREATE TABLE scraping_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source VARCHAR(100) NOT NULL,
    source_type VARCHAR(50) NOT NULL, -- linkedin, web_scraper, etc.
    status VARCHAR(50) DEFAULT 'running', -- running, completed, failed
    leads_found INTEGER DEFAULT 0,
    leads_imported INTEGER DEFAULT 0,
    error_message TEXT,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB
);

-- AI model usage tracking
CREATE TABLE ai_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name VARCHAR(100) NOT NULL,
    endpoint VARCHAR(255),
    request_type VARCHAR(100), -- lead_qualification, email_writing, etc.
    tokens_used INTEGER,
    response_time_ms INTEGER,
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance metrics
CREATE TABLE daily_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE UNIQUE NOT NULL,
    leads_found INTEGER DEFAULT 0,
    leads_contacted INTEGER DEFAULT 0,
    replies_received INTEGER DEFAULT 0,
    calls_booked INTEGER DEFAULT 0,
    calls_completed INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,2), -- percentage
    avg_lead_score DECIMAL(5,2),
    campaign_performance JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_leads_email ON leads(email);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_lead_score ON leads(lead_score DESC);
CREATE INDEX idx_leads_source ON leads(source);
CREATE INDEX idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX idx_outreach_lead_id ON outreach(lead_id);
CREATE INDEX idx_outreach_status ON outreach(status);
CREATE INDEX idx_outreach_sent_at ON outreach(sent_at DESC);
CREATE INDEX idx_calls_scheduled_time ON calls(scheduled_time);
CREATE INDEX idx_calls_status ON calls(status);
CREATE INDEX idx_scraping_jobs_source ON scraping_jobs(source);
CREATE INDEX idx_scraping_jobs_status ON scraping_jobs(status);
CREATE INDEX idx_ai_usage_model_name ON ai_usage(model_name);
CREATE INDEX idx_ai_usage_created_at ON ai_usage(created_at DESC);
CREATE INDEX idx_daily_metrics_date ON daily_metrics(date);

-- Triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_outreach_updated_at BEFORE UPDATE ON outreach
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_calls_updated_at BEFORE UPDATE ON calls
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_metrics_updated_at BEFORE UPDATE ON daily_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default campaign
INSERT INTO campaigns (name, description, target_sources, prompt_template, campaign_type) VALUES
('trucking_outreach', 'Outreach to trucking companies', ARRAY['linkedin_trucking', 'trucking_websites'], 'trucking_pitch', 'cold_outreach'),
('local_business_outreach', 'Outreach to local businesses', ARRAY['local_businesses', 'custom_list'], 'local_business_pitch', 'cold_outreach'),
('job_board_responses', 'Responses to job postings', ARRAY['indeed_jobs'], 'job_response', 'job_application');

-- Create view for hot leads (score >= 70)
CREATE VIEW hot_leads AS
SELECT l.*, 
       o.id as last_outreach_id,
       o.sent_at as last_contacted
FROM leads l
LEFT JOIN LATERAL (
    SELECT id, sent_at 
    FROM outreach 
    WHERE lead_id = l.id 
    AND status = 'sent' 
    ORDER BY sent_at DESC 
    LIMIT 1
) o ON true
WHERE l.lead_score >= 70 
AND l.status NOT IN ('converted', 'not_interested');

-- Create view for campaign performance
CREATE VIEW campaign_performance AS
SELECT 
    c.name,
    c.enabled,
    COUNT(DISTINCT l.id) as total_leads,
    COUNT(DISTINCT CASE WHEN l.lead_score >= 70 THEN l.id END) as hot_leads,
    COUNT(DISTINCT o.id) as outreach_sent,
    COUNT(DISTINCT CASE WHEN o.replied = true THEN o.id END) as replies_received,
    COUNT(DISTINCT ca.id) as calls_booked,
    ROUND(
        CASE 
            WHEN COUNT(DISTINCT o.id) > 0 
            THEN (COUNT(DISTINCT CASE WHEN o.replied = true THEN o.id END) * 100.0 / COUNT(DISTINCT o.id))
            ELSE 0 
        END, 2
    ) as reply_rate_percent,
    ROUND(AVG(l.lead_score), 2) as avg_lead_score
FROM campaigns c
LEFT JOIN leads l ON l.source = ANY(c.target_sources)
LEFT JOIN outreach o ON o.lead_id = l.id
LEFT JOIN calls ca ON ca.lead_id = l.id
GROUP BY c.id, c.name, c.enabled
ORDER BY reply_rate_percent DESC;