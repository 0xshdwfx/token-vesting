'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';

import ClaimButton from '@/components/ClaimButton';
import Metric from '@/components/Metric';
import Timeline from '@/components/Timeline';
import { useDemoVesting } from '@/hooks/useDemoVesting';
import { formatTokenAmount } from '@/lib/formatTokenAmount';

export default function DemoPage() {
	const {
		address,
		isConnected,
		schedule,
		hasSchedule,
		claimableAmount,
		createDemoSchedule,
		claimDemoTokens,
		isPending,
		isConfirming,
		isLoading,
		isError,
	} = useDemoVesting();

	const isSubmitting = isPending || isConfirming;

	if (!isConnected) {
		return (
			<main className='min-h-screen bg-slate-950 px-6 py-12 text-white'>
				<div className='mx-auto w-full max-w-5xl'>
					<header className='flex flex-col gap-6 border-b border-slate-800 pb-8 sm:flex-row sm:items-center sm:justify-between'>
						<div>
							<p className='text-sm font-medium text-cyan-400'>Token Vesting</p>
							<h1 className='mt-2 text-3xl font-bold tracking-tight sm:text-4xl'>
								Interactive beneficiary demo
							</h1>
						</div>

						<div className='shrink-0 self-start sm:self-auto'>
							<ConnectButton />
						</div>
					</header>

					<section className='mt-12 rounded-2xl border border-slate-800 bg-slate-900 p-8 shadow-2xl'>
						<h2 className='text-2xl font-semibold text-white'>
							Try the beneficiary flow
						</h2>

						<p className='mt-4 max-w-2xl leading-7 text-slate-300'>
							Connect a Sepolia wallet to create a fixed demo vesting schedule
							for your own address. This demo uses testnet tokens with no
							real-world value.
						</p>

						<p className='mt-4 text-sm text-amber-300'>
							You need Sepolia ETH to submit transactions.
						</p>
					</section>
				</div>
			</main>
		);
	}

	if (isLoading) {
		return (
			<main className='min-h-screen bg-slate-950 px-6 py-12 text-white'>
				<div className='mx-auto w-full max-w-5xl'>
					<p className='text-slate-300'>Loading your demo schedule...</p>
				</div>
			</main>
		);
	}

	if (isError) {
		return (
			<main className='min-h-screen bg-slate-950 px-6 py-12 text-white'>
				<div className='mx-auto w-full max-w-5xl'>
					<p className='text-red-400'>
						Unable to load the demo schedule. Please check that your wallet is
						connected to Sepolia.
					</p>
				</div>
			</main>
		);
	}

	if (hasSchedule === false || !schedule) {
		return (
			<main className='min-h-screen bg-slate-950 px-6 py-12 text-white'>
				<div className='mx-auto w-full max-w-5xl'>
					<header className='flex flex-col gap-6 border-b border-slate-800 pb-8 sm:flex-row sm:items-center sm:justify-between'>
						<div>
							<p className='text-sm font-medium text-cyan-400'>Token Vesting</p>
							<h1 className='mt-2 text-3xl font-bold tracking-tight sm:text-4xl'>
								Interactive beneficiary demo
							</h1>
						</div>

						<div className='shrink-0 self-start sm:self-auto'>
							<ConnectButton />
						</div>
					</header>

					<section className='mt-12 rounded-2xl border border-slate-800 bg-slate-900 p-8 shadow-2xl'>
						<h2 className='text-2xl font-semibold text-white'>
							Create your demo schedule
						</h2>

						<p className='mt-4 leading-7 text-slate-300'>
							Your connected wallet can create one fixed demo schedule for
							itself.
						</p>

						<ul className='mt-6 space-y-2 text-sm text-slate-400'>
							<li>Allocation: 1 VST</li>
							<li>Cliff: 60 seconds</li>
							<li>Vesting duration: 10 minutes</li>
							<li>Beneficiary: your connected wallet</li>
						</ul>

						<button
							type='button'
							onClick={createDemoSchedule}
							disabled={isSubmitting}
							className='mt-8 rounded-lg bg-cyan-500 px-5 py-3 font-semibold text-slate-950 transition hover:bg-cyan-400 disabled:cursor-not-allowed disabled:opacity-50'
						>
							{isSubmitting
								? 'Creating demo schedule...'
								: 'Create demo schedule'}
						</button>
					</section>
				</div>
			</main>
		);
	}

	return (
		<main className='min-h-screen bg-slate-950 px-6 py-12 text-white'>
			<div className='mx-auto w-full max-w-5xl'>
				<header className='flex flex-col gap-6 border-b border-slate-800 pb-8 sm:flex-row sm:items-center sm:justify-between'>
					<div>
						<p className='text-sm font-medium text-cyan-400'>Token Vesting</p>
						<h1 className='mt-2 text-3xl font-bold tracking-tight sm:text-4xl'>
							Interactive beneficiary demo
						</h1>
					</div>

					<div className='shrink-0 self-start sm:self-auto'>
						<ConnectButton />
					</div>
				</header>

				<section className='mt-12 rounded-2xl border border-slate-800 bg-slate-900 p-8 shadow-2xl'>
					<div className='mb-6'>
						<p className='text-sm text-slate-400'>Connected beneficiary</p>
						<p className='mt-1 break-all font-mono text-sm text-cyan-300'>
							{address}
						</p>
					</div>

					<div className='grid gap-4 md:grid-cols-3'>
						<Metric
							label='Demo allocation'
							value={`${formatTokenAmount(schedule.totalAllocation)} VST`}
						/>

						<Metric
							label='Claimed'
							value={`${formatTokenAmount(schedule.amountClaimed)} VST`}
						/>

						<Metric
							label='Claimable'
							value={`${formatTokenAmount(claimableAmount)} VST`}
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
						isClaimPending={isPending}
						isClaimConfirming={isConfirming}
						onClaim={claimDemoTokens}
					/>
				</section>
			</div>
		</main>
	);
}
