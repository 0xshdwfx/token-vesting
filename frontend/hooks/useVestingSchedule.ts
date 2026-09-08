'use client';

import { useAccount, useReadContract } from 'wagmi';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

export function useVestingSchedule() {
	const { address, isConnected } = useAccount();

	const scheduleQuery = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'getVestingSchedule',
		args: address ? [address] : undefined,
		query: {
			enabled: Boolean(address),
		},
	});

	const hasScheduleQuery = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'hasVestingSchedule',
		args: address ? [address] : undefined,
		query: {
			enabled: Boolean(address),
		},
	});

	const claimableAmountQuery = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'getClaimableAmount',
		args: address ? [address] : undefined,
		query: {
			enabled: Boolean(address),
		},
	});

	return {
		address,
		isConnected,
		schedule: scheduleQuery.data,
		hasSchedule: hasScheduleQuery.data,
		claimableAmount: claimableAmountQuery.data,
		isLoading:
			scheduleQuery.isLoading ||
			hasScheduleQuery.isLoading ||
			claimableAmountQuery.isLoading,
	};
}
