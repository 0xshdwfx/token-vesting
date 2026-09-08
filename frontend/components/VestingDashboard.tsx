'use client';

import ClaimButton from '@/components/ClaimButton';
import Metric from '@/components/Metric';
import Timeline from '@/components/Timeline';
import { useClaimVestedTokens } from '@/hooks/useClaimVestedTokens';
import { useVestingSchedule } from '@/hooks/useVestingSchedule';
import { formatUnits } from 'viem';

export default function VestingDashboard() {
	const {
		address,
		isConnected,
		schedule,
		hasSchedule,
		claimableAmount,
		isLoading,
	} = useVestingSchedule();

	const {
		claim,
		isPending: isClaimPending,
		isConfirming: isClaimConfirming,
	} = useClaimVestedTokens();

	function handleClaim() {
		if (!address) {
			return;
		}

		claim(address, claimableAmount);
	}

	if (!isConnected) {
		return (
			<section className='mt-12 rounded-2xl border border-slate-800 bg-slate-900 p-8 shadow-2xl'>
				<p className='text-slate-300'>
					Connect your wallet to view your vesting schedule.
				</p>
			</section>
		);
	}

	if (isLoading) {
		return (
			<section className='mt-12 rounded-2xl border border-slate-800 bg-slate-900 p-8 shadow-2xl'>
				<p className='text-slate-300'>Loading your vesting schedule...</p>
			</section>
		);
	}

	if (hasSchedule === false || !schedule) {
		return (
			<section className='mt-12 rounded-2xl border border-slate-800 bg-slate-900 p-8 shadow-2xl'>
				<p className='text-slate-300'>
					No vesting schedule was found for this wallet.
				</p>
			</section>
		);
	}

	return (
		<section className='mt-12 rounded-2xl border border-slate-800 bg-slate-900 p-8 shadow-2xl'>
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
		</section>
	);
}

function formatTokenAmount(value: bigint): string {
	return `${formatUnits(value, 18)} VST`;
}
