import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';
import { http } from 'viem';

const ALCHEMY_API_KEY = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY;

if (!ALCHEMY_API_KEY) {
	throw new Error('Missing NEXT_PUBLIC_ALCHEMY_API_KEY');
}

export const config = getDefaultConfig({
	appName: 'Token Vesting',
	projectId: '9a884bea4e5448474506781fac3613f0',
	chains: [sepolia],
	ssr: true,
	transports: {
		[sepolia.id]: http(
			`https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
		),
	},
});
