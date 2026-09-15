'use client';

import { formatUnits } from 'viem';

import Metric from '@/components/Metric';
import AddBeneficiaryForm from '@/components/AddBeneficiaryForm';
import BeneficiaryList from '@/components/BeneficiaryList';
import WithdrawExcessTokensButton from '@/components/WithdrawExcessTokensButton';
import PauseControls from '@/components/PauseControls';
import { useOwnerOverview } from '@/hooks/useOwnerOverview';
import { useWithdrawExcessTokens } from '@/hooks/useWithdrawExcessTokens';
import { usePauseControls } from '@/hooks/usePauseControls';

type OwnerDashboardProps = {
	isOwner: boolean;
};

export default function OwnerDashboard({ isOwner }: OwnerDashboardProps) {
	const {
		totalOutstandingAllocation,
		beneficiaryCount,
		isPaused,
		contractBalance,
		availableExcess,
		isLoading,
	} = useOwnerOverview(isOwner);

	const {
		withdrawExcess,
		isPending: isWithdrawPending,
		isConfirming: isWithdrawConfirming,
	} = useWithdrawExcessTokens();

	const {
		pause,
		unpause,
		isPending: isPausePending,
		isConfirming: isPauseConfirming,
	} = usePauseControls();

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
					<>
						<div className='mt-6 grid gap-4 md:grid-cols-2 lg:grid-cols-5'>
							<Metric
								label='Outstanding allocation'
								value={`${formatUnits(totalOutstandingAllocation, 18)} VST`}
							/>

							<Metric
								label='Contract balance'
								value={`${formatUnits(contractBalance, 18)} VST`}
							/>

							<Metric
								label='Available excess'
								value={`${formatUnits(availableExcess, 18)} VST`}
							/>

							<Metric
								label='Beneficiaries'
								value={beneficiaryCount.toString()}
							/>

							<Metric
								label='Contract status'
								value={isPaused ? 'Paused' : 'Active'}
							/>
						</div>

						<div className='mt-6'>
							<WithdrawExcessTokensButton
								isPending={isWithdrawPending}
								isConfirming={isWithdrawConfirming}
								onWithdraw={withdrawExcess}
							/>
						</div>

						<div className='mt-6'>
							<PauseControls
								isPaused={isPaused}
								isPending={isPausePending}
								isConfirming={isPauseConfirming}
								onPause={pause}
								onUnpause={unpause}
							/>
						</div>
					</>
				)}
			</section>

			<AddBeneficiaryForm isOwner={isOwner} />
			<BeneficiaryList isOwner={isOwner} />
		</>
	);
}
