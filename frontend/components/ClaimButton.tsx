'use client';

import type { Address } from 'viem';

type ClaimButtonProps = {
	address: Address | undefined;
	claimableAmount: bigint | undefined;
	isClaimPending: boolean;
	isClaimConfirming: boolean;
	onClaim: () => void;
};

export default function ClaimButton({
	address,
	claimableAmount,
	isClaimPending,
	isClaimConfirming,
	onClaim,
}: ClaimButtonProps) {
	const isDisabled =
		!address ||
		!claimableAmount ||
		claimableAmount === BigInt(0) ||
		isClaimPending ||
		isClaimConfirming;

	return (
		<button
			type='button'
			onClick={onClaim}
			disabled={isDisabled}
			className='mt-8 rounded-lg bg-cyan-500 px-5 py-3 font-semibold text-slate-950 transition hover:bg-cyan-400 disabled:cursor-not-allowed disabled:opacity-50'
		>
			{isClaimPending || isClaimConfirming
				? 'Claiming...'
				: 'Claim vested tokens'}
		</button>
	);
}
