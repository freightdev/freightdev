// src/configs/navigation/footer.ts

// Footer Configurations
interface NavLink {
  label: string;
  href: string;
  external?: boolean;
  badge?: string;
  children?: NavLink[];
}

interface NavSection {
  title?: string;
  links: NavLink[];
}

interface FooterConfig {
  brand: {
    name: string;
    tagline?: string;
    logo?: string;
  };
  sections: NavSection[];
  social?: {
    label: string;
    href: string;
    icon: string;
  }[];
  legal?: NavLink[];
  copyright?: string;
}

export const footerConfig: FooterConfig = {
  brand: {
    name: 'HWY-TMS',
    tagline: 'Modern TMS for Modern Carriers',
  },
  sections: [
    {
      title: 'Product',
      links: [
        { label: 'Features', href: '/home/features' },
        { label: 'Pricing', href: '/home/pricing' },
        { label: 'Integrations', href: '/home/integrations' },
        { label: 'Changelog', href: '/home/changelog' },
      ],
    },
    {
      title: 'Company',
      links: [
        { label: 'About', href: '/home/about' },
        { label: 'Blog', href: '/home/blog' },
        { label: 'Careers', href: '/home/careers' },
        { label: 'Contact', href: '/home/contact' },
      ],
    },
    {
      title: 'Resources',
      links: [
        { label: 'Documentation', href: '/docs' },
        { label: 'Help Center', href: '/help' },
        { label: 'API Reference', href: '/api' },
        { label: 'Status', href: '/status' },
      ],
    },
    {
      title: 'Legal',
      links: [
        { label: 'Privacy', href: '/legal/privacy' },
        { label: 'Terms', href: '/legal/terms' },
        { label: 'Security', href: '/legal/security' },
      ],
    },
  ],
  social: [
    { label: 'Twitter', href: 'https://twitter.com/hwy-tms', icon: '𝕏' },
    { label: 'LinkedIn', href: 'https://linkedin.com/company/hwy-tms', icon: 'in' },
    { label: 'GitHub', href: 'https://github.com/hwy-tms', icon: 'gh' },
  ],
  copyright: '© 2025 HWY-TMS. All rights reserved.',
};
