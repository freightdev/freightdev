// src/components/molecuels/Cards/TeamCard/teamCard.configs.ts

// TeamCard Configurations
export interface TeamCategory {
  name: string;
  icon: string;
  description: string;
}

export const teamCategories: TeamCategory[] = [
  {
    name: 'Leadership',
    icon: '👔',
    description: 'Experienced executives from top logistics companies',
  },
  {
    name: 'Engineering',
    icon: '💻',
    description: 'World-class developers building the future of TMS',
  },
  {
    name: 'Support',
    icon: '🎧',
    description: 'Dedicated team available 24/7 to help you succeed',
  },
];