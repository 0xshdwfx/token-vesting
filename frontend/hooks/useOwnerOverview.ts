'use client';

import { useReadContract } from 'wagmi';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

export function useOwnerOverview(isOwner: boolean) {
	const totalOutstandingAllocation = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'totalOutstandingAllocation',
		query: { enabled: isOwner },
	});

	const beneficiaryCount = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'getBeneficiariesLength',
		query: { enabled: isOwner },
	});

	const paused = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'paused',
		query: { enabled: isOwner },
	});

	return {
		totalOutstandingAllocation: totalOutstandingAllocation.data ?? BigInt(0),
		beneficiaryCount: beneficiaryCount.data ?? BigInt(0),
		isPaused: paused.data ?? false,
		isLoading:
			totalOutstandingAllocation.isLoading ||
			beneficiaryCount.isLoading ||
			paused.isLoading,
	};
}
