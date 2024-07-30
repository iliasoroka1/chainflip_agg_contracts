import '@/styles/globals.css'
import Providers from './providers'
import debug from 'debug'
import { twMerge } from 'tailwind-merge'
import { Inter } from 'next/font/google'

debug.enable('*')

var log = debug('app:layout')
log('Logging with debug enabled!')

const inter = Inter({
  subsets: ["latin"],
  weight: ["100", "200", "300", "400", "500", "600", "700", "800", "900"],
});

const RootLayout = async ({ children }: { children: React.ReactNode }) => {


  return (
    <html lang="en" suppressHydrationWarning>
                  <body
        className={twMerge(
          inter.className,
          "flex antialiased h-screen overflow-hidden bg-[#0F0F0F]"
        )}
      >
        <Providers>
          <div className="pl-2 pt-2 bg-[#0F0F0F] flex-1 overflow-y-auto">
            <div className="flex-1 bg-[#1A1C20] min-h-screen border border-transparent rounded-xl overflow-y-auto">
              {children}
            </div>
          </div>
        </Providers>
      </body>
    </html>
  );
};

export default RootLayout
