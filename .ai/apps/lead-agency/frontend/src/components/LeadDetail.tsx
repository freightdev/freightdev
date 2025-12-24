import React from 'react';
import { LeadDetail as LeadDetailType } from '../types/lead';

interface LeadDetailProps {
  lead: LeadDetailType | null;
  onClose: () => void;
}

const LeadDetail: React.FC<LeadDetailProps> = ({ lead, onClose }) => {
  if (!lead) return null;

  const formatBudget = (min: number | null, max: number | null) => {
    if (!min && !max) return 'N/A';
    if (min && max) return `$${min.toLocaleString()} - $${max.toLocaleString()}`;
    if (min) return `$${min.toLocaleString()}+`;
    if (max) return `Up to $${max.toLocaleString()}`;
    return 'N/A';
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex justify-between items-start">
          <div className="flex-1">
            <h2 className="text-2xl font-bold text-gray-900">{lead.title}</h2>
            <div className="mt-2 flex items-center gap-3">
              <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
                lead.score >= 80 ? 'bg-green-100 text-green-800' :
                lead.score >= 60 ? 'bg-yellow-100 text-yellow-800' :
                'bg-red-100 text-red-800'
              }`}>
                Score: {lead.score}
              </span>
              <span className="text-sm text-gray-500 capitalize">{lead.source}</span>
            </div>
          </div>
          <button
            onClick={onClose}
            className="ml-4 text-gray-400 hover:text-gray-600 transition-colors"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Content */}
        <div className="px-6 py-4 space-y-6">
          {/* Basic Info */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-1">Budget</h3>
              <p className="text-lg font-semibold text-gray-900">{formatBudget(lead.budget_min, lead.budget_max)}</p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-1">Estimated Hours</h3>
              <p className="text-lg font-semibold text-gray-900">{lead.estimated_hours || 'N/A'}</p>
            </div>
            {lead.company_name && (
              <div>
                <h3 className="text-sm font-medium text-gray-500 mb-1">Company</h3>
                <p className="text-lg font-semibold text-gray-900">{lead.company_name}</p>
              </div>
            )}
            {lead.contact_email && (
              <div>
                <h3 className="text-sm font-medium text-gray-500 mb-1">Contact Email</h3>
                <a href={`mailto:${lead.contact_email}`} className="text-lg font-semibold text-blue-600 hover:text-blue-700">
                  {lead.contact_email}
                </a>
              </div>
            )}
          </div>

          {/* Tech Stack */}
          {lead.tech_stack.length > 0 && (
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-2">Tech Stack</h3>
              <div className="flex flex-wrap gap-2">
                {lead.tech_stack.map((tech, idx) => (
                  <span
                    key={idx}
                    className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-50 text-blue-700"
                  >
                    {tech}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Description */}
          {lead.description && (
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-2">Description</h3>
              <p className="text-gray-700 whitespace-pre-wrap">{lead.description}</p>
            </div>
          )}

          {/* Research Notes */}
          {lead.research_notes && (
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-2">Research Notes</h3>
              <div className="bg-gray-50 rounded-lg p-4">
                <p className="text-gray-700 whitespace-pre-wrap">{lead.research_notes}</p>
              </div>
            </div>
          )}

          {/* Outreach Draft */}
          {lead.outreach_draft && (
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-2">Outreach Draft</h3>
              <div className="bg-blue-50 rounded-lg p-4">
                <p className="text-gray-700 whitespace-pre-wrap">{lead.outreach_draft}</p>
              </div>
              <button
                onClick={() => navigator.clipboard.writeText(lead.outreach_draft || '')}
                className="mt-2 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
              >
                Copy to Clipboard
              </button>
            </div>
          )}

          {/* URL */}
          {lead.url && (
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-2">Original Post</h3>
              <a
                href={lead.url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:text-blue-700 underline"
              >
                View original post →
              </a>
            </div>
          )}

          {/* Score Breakdown */}
          {lead.score_breakdown && (
            <div>
              <h3 className="text-sm font-medium text-gray-500 mb-2">Score Breakdown</h3>
              <div className="bg-gray-50 rounded-lg p-4">
                <pre className="text-sm text-gray-700">{JSON.stringify(lead.score_breakdown, null, 2)}</pre>
              </div>
            </div>
          )}

          {/* Metadata */}
          <div className="border-t border-gray-200 pt-4 text-sm text-gray-500">
            <p>Found: {new Date(lead.found_at).toLocaleString()}</p>
            <p>Status: <span className="capitalize">{lead.status.replace('_', ' ')}</span></p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LeadDetail;
