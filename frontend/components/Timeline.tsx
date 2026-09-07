type TimelineProps = {
	startTime: bigint;
	cliffDuration: bigint;
	vestingDuration: bigint;
};

export default function Timeline({
	startTime,
	cliffDuration,
	vestingDuration,
}: TimelineProps) {
	const cliffTime = startTime + cliffDuration;
	const vestingEndTime = startTime + vestingDuration;

	return (
		<div className='mt-8 grid gap-4 border-t border-slate-800 pt-8 sm:grid-cols-3'>
			<TimelineItem label='Start date' timestamp={startTime} />
			<TimelineItem label='Cliff date' timestamp={cliffTime} />
			<TimelineItem label='Vesting end' timestamp={vestingEndTime} />
		</div>
	);
}

type TimelineItemProps = {
	label: string;
	timestamp: bigint;
};

function TimelineItem({ label, timestamp }: TimelineItemProps) {
	return (
		<div>
			<p className='text-sm text-slate-400'>{label}</p>
			<p className='mt-1 font-medium'>
				{new Date(Number(timestamp) * 1000).toLocaleDateString('en-GB')}
			</p>
		</div>
	);
}
