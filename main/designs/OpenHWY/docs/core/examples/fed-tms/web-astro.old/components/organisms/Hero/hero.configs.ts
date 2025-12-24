import type { HeroProps } from './hero.types';

export const heroSections: Record<string, HeroProps> = {
  home: {
    title: 'The Modern TMS for Forward-Thinking Carriers',
    subtitle: 'Welcome to the Future of Freight',
    description: 'Streamline your operations with AI-powered dispatch, real-time tracking, and intelligent automation. Built for carriers who demand more.',
    primaryCta: { label: 'Start Free Trial', href: '/auth/signup' },
    secondaryCta: { label: 'Watch Demo', href: '/demo' },
    alignment: 'center',
  },
  features: {
    title: 'Powerful Features for Modern Carriers',
    description: 'Everything you need to run your transportation business efficiently, all in one platform.',
    alignment: 'center',
  },
  pricing: {
    title: 'Simple, Transparent Pricing',
    description: 'Choose the perfect plan for your fleet. No hidden fees, no surprises.',
    alignment: 'center',
  },
  about: {
    title: 'Built by Carriers, for Carriers',
    description: 'We understand the challenges of running a transportation business because we\'ve been there.',
    alignment: 'center',
  },
  contact: {
    title: 'Get in Touch',
    description: 'Have questions? We\'re here to help. Reach out to our team anytime.',
    alignment: 'center',
  },
};
