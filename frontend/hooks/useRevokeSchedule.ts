'use client';

import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import type { Address } from 'viem';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';
import { getContractErrorMessage } from '@/lib/getContractErrorMessage';

export function useRevokeSchedule() {
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
		toast.success('Vesting schedule revoked');
	}, [isConfirmed, queryClient, transactionHash]);

	function revoke(beneficiary: Address) {
		writeContract({
			address: TOKEN_VESTING_ADDRESS,
			abi: tokenVestingAbi,
			functionName: 'revokeSchedule',
			args: [beneficiary],
			gas: BigInt(300000),
		});
	}

	return {
		revoke,
		isPending,
		isConfirming,
	};
}
