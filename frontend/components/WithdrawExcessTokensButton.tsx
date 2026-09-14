'use client';

type WithdrawExcessTokensButtonProps = {
	isPending: boolean;
	isConfirming: boolean;
	onWithdraw: () => void;
};

export default function WithdrawExcessTokensButton({
	isPending,
	isConfirming,
	onWithdraw,
}: WithdrawExcessTokensButtonProps) {
	const isDisabled = isPending || isConfirming;

	return (
		<button
			type='button'
			aria-label={'Withdraw excess tokens'}
			onClick={onWithdraw}
			disabled={isDisabled}
			className='rounded-lg border border-amber-500/60 px-4 py-2 text-sm font-semibold text-amber-300 transition hover:bg-amber-500/10 disabled:cursor-not-allowed disabled:opacity-50 cursor-pointer'
		>
			{isPending || isConfirming ? 'Withdrawing...' : 'Withdraw excess tokens'}
		</button>
	);
}
