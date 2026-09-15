'use client';

type PauseControlsProps = {
	isPaused: boolean;
	isPending: boolean;
	isConfirming: boolean;
	onPause: () => void;
	onUnpause: () => void;
};

export default function PauseControls({
	isPaused,
	isPending,
	isConfirming,
	onPause,
	onUnpause,
}: PauseControlsProps) {
	const isDisabled = isPending || isConfirming;

	return !isPaused ? (
		<button
			type='button'
			aria-label={'Pause contract'}
			onClick={onPause}
			disabled={isDisabled}
			className='rounded-lg border border-amber-500/60 px-4 py-2 text-sm font-semibold text-amber-300 transition hover:bg-amber-500/10 disabled:cursor-not-allowed disabled:opacity-50 cursor-pointer'
		>
			{isPending || isConfirming ? 'Pausing...' : 'Pause'}
		</button>
	) : (
		<button
			type='button'
			aria-label={'Unpause contract'}
			onClick={onUnpause}
			disabled={isDisabled}
			className='rounded-lg border border-amber-500/60 px-4 py-2 text-sm font-semibold text-amber-300 transition hover:bg-amber-500/10 disabled:cursor-not-allowed disabled:opacity-50 cursor-pointer'
		>
			{isPending || isConfirming ? 'Unpausing...' : 'Unpause'}
		</button>
	);
}
