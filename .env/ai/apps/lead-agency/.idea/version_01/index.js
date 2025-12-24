// ============================================
// LEAD ENGINE - MAIN ORCHESTRATOR
// ============================================
// This runs continuously, reading config and executing campaigns

const fs = require("fs");
const toml = require("toml");
const { Pool } = require("pg");
const Redis = require("ioredis");
const cron = require("node-cron");

class LeadEngine {
  constructor() {
    this.configPath = process.env.CONFIG_PATH || "/app/config.toml";
    this.config = null;
    this.db = null;
    this.redis = null;
    this.ollamaIndex = 0;
    this.isRunning = false;
    this.scrapers = {};
  }

  // ============================================
  // INITIALIZATION
  // ============================================
  async initialize() {
    console.log("🚀 Lead Engine initializing...");

    try {
      // Load configuration
      this.loadConfig();
      console.log("✓ Configuration loaded");

      // Connect to PostgreSQL
      this.db = new Pool({
        connectionString: process.env.DATABASE_URL,
        max: 20,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 5000,
      });
      await this.db.query("SELECT NOW()");
      console.log("✓ PostgreSQL connected");

      // Connect to Redis
      this.redis = new Redis(process.env.REDIS_URL);
      await this.redis.ping();
      console.log("✓ Redis connected");

      // Load scraper modules
      this.loadScrapers();
      console.log("✓ Scrapers loaded");

      // Verify Ollama instances
      await this.verifyOllamaInstances();

      console.log("✅ Lead Engine ready!\n");
    } catch (error) {
      console.error("❌ Initialization failed:", error);
      throw error;
    }
  }

  loadConfig() {
    try {
      const configFile = fs.readFileSync(this.configPath, "utf8");
      this.config = toml.parse(configFile);

      // Validate config
      if (
        !this.config.engine ||
        !this.config.ollama ||
        !this.config.campaigns
      ) {
        throw new Error("Invalid config structure");
      }
    } catch (error) {
      throw new Error(`Failed to load config: ${error.message}`);
    }
  }

  reloadConfig() {
    console.log("🔄 Reloading configuration...");
    const oldConfig = this.config;
    try {
      this.loadConfig();
      console.log("✓ Configuration reloaded");
      return true;
    } catch (error) {
      console.error("Failed to reload config, keeping old one:", error);
      this.config = oldConfig;
      return false;
    }
  }

  loadScrapers() {
    const scraperDir = "/app/scrapers";
    if (!fs.existsSync(scraperDir)) {
      console.warn("Scraper directory not found, skipping");
      return;
    }

    const scraperFiles = fs
      .readdirSync(scraperDir)
      .filter((f) => f.endsWith(".js"));

    for (const file of scraperFiles) {
      try {
        const ScraperClass = require(`${scraperDir}/${file}`);
        const scraperName = file.replace(".js", "");
        this.scrapers[scraperName] = new ScraperClass(this);
        console.log(`  - Loaded scraper: ${scraperName}`);
      } catch (error) {
        console.error(`  - Failed to load ${file}:`, error.message);
      }
    }
  }

  async verifyOllamaInstances() {
    console.log("🔍 Verifying Ollama instances...");
    const endpoints = this.config.ollama.primary_endpoints;
    const working = [];

    for (const endpoint of endpoints) {
      try {
        const response = await fetch(`${endpoint}/api/tags`, {
          signal: AbortSignal.timeout(5000),
        });
        if (response.ok) {
          working.push(endpoint);
          console.log(`  ✓ ${endpoint}`);
        }
      } catch (error) {
        console.log(`  ✗ ${endpoint} - ${error.message}`);
      }
    }

    if (working.length === 0) {
      throw new Error("No Ollama instances available!");
    }

    console.log(
      `✓ ${working.length}/${endpoints.length} Ollama instances working`,
    );
  }

  // ============================================
  // OLLAMA ORCHESTRATION
  // ============================================
  getOllamaEndpoint() {
    const strategy = this.config.ollama.load_balance_strategy;
    const endpoints = this.config.ollama.primary_endpoints;

    switch (strategy) {
      case "round-robin":
        const endpoint = endpoints[this.ollamaIndex % endpoints.length];
        this.ollamaIndex++;
        return endpoint;

      case "random":
        return endpoints[Math.floor(Math.random() * endpoints.length)];

      default:
        return endpoints[0];
    }
  }

