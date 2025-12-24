import React, { useState } from 'react';
import axios from 'axios';
import { Stats } from '../types/lead';

interface SearchControlProps {
  onSearchStarted: () => void;
  onSearchComplete: () => void;
  stats: Stats | null;
}

const SearchControl: React.FC<SearchControlProps> = ({ onSearchStarted, onSearchComplete, stats }) => {
  const [searching, setSearching] = useState(false);
  const [searchId, setSearchId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const startSearch = async () => {
    try {
      setSearching(true);
      setError(null);
      onSearchStarted();

      const response = await axios.post('/api/search', {
        categories: ['web_development'],
        min_budget: 1000,
        sources: ['reddit', 'hackernews'],
        min_score: 70
      });

      setSearchId(response.data.search_id);

      // Poll for completion (simplified - waits 5-10 minutes as per API response)
      setTimeout(() => {
        setSearching(false);
        setSearchId(null);
        onSearchComplete();
      }, 10 * 60 * 1000); // 10 minutes

    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to start search');
      setSearching(false);
      onSearchComplete();
    }
  };

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <div className="flex items-center justify-between">
        <div className="flex-1">
          <h2 className="text-2xl font-bold text-gray-900">Lead Agency v2</h2>
          <p className="text-sm text-gray-600 mt-1">
            Autonomous lead generation system • Scheduled runs at 9am & 6pm daily
          </p>

          {/* Stats Display */}
          {stats && (
            <div className="mt-4 grid grid-cols-3 gap-4">
              <div className="bg-gray-50 rounded-lg p-3">
                <div className="text-sm font-medium text-gray-500">Total Leads</div>
                <div className="text-2xl font-bold text-gray-900">{stats.total_leads}</div>
              </div>
              <div className="bg-green-50 rounded-lg p-3">
                <div className="text-sm font-medium text-green-700">Qualified</div>
                <div className="text-2xl font-bold text-green-900">{stats.qualified_leads}</div>
              </div>
              <div className="bg-blue-50 rounded-lg p-3">
                <div className="text-sm font-medium text-blue-700">Avg Score</div>
                <div className="text-2xl font-bold text-blue-900">{stats.average_score.toFixed(1)}</div>
              </div>
            </div>
          )}
        </div>

        {/* Manual Search Button */}
        <div className="ml-6">
          <button
            onClick={startSearch}
            disabled={searching}
            className={`px-6 py-3 rounded-lg font-medium transition-all ${
              searching
                ? 'bg-gray-400 cursor-not-allowed text-white'
                : 'bg-blue-600 hover:bg-blue-700 text-white shadow-md hover:shadow-lg'
            }`}
          >
            {searching ? (
              <div className="flex items-center gap-2">
                <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                <span>Searching...</span>
              </div>
            ) : (
              '🔍 Start Manual Search'
            )}
          </button>
          {searching && (
            <p className="text-xs text-gray-500 mt-2 text-center">Est. 5-10 minutes</p>
          )}
          {searchId && (
            <p className="text-xs text-gray-600 mt-2 text-center">ID: {searchId}</p>
          )}
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="mt-4 bg-red-50 border border-red-200 rounded-lg p-3">
          <p className="text-sm text-red-800">{error}</p>
        </div>
      )}
    </div>
  );
};

export default SearchControl;
