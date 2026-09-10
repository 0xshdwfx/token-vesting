'use client';

import type { Address } from 'viem';

import { useRevokeSchedule } from '@/hooks/useRevokeSchedule';

type RevokeScheduleButtonProps = {
	beneficiary: Address;
	revoked: boolean;
};

export default function RevokeScheduleButton({
	beneficiary,
	revoked,
}: RevokeScheduleButtonProps) {
	const { revoke, isPending, isConfirming } = useRevokeSchedule();

	const isDisabled = revoked || isPending || isConfirming;

	return (
		<button
			type='button'
			onClick={() => revoke(beneficiary)}
			disabled={isDisabled}
			className='rounded-lg border border-amber-500/60 px-4 py-2 text-sm font-semibold text-amber-300 transition hover:bg-amber-500/10 disabled:cursor-not-allowed disabled:opacity-50 cursor-pointer'
		>
			{isPending || isConfirming
				? 'Revoking...'
				: revoked
					? 'Schedule revoked'
					: 'Revoke schedule'}
		</button>
	);
}
