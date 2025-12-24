import { featureCategories, simpleFeatures } from '../../../components/molecules/Cards/FeatureCard/features';
import { ctaSections, heroSections } from '../../../components/organisms/Hero/hero.configs';
import type { PageBlueprint } from '../../page.types';

export const featuresPage: PageBlueprint = {
  title: 'Features - HWY-TMS',
  description: 'Feature overview',
  sections: [
    { component: 'Hero', props: heroSections.features },
    {
      component: 'Section',
      props: {
        spacing: 'lg',
        heading: {
          title: 'Everything You Need',
          description: 'Comprehensive features for modern carriers',
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
      props: { spacing: 'xl' },
      children: [
        {
          component: 'Card',
          props: {
            variant: 'feature-category',
            data: featureCategories,
            layout: 'stack',
          },
        },
      ],
    },
    { component: 'CTA', props: ctaSections.features },
  ],
};
