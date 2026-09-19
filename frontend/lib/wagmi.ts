import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';

export const config = getDefaultConfig({
	appName: 'Token Vesting',
	projectId: '9a884bea4e5448474506781fac3613f0',
	chains: [sepolia],
	ssr: true,
});
