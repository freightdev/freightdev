// src/configs/content/contact.ts

// Contact Configurations
export interface ContactMethod {
  title: string;
  icon: string;
  description: string;
  contact: string;
  availability: string;
}

export const contactMethods: ContactMethod[] = [
  {
    title: 'Sales',
    icon: '💼',
    description: 'Questions about pricing or features?',
    contact: 'sales@hwy-tms.com',
    availability: 'Mon-Fri, 8am-6pm EST',
  },
  {
    title: 'Support',
    icon: '🎧',
    description: 'Need help with your account?',
    contact: 'support@hwy-tms.com',
    availability: '24/7 Support',
  },
  {
    title: 'Phone',
    icon: '📞',
    description: 'Prefer to talk? Give us a call.',
    contact: '1-800-HWY-TMS1',
    availability: 'Mon-Fri, 8am-8pm EST',
  },
];
