/** @type {import('next').NextConfig} */
const nextConfig = {
  serverExternalPackages: ['pg', 'bcryptjs', 'jsonwebtoken'],
};

export default nextConfig;