  async callOllama(prompt, taskType = "lead_qualification") {
    const model = this.config.ollama.models[taskType] || "llama3.2:13b";
    const maxRetries = this.config.ollama.max_retries;
    const timeout = this.config.ollama.timeout_seconds * 1000;

    let lastError;

    for (let attempt = 0; attempt < maxRetries; attempt++) {
      const endpoint = this.getOllamaEndpoint();

      try {
        const startTime = Date.now();

        const response = await fetch(`${endpoint}/api/generate`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            model,
            prompt,
            stream: false,
            options: {
              temperature: 0.3,
              num_predict: 600,
            },
          }),
          signal: AbortSignal.timeout(timeout),
        });

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();
        const responseTime = Date.now() - startTime;

        // Log usage
        await this.logAIUsage({
          model_name: model,
          endpoint,
          task_type: taskType,
          response_time_ms: responseTime,
          completion_tokens: data.response?.length || 0,
        });

        return {
          response: data.response,
          model,
          endpoint,
          responseTime,
        };
      } catch (error) {
        lastError = error;
        console.error(
          `Ollama attempt ${attempt + 1} failed (${endpoint}):`,
          error.message,
        );

        if (attempt < maxRetries - 1) {
          await new Promise((r) =>
            setTimeout(r, this.config.ollama.retry_delay_seconds * 1000),
          );
        }
      }
    }

    // All retries failed - try cloud fallback
    if (this.config.ollama.enable_cloud_fallback) {
      console.log("☁️ Falling back to cloud provider...");
      return await this.callCloudFallback(prompt, taskType);
    }

    throw new Error(`All Ollama instances failed: ${lastError.message}`);
  }

  async callCloudFallback(prompt, taskType) {
    const provider = this.config.ollama.cloud_fallback_provider;
    const apiKey = process.env.CLOUD_API_KEY;

    if (!apiKey) {
      throw new Error("Cloud API key not configured");
    }

    const startTime = Date.now();

    if (provider === "anthropic") {
      const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 1000,
          messages: [{ role: "user", content: prompt }],
        }),
      });

      const data = await response.json();
      const responseTime = Date.now() - startTime;

      await this.logAIUsage({
        model_name: "claude-sonnet-4",
        endpoint: "anthropic-cloud",
        task_type: taskType,
        response_time_ms: responseTime,
        prompt_tokens: data.usage?.input_tokens || 0,
        completion_tokens: data.usage?.output_tokens || 0,
        estimated_cost:
          data.usage?.input_tokens * 0.000003 +
          data.usage?.output_tokens * 0.000015,
      });

      return {
        response: data.content[0].text,
        model: "claude-sonnet-4",
        endpoint: "cloud-fallback",
        responseTime,
      };
    }

    throw new Error(`Cloud provider '${provider}' not implemented`);
  }

  // ============================================
  // PROMPT BUILDING
  // ============================================
  buildPrompt(templateName, variables) {
    const template = this.config.prompts[templateName];
    if (!template) {
      throw new Error(`Prompt template '${templateName}' not found`);
    }

    let prompt = template.system || "";

    // Add the main prompt content
    const mainPrompt =
      template.qualification ||
      template.initial_email_body ||
      template.response_handling ||
      "";

    if (mainPrompt) {
      prompt += "\n\n" + mainPrompt;
    }

    // Replace all variables
    Object.keys(variables).forEach((key) => {
      const regex = new RegExp(`{{${key}}}`, "g");
      prompt = prompt.replace(regex, String(variables[key] || ""));
    });

    return prompt;
  }

  // ============================================
  // LEAD QUALIFICATION
  // ============================================
  async qualifyLead(leadData, campaignName) {
    try {
      const campaign = this.config.campaigns.find(
        (c) => c.name === campaignName,
      );
      if (!campaign) {
        throw new Error(`Campaign '${campaignName}' not found`);
      }

      const prompt = this.buildPrompt(campaign.prompt_template, {
        LEAD_DATA: JSON.stringify(leadData, null, 2),
      });

      const result = await this.callOllama(prompt, "lead_qualification");

      // Parse JSON from AI response
      const jsonMatch = result.response.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error("AI did not return valid JSON");
      }

      const qualification = JSON.parse(jsonMatch[0]);

      // Store lead in database
      const leadId = await this.storeLead({
        ...leadData,
        ...qualification,
        source_campaign: campaignName,
        ai_model_used: result.model,
        processing_time_ms: result.responseTime,
      });

      await this.log(
        "info",
        "lead-engine",
        `Lead qualified: ${leadData.email} (score: ${qualification.lead_score})`,
        {
          lead_id: leadId,
          campaign_name: campaignName,
        },
      );

      return { leadId, qualification };
    } catch (error) {
      await this.log(
        "error",
        "lead-engine",
        `Failed to qualify lead: ${error.message}`,
        {
          campaign_name: campaignName,
          lead_data: leadData,
        },
      );
      throw error;
    }
  }

  async storeLead(leadData) {
    const query = `
      INSERT INTO leads (
        email, first_name, last_name, full_name, company_name, phone,
        linkedin_url, website, source_type, source_url, source_campaign,
        industry, company_size, job_title, lead_score, budget_estimate,
        pain_points, likely_needs, qualification_notes, qualification_status,
        raw_data, ai_model_used, processing_time_ms
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
        $16, $17, $18, $19, $20, $21, $22, $23
      )
      ON CONFLICT (email) DO UPDATE SET
        lead_score = EXCLUDED.lead_score,
        qualification_notes = EXCLUDED.qualification_notes,
        updated_at = CURRENT_TIMESTAMP
      RETURNING id
    `;

    const values = [
      leadData.email,
      leadData.first_name,
      leadData.last_name,
      leadData.full_name,
      leadData.company_name,
      leadData.phone,
      leadData.linkedin_url,
      leadData.website,
      leadData.source_type,
      leadData.source_url,
      leadData.source_campaign,
      leadData.industry,
      leadData.company_size,
      leadData.job_title,
      leadData.lead_score || 50,
      leadData.budget_estimate,
      JSON.stringify(leadData.pain_points || []),
      JSON.stringify(leadData.likely_needs || []),
      leadData.qualification_notes,
      leadData.lead_score >= 70 ? "qualified" : "new",
      JSON.stringify(leadData.raw_data || {}),
      leadData.ai_model_used,
      leadData.processing_time_ms,
    ];

    const result = await this.db.query(query, values);
    return result.rows[0].id;
  }

  // ============================================
  // DAILY LIMITS CHECK
  // ============================================
  async checkDailyLimits() {
    const today = new Date().toISOString().split("T")[0];

    const leadsResult = await this.db.query(
      `SELECT COUNT(*) as count FROM leads WHERE DATE(created_at) = $1`,
      [today],
    );

    const outreachResult = await this.db.query(
      `SELECT COUNT(*) as count FROM outreach WHERE DATE(sent_at) = $1`,
      [today],
    );

    const leadsToday = parseInt(leadsResult.rows[0].count);
    const outreachToday = parseInt(outreachResult.rows[0].count);

    return {
      leads: leadsToday,
      outreach: outreachToday,
      canScrape: leadsToday < this.config.engine.max_leads_per_day,
      canOutreach: outreachToday < this.config.engine.max_outreach_per_day,
    };
  }

  // ============================================
  // CAMPAIGN EXECUTION
  // ============================================
  async runCampaigns() {
    if (!this.config.engine.enabled) {
      console.log("⏸️  Engine disabled in config");
      return;
    }

    if (this.isRunning) {
      console.log("⏭️  Campaign already running, skipping");
      return;
    }

    this.isRunning = true;
    console.log("\n🎯 Starting campaign execution...");

    try {
      // Check daily limits
      const limits = await this.checkDailyLimits();
      console.log(
        `📊 Today's stats: ${limits.leads} leads, ${limits.outreach} outreach sent`,
      );

      if (!limits.canScrape) {
        console.log("⚠️  Daily lead limit reached");
        return;
      }

      // Get active campaigns
      const activeCampaigns = this.config.campaigns.filter((c) => c.enabled);
      console.log(`📋 Active campaigns: ${activeCampaigns.length}`);

      for (const campaign of activeCampaigns) {
        await this.executeCampaign(campaign, limits);
      }

      console.log("✅ Campaign execution complete\n");
    } catch (error) {
      await this.log(
        "error",
        "lead-engine",
        `Campaign execution failed: ${error.message}`,
        {
          stack_trace: error.stack,
        },
      );
      console.error("❌ Campaign execution failed:", error);
    } finally {
      this.isRunning = false;
    }
  }

  async executeCampaign(campaign, limits) {
    console.log(`\n▶️  Campaign: ${campaign.name}`);

    // Get sources for this campaign
    const sources = this.config.sources.filter(
      (s) => s.enabled && campaign.target_sources.includes(s.name),
    );

    console.log(`  Sources: ${sources.map((s) => s.name).join(", ")}`);

    for (const source of sources) {
      // Check limits before each source
      const currentLimits = await this.checkDailyLimits();
      if (!currentLimits.canScrape) {
        console.log("  ⚠️  Daily limit reached, stopping");
        break;
      }

      await this.processSource(source, campaign);
    }
  }

  async processSource(source, campaign) {
    console.log(`  📥 Processing: ${source.name} (${source.type})`);

    const scraper = this.scrapers[source.type];
    if (!scraper) {
      console.log(`    ⚠️  No scraper available for type: ${source.type}`);
      return;
    }

    try {
      const leads = await scraper.scrape(source, campaign);
      console.log(`    ✓ Found ${leads.length} potential leads`);

      // Qualify each lead
      let qualified = 0;
      for (const lead of leads) {
        try {
          const { qualification } = await this.qualifyLead(lead, campaign.name);
          if (qualification.lead_score >= 50) {
            qualified++;
          }
        } catch (error) {
          console.error(
            `    ✗ Failed to qualify ${lead.email}:`,
            error.message,
          );
        }
      }

      console.log(`    ✓ Qualified ${qualified}/${leads.length} leads`);
    } catch (error) {
      console.error(`    ✗ Scraping failed:`, error.message);
      await this.log(
        "error",
        "scraper",
        `Scraping failed for ${source.name}: ${error.message}`,
        {
          source_name: source.name,
          campaign_name: campaign.name,
        },
      );
    }
  }

  // ============================================
  // LOGGING & UTILITIES
  // ============================================
  async log(level, component, message, metadata = {}) {
    try {
      await this.db.query(
        `INSERT INTO system_logs (level, component, message, metadata, lead_id, campaign_name)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          level,
          component,
          message,
          JSON.stringify(metadata),
          metadata.lead_id || null,
          metadata.campaign_name || null,
        ],
      );
    } catch (error) {
      console.error("Failed to write log:", error);
    }
  }

  async logAIUsage(data) {
    try {
      await this.db.query(
        `INSERT INTO ai_usage (
          model_name, endpoint, task_type, prompt_tokens, completion_tokens,
          total_tokens, response_time_ms, estimated_cost, lead_id, campaign_name
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
        [
          data.model_name,
          data.endpoint,
          data.task_type,
          data.prompt_tokens || 0,
          data.completion_tokens || 0,
          (data.prompt_tokens || 0) + (data.completion_tokens || 0),
          data.response_time_ms,
          data.estimated_cost || 0,
          data.lead_id || null,
          data.campaign_name || null,
        ],
      );
    } catch (error) {
      console.error("Failed to log AI usage:", error);
    }
  }

  // ============================================
  // SCHEDULER
  // ============================================
  startScheduler() {
    const interval = this.config.engine.scrape_interval_minutes;
    const cronExpression = `*/${interval} * * * *`;

    console.log(`⏰ Scheduler started (every ${interval} minutes)`);

    cron.schedule(cronExpression, () => {
      this.runCampaigns();
    });

    // Also run immediately on startup
    setTimeout(() => this.runCampaigns(), 5000);
  }

  // ============================================
  // MAIN START
  // ============================================
  async start() {
    await this.initialize();
    this.startScheduler();

    // Setup config reload on SIGHUP
    process.on("SIGHUP", () => this.reloadConfig());

    console.log("🟢 Lead Engine is running!\n");
  }

  async shutdown() {
    console.log("\n🔴 Shutting down...");
    this.isRunning = false;
    if (this.db) await this.db.end();
    if (this.redis) await this.redis.quit();
    console.log("👋 Goodbye!");
  }
}

// ============================================
// RUN
// ============================================
const engine = new LeadEngine();

engine.start().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});

// Graceful shutdown
process.on("SIGTERM", () => engine.shutdown().then(() => process.exit(0)));
process.on("SIGINT", () => engine.shutdown().then(() => process.exit(0)));

module.exports = LeadEngine;
