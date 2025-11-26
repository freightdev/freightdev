import { authMiddleware } from "@repo/auth/middleware";
import { internationalizationMiddleware } from "@repo/internationalization/middleware";
import { securityMiddleware, noseconeOptions } from "@repo/security/middleware";
import { createNEMO } from "@rescale/nemo";
import { type NextRequest, NextResponse } from "next/server";

export const config = {
  matcher: ["/((?!_next/static|_next/image|ingest|favicon.ico).*)"],
  runtime: "nodejs",
};

// Compose all middleware
export default async function middleware(request: NextRequest) {
  // 1. Run auth check first
  const authResponse = await authMiddleware(request);
  if (authResponse.status === 302 || authResponse.status !== 200) {
    return authResponse;
  }

  // 2. Run i18n middleware
  const i18nResponse = await internationalizationMiddleware(request);
  if (i18nResponse && i18nResponse.status === 302) {
    return i18nResponse;
  }

  // 3. Run security headers
  const securityHeaders = securityMiddleware(noseconeOptions);
  const securityResponse = securityHeaders();

  // Return response with security headers
  return securityResponse || NextResponse.next();
}
