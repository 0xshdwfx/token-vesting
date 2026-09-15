'use client';

import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import type { Address } from 'viem';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

export function useAddBeneficiary() {
	const queryClient = useQueryClient();

	const {
		writeContract,
		data: transactionHash,
		isPending,
	} = useWriteContract({
		mutation: {
			onSuccess: () => {
				toast.success('Beneficiary transaction submitted');
			},
			onError: (error) => {
				toast.error(error.message);
			},
		},
	});

	const {
		isLoading: isConfirming,
		isSuccess: isConfirmed,
		error: confirmationError,
	} = useWaitForTransactionReceipt({
		hash: transactionHash,
	});

	useEffect(() => {
		if (!confirmationError) {
			return;
		}

		toast.error(confirmationError.message);
	}, [confirmationError]);

	useEffect(() => {
		if (!transactionHash || !isConfirmed) {
			return;
		}

		void queryClient.invalidateQueries();
		toast.success('Beneficiary successfully added');
	}, [isConfirmed, queryClient, transactionHash]);

	function addBeneficiary(
		beneficiary: Address,
		totalAllocation: bigint,
		startTime: bigint,
		cliffDuration: bigint,
		vestingDuration: bigint,
	) {
		writeContract({
			address: TOKEN_VESTING_ADDRESS,
			abi: tokenVestingAbi,
			functionName: 'addBeneficiary',
			args: [
				beneficiary,
				totalAllocation,
				startTime,
				cliffDuration,
				vestingDuration,
			],
			gas: BigInt(300000),
		});
	}

	return {
		addBeneficiary,
		isPending,
		isConfirming,
	};
}
