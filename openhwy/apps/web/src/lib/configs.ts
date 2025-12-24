import { stats } from '../../components/atoms/Card/content/about';
import { simpleFeatures } from '../../components/molecules/Cards/FeatureCard/features';
import { pricingPlans } from '../../components/molecules/Cards/PricingCard/pricing';
import { testimonials } from '../../components/molecules/Cards/TestimonialCard/testimonials';
import { heroSections } from '../../components/organisms/Hero/hero.configs';
import type { PageBlueprint } from '../page.types';

export const homePage: PageBlueprint = {
  title: 'HWY-TMS - Modern TMS for Modern Carriers',
  description: 'Modern TMS marketing site',
  sections: [
    { component: 'Hero', props: heroSections.home },
    {
      component: 'Section',
      props: { spacing: 'lg', background: 'card' },
      children: [
        {
          component: 'Card',
          props: {
            variant: 'stat',
            data: stats,
            layout: 'grid-4',
            gap: 'lg',
            styleVariant: 'ghost',
          },
        },
      ],
    },
    {
      component: 'Section',
      props: {
        spacing: 'xl',
        heading: {
          title: 'Everything You Need to Succeed',
          subtitle: 'Features',
          description: 'Powerful tools designed for modern transportation businesses',
        },
      },
      children: [
        {
          component: 'Card',
          props: {
            variant: 'feature',
            data: simpleFeatures,
            layout: 'grid-3',
            gap: 'lg',
            styleVariant: 'elevated',
          },
        },
      ],
    },
    {
      component: 'Section',
      props: {
        spacing: 'xl',
        background: 'card',
        heading: {
          title: 'Simple, Transparent Pricing',
          subtitle: 'Pricing',
          description: 'Choose the perfect plan for your fleet',
        },
      },
      children: [
        {
          component: 'Card',
          props: {
            variant: 'pricing',
            data: pricingPlans,
            layout: 'grid-3',
            gap: 'lg',
          },
        },
      ],
    },
    {
      component: 'Section',
      props: {
        spacing: 'xl',
        heading: {
          title: 'Loved by Carriers Nationwide',
          subtitle: 'Testimonials',
        },
      },
      children: [
        {
          component: 'Card',
          props: {
            variant: 'testimonial',
            data: testimonials,
            layout: 'grid-3',
            gap: 'lg',
            styleVariant: 'elevated',
          },
        },
      ],
    },
    {
      component: 'CTA',
      props: {
        title: 'Ready to Transform Your Operations?',
        description: 'Join thousands of carriers already using HWY-TMS. Start your free 14-day trial today.',
        primaryButton: { label: 'Start Free Trial', href: '/auth/signup' },
        secondaryButton: { label: 'Schedule Demo', href: '/home/contact' },
        variant: 'gradient',
      },
    },
  ],
};
