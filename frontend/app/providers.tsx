'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RainbowKitProvider } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { useState, type ReactNode } from 'react';
import { Toaster } from 'sonner';

import { config } from '@/lib/wagmi';

type ProvidersProps = {
	children: ReactNode;
};

export default function Providers({ children }: ProvidersProps) {
	const [queryClient] = useState(() => new QueryClient());

	return (
		<WagmiProvider config={config}>
			<QueryClientProvider client={queryClient}>
				<RainbowKitProvider>
					{children}
					<Toaster richColors position='top-right' />
				</RainbowKitProvider>
			</QueryClientProvider>
		</WagmiProvider>
	);
}
