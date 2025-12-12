// src/configs/content/pricings.ts

// Pricing Configurations
export interface PricingPlan {
  name: string;
  price: string;
  period: string;
  description: string;
  features: string[];
  cta: string;
  ctaLink?: string;
  highlighted?: boolean;
  badge?: string;
}

export const pricingPlans: PricingPlan[] = [
  {
    name: 'Starter',
    price: '$49',
    period: 'per month',
    description: 'Perfect for owner-operators and small fleets',
    features: [
      'Up to 5 trucks',
      'Basic dispatch management',
      'Mobile apps (iOS & Android)',
      'Email support',
      'Basic reporting',
      'Document management',
      'Driver app access',
    ],
    cta: 'Start Free Trial',
    ctaLink: '/auth/signup',
    highlighted: false,
  },
  {
    name: 'Professional',
    price: '$149',
    period: 'per month',
    description: 'For growing fleets that need advanced features',
    features: [
      'Up to 25 trucks',
      'Advanced dispatch & routing',
      'E.L.D.A. AI Assistant',
      'Priority email & chat support',
      'Advanced analytics & reports',
      'Document management & e-signatures',
      'Automated invoicing',
      'GPS tracking integration',
      'Load board integrations',
      'Accounting software sync',
    ],
    cta: 'Start Free Trial',
    ctaLink: '/auth/signup',
    highlighted: true,
    badge: 'Most Popular',
  },
  {
    name: 'Enterprise',
    price: 'Custom',
    period: 'contact us',
    description: 'For large operations with custom requirements',
    features: [
      'Unlimited trucks',
      'Everything in Professional',
      'Custom integrations',
      'Dedicated account manager',
      '24/7 phone support',
      'White-label options',
      'Custom training & onboarding',
      'API access',
      'Advanced security features',
      'SLA guarantees',
      'Custom development',
    ],
    cta: 'Contact Sales',
    ctaLink: '/home/contact',
    highlighted: false,
  },
];
