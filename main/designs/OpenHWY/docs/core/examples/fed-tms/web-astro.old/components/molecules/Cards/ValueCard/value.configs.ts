// src/components/molecuels/Cards/ValueCard/valueCard.configs.ts

// ValueCard Configurations
export interface ValueProposition {
  title: string;
  description: string;
  icon: string;
}

export const values: ValueProposition[] = [
  {
    title: 'Customer First',
    description: 'Every decision we make starts with how it benefits our customers.',
    icon: '🎯',
  },
  {
    title: 'Innovation',
    description: 'We continuously push boundaries to deliver cutting-edge solutions.',
    icon: '💡',
  },
  {
    title: 'Reliability',
    description: 'Your business depends on us. We take that responsibility seriously.',
    icon: '⚡',
  },
  {
    title: 'Transparency',
    description: 'Open communication and honest pricing. No hidden fees or surprises.',
    icon: '🔍',
  },
];