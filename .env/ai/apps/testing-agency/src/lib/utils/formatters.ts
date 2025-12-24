// src/lib/utils/formatters.ts

/** Format bytes into human-readable string */
export function formatBytes(bytes: number, decimals = 2): string {
	if (bytes === 0) return '0 Bytes';

	const k = 1024;
	const dm = decimals < 0 ? 0 : decimals;
	const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];

	const i = Math.floor(Math.log(bytes) / Math.log(k));

	return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
}

/** Format duration in ms into human-readable string */
export function formatDuration(ms: number): string {
	if (ms < 1000) return `${ms}ms`;
	if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
	if (ms < 3600000) return `${Math.floor(ms / 60000)}m ${Math.floor((ms % 60000) / 1000)}s`;
	return `${Math.floor(ms / 3600000)}h ${Math.floor((ms % 3600000) / 60000)}m`;
}

/** Format a date into a readable string with optional Intl.DateTimeFormat options */
export function formatDate(
	date: string | number | Date,
	options: Intl.DateTimeFormatOptions = {}
): string {
	const defaultOptions: Intl.DateTimeFormatOptions = {
		year: 'numeric',
		month: 'short',
		day: 'numeric',
		hour: '2-digit',
		minute: '2-digit'
	};

	return new Date(date).toLocaleDateString('en-US', { ...defaultOptions, ...options });
}

/** Format relative time (e.g., "2 hours ago") */
export function formatRelativeTime(date: string | number | Date): string {
	const now = new Date();
	const diff = now.getTime() - new Date(date).getTime();

	const seconds = Math.floor(diff / 1000);
	const minutes = Math.floor(seconds / 60);
	const hours = Math.floor(minutes / 60);
	const days = Math.floor(hours / 24);

	if (seconds < 60) return 'just now';
	if (minutes < 60) return `${minutes} minute${minutes !== 1 ? 's' : ''} ago`;
	if (hours < 24) return `${hours} hour${hours !== 1 ? 's' : ''} ago`;
	if (days < 7) return `${days} day${days !== 1 ? 's' : ''} ago`;

	return formatDate(date);
}

/** Format number with Intl.NumberFormat options */
export function formatNumber(num: number, options: Intl.NumberFormatOptions = {}): string {
	const defaultOptions: Intl.NumberFormatOptions = {
		maximumFractionDigits: 2,
		minimumFractionDigits: 0
	};
	return new Intl.NumberFormat('en-US', { ...defaultOptions, ...options }).format(num);
}

/** Format value as a percentage of total */
export function formatPercent(value: number, total: number): string {
	if (!total || total === 0) return '0%';
	return `${Math.round((value / total) * 100)}%`;
}
