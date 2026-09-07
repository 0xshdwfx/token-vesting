'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import {
	useAccount,
	useReadContract,
	useWaitForTransactionReceipt,
	useWriteContract,
} from 'wagmi';
import { formatUnits } from 'viem';
import { toast } from 'sonner';

import ClaimButton from '@/components/ClaimButton';
import Metric from '@/components/Metric';
import Timeline from '@/components/Timeline';
import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

export default function Home() {
	const { address, isConnected } = useAccount();

	const { data: schedule, isLoading: isScheduleLoading } = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'getVestingSchedule',
		args: address ? [address] : undefined,
		query: {
			enabled: Boolean(address),
		},
	});

	const { data: hasSchedule, isLoading: isHasScheduleLoading } =
		useReadContract({
			address: TOKEN_VESTING_ADDRESS,
			abi: tokenVestingAbi,
			functionName: 'hasVestingSchedule',
			args: address ? [address] : undefined,
			query: {
				enabled: Boolean(address),
			},
		});

	const { data: claimableAmount } = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'getClaimableAmount',
		args: address ? [address] : undefined,
		query: {
			enabled: Boolean(address),
		},
	});

	const {
		writeContract,
		data: claimTransactionHash,
		isPending: isClaimPending,
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

	const { isLoading: isClaimConfirming } = useWaitForTransactionReceipt({
		hash: claimTransactionHash,
	});

	function handleClaim() {
		if (!address || !claimableAmount || claimableAmount === BigInt(0)) {
			toast.error('No tokens are currently claimable');
			return;
		}

		writeContract({
			address: TOKEN_VESTING_ADDRESS,
			abi: tokenVestingAbi,
			functionName: 'claimVestedTokens',
			args: [address],
		});
	}

	return (
		<main className='min-h-screen bg-slate-950 px-6 py-12 text-white'>
			<div className='mx-auto w-full max-w-5xl'>
				<header className='flex flex-col gap-6 border-b border-slate-800 pb-8 sm:flex-row sm:items-center sm:justify-between'>
					<div className='min-w-0'>
						<p className='text-sm font-medium text-cyan-400'>Token Vesting</p>

						<h1 className='mt-2 text-3xl font-bold tracking-tight sm:text-4xl'>
							Manage your vesting schedule
						</h1>
					</div>

					<div className='shrink-0 self-start sm:self-auto'>
						<ConnectButton />
					</div>
				</header>

				<section className='mt-12 rounded-2xl border border-slate-800 bg-slate-900 p-8 shadow-2xl'>
					{!isConnected && (
						<p className='text-slate-300'>
							Connect your wallet to view your vesting schedule.
						</p>
					)}

					{isConnected && (isScheduleLoading || isHasScheduleLoading) && (
						<p className='text-slate-300'>Loading your vesting schedule...</p>
					)}

					{isConnected &&
						!isScheduleLoading &&
						!isHasScheduleLoading &&
						hasSchedule === false && (
							<p className='text-slate-300'>
								No vesting schedule was found for this wallet.
							</p>
						)}

					{isConnected && hasSchedule === true && schedule && (
						<>
							<div className='grid gap-4 md:grid-cols-3'>
								<Metric
									label='Total allocation'
									value={formatTokenAmount(schedule.totalAllocation)}
								/>

								<Metric
									label='Claimed'
									value={formatTokenAmount(schedule.amountClaimed)}
								/>

								<Metric
									label='Claimable'
									value={formatTokenAmount(claimableAmount ?? BigInt(0))}
								/>
							</div>

							<Timeline
								startTime={schedule.startTime}
								cliffDuration={schedule.cliffDuration}
								vestingDuration={schedule.vestingDuration}
							/>

							<ClaimButton
								address={address}
								claimableAmount={claimableAmount}
								isClaimPending={isClaimPending}
								isClaimConfirming={isClaimConfirming}
								onClaim={handleClaim}
							/>
						</>
					)}
				</section>
			</div>
		</main>
	);
}

function formatTokenAmount(value: bigint): string {
	return `${formatUnits(value, 18)} VST`;
}
