'use client';

import { useBeneficiaryList } from '@/hooks/useBeneficiaryList';
import { formatUnits } from 'viem';

type BeneficiaryListProps = {
	isOwner: boolean;
};

export default function BeneficiaryList({ isOwner }: BeneficiaryListProps) {
	const { beneficiaries, isLoading } = useBeneficiaryList(isOwner);

	if (!isOwner) {
		return null;
	}

	if (isLoading) {
		return (
			<section className='mt-8 rounded-2xl border border-slate-800 bg-slate-900 p-8'>
				<p className='text-slate-400'>Loading beneficiaries...</p>
			</section>
		);
	}

	return (
		<section className='mt-8 rounded-2xl border border-slate-800 bg-slate-900 p-8'>
			<h2 className='text-2xl font-semibold text-white'>Beneficiaries</h2>

			<div className='mt-6 space-y-4'>
				{beneficiaries.map((beneficiary) => (
					<div
						key={beneficiary}
						className='rounded-xl border border-slate-800 bg-slate-950 p-4'
					>
						<p className='break-all font-mono text-sm text-slate-300'>
							{beneficiary}
						</p>
					</div>
				))}
			</div>
		</section>
	);
}
