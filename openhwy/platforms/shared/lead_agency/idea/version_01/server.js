// ============================================
// API SERVER - REST API for Dashboard & Webhooks
// ============================================

const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");
const Redis = require("ioredis");
const fs = require("fs");
const toml = require("toml");

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Database & Redis
const db = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
});

const redis = new Redis(process.env.REDIS_URL);

// Load config
let config;
try {
  const configFile = fs.readFileSync(
    process.env.CONFIG_PATH || "/app/config.toml",
    "utf8",
  );
  config = toml.parse(configFile);
} catch (error) {
  console.error("Failed to load config:", error);
  process.exit(1);
}

// ============================================
// DASHBOARD ENDPOINTS
// ============================================

// Dashboard overview stats
app.get("/api/dashboard/stats", async (req, res) => {
  try {
    const today = new Date().toISOString().split("T")[0];

    const stats = await db.query(
      `
      SELECT
        (SELECT COUNT(*) FROM leads) as total_leads,
        (SELECT COUNT(*) FROM leads WHERE DATE(created_at) = $1) as leads_today,
        (SELECT COUNT(*) FROM leads WHERE lead_score >= 70) as hot_leads,
        (SELECT COUNT(*) FROM leads WHERE responded = true) as responded_leads,
        (SELECT COUNT(*) FROM calls WHERE status = 'scheduled') as scheduled_calls,
        (SELECT COUNT(*) FROM outreach WHERE DATE(sent_at) = $1) as outreach_today,
        (SELECT COUNT(*) FROM outreach WHERE replied = true) as total_replies,
        (SELECT ROUND(AVG(lead_score)::numeric, 1) FROM leads) as avg_lead_score
    `,
      [today],
    );

    res.json(stats.rows[0]);
  } catch (error) {
    console.error("Error fetching stats:", error);
    res.status(500).json({ error: "Failed to fetch stats" });
  }
});

