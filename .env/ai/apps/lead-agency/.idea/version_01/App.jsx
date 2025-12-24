// ============================================
// LEAD GENERATION DASHBOARD - REACT APP
// ============================================
import React, { useState, useEffect } from "react";
import "./App.css";

const API_URL = process.env.REACT_APP_API_URL || "http://localhost:3001";

function App() {
  const [stats, setStats] = useState(null);
  const [leads, setLeads] = useState([]);
  const [hotLeads, setHotLeads] = useState([]);
  const [campaigns, setCampaigns] = useState([]);
  const [calls, setCalls] = useState([]);
  const [activeTab, setActiveTab] = useState("overview");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 30000); // Refresh every 30s
    return () => clearInterval(interval);
  }, []);

  const loadData = async () => {
    try {
      const [statsRes, leadsRes, hotRes, campaignsRes, callsRes] =
        await Promise.all([
          fetch(`${API_URL}/api/dashboard/stats`),
          fetch(`${API_URL}/api/leads?limit=20`),
          fetch(`${API_URL}/api/leads/hot`),
          fetch(`${API_URL}/api/campaigns`),
          fetch(`${API_URL}/api/calls`),
        ]);

      setStats(await statsRes.json());
      const leadsData = await leadsRes.json();
      setLeads(leadsData.leads || []);
      setHotLeads(await hotRes.json());
      setCampaigns(await campaignsRes.json());
      setCalls(await callsRes.json());
      setLoading(false);
    } catch (error) {
      console.error("Failed to load data:", error);
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <div className="app">
      <header className="header">
        <h1>🚀 Lead Generation Engine</h1>
        <div className="header-actions">
          <button onClick={loadData} className="btn-refresh">
            ↻ Refresh
          </button>
        </div>
      </header>

      <nav className="tabs">
        <button
          className={activeTab === "overview" ? "active" : ""}
          onClick={() => setActiveTab("overview")}
        >
          Overview
        </button>
        <button
          className={activeTab === "leads" ? "active" : ""}
          onClick={() => setActiveTab("leads")}
        >
          Leads
        </button>
        <button
          className={activeTab === "hot" ? "active" : ""}
          onClick={() => setActiveTab("hot")}
        >
          Hot Leads ({hotLeads.length})
        </button>
        <button
          className={activeTab === "calls" ? "active" : ""}
          onClick={() => setActiveTab("calls")}
        >
          Calls ({calls.length})
        </button>
        <button
          className={activeTab === "campaigns" ? "active" : ""}
          onClick={() => setActiveTab("campaigns")}
        >
          Campaigns
        </button>
      </nav>

      <main className="content">
        {activeTab === "overview" && <Overview stats={stats} />}
        {activeTab === "leads" && <LeadsTable leads={leads} />}
        {activeTab === "hot" && <HotLeads leads={hotLeads} />}
        {activeTab === "calls" && <CallsList calls={calls} />}
        {activeTab === "campaigns" && <Campaigns campaigns={campaigns} />}
      </main>
    </div>
  );
}

// ============================================
// OVERVIEW TAB
// ============================================
function Overview({ stats }) {
  return (
    <div className="overview">
      <div className="stats-grid">
        <StatCard
          label="Total Leads"
          value={stats?.total_leads || 0}
          change={`+${stats?.leads_today || 0} today`}
          icon="📊"
        />
        <StatCard
          label="Hot Leads"
          value={stats?.hot_leads || 0}
          subtitle="Score ≥ 70"
          icon="🔥"
          highlight
        />
        <StatCard
          label="Responses"
          value={stats?.total_replies || 0}
          subtitle="From outreach"
          icon="💬"
        />
        <StatCard
          label="Scheduled Calls"
          value={stats?.scheduled_calls || 0}
          subtitle="Ready to close"
          icon="📞"
          highlight
        />
        <StatCard
          label="Avg Lead Score"
          value={stats?.avg_lead_score || 0}
          subtitle="Out of 100"
          icon="⭐"
        />
        <StatCard
          label="Outreach Today"
          value={stats?.outreach_today || 0}
          subtitle="Emails sent"
          icon="📧"
        />
      </div>

      <div className="activity">
        <h2>Recent Activity</h2>
        <p className="placeholder">Activity feed coming soon...</p>
      </div>
    </div>
  );
}

function StatCard({ label, value, change, subtitle, icon, highlight }) {
  return (
    <div className={`stat-card ${highlight ? "highlight" : ""}`}>
      <div className="stat-icon">{icon}</div>
      <div className="stat-content">
        <div className="stat-value">{value}</div>
        <div className="stat-label">{label}</div>
        {(change || subtitle) && (
          <div className="stat-meta">{change || subtitle}</div>
        )}
      </div>
    </div>
  );
}

