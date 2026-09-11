'use client';

import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import type { Address } from 'viem';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

export function useReclaimUnvestedTokens() {
	const queryClient = useQueryClient();

	const {
		writeContract,
		data: transactionHash,
		isPending,
	} = useWriteContract({
		mutation: {
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
		if (confirmationError) {
			toast.error(confirmationError.message);
		}
	}, [confirmationError]);

	useEffect(() => {
		if (!transactionHash || !isConfirmed) {
			return;
		}

		void queryClient.invalidateQueries();
		toast.success('Unvested tokens successfully reclaimed');
	}, [isConfirmed, queryClient, transactionHash]);

	function reclaim(beneficiary: Address) {
		writeContract({
			address: TOKEN_VESTING_ADDRESS,
			abi: tokenVestingAbi,
			functionName: 'reclaimUnvestedTokens',
			args: [beneficiary],
		});
	}

	return {
		reclaim,
		isPending,
		isConfirming,
	};
}
