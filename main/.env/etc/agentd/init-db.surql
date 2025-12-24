-- Initialize SurrealDB Schema for Agency Forge
-- Database: codriver_agency
-- Namespace: openhwy

USE NS openhwy;
USE DB codriver_agency;

-- Agent State Tables
DEFINE TABLE coordinator_state SCHEMAFULL;
DEFINE FIELD id ON coordinator_state TYPE string;
DEFINE FIELD session_id ON coordinator_state TYPE string;
DEFINE FIELD context ON coordinator_state TYPE string;
DEFINE FIELD created_at ON coordinator_state TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON coordinator_state TYPE datetime DEFAULT time::now();

DEFINE TABLE assistant_state SCHEMAFULL;
DEFINE FIELD id ON assistant_state TYPE string;
DEFINE FIELD agent_name ON assistant_state TYPE string;
DEFINE FIELD context ON assistant_state TYPE string;
DEFINE FIELD created_at ON assistant_state TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON assistant_state TYPE datetime DEFAULT time::now();

-- Prompts Management
DEFINE TABLE prompts SCHEMAFULL;
DEFINE FIELD id ON prompts TYPE string;
DEFINE FIELD name ON prompts TYPE string;
DEFINE FIELD category ON prompts TYPE string;
DEFINE FIELD content ON prompts TYPE string;
DEFINE FIELD version ON prompts TYPE int DEFAULT 1;
DEFINE FIELD created_at ON prompts TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON prompts TYPE datetime DEFAULT time::now();

-- Operation Logs
DEFINE TABLE operation_logs SCHEMAFULL;
DEFINE FIELD id ON operation_logs TYPE string;
DEFINE FIELD agent_name ON operation_logs TYPE string;
DEFINE FIELD operation ON operation_logs TYPE string;
DEFINE FIELD status ON operation_logs TYPE string;
DEFINE FIELD details ON operation_logs TYPE option<string>;
DEFINE FIELD created_at ON operation_logs TYPE datetime DEFAULT time::now();

-- Recovery Checkpoints
DEFINE TABLE recovery_checkpoints SCHEMAFULL;
DEFINE FIELD id ON recovery_checkpoints TYPE string;
DEFINE FIELD checkpoint_type ON recovery_checkpoints TYPE string;
DEFINE FIELD data ON recovery_checkpoints TYPE string;
DEFINE FIELD created_at ON recovery_checkpoints TYPE datetime DEFAULT time::now();

-- Lead Generation Tables
DEFINE TABLE leads SCHEMAFULL;
DEFINE FIELD id ON leads TYPE string;
DEFINE FIELD source ON leads TYPE string;
DEFINE FIELD source_url ON leads TYPE string;
DEFINE FIELD title ON leads TYPE string;
DEFINE FIELD description ON leads TYPE option<string>;
DEFINE FIELD author ON leads TYPE option<string>;
DEFINE FIELD fit_score ON leads TYPE option<float>;
DEFINE FIELD category ON leads TYPE option<string>;
DEFINE FIELD pricing_estimate ON leads TYPE option<string>;
DEFINE FIELD status ON leads TYPE string DEFAULT "new";
DEFINE FIELD raw_data ON leads TYPE option<string>;
DEFINE FIELD analyzed_at ON leads TYPE option<datetime>;
DEFINE FIELD created_at ON leads TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON leads TYPE datetime DEFAULT time::now();

DEFINE INDEX leads_source ON leads FIELDS source;
DEFINE INDEX leads_status ON leads FIELDS status;
DEFINE INDEX leads_fit_score ON leads FIELDS fit_score;
DEFINE INDEX leads_created_at ON leads FIELDS created_at;

-- Lead Analysis Results
DEFINE TABLE lead_analysis SCHEMAFULL;
DEFINE FIELD id ON lead_analysis TYPE string;
DEFINE FIELD lead_id ON lead_analysis TYPE string;
DEFINE FIELD model_used ON lead_analysis TYPE string;
DEFINE FIELD fit_score ON lead_analysis TYPE float;
DEFINE FIELD category ON lead_analysis TYPE string;
DEFINE FIELD pricing_estimate ON lead_analysis TYPE string;
DEFINE FIELD reasoning ON lead_analysis TYPE string;
DEFINE FIELD tags ON lead_analysis TYPE array;
DEFINE FIELD created_at ON lead_analysis TYPE datetime DEFAULT time::now();

-- Outreach Messages
DEFINE TABLE outreach_messages SCHEMAFULL;
DEFINE FIELD id ON outreach_messages TYPE string;
DEFINE FIELD lead_id ON outreach_messages TYPE string;
DEFINE FIELD message_type ON outreach_messages TYPE string;
DEFINE FIELD subject ON outreach_messages TYPE option<string>;
DEFINE FIELD body ON outreach_messages TYPE string;
DEFINE FIELD status ON outreach_messages TYPE string DEFAULT "draft";
DEFINE FIELD sent_at ON outreach_messages TYPE option<datetime>;
DEFINE FIELD created_at ON outreach_messages TYPE datetime DEFAULT time::now();

-- Collection Jobs (for data-collector compatibility)
DEFINE TABLE collection_jobs SCHEMAFULL;
DEFINE FIELD id ON collection_jobs TYPE string;
DEFINE FIELD name ON collection_jobs TYPE string;
DEFINE FIELD job_type ON collection_jobs TYPE string;
DEFINE FIELD schedule ON collection_jobs TYPE string;
DEFINE FIELD enabled ON collection_jobs TYPE bool DEFAULT true;
DEFINE FIELD last_run ON collection_jobs TYPE option<datetime>;
DEFINE FIELD next_run ON collection_jobs TYPE option<datetime>;
DEFINE FIELD run_count ON collection_jobs TYPE int DEFAULT 0;
DEFINE FIELD success_count ON collection_jobs TYPE int DEFAULT 0;
DEFINE FIELD failure_count ON collection_jobs TYPE int DEFAULT 0;
DEFINE FIELD created_at ON collection_jobs TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON collection_jobs TYPE datetime DEFAULT time::now();
