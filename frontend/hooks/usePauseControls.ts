'use client';

import { useEffect, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';
import { getContractErrorMessage } from '@/lib/getContractErrorMessage';

export function usePauseControls() {
	const [action, setAction] = useState<'pause' | 'unpause' | null>(null);
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
		toast.success(
			action === 'pause'
				? 'Contract successfully paused'
				: 'Contract successfully unpaused',
		);
	}, [action, isConfirmed, queryClient, transactionHash]);

	function pause() {
		setAction('pause');
		writeContract({
			address: TOKEN_VESTING_ADDRESS,
			abi: tokenVestingAbi,
			functionName: 'pause',
			gas: BigInt(300000),
		});
	}

	function unpause() {
		setAction('unpause');
		writeContract({
			address: TOKEN_VESTING_ADDRESS,
			abi: tokenVestingAbi,
			functionName: 'unpause',
			gas: BigInt(300000),
		});
	}

	return {
		pause,
		unpause,
		isPending,
		isConfirming,
	};
}
