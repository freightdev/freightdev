import { stats, teamCategories, values } from '../../../components/atoms/Card/content/about';
import { testimonials } from '../../../components/molecules/Cards/TestimonialCard/testimonials';
import { ctaSections, heroSections } from '../../../components/organisms/Hero/hero.configs';
import type { PageBlueprint } from '../../page.types';

export const aboutPage: PageBlueprint = {
  title: 'About - HWY-TMS',
  description: 'About the team',
  sections: [
    { component: 'Hero', props: heroSections.about },
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
            styleVariant: 'elevated',
          },
        },
      ],
    },
    {
      component: 'Section',
      props: {
        spacing: 'lg',
        heading: {
          title: 'Our Values',
          description: 'The principles that guide everything we do',
        },
      },
      children: [
        {
          component: 'Card',
          props: {
            variant: 'value',
            data: values,
            layout: 'grid-2',
            gap: 'lg',
            styleVariant: 'elevated',
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
          title: 'Our Team',
          description: 'Meet the people behind HWY-TMS',
        },
      },
      children: [
        {
          component: 'Card',
          props: {
            variant: 'team',
            data: teamCategories,
            layout: 'grid-3',
            gap: 'lg',
            styleVariant: 'elevated',
          },
        },
      ],
    },
    {
      component: 'Section',
      props: { spacing: 'lg', heading: { title: 'What Our Customers Say' } },
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
    { component: 'CTA', props: ctaSections.about },
  ],
};
