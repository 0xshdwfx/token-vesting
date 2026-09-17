'use client';

import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';
import { getContractErrorMessage } from '@/lib/getContractErrorMessage';

type Address = `0x${string}`;

export function useClaimVestedTokens() {
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
		if (!isConfirmed) {
			return;
		}

		void queryClient.invalidateQueries();
		toast.success('Claim confirmed');
	}, [isConfirmed, queryClient]);

	useEffect(() => {
		if (!confirmationError) {
			return;
		}

		toast.error(getContractErrorMessage(confirmationError));
	}, [confirmationError]);

	useEffect(() => {
		if (!transactionHash || !isConfirmed) {
			return;
		}

		void queryClient.invalidateQueries();
		toast.success('Claim confirmed');
	}, [transactionHash, isConfirmed, queryClient]);

	function claim(beneficiary: Address, claimableAmount: bigint | undefined) {
		if (!claimableAmount || claimableAmount === BigInt(0)) {
			toast.error('No tokens are currently claimable');
			return;
		}

		writeContract({
			address: TOKEN_VESTING_ADDRESS,
			abi: tokenVestingAbi,
			functionName: 'claimVestedTokens',
			args: [beneficiary],
		});
	}

	return {
		claim,
		isPending,
		isConfirming,
	};
}
