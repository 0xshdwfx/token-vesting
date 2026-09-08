'use client';

import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import { toast } from 'sonner';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

export function useClaimVestedTokens() {
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

	const { isLoading: isConfirming } = useWaitForTransactionReceipt({
		hash: transactionHash,
	});

	function claim(
		beneficiary: `0x${string}`,
		claimableAmount: bigint | undefined,
	) {
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
