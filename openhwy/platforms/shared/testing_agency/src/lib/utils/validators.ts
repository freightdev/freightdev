// src/lib/utils/validators.ts

/** Validate if a string is a valid URL */
export function validateUrl(url: string): boolean {
	try {
		new URL(url);
		return true;
	} catch {
		return false;
	}
}

/** Validate if a string is a valid email */
export function validateEmail(email: string): boolean {
	const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
	return emailRegex.test(email);
}

/** Validate if a string is valid JSON */
export function validateJson(jsonString: string): boolean {
	try {
		JSON.parse(jsonString);
		return true;
	} catch {
		return false;
	}
}

/** Validate that a value is not null, undefined, or empty */
export function validateRequired(value: unknown): boolean {
	return value !== null && value !== undefined && value.toString().trim() !== '';
}

/** Validate that a string has at least minLength characters */
export function validateMinLength(value: unknown, minLength: number): boolean {
	return value != null && value.toString().length >= minLength;
}

/** Validate that a string has at most maxLength characters */
export function validateMaxLength(value: unknown, maxLength: number): boolean {
	return value == null || value.toString().length <= maxLength;
}

/** Validate a string against a custom regex pattern */
export function validatePattern(value: unknown, pattern: string | RegExp): boolean {
	if (!value) return true;
	const regex = pattern instanceof RegExp ? pattern : new RegExp(pattern);
	return regex.test(value.toString());
}
