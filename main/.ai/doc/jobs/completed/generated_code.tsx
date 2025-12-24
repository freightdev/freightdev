```tsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';

interface Lead {
  id: number;
  title: string;
  source: string;
  budget: number;
  score: number;
  status: string;
}

const LeadDashboard: React.FC = () => {
  const [leads, setLeads] = useState<Lead[]>([]);
  const [filteredLeads, setFilteredLeads] = useState<Lead[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    axios.get('https://api.example.com/leads')
      .then(response => {
        setLeads(response.data);
        setFilteredLeads(response.data);
        setLoading(false);
      })
      .catch(error => {
        console.error("Error fetching leads:", error);
        setError(error);
        setLoading(false);
      });
  }, []);

  useEffect(() => {
    const filtered = leads.filter(lead =>
      lead.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      lead.source.toLowerCase().includes(searchTerm.toLowerCase()) ||
      lead.status.toLowerCase().includes(searchTerm.toLowerCase())
    );
    setFilteredLeads(filtered);
  }, [searchTerm, leads]);

  const handleSearch = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(event.target.value);
  };

  if (loading) return <div className="text-center">Loading...</div>;
  if (error) return <div>Error fetching data</div>;

  return (
    <div className="p-6 max-w-sm mx-auto bg-white rounded-lg shadow-md flex items-center space-x-4">
      <div>
        <h2 className="text-lg font-medium text-gray-900 mb-4">Lead Dashboard</h2>
        <input 
          type="text" 
          placeholder="Search leads..." 
          value={searchTerm} 
          onChange={handleSearch} 
          className="border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 w-full"
        />
        <ul className="list-disc pl-5 mt-2">
          {filteredLeads.map((lead) => (
            <li key={lead.id} className="text-gray-700">{lead.title}</li>
          ))}
        </ul>
      </div>
    </div>
  );
};

export default LeadDashboard;
```
