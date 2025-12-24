// src/configs/navigation.ts

// Navbar Configurations
interface NavbarProps {
  config?: NavigationConfig;
}

export interface NavLink {
  label: string;
  href: string;
  external?: boolean;
  badge?: string;
  children?: NavLink[];
}

export interface NavigationConfig {
  brand: {
    name: string;
    logo?: string;
    href: string;
  };
  links: NavLink[];
  actions?: {
    primary?: NavLink;
    secondary?: NavLink;
  };
}

export const navigationConfig: NavigationConfig = {
  brand: {
    name: 'HWY-TMS',
    href: '/',
  },
  links: [
    { label: 'Features', href: '/home/features' },
    { label: 'Pricing', href: '/home/pricing' },
    { label: 'About', href: '/home/about' },
    { label: 'Contact', href: '/home/contact' },
  ],
  actions: {
    secondary: { label: 'Login', href: '/auth/login' },
    primary: { label: 'Sign Up', href: '/auth/signup' },
  },
};
