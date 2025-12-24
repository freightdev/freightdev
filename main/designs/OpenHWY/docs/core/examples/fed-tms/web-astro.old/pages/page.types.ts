export type ComponentKey =
  | 'Hero'
  | 'Section'
  | 'Card'
  | 'CTA'
  | 'Container'
  | 'ContactSection'
  | 'MapCard'
  | 'LinkCard'
  | 'Button';

export interface ComponentNode {
  component: ComponentKey;
  props?: Record<string, any>;
  children?: ComponentNode[];
}

export interface PageBlueprint {
  title: string;
  description?: string;
  sections: ComponentNode[];
}
