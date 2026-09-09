'use client';

import { formatUnits } from 'viem';

import Metric from '@/components/Metric';
import AddBeneficiaryForm from '@/components/AddBeneficiaryForm';
import BeneficiaryList from '@/components/BeneficiaryList';
import { useOwnerOverview } from '@/hooks/useOwnerOverview';

type OwnerDashboardProps = {
	isOwner: boolean;
};

export default function OwnerDashboard({ isOwner }: OwnerDashboardProps) {
	const { totalOutstandingAllocation, beneficiaryCount, isPaused, isLoading } =
		useOwnerOverview(isOwner);

	if (!isOwner) {
		return null;
	}

	return (
		<>
			<section className='mt-8 rounded-2xl border border-amber-900/50 bg-slate-900 p-8 shadow-2xl'>
				<p className='text-sm font-medium text-amber-400'>
					Owner administration
				</p>

				<h2 className='mt-2 text-2xl font-semibold text-white'>
					Contract overview
				</h2>

				{isLoading ? (
					<p className='mt-6 text-slate-400'>Loading contract overview...</p>
				) : (
					<div className='mt-6 grid gap-4 md:grid-cols-3'>
						<Metric
							label='Outstanding allocation'
							value={`${formatUnits(totalOutstandingAllocation, 18)} VST`}
						/>

						<Metric label='Beneficiaries' value={beneficiaryCount.toString()} />

						<Metric
							label='Contract status'
							value={isPaused ? 'Paused' : 'Active'}
						/>
					</div>
				)}
			</section>

			<AddBeneficiaryForm isOwner={isOwner} />
			<BeneficiaryList isOwner={isOwner} />
		</>
	);
}
