'use client';

import { useEffect, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import {
	useAccount,
	useReadContract,
	useWaitForTransactionReceipt,
	useWriteContract,
} from 'wagmi';

import { DEMO_TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { demoTokenVestingAbi } from '@/lib/contracts/demoTokenVestingAbi';

type Action = 'create' | 'claim' | null;

export function useDemoVesting() {
	const { address, isConnected } = useAccount();
	const queryClient = useQueryClient();
	const [action, setAction] = useState<Action>(null);

	const scheduleQuery = useReadContract({
		address: DEMO_TOKEN_VESTING_ADDRESS,
		abi: demoTokenVestingAbi,
		functionName: 'getVestingSchedule',
		args: address ? [address] : undefined,
		query: {
			enabled: Boolean(address),
		},
	});

	const hasScheduleQuery = useReadContract({
		address: DEMO_TOKEN_VESTING_ADDRESS,
		abi: demoTokenVestingAbi,
		functionName: 'hasDemoSchedule',
		args: address ? [address] : undefined,
		query: {
			enabled: Boolean(address),
		},
	});

	const claimableAmountQuery = useReadContract({
		address: DEMO_TOKEN_VESTING_ADDRESS,
		abi: demoTokenVestingAbi,
		functionName: 'getClaimableAmount',
		args: address ? [address] : undefined,
		query: {
			enabled: Boolean(address),
		},
	});

	const {
		writeContract,
		data: transactionHash,
		isPending,
	} = useWriteContract({
		mutation: {
			onError: (error) => {
				toast.error(error.message);
				setAction(null);
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
		setAction(null);
	}, [confirmationError]);

	useEffect(() => {
		if (!transactionHash || !isConfirmed || !action) {
			return;
		}

		void queryClient.invalidateQueries();

		toast.success(
			action === 'create'
				? 'Demo vesting schedule created'
				: 'Demo tokens successfully claimed',
		);

		setAction(null);
	}, [action, isConfirmed, queryClient, transactionHash]);

	function createDemoSchedule() {
		setAction('create');

		writeContract({
			address: DEMO_TOKEN_VESTING_ADDRESS,
			abi: demoTokenVestingAbi,
			functionName: 'createDemoSchedule',
		});
	}

	function claimDemoTokens() {
		if (!claimableAmountQuery.data || claimableAmountQuery.data === BigInt(0)) {
			toast.error('No demo tokens are currently claimable');
			return;
		}

		setAction('claim');

		writeContract({
			address: DEMO_TOKEN_VESTING_ADDRESS,
			abi: demoTokenVestingAbi,
			functionName: 'claimDemoTokens',
		});
	}

	return {
		address,
		isConnected,
		schedule: scheduleQuery.data,
		hasSchedule: hasScheduleQuery.data,
		claimableAmount: claimableAmountQuery.data ?? BigInt(0),
		createDemoSchedule,
		claimDemoTokens,
		isPending,
		isConfirming,
		isSubmitting: isPending || isConfirming,
		isLoading:
			scheduleQuery.isLoading ||
			hasScheduleQuery.isLoading ||
			claimableAmountQuery.isLoading,
		isError:
			scheduleQuery.isError ||
			hasScheduleQuery.isError ||
			claimableAmountQuery.isError,
	};
}
