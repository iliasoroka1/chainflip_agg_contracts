const nextConfig = {
  reactStrictMode: true,
  appDir: true, // app router mode
  rsc: true, // serverside rendering
  logging: {
    fetches: {
      fullUrl: true,
    },
  },
  transpilePackages: ['next-mdx-remote'],
  async redirects() {
    return [
      {
        source: '/',
        destination: '/swap',
        permanent: true,
      },
      {
        source: '/trade',
        destination: '/swap',
        permanent: true,
      },
      // {
      //   source: '/names',
      //   destination: '/mayaname',
      //   permanent: true,
      // },
      {
        source: '/earn',
        destination: '/vaults',
        permanent: true,
      },
      {
        source: '/withdraw',
        destination: '/vaults/withdraw',
        permanent: true,
      },
      {
        source: '/deposit',
        destination: '/vaults/deposit',
        permanent: true,
      },
      {
        source: '/earn/deposit',
        destination: '/vaults/deposit',
        permanent: true,
      },
    ];  
  },
  headers() {
    return [
      {
        source: '/(.*)',
        headers: securityHeaders,
      },
    ];
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
      {
        protocol: 'http',
        hostname: '**',
      },
    ],
  },
};

const ContentSecurityPolicy = `
    default-src 'self' vercel.live;
    script-src 'self' 'unsafe-eval' 'unsafe-inline' cdn.vercel-insights.com vercel.live va.vercel-scripts.com;
    style-src 'self' 'unsafe-inline';
    img-src *;
    media-src *;
    connect-src *;
    font-src 'self' data:;
    frame-src 'self' *.codesandbox.io vercel.live;
`;

const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: ContentSecurityPolicy.replace(/\n/g, ''),
  },
  {
    key: 'Referrer-Policy',
    value: 'origin-when-cross-origin',
  },
  {
    key: 'X-Frame-Options',
    value: 'DENY',
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff',
  },
  {
    key: 'X-DNS-Prefetch-Control',
    value: 'on',
  },
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=31536000; includeSubDomains; preload',
  },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=()',
  },
];

export default nextConfig;
