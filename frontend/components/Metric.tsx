type MetricProps = {
	label: string;
	value: string;
};

export default function Metric({ label, value }: MetricProps) {
	return (
		<div className='rounded-xl border border-slate-800 bg-slate-950 p-5'>
			<p className='text-sm text-slate-400'>{label}</p>
			<p className='mt-2 text-2xl font-semibold'>{value}</p>
		</div>
	);
}
