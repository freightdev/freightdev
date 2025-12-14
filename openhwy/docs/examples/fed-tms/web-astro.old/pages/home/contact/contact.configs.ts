import { contactMethods } from '../../../components/molecules/Cards/ContactCard/contact';
import { heroSections } from '../../../components/organisms/Hero/hero.configs';
import type { PageBlueprint } from '../../page.types';

export const contactPage: PageBlueprint = {
  title: 'Contact - HWY-TMS',
  description: 'Contact information',
  sections: [
    { component: 'Hero', props: heroSections.contact },
    {
      component: 'Section',
      props: { spacing: 'lg' },
      children: [
        {
          component: 'Card',
          props: {
            variant: 'contact',
            data: contactMethods,
            layout: 'grid-3',
            gap: 'lg',
            styleVariant: 'elevated',
          },
        },
      ],
    },
    {
      component: 'Section',
      props: { spacing: 'xl', background: 'card' },
      children: [
        {
          component: 'ContactSection',
          props: {
            title: 'Connect with our team',
            description: 'Send us a note and our specialists will respond within one business day.',
          },
        },
      ],
    },
  ],
};
