'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import VestingDashboard from '@/components/VestingDashboard';
import OwnerDashboard from '@/components/OwnerDashboard';
import { useTokenVestingOwner } from '@/hooks/useTokenVestingOwner';

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
