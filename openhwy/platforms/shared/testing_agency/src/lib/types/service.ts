// Define Service type
export interface Service {
	id: string;
	name: string;
	baseUrl: string;
	description?: string;
	status: 'active' | 'inactive' | 'unknown' | 'checking';
	lastHealthCheck: string | null;
	createdAt: string;
	updatedAt: string;
}