// Recent leads
app.get("/api/leads", async (req, res) => {
  try {
    const { limit = 50, offset = 0, status, min_score, campaign } = req.query;

    let query = `
      SELECT
        id, email, full_name, company_name, job_title, phone,
        lead_score, qualification_status, source_campaign,
        responded, call_booked, created_at, updated_at
      FROM leads
      WHERE 1=1
    `;

    const params = [];
    let paramCount = 1;

    if (status) {
      query += ` AND qualification_status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    if (min_score) {
      query += ` AND lead_score >= $${paramCount}`;
      params.push(parseInt(min_score));
      paramCount++;
    }

    if (campaign) {
      query += ` AND source_campaign = $${paramCount}`;
      params.push(campaign);
      paramCount++;
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await db.query(query, params);

    // Get total count
    const countResult = await db.query("SELECT COUNT(*) FROM leads WHERE 1=1");

    res.json({
      leads: result.rows,
      total: parseInt(countResult.rows[0].count),
      limit: parseInt(limit),
      offset: parseInt(offset),
    });
  } catch (error) {
    console.error("Error fetching leads:", error);
    res.status(500).json({ error: "Failed to fetch leads" });
  }
});

// Hot leads (score >= 70, ready for calls)
app.get("/api/leads/hot", async (req, res) => {
  try {
    const result = await db.query(`
      SELECT * FROM hot_leads
      ORDER BY lead_score DESC, created_at DESC
      LIMIT 50
    `);

    res.json(result.rows);
  } catch (error) {
    console.error("Error fetching hot leads:", error);
    res.status(500).json({ error: "Failed to fetch hot leads" });
  }
});

// Single lead details
app.get("/api/leads/:id", async (req, res) => {
  try {
    const { id } = req.params;

    // Get lead data
    const leadResult = await db.query("SELECT * FROM leads WHERE id = $1", [
      id,
    ]);
    if (leadResult.rows.length === 0) {
      return res.status(404).json({ error: "Lead not found" });
    }

    const lead = leadResult.rows[0];

    // Get outreach history
    const outreachResult = await db.query(
      "SELECT * FROM outreach WHERE lead_id = $1 ORDER BY sent_at DESC",
      [id],
    );

    // Get conversations
    const conversationsResult = await db.query(
      "SELECT * FROM conversations WHERE lead_id = $1 ORDER BY created_at DESC",
      [id],
    );

    // Get calls
    const callsResult = await db.query(
      "SELECT * FROM calls WHERE lead_id = $1 ORDER BY scheduled_at DESC",
      [id],
    );

    res.json({
      lead,
      outreach: outreachResult.rows,
      conversations: conversationsResult.rows,
      calls: callsResult.rows,
    });
  } catch (error) {
    console.error("Error fetching lead details:", error);
    res.status(500).json({ error: "Failed to fetch lead details" });
  }
});

// Update lead
app.patch("/api/leads/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { qualification_status, tags, notes } = req.body;

    const updates = [];
    const values = [];
    let paramCount = 1;

    if (qualification_status) {
      updates.push(`qualification_status = $${paramCount}`);
      values.push(qualification_status);
      paramCount++;
    }

    if (tags) {
      updates.push(`tags = $${paramCount}`);
      values.push(JSON.stringify(tags));
      paramCount++;
    }

    if (notes !== undefined) {
      updates.push(`qualification_notes = $${paramCount}`);
      values.push(notes);
      paramCount++;
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: "No updates provided" });
    }

    values.push(id);
    const query = `
      UPDATE leads
      SET ${updates.join(", ")}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await db.query(query, values);
    res.json(result.rows[0]);
  } catch (error) {
    console.error("Error updating lead:", error);
    res.status(500).json({ error: "Failed to update lead" });
  }
});

// Campaign performance
app.get("/api/campaigns", async (req, res) => {
  try {
    const result = await db.query("SELECT * FROM campaign_performance");
    res.json(result.rows);
  } catch (error) {
    console.error("Error fetching campaigns:", error);
    res.status(500).json({ error: "Failed to fetch campaigns" });
  }
});

// Daily stats (for charts)
app.get("/api/stats/daily", async (req, res) => {
  try {
    const { days = 30 } = req.query;

    const result = await db.query(
      `
      SELECT * FROM daily_stats
      ORDER BY date DESC
      LIMIT $1
    `,
      [parseInt(days)],
    );

    res.json(result.rows.reverse()); // Oldest first for charts
  } catch (error) {
    console.error("Error fetching daily stats:", error);
    res.status(500).json({ error: "Failed to fetch daily stats" });
  }
});

// Outreach history
app.get("/api/outreach", async (req, res) => {
  try {
    const { limit = 50, campaign } = req.query;

    let query = `
      SELECT o.*, l.email, l.full_name, l.company_name
      FROM outreach o
      JOIN leads l ON l.id = o.lead_id
      WHERE 1=1
    `;

    const params = [];
    if (campaign) {
      query += ` AND o.campaign_name = $1`;
      params.push(campaign);
    }

    query += ` ORDER BY o.sent_at DESC LIMIT $${params.length + 1}`;
    params.push(parseInt(limit));

    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error("Error fetching outreach:", error);
    res.status(500).json({ error: "Failed to fetch outreach" });
  }
});

// Scheduled calls
app.get("/api/calls", async (req, res) => {
  try {
    const result = await db.query(`
      SELECT c.*, l.email, l.full_name, l.company_name, l.phone, l.lead_score
      FROM calls c
      JOIN leads l ON l.id = c.lead_id
      WHERE c.status = 'scheduled'
      ORDER BY c.scheduled_at ASC
    `);

    res.json(result.rows);
  } catch (error) {
    console.error("Error fetching calls:", error);
    res.status(500).json({ error: "Failed to fetch calls" });
  }
});

// AI usage stats
app.get("/api/stats/ai-usage", async (req, res) => {
  try {
    const result = await db.query(`
      SELECT
        model_name,
        COUNT(*) as total_calls,
        AVG(response_time_ms) as avg_response_time,
        SUM(total_tokens) as total_tokens,
        SUM(estimated_cost) as total_cost
      FROM ai_usage
      WHERE created_at >= NOW() - INTERVAL '7 days'
      GROUP BY model_name
      ORDER BY total_calls DESC
    `);

    res.json(result.rows);
  } catch (error) {
    console.error("Error fetching AI usage:", error);
    res.status(500).json({ error: "Failed to fetch AI usage" });
  }
});

// System logs
app.get("/api/logs", async (req, res) => {
  try {
    const { level, component, limit = 100 } = req.query;

    let query = "SELECT * FROM system_logs WHERE 1=1";
    const params = [];
    let paramCount = 1;

    if (level) {
      query += ` AND level = $${paramCount}`;
      params.push(level);
      paramCount++;
    }

    if (component) {
      query += ` AND component = $${paramCount}`;
      params.push(component);
      paramCount++;
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramCount}`;
    params.push(parseInt(limit));

    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error("Error fetching logs:", error);
    res.status(500).json({ error: "Failed to fetch logs" });
  }
});

// ============================================
// WEBHOOKS & ACTIONS
// ============================================

// Webhook: Add lead manually
app.post("/api/leads", async (req, res) => {
  try {
    const lead = req.body;

    const result = await db.query(
      `
      INSERT INTO leads (
        email, first_name, last_name, full_name, company_name,
        phone, website, source_type, source_campaign
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `,
      [
        lead.email,
        lead.first_name,
        lead.last_name,
        lead.full_name,
        lead.company_name,
        lead.phone,
        lead.website,
        "manual",
        lead.campaign || "manual_entry",
      ],
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error("Error adding lead:", error);
    res.status(500).json({ error: "Failed to add lead" });
  }
});

// Book a call
app.post("/api/calls", async (req, res) => {
  try {
    const { lead_id, scheduled_at, call_type, notes } = req.body;

    const result = await db.query(
      `
      INSERT INTO calls (lead_id, scheduled_at, call_type, notes, status)
      VALUES ($1, $2, $3, $4, 'scheduled')
      RETURNING *
    `,
      [lead_id, scheduled_at, call_type || "discovery", notes],
    );

    // Update lead
    await db.query("UPDATE leads SET call_booked = true WHERE id = $1", [
      lead_id,
    ]);

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error("Error booking call:", error);
    res.status(500).json({ error: "Failed to book call" });
  }
});

// Update call status
app.patch("/api/calls/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { status, outcome, notes, next_steps } = req.body;

    const updates = [];
    const values = [];
    let paramCount = 1;

    if (status) {
      updates.push(`status = $${paramCount}`);
      values.push(status);
      paramCount++;
    }

    if (outcome) {
      updates.push(`outcome = $${paramCount}`);
      values.push(outcome);
      paramCount++;
    }

    if (notes) {
      updates.push(`notes = $${paramCount}`);
      values.push(notes);
      paramCount++;
    }

    if (next_steps) {
      updates.push(`next_steps = $${paramCount}`);
      values.push(next_steps);
      paramCount++;
    }

    values.push(id);
    const query = `
      UPDATE calls
      SET ${updates.join(", ")}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await db.query(query, values);
    res.json(result.rows[0]);
  } catch (error) {
    console.error("Error updating call:", error);
    res.status(500).json({ error: "Failed to update call" });
  }
});

// Reload configuration
app.post("/api/system/reload-config", async (req, res) => {
  try {
    const configFile = fs.readFileSync(
      process.env.CONFIG_PATH || "/app/config.toml",
      "utf8",
    );
    config = toml.parse(configFile);

    // Notify lead engine via Redis
    await redis.publish(
      "config-reload",
      JSON.stringify({ timestamp: Date.now() }),
    );

    res.json({ message: "Configuration reloaded successfully" });
  } catch (error) {
    console.error("Error reloading config:", error);
    res.status(500).json({ error: "Failed to reload config" });
  }
});

// Get current config (sanitized)
app.get("/api/system/config", async (req, res) => {
  try {
    // Return config without sensitive data
    const sanitized = {
      engine: config.engine,
      campaigns: config.campaigns?.map((c) => ({
        name: c.name,
        enabled: c.enabled,
        campaign_type: c.campaign_type,
      })),
      sources: config.sources?.map((s) => ({
        name: s.name,
        type: s.type,
        enabled: s.enabled,
      })),
    };

    res.json(sanitized);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch config" });
  }
});

// Search leads
app.get("/api/leads/search", async (req, res) => {
  try {
    const { q } = req.query;

    if (!q || q.length < 2) {
      return res.status(400).json({ error: "Query too short" });
    }

    const result = await db.query(
      `
      SELECT id, email, full_name, company_name, lead_score
      FROM leads
      WHERE
        email ILIKE $1 OR
        full_name ILIKE $1 OR
        company_name ILIKE $1
      LIMIT 20
    `,
      [`%${q}%`],
    );

    res.json(result.rows);
  } catch (error) {
    console.error("Error searching leads:", error);
    res.status(500).json({ error: "Failed to search leads" });
  }
});

// ============================================
// HEALTH CHECK
// ============================================
app.get("/health", async (req, res) => {
  try {
    await db.query("SELECT 1");
    await redis.ping();
    res.json({ status: "healthy", timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(503).json({ status: "unhealthy", error: error.message });
  }
});

// ============================================
// START SERVER
// ============================================
app.listen(PORT, () => {
  console.log(`🚀 API Server running on port ${PORT}`);
});

// Graceful shutdown
process.on("SIGTERM", async () => {
  console.log("SIGTERM received, shutting down gracefully");
  await db.end();
  await redis.quit();
  process.exit(0);
});
