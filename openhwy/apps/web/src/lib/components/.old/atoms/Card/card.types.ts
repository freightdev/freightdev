import type { BaseComponentProps, LayoutType, Size, Variant } from '@/utils';
import type { ContactMethod } from '../../ui/molecules/Cards/ContactCard/contact';
import type { FAQ } from '../../ui/molecules/Cards/FAQCard/faqs';
import type { FeatureCategory, SimpleFeature } from '../../ui/molecules/Cards/FeatureCard/features';
import type { PricingPlan } from '../../ui/molecules/Cards/PricingCard/pricing';
import type { Testimonial } from '../../ui/molecules/Cards/TestimonialCard/testimonials';
import type { Stat, TeamCategory, ValueProposition } from './content/about';

export type CardVariant =
  | 'feature'
  | 'feature-category'
  | 'pricing'
  | 'faq'
  | 'testimonial'
  | 'stat'
  | 'value'
  | 'contact'
  | 'team'
  | 'generic';

export type CardData =
  | SimpleFeature
  | FeatureCategory
  | PricingPlan
  | FAQ
  | Testimonial
  | Stat
  | ValueProposition
  | ContactMethod
  | TeamCategory
  | Record<string, any>;

export interface CardCollectionProps extends BaseComponentProps {
  variant: CardVariant;
  data: CardData | CardData[];
  layout?: LayoutType;
  gap?: Size;
  styleVariant?: Variant;
  hoverable?: boolean;
  animated?: boolean;
}

export interface CardRendererProps<T = CardData> {
  item: T;
  index: number;
}
