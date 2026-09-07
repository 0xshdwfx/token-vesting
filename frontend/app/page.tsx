import { ConnectButton } from '@rainbow-me/rainbowkit';

import VestingDashboard from '@/components/VestingDashboard';

export default function Home() {
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
			</div>
		</main>
	);
}
