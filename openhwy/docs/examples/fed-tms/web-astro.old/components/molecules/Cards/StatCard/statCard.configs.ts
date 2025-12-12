// src/components/molecuels/Cards/StatCard/statCard.configs.ts

// StatCard Configurations
export interface Stat {
  value: string;
  label: string;
  description?: string;
  icon?: string;
}

export const stats: Stat[] = [
  { value: '10,000+', label: 'Active Carriers' },
  { value: '50M+', label: 'Loads Managed' },
  { value: '99.9%', label: 'Uptime SLA' },
  { value: '24/7', label: 'Support Available' },
];
