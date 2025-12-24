import React from 'react';

interface LeadFiltersProps {
  minScore: number;
  status: string;
  source: string;
  onMinScoreChange: (score: number) => void;
  onStatusChange: (status: string) => void;
  onSourceChange: (source: string) => void;
}

const LeadFilters: React.FC<LeadFiltersProps> = ({
  minScore,
  status,
  source,
  onMinScoreChange,
  onStatusChange,
  onSourceChange,
}) => {
  return (
    <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
      <h3 className="text-sm font-medium text-gray-700 mb-3">Filters</h3>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Min Score Filter */}
        <div>
          <label htmlFor="min-score" className="block text-sm font-medium text-gray-700 mb-1">
            Min Score
          </label>
          <select
            id="min-score"
            value={minScore}
            onChange={(e) => onMinScoreChange(Number(e.target.value))}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value={0}>All Scores</option>
            <option value={50}>50+</option>
            <option value={60}>60+</option>
            <option value={70}>70+</option>
            <option value={80}>80+</option>
            <option value={90}>90+</option>
          </select>
        </div>

        {/* Status Filter */}
        <div>
          <label htmlFor="status" className="block text-sm font-medium text-gray-700 mb-1">
            Status
          </label>
          <select
            id="status"
            value={status}
            onChange={(e) => onStatusChange(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="">All Statuses</option>
            <option value="new">New</option>
            <option value="qualified">Qualified</option>
            <option value="reached_out">Reached Out</option>
            <option value="responded">Responded</option>
            <option value="won">Won</option>
            <option value="lost">Lost</option>
          </select>
        </div>

        {/* Source Filter */}
        <div>
          <label htmlFor="source" className="block text-sm font-medium text-gray-700 mb-1">
            Source
          </label>
          <select
            id="source"
            value={source}
            onChange={(e) => onSourceChange(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="">All Sources</option>
            <option value="reddit">Reddit</option>
            <option value="hackernews">HackerNews</option>
            <option value="indeed">Indeed</option>
            <option value="linkedin">LinkedIn</option>
          </select>
        </div>
      </div>
    </div>
  );
};

export default LeadFilters;
