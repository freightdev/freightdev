import Button from '@/components/atoms/Button';
import Card from '@/components/atoms/Card';
import Container from '@/components/atoms/Container';
import LinkCard from '@/components/molecules/Cards/LinkCard';
import MapCard from '@/components/molecules/Cards/MapCard';
import CTA from '@/components/organisms/CTA';
import ContactSection from '@/components/organisms/ContactSection';
import Hero from '@/components/organisms/Hero';
import Section from '@/components/organisms/Section';

export const componentRegistry = {
  Hero,
  Section,
  Card,
  CTA,
  Container,
  ContactSection,
  MapCard,
  LinkCard,
  Button,
} as const;

export type RegisteredComponent = keyof typeof componentRegistry;
