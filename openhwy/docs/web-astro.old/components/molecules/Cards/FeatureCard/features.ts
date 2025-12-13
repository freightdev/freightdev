// src/configs/content/features.ts

// Features Configurations
export interface FeatureItem {
  name: string;
  description: string;
  icon?: string;
}

export interface FeatureCategory {
  title: string;
  icon: string;
  features: FeatureItem[];
}

export const featureCategories: FeatureCategory[] = [
  {
    title: 'Dispatch Management',
    icon: '🚚',
    features: [
      {
        name: 'Load Board Integration',
        description: 'Connect to major load boards and book loads directly from the platform.',
      },
      {
        name: 'Driver Assignment',
        description: 'Intelligently match drivers to loads based on location, availability, and preferences.',
      },
      {
        name: 'Route Optimization',
        description: 'Optimize routes for fuel efficiency and delivery times with AI-powered routing.',
      },
      {
        name: 'Real-Time Updates',
        description: 'Get instant notifications on load status, driver location, and delivery updates.',
      },
    ],
  },
  {
    title: 'Document Management',
    icon: '📄',
    features: [
      {
        name: 'Digital Documents',
        description: 'Manage all transportation documents digitally - BOL, POD, Rate Confirmations, and more.',
      },
      {
        name: 'E-Signatures',
        description: 'Collect electronic signatures on delivery and streamline the paperwork process.',
      },
      {
        name: 'Document Templates',
        description: 'Create custom templates for all your business documents and forms.',
      },
      {
        name: 'Cloud Storage',
        description: 'Securely store all documents in the cloud with easy search and retrieval.',
      },
    ],
  },
  {
    title: 'Financial Management',
    icon: '💰',
    features: [
      {
        name: 'Automated Invoicing',
        description: 'Generate and send invoices automatically when loads are delivered.',
      },
      {
        name: 'Payment Processing',
        description: 'Accept payments via ACH, credit card, or check with integrated payment processing.',
      },
      {
        name: 'Expense Tracking',
        description: 'Track all business expenses including fuel, maintenance, and overhead costs.',
      },
      {
        name: 'Financial Reporting',
        description: 'Comprehensive financial reports including P&L, revenue by customer, and more.',
      },
    ],
  },
  {
    title: 'Fleet Management',
    icon: '🗺️',
    features: [
      {
        name: 'GPS Tracking',
        description: 'Real-time GPS tracking for all your trucks with geofencing capabilities.',
      },
      {
        name: 'Maintenance Scheduling',
        description: 'Schedule and track maintenance based on mileage, time, or engine hours.',
      },
      {
        name: 'Fuel Management',
        description: 'Monitor fuel consumption, costs, and efficiency across your fleet.',
      },
      {
        name: 'Asset Management',
        description: 'Track trucks, trailers, and equipment with detailed asset profiles.',
      },
    ],
  },
  {
    title: 'Compliance & Safety',
    icon: '✅',
    features: [
      {
        name: 'ELD Integration',
        description: 'Integration with major ELD providers for HOS tracking and compliance.',
      },
      {
        name: 'Driver Qualification Files',
        description: 'Maintain complete DQ files with expiration alerts and document management.',
      },
      {
        name: 'Safety Reports',
        description: 'Track safety metrics, incidents, and CSA scores for your fleet.',
      },
      {
        name: 'Compliance Alerts',
        description: 'Get alerts for expiring licenses, permits, and required documents.',
      },
    ],
  },
  {
    title: 'AI Assistant (E.L.D.A.)',
    icon: '🤖',
    features: [
      {
        name: 'Natural Language Processing',
        description: 'Interact with your TMS using natural language commands and questions.',
      },
      {
        name: 'Smart Recommendations',
        description: 'Get AI-powered recommendations for load selection, pricing, and routing.',
      },
      {
        name: 'Automated Tasks',
        description: 'Automate repetitive tasks like status updates, document generation, and reporting.',
      },
      {
        name: 'Predictive Analytics',
        description: 'Forecast revenue, identify trends, and make data-driven decisions.',
      },
    ],
  },
];


export interface SimpleFeature {
  icon: string;
  title: string;
  description: string;
  link?: string;
}

export const simpleFeatures: SimpleFeature[] = [
  {
    icon: '⚡',
    title: 'Lightning Fast Dispatching',
    description: 'Dispatch loads in seconds with our intuitive interface and smart automation tools.',
  },
  {
    icon: '📱',
    title: 'Mobile-First Design',
    description: 'Manage your operations on the go with our native mobile apps for iOS and Android.',
  },
  {
    icon: '🤖',
    title: 'AI-Powered Assistant',
    description: 'E.L.D.A. learns your workflow and helps automate repetitive tasks.',
  },
  {
    icon: '📊',
    title: 'Real-Time Analytics',
    description: 'Track performance metrics and gain insights with comprehensive reporting tools.',
  },
  {
    icon: '🗺️',
    title: 'Live GPS Tracking',
    description: 'Monitor your fleet in real-time with integrated GPS tracking and geofencing.',
  },
  {
    icon: '💰',
    title: 'Automated Invoicing',
    description: 'Generate and send invoices automatically with integrated payment processing.',
  },
];
