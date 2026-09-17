'use client';

import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';
import { getContractErrorMessage } from '@/lib/getContractErrorMessage';

export function useWithdrawExcessTokens() {
	const queryClient = useQueryClient();

	const {
		writeContract,
		data: transactionHash,
		isPending,
	} = useWriteContract({
		mutation: {
			onError: (error) => {
				toast.error(getContractErrorMessage(error));
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
			toast.error(getContractErrorMessage(confirmationError));
		}
	}, [confirmationError]);

	useEffect(() => {
		if (!transactionHash || !isConfirmed) {
			return;
		}

		void queryClient.invalidateQueries();
		toast.success('Excess tokens successfully withdrawn');
	}, [isConfirmed, queryClient, transactionHash]);

	function withdrawExcess() {
		writeContract({
			address: TOKEN_VESTING_ADDRESS,
			abi: tokenVestingAbi,
			functionName: 'withdrawExcessTokens',
			gas: BigInt(300000),
		});
	}

	return {
		withdrawExcess,
		isPending,
		isConfirming,
	};
}
