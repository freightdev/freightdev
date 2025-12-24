import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Lead, LeadDetail as LeadDetailType, Stats } from './types/lead';
import SearchControl from './components/SearchControl';
import LeadFilters from './components/LeadFilters';
import LeadList from './components/LeadList';
import LeadDetail from './components/LeadDetail';

function App() {
  const [leads, setLeads] = useState<Lead[]>([]);
  const [stats, setStats] = useState<Stats | null>(null);
  const [selectedLead, setSelectedLead] = useState<LeadDetailType | null>(null);
  const [loading, setLoading] = useState(true);

  // Filter states
  const [minScore, setMinScore] = useState(70);
  const [status, setStatus] = useState('');
  const [source, setSource] = useState('');

  // Fetch leads
  const fetchLeads = async () => {
    try {
      setLoading(true);
      const params: any = {
        min_score: minScore,
        limit: 100,
      };
      if (status) params.status = status;
      if (source) params.source = source;

      const response = await axios.get('/api/leads', { params });
      setLeads(response.data);
    } catch (error) {
      console.error('Error fetching leads:', error);
    } finally {
      setLoading(false);
    }
  };

  // Fetch stats
  const fetchStats = async () => {
    try {
      const response = await axios.get('/api/stats');
      setStats(response.data);
    } catch (error) {
      console.error('Error fetching stats:', error);
    }
  };

  // Fetch lead details
  const fetchLeadDetails = async (lead: Lead) => {
    try {
      const response = await axios.get(`/api/leads/${lead.id}`);
      setSelectedLead(response.data);
    } catch (error) {
      console.error('Error fetching lead details:', error);
    }
  };

  // Initial load
  useEffect(() => {
    fetchLeads();
    fetchStats();
  }, []);

  // Reload when filters change
  useEffect(() => {
    fetchLeads();
  }, [minScore, status, source]);

  // Auto-refresh every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      fetchLeads();
      fetchStats();
    }, 30000);

    return () => clearInterval(interval);
  }, [minScore, status, source]);

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="max-w-7xl mx-auto px-4 py-8 space-y-6">
        {/* Search Control & Stats */}
        <SearchControl
          onSearchStarted={() => {
            setLoading(true);
          }}
          onSearchComplete={() => {
            fetchLeads();
            fetchStats();
          }}
          stats={stats}
        />

        {/* Filters */}
        <LeadFilters
          minScore={minScore}
          status={status}
          source={source}
          onMinScoreChange={setMinScore}
          onStatusChange={setStatus}
          onSourceChange={setSource}
        />

        {/* Leads Table */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900">
              Leads ({leads.length})
            </h2>
          </div>
          <LeadList
            leads={leads}
            loading={loading}
            onSelectLead={fetchLeadDetails}
          />
        </div>

        {/* Lead Detail Modal */}
        <LeadDetail
          lead={selectedLead}
          onClose={() => setSelectedLead(null)}
        />
      </div>
    </div>
  );
}

export default App;
