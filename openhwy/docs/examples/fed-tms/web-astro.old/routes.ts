/**
 * Route Registry
 * Enhanced routing system with type-safe route definitions
 */

interface RouteConfig {
  path: string;
  name: string;
  title?: string;
  description?: string;
  meta?: Record<string, string>;
}

type RouteRegistry = Record<string, RouteConfig>;

// ============================================================================
// Auto-discover routes from pages directory
// ============================================================================

const pageModules = import.meta.glob('../pages/**/*.astro', { eager: true });

/**
 * Auto-generated routes from file system
 */
export const routes: RouteRegistry = Object.fromEntries(
  Object.keys(pageModules).map((filePath) => {
    // Remove "../pages" prefix and extension
    let route = filePath
      .replace('../pages', '')
      .replace(/\.astro$/, '')
      .replace(/\/index$/, '');

    // Key: remove leading slash or use "home"
    const key = route.replace(/^\//, '') || 'home';

    // Value: the actual route path
    const value = route === '' ? '/' : route;

    // Create route config
    const config: RouteConfig = {
      path: value,
      name: key,
    };

    return [key, config];
  })
);

// ============================================================================
// Route Helper Functions
// ============================================================================

/**
 * Get route path by key
 */
export function route(key: string): string {
  return routes[key]?.path || '/';
}

/**
 * Get all route paths
 */
export function getAllRoutes(): string[] {
  return Object.values(routes).map((r) => r.path);
}

/**
 * Get all route keys
 */
export function getAllRouteKeys(): string[] {
  return Object.keys(routes);
}

/**
 * Check if route exists
 */
export function routeExists(key: string): boolean {
  return key in routes;
}

/**
 * Get route by path
 */
export function getRouteByPath(path: string): RouteConfig | undefined {
  return Object.values(routes).find((r) => r.path === path);
}

// ============================================================================
// Static/External URLs
// ============================================================================

export const external = {
  app: import.meta.env.PUBLIC_APP_URL ?? 'https://app.open-hwy.com',
  download: import.meta.env.PUBLIC_DOWNLOAD_URL ?? '/downloads',
  docs: import.meta.env.PUBLIC_DOCS_URL ?? 'https://docs.open-hwy.com',
  api: import.meta.env.PUBLIC_API_URL ?? 'https://api.open-hwy.com',
  status: import.meta.env.PUBLIC_STATUS_URL ?? 'https://status.open-hwy.com',
} as const;

// ============================================================================
// Common Routes (Convenience Accessors)
// ============================================================================

export const page = {
  home: route('home'),
  features: route('home/features'),
  pricing: route('home/pricing'),
  about: route('home/about'),
  contact: route('home/contact'),
  login: route('auth/login'),
  signup: route('auth/signup'),
  download: external.download,
} as const;

// Alias for external URLs
export const site = external;

// ============================================================================
// Exports
// ============================================================================

export default {
  routes,
  route,
  page,
  external,
  getAllRoutes,
  getAllRouteKeys,
  routeExists,
  getRouteByPath,
};
