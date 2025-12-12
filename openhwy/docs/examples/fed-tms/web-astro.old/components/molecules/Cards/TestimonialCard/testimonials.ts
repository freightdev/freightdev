// src/configs/content/testimonials.ts

// Testimonials Configuration
export interface Testimonial {
  quote: string;
  author: string;
  role: string;
  company?: string;
  image?: string;
  rating?: number;
}

export const testimonials: Testimonial[] = [
  {
    quote: 'HWY-TMS transformed our dispatch operations. We cut our processing time by 70% and our drivers love the mobile app.',
    author: 'Sarah Johnson',
    role: 'Operations Manager',
    company: 'Swift Logistics',
    rating: 5,
  },
  {
    quote: 'The AI assistant is incredible. It handles routine tasks so our team can focus on growing the business.',
    author: 'Michael Chen',
    role: 'CEO',
    company: 'Pacific Transport',
    rating: 5,
  },
  {
    quote: 'Best investment we made. The ROI was clear within the first month. Highly recommend for any carrier.',
    author: 'David Martinez',
    role: 'Fleet Manager',
    company: 'National Freight',
    rating: 5,
  },
];
