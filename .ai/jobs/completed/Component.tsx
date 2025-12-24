To fulfill the requirements specified in your task, I'll create a React component named `LeadList` using TypeScript and Tailwind CSS. This component will fetch data from the provided API endpoint (`http://localhost:8000/api/leads`) and display it in a table format with loading and error states.

Here's how you can implement the `LeadList` component:

```tsx
import React, { useEffect, useState } from 'react';
import axios from 'axios';

interface Lead {
  budget_min: number;
  budget_max: number;
}

const LeadList: React.FC = () => {
  const [leads, setLeads] = useState<Lead[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    axios.get('http://localhost:8000/api/leads')
      .then(response => {
        setLeads(response.data);
        setLoading(false);
      })
      .catch(error => {
        console.error("Error fetching leads:", error);
        setError(true);
        setLoading(false);
      });
  }, []);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error loading data</div>;

  return (
    <table className="min-w-full table-auto">
      <thead>
        <tr className="bg-gray-800 text-white">
          <th className="px-4 py-2">Budget Min</th>
          <th className="px-4 py-2">Budget Max</th>
        </tr>
      </thead>
      <tbody className="bg-white">
        {leads.map((lead, index) => (
          <tr key={index} className={index % 2 === 0 ? 'bg-gray-100' : 'bg-white'}>
            <td className="border px-4 py-2">{lead.budget_min}</td>
            <td className="border px-4 py-2">{lead.budget_max}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};

export default LeadList;
```

### Explanation:
1. **State Management**: The component uses React's `useState` to manage the state of leads, loading status, and error status.
2. **Effect Hook**: The `useEffect` hook is used to fetch data from the API when the component mounts. It handles both success and failure scenarios using `.then()` and `.catch()`.
3. **Conditional Rendering**: Based on the loading state, it displays a "Loading..." message or an "Error loading data" message if there's an error.
4. **Table Display**: The leads are displayed in a table format with Tailwind CSS for styling. Each row alternates between gray background colors to enhance readability.
5. **TypeScript Interfaces**: TypeScript interfaces (`Lead`) are used to define the structure of data fetched from the API, ensuring type safety and better developer experience.

This implementation adheres strictly to the task requirements, including using Tailwind CSS for styling, handling loading and error states, and utilizing TypeScript for type checking in React components.