// ============================================
// LEADS TABLE
// ============================================
function LeadsTable({ leads }) {
  return (
    <div className="leads-table">
      <h2>Recent Leads</h2>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Company</th>
            <th>Email</th>
            <th>Score</th>
            <th>Status</th>
            <th>Campaign</th>
            <th>Created</th>
          </tr>
        </thead>
        <tbody>
          {leads.map((lead) => (
            <tr key={lead.id}>
              <td>{lead.full_name || "—"}</td>
              <td>{lead.company_name || "—"}</td>
              <td>{lead.email || "—"}</td>
              <td>
                <span
                  className={`score score-${getScoreClass(lead.lead_score)}`}
                >
                  {lead.lead_score}
                </span>
              </td>
              <td>
                <span className={`status status-${lead.qualification_status}`}>
                  {lead.qualification_status}
                </span>
              </td>
              <td className="campaign">{lead.source_campaign}</td>
              <td className="date">{formatDate(lead.created_at)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ============================================
// HOT LEADS
// ============================================
function HotLeads({ leads }) {
  return (
    <div className="hot-leads">
      <h2>🔥 Hot Leads - Ready for Calls</h2>
      <div className="leads-grid">
        {leads.map((lead) => (
          <div key={lead.id} className="lead-card hot">
            <div className="lead-header">
              <h3>{lead.full_name || lead.email}</h3>
              <span className="score-badge">{lead.lead_score}</span>
            </div>
            <div className="lead-info">
              <p>
                <strong>Company:</strong> {lead.company_name}
              </p>
              <p>
                <strong>Title:</strong> {lead.job_title || "—"}
              </p>
              <p>
                <strong>Email:</strong> {lead.email}
              </p>
              {lead.phone && (
                <p>
                  <strong>Phone:</strong> {lead.phone}
                </p>
              )}
            </div>
            <div className="lead-actions">
              <button className="btn-primary">📞 Book Call</button>
              <button className="btn-secondary">📧 Send Email</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ============================================
// CALLS LIST
// ============================================
function CallsList({ calls }) {
  return (
    <div className="calls-list">
      <h2>Scheduled Calls</h2>
      <table>
        <thead>
          <tr>
            <th>Lead</th>
            <th>Company</th>
            <th>Scheduled</th>
            <th>Type</th>
            <th>Score</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {calls.map((call) => (
            <tr key={call.id}>
              <td>{call.full_name}</td>
              <td>{call.company_name}</td>
              <td>{formatDateTime(call.scheduled_at)}</td>
              <td className="call-type">{call.call_type}</td>
              <td>
                <span
                  className={`score score-${getScoreClass(call.lead_score)}`}
                >
                  {call.lead_score}
                </span>
              </td>
              <td>
                <button className="btn-sm">View</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ============================================
// CAMPAIGNS
// ============================================
function Campaigns({ campaigns }) {
  return (
    <div className="campaigns">
      <h2>Campaign Performance</h2>
      <table>
        <thead>
          <tr>
            <th>Campaign</th>
            <th>Status</th>
            <th>Leads</th>
            <th>Outreach</th>
            <th>Replies</th>
            <th>Response Rate</th>
            <th>Avg Score</th>
          </tr>
        </thead>
        <tbody>
          {campaigns.map((campaign) => (
            <tr key={campaign.campaign_name}>
              <td>
                <strong>{campaign.campaign_name}</strong>
              </td>
              <td>
                <span
                  className={`status ${campaign.enabled ? "status-active" : "status-paused"}`}
                >
                  {campaign.enabled ? "✓ Active" : "⏸ Paused"}
                </span>
              </td>
              <td>{campaign.total_leads || 0}</td>
              <td>{campaign.total_outreach || 0}</td>
              <td>{campaign.total_replies || 0}</td>
              <td>
                <strong>{campaign.response_rate || 0}%</strong>
              </td>
              <td>{Math.round(campaign.avg_lead_score || 0)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ============================================
// UTILITIES
// ============================================
function getScoreClass(score) {
  if (score >= 80) return "excellent";
  if (score >= 70) return "good";
  if (score >= 50) return "medium";
  return "low";
}

function formatDate(dateString) {
  const date = new Date(dateString);
  const now = new Date();
  const diff = now - date;
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));

  if (days === 0) return "Today";
  if (days === 1) return "Yesterday";
  if (days < 7) return `${days} days ago`;
  return date.toLocaleDateString();
}

function formatDateTime(dateString) {
  const date = new Date(dateString);
  return date.toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

export default App;
