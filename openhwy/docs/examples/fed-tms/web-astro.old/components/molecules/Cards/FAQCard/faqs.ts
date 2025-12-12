// src/configs/content/faqs.ts

// FAQs Configurations
export interface FAQ {
  question: string;
  answer: string;
  category?: string;
}

export const faqs: FAQ[] = [
  {
    question: 'Is there a free trial?',
    answer: 'Yes! We offer a 14-day free trial with full access to all features in your chosen plan. No credit card required to start.',
  },
  {
    question: 'Can I change plans later?',
    answer: 'Absolutely. You can upgrade or downgrade your plan at any time. Changes take effect on your next billing cycle.',
  },
  {
    question: 'What payment methods do you accept?',
    answer: 'We accept all major credit cards (Visa, Mastercard, Amex, Discover) and ACH bank transfers for annual plans.',
  },
  {
    question: 'Is there a setup fee?',
    answer: 'No setup fees. The price you see is what you pay. We offer free onboarding and training for all plans.',
  },
  {
    question: 'What happens when I exceed my truck limit?',
    answer: "You'll be prompted to upgrade to the next tier. We'll never charge you extra without your approval.",
  },
  {
    question: 'Can I cancel anytime?',
    answer: 'Yes, you can cancel anytime. There are no long-term contracts or cancellation fees. Your data is always exportable.',
  },
];
