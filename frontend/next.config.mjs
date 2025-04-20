/** @type {import('next').NextConfig} */

const nextConfig = {
  reactStrictMode: true, // Default to true; overridden in development
  output: "standalone", // Ensure standalone output for production
  generateBuildId: async () => {
    // Return a unique identifier for each build.
    return Date.now().toString()
  },
  headers: async () => {
    return [
      {
        // Apply these headers to all routes
        source: "/:path*",
        headers: [
          {
            key: "Strict-Transport-Security",
            value: "max-age=7776000; includeSubDomains",
          },
          {
            key: "X-Content-Type-Options",
            value: "nosniff",
          },
          {
            key: "X-Frame-Options",
            value: "DENY",
          },
          {
            key: "Referrer-Policy",
            value: "strict-origin-when-cross-origin",
          },
          {
            key: "Permissions-Policy",
            value: "document-domain=()",
          },
          {
            key: "Content-Security-Policy",
            value: (() => {
              const connectSrcDev = [
                "http://127.0.0.1",
                "http://127.0.0.1:80/api/*",
                "http://localhost",
                "http://localhost:80/api/*",
              ]
              let baseDirectives
              if (process.env.POSTHOG_KEY) {
                baseDirectives = [
                  "connect-src 'self' https://*.posthog.com",
                  "default-src 'self'",
                  "worker-src 'self' blob:",
                  "frame-ancestors 'none'",
                  "img-src 'self' data:",
                  "object-src 'none'",
                  "script-src 'self' 'unsafe-inline' https://*.posthog.com",
                  "style-src 'self' 'unsafe-inline'",
                ]
              } else {
                baseDirectives = [
                  "connect-src 'self'",
                  "default-src 'self'",
                  "worker-src 'self' blob:",
                  "frame-ancestors 'none'",
                  "img-src 'self' data:",
                  "object-src 'none'",
                  "script-src 'self' 'unsafe-inline'",
                  "style-src 'self' 'unsafe-inline'",
                ]
              }

              // Modify connect-src based on environment
              if (process.env.NODE_ENV !== "production") {
                const connectSrcIndex = baseDirectives.findIndex((dir) =>
                  dir.startsWith("connect-src")
                )
                if (connectSrcIndex !== -1) {
                  baseDirectives[connectSrcIndex] = [
                    baseDirectives[connectSrcIndex],
                    ...connectSrcDev,
                  ].join(" ")
                }
              }

              return baseDirectives.join("; ")
            })(),
          },
        ],
      },
    ]
  },
}

// Override settings for non-production environments
if (process.env.NODE_ENV !== "production") {
  nextConfig.reactStrictMode = false
}

export default nextConfig
