'use client';

import { useAccount, useReadContract } from 'wagmi';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

export function useTokenVestingOwner() {
	const { address: connectedAddress } = useAccount();

	const {
		data: owner,
		isLoading,
		error,
	} = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'owner',
	});

	const isOwner =
		connectedAddress !== undefined &&
		owner !== undefined &&
		connectedAddress.toLowerCase() === owner.toLowerCase();

	return {
		owner,
		isOwner,
		isLoading,
		error,
	};
}
``;
