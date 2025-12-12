import { faqs } from '../../../components/molecules/Cards/FAQCard/faqs';
import { pricingPlans } from '../../../components/molecules/Cards/PricingCard/pricing';
import { ctaSections, heroSections } from '../../../components/organisms/Hero/hero.configs';
import type { PageBlueprint } from '../../page.types';

export const pricingPage: PageBlueprint = {
  title: 'Pricing - HWY-TMS',
  description: 'Pricing overview',
  sections: [
    { component: 'Hero', props: heroSections.pricing },
    {
      component: 'Section',
      props: { spacing: 'lg' },
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
        spacing: 'lg',
        background: 'card',
        heading: {
          title: 'Frequently Asked Questions',
        },
      },
      children: [
        {
          component: 'Card',
          props: {
            variant: 'faq',
            data: faqs,
            layout: 'grid-1',
            gap: 'md',
            styleVariant: 'elevated',
          },
        },
      ],
    },
    { component: 'CTA', props: ctaSections.pricing },
  ],
};
