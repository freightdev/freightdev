// src/lib/services/mockDataGenerator.js
// Smart Mock Data Generation

export class MockDataGenerator {
	constructor() {
		this.generators = {
			// User data
			firstName: () =>
				this.randomChoice(['John', 'Jane', 'Mike', 'Sarah', 'Chris', 'Emma', 'David', 'Lisa']),
			lastName: () =>
				this.randomChoice([
					'Smith',
					'Johnson',
					'Williams',
					'Brown',
					'Jones',
					'Garcia',
					'Miller',
					'Davis'
				]),
			email: () => {
				const first = this.generators.firstName().toLowerCase();
				const last = this.generators.lastName().toLowerCase();
				const domains = ['gmail.com', 'yahoo.com', 'outlook.com', 'company.com'];
				return `${first}.${last}@${this.randomChoice(domains)}`;
			},

			// IDs and tokens
			uuid: () =>
				'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
					const r = (Math.random() * 16) | 0;
					const v = c === 'x' ? r : (r & 0x3) | 0x8;
					return v.toString(16);
				}),
			jwt: () =>
				'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' +
				btoa(
					JSON.stringify({
						sub: this.generators.uuid(),
						name: `${this.generators.firstName()} ${this.generators.lastName()}`,
						iat: Math.floor(Date.now() / 1000)
					})
				) +
				'.signature',

			// Numbers and amounts
			amount: () => Math.floor(Math.random() * 1000000) / 100, // $0.01 to $9999.99
			quantity: () => Math.floor(Math.random() * 100) + 1,
			price: () => Math.floor(Math.random() * 50000) / 100, // $0.01 to $499.99

			// Dates
			futureDate: () =>
				new Date(Date.now() + Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),
			pastDate: () =>
				new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),

			// Business data
			companyName: () =>
				this.randomChoice([
					'Tech Corp',
					'Global Systems',
					'Digital Solutions',
					'Innovation Labs',
					'Smart Systems',
					'Future Tech',
					'Advanced Solutions',
					'Prime Industries'
				]),
			product: () =>
				this.randomChoice([
					'Premium Widget',
					'Smart Device',
					'Digital Service',
					'Cloud Solution',
					'Mobile App',
					'Web Platform',
					'API Service',
					'Data Analytics'
				]),

			// Addresses
			streetAddress: () =>
				`${Math.floor(Math.random() * 9999) + 1} ${this.randomChoice([
					'Main St',
					'Oak Ave',
					'Park Rd',
					'First St',
					'Second Ave',
					'Mill St'
				])}`,
			city: () =>
				this.randomChoice([
					'New York',
					'Los Angeles',
					'Chicago',
					'Houston',
					'Phoenix',
					'Philadelphia'
				]),
			state: () => this.randomChoice(['CA', 'NY', 'TX', 'FL', 'IL', 'PA', 'OH', 'GA']),
			zipCode: () => String(Math.floor(Math.random() * 90000) + 10000),

			// Phone numbers
			phoneNumber: () =>
				`+1-${Math.floor(Math.random() * 900) + 100}-${Math.floor(Math.random() * 900) + 100}-${Math.floor(Math.random() * 9000) + 1000}`,

			// Payment data
			cardNumber: () =>
				'4' +
				Array(15)
					.fill(0)
					.map(() => Math.floor(Math.random() * 10))
					.join(''),
			expiryDate: () => {
				const month = String(Math.floor(Math.random() * 12) + 1).padStart(2, '0');
				const year = String(new Date().getFullYear() + Math.floor(Math.random() * 5) + 1).slice(-2);
				return `${month}/${year}`;
			},
			cvv: () => String(Math.floor(Math.random() * 900) + 100),

			// Status values
			userStatus: () => this.randomChoice(['active', 'inactive', 'pending', 'suspended']),
			orderStatus: () =>
				this.randomChoice(['pending', 'processing', 'shipped', 'delivered', 'cancelled']),
			paymentStatus: () => this.randomChoice(['pending', 'completed', 'failed', 'refunded'])
		};
	}

	randomChoice(array) {
		return array[Math.floor(Math.random() * array.length)];
	}

	generate(template) {
		if (typeof template === 'string') {
			// Simple variable replacement like {{firstName}}
			return template.replace(/\{\{(\w+)\}\}/g, (match, key) => {
				return this.generators[key] ? this.generators[key]() : match;
			});
		}

		if (Array.isArray(template)) {
			return template.map((item) => this.generate(item));
		}

		if (typeof template === 'object' && template !== null) {
			const result = {};
			for (const [key, value] of Object.entries(template)) {
				result[key] = this.generate(value);
			}
			return result;
		}

		return template;
	}

	generateTestData(type, count = 1) {
		const templates = {
			user: {
				id: '{{uuid}}',
				firstName: '{{firstName}}',
				lastName: '{{lastName}}',
				email: '{{email}}',
				phone: '{{phoneNumber}}',
				status: '{{userStatus}}',
				createdAt: '{{pastDate}}',
				updatedAt: '{{pastDate}}'
			},
			order: {
				id: '{{uuid}}',
				userId: '{{uuid}}',
				items: [
					{
						productId: '{{uuid}}',
						name: '{{product}}',
						quantity: '{{quantity}}',
						price: '{{price}}'
					}
				],
				total: '{{amount}}',
				status: '{{orderStatus}}',
				createdAt: '{{pastDate}}'
			},
			payment: {
				id: '{{uuid}}',
				orderId: '{{uuid}}',
				amount: '{{amount}}',
				currency: 'USD',
				method: 'credit_card',
				cardNumber: '{{cardNumber}}',
				status: '{{paymentStatus}}',
				processedAt: '{{pastDate}}'
			}
		};

		const template = templates[type];
		if (!template) {
			throw new Error(`Unknown data type: ${type}`);
		}

		if (count === 1) {
			return this.generate(template);
		}

		return Array(count)
			.fill(null)
			.map(() => this.generate(template));
	}
}

export const mockDataGenerator = new MockDataGenerator();
