'use client';

import { formatUnits } from 'viem';
import { useReadContract } from 'wagmi';

import Metric from '@/components/Metric';
import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

type OwnerDashboardProps = {
	isOwner: boolean;
};

export default function OwnerDashboard({ isOwner }: OwnerDashboardProps) {
	const { data: totalOutstandingAllocation } = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'totalOutstandingAllocation',
		query: {
			enabled: isOwner,
		},
	});

	const { data: beneficiaryCount } = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'getBeneficiariesLength',
		query: {
			enabled: isOwner,
		},
	});

	const { data: isPaused } = useReadContract({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'paused',
		query: {
			enabled: isOwner,
		},
	});

	if (!isOwner) {
		return null;
	}

	return (
		<section className='mt-8 rounded-2xl border border-amber-900/50 bg-slate-900 p-8 shadow-2xl'>
			<div>
				<p className='text-sm font-medium text-amber-400'>
					Owner administration
				</p>

				<h2 className='mt-2 text-2xl font-semibold text-white'>
					Contract overview
				</h2>
			</div>

			<div className='mt-6 grid gap-4 md:grid-cols-3'>
				<Metric
					label='Outstanding allocation'
					value={`${formatUnits(
						totalOutstandingAllocation ?? BigInt(0),
						18,
					)} VST`}
				/>

				<Metric
					label='Beneficiaries'
					value={String(beneficiaryCount ?? BigInt(0))}
				/>

				<Metric
					label='Contract status'
					value={isPaused ? 'Paused' : 'Active'}
				/>
			</div>
		</section>
	);
}
