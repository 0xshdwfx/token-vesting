'use client';

type OwnerDashboardProps = {
	isOwner: boolean;
};

export default function OwnerDashboard({ isOwner }: OwnerDashboardProps) {
	if (!isOwner) {
		return null;
	}

	return (
		<section className='mt-8 rounded-2xl border border-amber-900/50 bg-slate-900 p-8 shadow-2xl'>
			<h2 className='text-2xl font-semibold text-amber-400'>
				Owner administration
			</h2>

			<p className='mt-2 text-slate-400'>Owner controls will appear here.</p>
		</section>
	);
}
