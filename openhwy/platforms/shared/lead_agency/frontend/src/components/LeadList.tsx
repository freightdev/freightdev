import React from 'react';
import { Lead } from '../types/lead';

interface LeadListProps {
  leads: Lead[];
  loading: boolean;
  onSelectLead: (lead: Lead) => void;
}

const LeadList: React.FC<LeadListProps> = ({ leads, loading, onSelectLead }) => {
  if (loading) {
    return (
      <div className="flex justify-center items-center py-12">
        <div className="text-gray-600">Loading leads...</div>
      </div>
    );
  }

  if (leads.length === 0) {
    return (
      <div className="flex justify-center items-center py-12">
        <div className="text-gray-500">No leads found. Start a search to find leads!</div>
      </div>
    );
  }

  const formatBudget = (min: number | null, max: number | null) => {
    if (!min && !max) return 'N/A';
    if (min && max) return `$${min.toLocaleString()} - $${max.toLocaleString()}`;
    if (min) return `$${min.toLocaleString()}+`;
    if (max) return `Up to $${max.toLocaleString()}`;
    return 'N/A';
  };

  const getScoreColor = (score: number) => {
    if (score >= 80) return 'text-green-600 bg-green-50';
    if (score >= 60) return 'text-yellow-600 bg-yellow-50';
    return 'text-red-600 bg-red-50';
  };

  const getStatusBadge = (status: string) => {
    const statusColors: Record<string, string> = {
      'new': 'bg-blue-100 text-blue-800',
      'qualified': 'bg-green-100 text-green-800',
      'reached_out': 'bg-purple-100 text-purple-800',
      'responded': 'bg-indigo-100 text-indigo-800',
      'won': 'bg-emerald-100 text-emerald-800',
      'lost': 'bg-gray-100 text-gray-800',
    };
    return statusColors[status] || 'bg-gray-100 text-gray-800';
  };

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full bg-white border border-gray-200 rounded-lg">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Score
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Title
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Source
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Budget
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Tech Stack
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Status
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Found
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {leads.map((lead) => (
            <tr
              key={lead.id}
              onClick={() => onSelectLead(lead)}
              className="hover:bg-gray-50 cursor-pointer transition-colors"
            >
              <td className="px-6 py-4 whitespace-nowrap">
                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getScoreColor(lead.score)}`}>
                  {lead.score}
                </span>
              </td>
              <td className="px-6 py-4">
                <div className="text-sm font-medium text-gray-900 line-clamp-2">
                  {lead.title}
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="text-sm text-gray-600 capitalize">{lead.source}</span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="text-sm text-gray-900">{formatBudget(lead.budget_min, lead.budget_max)}</span>
              </td>
              <td className="px-6 py-4">
                <div className="flex flex-wrap gap-1">
                  {lead.tech_stack.slice(0, 3).map((tech, idx) => (
                    <span
                      key={idx}
                      className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-50 text-blue-700"
                    >
                      {tech}
                    </span>
                  ))}
                  {lead.tech_stack.length > 3 && (
                    <span className="text-xs text-gray-500">+{lead.tech_stack.length - 3}</span>
                  )}
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusBadge(lead.status)}`}>
                  {lead.status.replace('_', ' ')}
                </span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {new Date(lead.found_at).toLocaleDateString()}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default LeadList;
