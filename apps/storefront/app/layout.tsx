import type { Metadata } from 'next';
import { Bricolage_Grotesque, DM_Sans } from 'next/font/google';
import './globals.css';
import { Header } from '@/components/Header';
import { Footer } from '@/components/Footer';

const display = Bricolage_Grotesque({ subsets: ['latin'], variable: '--font-display', weight: ['500', '700', '800'] });
const body = DM_Sans({ subsets: ['latin'], variable: '--font-body' });

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3001'),
  title: { default: 'EcloudMall — Shop proudly South African SMMEs', template: '%s · EcloudMall' },
  description:
    'EcloudMall is the marketplace for South African small businesses. Discover township makers, Black- and women-owned brands and local legends from all 9 provinces.',
  openGraph: { siteName: 'EcloudMall', locale: 'en_ZA', type: 'website' },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en-ZA" className={`${display.variable} ${body.variable}`}>
      <body className="min-h-screen font-sans">
        <Header />
        <main>{children}</main>
        <Footer />
      </body>
    </html>
  );
}
