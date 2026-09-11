'use client';

import type { Address } from 'viem';

type ReclaimTokensButtonProps = {
	beneficiary: Address;
	isPending: boolean;
	isConfirming: boolean;
	onReclaim: () => void;
};

export default function ReclaimTokensButton({
	beneficiary,
	isPending,
	isConfirming,
	onReclaim,
}: ReclaimTokensButtonProps) {
	const isDisabled = isPending || isConfirming;

	return (
		<button
			type='button'
			aria-label={`Reclaim unvested tokens for ${beneficiary}`}
			onClick={onReclaim}
			disabled={isDisabled}
			className='rounded-lg border border-amber-500/60 px-4 py-2 text-sm font-semibold text-amber-300 transition hover:bg-amber-500/10 disabled:cursor-not-allowed disabled:opacity-50'
		>
			{isPending || isConfirming ? 'Reclaiming...' : 'Reclaim unvested tokens'}
		</button>
	);
}
