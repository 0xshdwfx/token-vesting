'use client';

import { formatUnits } from 'viem';

import { useBeneficiaryList } from '@/hooks/useBeneficiaryList';

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

			{beneficiaries.length === 0 ? (
				<p className='mt-6 text-slate-400'>No beneficiaries have been added.</p>
			) : (
				<div className='mt-6 space-y-4'>
					{beneficiaries.map((beneficiary) => (
						<article
							key={beneficiary.beneficiary}
							className='rounded-xl border border-slate-800 bg-slate-950 p-5'
						>
							<p className='break-all font-mono text-sm text-slate-300'>
								{beneficiary.beneficiary}
							</p>

							<div className='mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-4'>
								<Detail
									label='Allocation'
									value={`${formatUnits(beneficiary.totalAllocation, 18)} VST`}
								/>

								<Detail
									label='Claimed'
									value={`${formatUnits(beneficiary.amountClaimed, 18)} VST`}
								/>

								<Detail
									label='Status'
									value={beneficiary.revoked ? 'Revoked' : 'Active'}
								/>

								<Detail
									label='Unvested tokens'
									value={
										beneficiary.unvestedTokensReclaimed
											? 'Reclaimed'
											: 'Not reclaimed'
									}
								/>
							</div>
						</article>
					))}
				</div>
			)}
		</section>
	);
}

type DetailProps = {
	label: string;
	value: string;
};

function Detail({ label, value }: DetailProps) {
	return (
		<div>
			<p className='text-sm text-slate-500'>{label}</p>
			<p className='mt-1 text-sm font-medium text-slate-200'>{value}</p>
		</div>
	);
}
