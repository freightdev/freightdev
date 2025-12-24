import type { CTAProps } from './cta.types';

export const ctaSections: Record<string, CTAProps> = {
  features: {
    title: 'Ready to Transform Your Operations?',
    description: 'Join thousands of carriers already using HWY-TMS to run their business more efficiently.',
    primaryButton: { label: 'Start Free Trial', href: '/auth/signup' },
    secondaryButton: { label: 'Schedule Demo', href: '/demo' },
    background: 'gradient',
  },
  pricing: {
    title: 'Start Your Free 14-Day Trial',
    description: 'No credit card required. Cancel anytime. Get up and running in minutes.',
    primaryButton: { label: 'Get Started', href: '/auth/signup' },
    secondaryButton: { label: 'Contact Sales', href: '/home/contact' },
    background: 'gradient',
  },
  about: {
    title: 'Join Our Growing Community',
    description: 'See why thousands of carriers trust HWY-TMS to power their operations.',
    primaryButton: { label: 'Start Free Trial', href: '/auth/signup' },
    background: 'gradient',
  },
};
