// src/lib/types/testing.ts

export type Assertion = {
	field: string;
	expected: unknown;
	actual: unknown;
};

export type TestSuite = {
	id: string;
	name: string;
	description: string;
	serviceId: string;
	tests: TestCase[];
	createdAt: string;
	updatedAt: string;
};

export type TestCase = {
	id: string;
	name: string;
	description: string;
	suiteId: string;
	method: 'GET' | 'POST' | 'PUT' | 'DELETE' | string;
	endpoint: string;
	headers: Record<string, string>;
	body: unknown;
	assertions: Assertion[];
	createdAt: string;
	updatedAt: string;
};

export type TestResult = {
	id: string;
	testId: string;
	suiteId: string;
	status: 'passed' | 'failed' | string;
	responseTime: number;
	statusCode: number;
	response: unknown;
	error: string | null;
	timestamp: string;
};
