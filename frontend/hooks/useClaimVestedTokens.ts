'use client';

import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

type Address = `0x${string}`;

export function useClaimVestedTokens() {
	const queryClient = useQueryClient();

	const {
		writeContract,
		data: transactionHash,
		isPending,
	} = useWriteContract({
		mutation: {
			onSuccess: () => {
				toast.success('Claim transaction submitted');
			},
			onError: (error) => {
				toast.error(error.message);
			},
		},
	});

	const { isLoading: isConfirming, isSuccess: isConfirmed } =
		useWaitForTransactionReceipt({
			hash: transactionHash,
		});

	useEffect(() => {
		if (!isConfirmed) {
			return;
		}

		void queryClient.invalidateQueries();
		toast.success('Claim confirmed');
	}, [isConfirmed, queryClient]);

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
