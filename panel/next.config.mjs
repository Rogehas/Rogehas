/** @type {import('next').NextConfig} */
const nextConfig = {
  // Statik çıktı: Firebase Hosting'e (ücretsiz plan) yüklenir.
  output: 'export',
  trailingSlash: true,
};
export default nextConfig;
