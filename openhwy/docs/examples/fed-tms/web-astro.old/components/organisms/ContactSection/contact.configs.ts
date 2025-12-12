import type { FormField, FormSectionConfig } from '@/components/molecules/Fields/FormField/form-field.types';

const fields: Record<string, FormField> = {
  firstName: {
    name: 'firstName',
    label: 'First Name',
    type: 'text',
    required: true,
  },
  lastName: {
    name: 'lastName',
    label: 'Last Name',
    type: 'text',
    required: true,
  },
  email: {
    name: 'email',
    label: 'Email',
    type: 'email',
    required: true,
  },
  company: {
    name: 'company',
    label: 'Company Name',
    type: 'text',
  },
  subject: {
    name: 'subject',
    label: 'Subject',
    type: 'select',
    required: true,
    options: [
      { label: 'Sales Inquiry', value: 'sales' },
      { label: 'Technical Support', value: 'support' },
      { label: 'Request a Demo', value: 'demo' },
      { label: 'Partnership', value: 'partnership' },
      { label: 'Other', value: 'other' },
    ],
  },
  message: {
    name: 'message',
    label: 'Message',
    type: 'textarea',
    required: true,
  },
};

export const contactFormSections: FormSectionConfig[] = [
  {
    gridClass: 'grid md:grid-cols-2 gap-6',
    fields: [fields.firstName, fields.lastName],
  },
  { fields: [fields.email] },
  { fields: [fields.company] },
  { fields: [fields.subject] },
  { fields: [fields.message] },
];

export const contactFormCopy = {
  title: 'Send us a Message',
  submitLabel: 'Send Message',
};
