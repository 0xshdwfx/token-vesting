'use client';

import { useReadContract } from 'wagmi';

import {
	TOKEN_VESTING_ADDRESS,
	VESTING_TOKEN_ADDRESS,
} from '@/lib/contracts/addresses';
import { erc20Abi } from '@/lib/contracts/erc20Abi';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

export function useOwnerOverview(isOwner: boolean) {
	const totalOutstandingAllocation = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'totalOutstandingAllocation',
		query: {
			enabled: isOwner,
		},
	});

	const beneficiaryCount = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'getBeneficiariesLength',
		query: {
			enabled: isOwner,
		},
	});

	const paused = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'paused',
		query: {
			enabled: isOwner,
		},
	});

	const contractBalance = useReadContract({
		address: VESTING_TOKEN_ADDRESS,
		abi: erc20Abi,
		functionName: 'balanceOf',
		args: [TOKEN_VESTING_ADDRESS],
		query: {
			enabled: isOwner,
		},
	});

	const outstandingAllocation = totalOutstandingAllocation.data ?? BigInt(0);

	const vestingTokenBalance = contractBalance.data ?? BigInt(0);

	const availableExcess =
		vestingTokenBalance > outstandingAllocation
			? vestingTokenBalance - outstandingAllocation
			: BigInt(0);

	return {
		totalOutstandingAllocation: outstandingAllocation,
		beneficiaryCount: beneficiaryCount.data ?? BigInt(0),
		isPaused: paused.data ?? false,
		contractBalance: vestingTokenBalance,
		availableExcess,
		isLoading:
			totalOutstandingAllocation.isLoading ||
			beneficiaryCount.isLoading ||
			paused.isLoading ||
			contractBalance.isLoading,
	};
}
