// src/lib/utils/constants.ts

/** -----------------------------
 * HTTP Methods
 * ----------------------------- */
export const HTTP_METHODS = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'] as const;
export type HttpMethod = (typeof HTTP_METHODS)[number];

/** -----------------------------
 * HTTP Status Codes
 * ----------------------------- */
export const HTTP_STATUS_CODES = {
	200: 'OK',
	201: 'Created',
	204: 'No Content',
	400: 'Bad Request',
	401: 'Unauthorized',
	403: 'Forbidden',
	404: 'Not Found',
	405: 'Method Not Allowed',
	422: 'Unprocessable Entity',
	500: 'Internal Server Error',
	502: 'Bad Gateway',
	503: 'Service Unavailable',
	504: 'Gateway Timeout'
} as const;
export type HttpStatusCode = keyof typeof HTTP_STATUS_CODES;

/** -----------------------------
 * Content Types
 * ----------------------------- */
export const CONTENT_TYPES = {
	JSON: 'application/json',
	XML: 'application/xml',
	FORM: 'application/x-www-form-urlencoded',
	MULTIPART: 'multipart/form-data',
	TEXT: 'text/plain',
	HTML: 'text/html'
} as const;
export type ContentType = (typeof CONTENT_TYPES)[keyof typeof CONTENT_TYPES];

/** -----------------------------
 * Auth Types
 * ----------------------------- */
export const AUTH_TYPES = {
	NONE: 'none',
	BEARER: 'bearer',
	BASIC: 'basic',
	API_KEY: 'apikey',
	CUSTOM: 'custom'
} as const;
export type AuthType = (typeof AUTH_TYPES)[keyof typeof AUTH_TYPES];

/** -----------------------------
 * Test Assertion Types
 * ----------------------------- */
export const TEST_ASSERTION_TYPES = {
	STATUS_CODE: 'status_code',
	RESPONSE_TIME: 'response_time',
	CONTAINS: 'contains',
	EQUALS: 'equals',
	JSON_PATH: 'json_path',
	HEADER_EXISTS: 'header_exists',
	HEADER_EQUALS: 'header_equals',
	REGEX: 'regex',
	NOT_NULL: 'not_null',
	TYPE: 'type'
} as const;
export type TestAssertionType = (typeof TEST_ASSERTION_TYPES)[keyof typeof TEST_ASSERTION_TYPES];

/** -----------------------------
 * Environments
 * ----------------------------- */
export const ENVIRONMENTS = ['development', 'staging', 'production'] as const;
export type Environment = (typeof ENVIRONMENTS)[number];

/** -----------------------------
 * Service Status
 * ----------------------------- */
export const SERVICE_STATUS = {
	ACTIVE: 'active',
	INACTIVE: 'inactive',
	CHECKING: 'checking',
	UNKNOWN: 'unknown'
} as const;
export type ServiceStatus = (typeof SERVICE_STATUS)[keyof typeof SERVICE_STATUS];

/** -----------------------------
 * Notification Types
 * ----------------------------- */
export const NOTIFICATION_TYPES = {
	SUCCESS: 'success',
	ERROR: 'error',
	WARNING: 'warning',
	INFO: 'info'
} as const;
export type NotificationType = (typeof NOTIFICATION_TYPES)[keyof typeof NOTIFICATION_TYPES];
