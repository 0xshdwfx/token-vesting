'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import VestingDashboard from '@/components/VestingDashboard';
import OwnerDashboard from '@/components/OwnerDashboard';
import { useTokenVestingOwner } from '@/hooks/useTokenVestingOwner';

import Link from 'next/link';

export default function Home() {
	const { isOwner, isLoading: isOwnerLoading } = useTokenVestingOwner();

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

				<section className='mt-8 rounded-2xl border border-cyan-500/30 bg-cyan-500/5 p-6'>
					<p className='text-sm font-medium text-cyan-400'>
						Public interactive demo
					</p>

					<h2 className='mt-2 text-xl font-semibold text-white'>
						Try the beneficiary experience
					</h2>

					<p className='mt-2 max-w-2xl text-sm leading-6 text-slate-300'>
						Connect a Sepolia wallet to create a fixed demo vesting schedule for
						your own address. The demo uses testnet tokens with no real-world
						value.
					</p>

					<Link
						href='/demo'
						className='mt-4 inline-flex rounded-lg bg-cyan-500 px-4 py-2 font-semibold text-slate-950 transition hover:bg-cyan-400'
					>
						Open interactive demo
					</Link>
				</section>

				<VestingDashboard />

				{isOwnerLoading && (
					<p className='mt-6 text-sm text-slate-400'>
						Checking owner permissions...
					</p>
				)}

				{!isOwnerLoading && (
					<p className='mt-6 text-sm text-slate-400'>
						{isOwner
							? 'Connected as contract owner'
							: 'Connected wallet is not the contract owner'}
					</p>
				)}

				<OwnerDashboard isOwner={isOwner} />
			</div>
		</main>
	);
}
