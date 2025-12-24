```tsx
// LeadDashboard.tsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { TableHead, TableRow, TableCell, TableBody, TableContainer, Paper, TextField, MenuItem } from '@mui/material';
import { styled } from '@mui/system';

const StyledTable = styled(TableContainer)(({ theme }) => ({
  marginTop: theme.spacing(2),
  overflowX: 'auto',
}));

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
  const [minScore, setMinScore] = useState(0);
  const [statusFilter, setStatusFilter] = useState('');

  useEffect(() => {
    axios.get('https://api.example.com/leads').then(response => {
      setLeads(response.data);
      setFilteredLeads(response.data);
    });
  }, []);

  useEffect(() => {
    const filtered = leads.filter(lead =>
      lead.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      lead.source.toLowerCase().includes(searchTerm.toLowerCase()) ||
      lead.status.toLowerCase().includes(searchTerm.toLowerCase())
    ).filter(lead => lead.score >= minScore).filter(lead => statusFilter === '' || lead.status === statusFilter);
    setFilteredLeads(filtered);
  }, [searchTerm, leads, minScore, statusFilter]);

  const handleSearch = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(event.target.value);
  };

  const handleMinScoreChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setMinScore(Number(event.target.value));
  };

  const handleStatusFilterChange = (event: React.ChangeEvent<{ value: unknown }>) => {
    setStatusFilter(event.target.value as string);
  };

  return (
    <div className="p-4">
      <TextField
        label="Search"
        variant="outlined"
        value={searchTerm}
        onChange={handleSearch}
        style={{ marginBottom: '20px' }}
      />
      <TextField
        label="Min Score"
        type="number"
        variant="outlined"
        value={minScore}
        onChange={handleMinScoreChange}
        style={{ marginBottom: '20px', marginLeft: '10px', marginRight: '10px' }}
      />
      <TextField
        select
        label="Status"
        variant="outlined"
        value={statusFilter}
        onChange={handleStatusFilterChange}
        style={{ marginBottom: '20px', marginLeft: '10px' }}
      >
        <MenuItem value="">All</MenuItem>
        <MenuItem value="qualified">Qualified</MenuItem>
        <MenuItem value="unqualified">Unqualified</MenuItem>
      </TextField>
      <StyledTable component={Paper}>
        <TableHead>
          <TableRow>
            <TableCell>Title</TableCell>
            <TableCell>Source</TableCell>
            <TableCell align="right">Budget</TableCell>
            <TableCell align="right">Score</TableCell>
            <TableCell>Status</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {filteredLeads.map(lead => (
            <TableRow key={lead.id}>
              <TableCell>{lead.title}</TableCell>
              <TableCell>{lead.source}</TableCell>
              <TableCell align="right">{lead.budget}</TableCell>
              <TableCell align="right">{lead.score}</TableCell>
              <TableCell>{lead.status}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </StyledTable>
    </div>
  );
};

export default LeadDashboard;
```
