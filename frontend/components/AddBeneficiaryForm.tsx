'use client';

import { useState, type FormEvent } from 'react';
import { isAddress, parseUnits, type Address } from 'viem';
import { toast } from 'sonner';
import { useWaitForTransactionReceipt, useWriteContract } from 'wagmi';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

type AddBeneficiaryFormProps = {
	isOwner: boolean;
};

const DEFAULT_CLIFF_DURATION = 30 * 24 * 60 * 60;
const DEFAULT_VESTING_DURATION = 365 * 24 * 60 * 60;

export default function AddBeneficiaryForm({
	isOwner,
}: AddBeneficiaryFormProps) {
	const [beneficiary, setBeneficiary] = useState('');
	const [allocation, setAllocation] = useState('');
	const [startTime, setStartTime] = useState('');
	const [cliffDuration, setCliffDuration] = useState(
		String(DEFAULT_CLIFF_DURATION),
	);
	const [vestingDuration, setVestingDuration] = useState(
		String(DEFAULT_VESTING_DURATION),
	);

	const {
		writeContract,
		data: transactionHash,
		isPending,
	} = useWriteContract({
		mutation: {
			onSuccess: () => {
				toast.success('Beneficiary transaction submitted');
			},
			onError: (error) => {
				toast.error(error.message);
			},
		},
	});

	const { isLoading: isConfirming } = useWaitForTransactionReceipt({
		hash: transactionHash,
	});

	if (!isOwner) {
		return null;
	}

	function handleSubmit(event: FormEvent<HTMLFormElement>) {
		event.preventDefault();

		if (!isAddress(beneficiary)) {
			toast.error('Enter a valid beneficiary address');
			return;
		}

		if (!allocation || !startTime || !cliffDuration || !vestingDuration) {
			toast.error('Complete every field');
			return;
		}

		const allocationWei = parseUnits(allocation, 18);
		const startTimeSeconds = BigInt(startTime);
		const cliffDurationSeconds = BigInt(cliffDuration);
		const vestingDurationSeconds = BigInt(vestingDuration);

		if (startTimeSeconds <= BigInt(0)) {
			toast.error('Start time must be greater than zero');
			return;
		}

		if (cliffDurationSeconds >= vestingDurationSeconds) {
			toast.error('Cliff must be shorter than vesting duration');
			return;
		}

		writeContract({
			address: TOKEN_VESTING_ADDRESS,
			abi: tokenVestingAbi,
			functionName: 'addBeneficiary',
			args: [
				beneficiary as Address,
				allocationWei,
				startTimeSeconds,
				cliffDurationSeconds,
				vestingDurationSeconds,
			],
		});
	}

	const isSubmitting = isPending || isConfirming;

	return (
		<section className='mt-8 rounded-2xl border border-slate-800 bg-slate-900 p-8 shadow-2xl'>
			<div>
				<p className='text-sm font-medium text-amber-400'>
					Owner administration
				</p>
				<h2 className='mt-2 text-2xl font-semibold text-white'>
					Add beneficiary
				</h2>
			</div>

			<form className='mt-6 grid gap-4 md:grid-cols-2' onSubmit={handleSubmit}>
				<Field
					label='Beneficiary address'
					value={beneficiary}
					onChange={setBeneficiary}
					placeholder='0x...'
					type='text'
				/>

				<Field
					label='Allocation (VST)'
					value={allocation}
					onChange={setAllocation}
					placeholder='1000'
					type='number'
					min='0'
					step='any'
				/>

				<Field
					label='Start time (Unix seconds)'
					value={startTime}
					onChange={setStartTime}
					placeholder='1750000000'
					type='number'
					min='1'
				/>

				<Field
					label='Cliff duration (seconds)'
					value={cliffDuration}
					onChange={setCliffDuration}
					type='number'
					min='1'
				/>

				<Field
					label='Vesting duration (seconds)'
					value={vestingDuration}
					onChange={setVestingDuration}
					type='number'
					min='1'
				/>

				<button
					type='submit'
					disabled={isSubmitting}
					className='self-end rounded-lg bg-amber-400 px-5 py-3 font-semibold text-slate-950 transition hover:bg-amber-300 disabled:cursor-not-allowed disabled:opacity-50'
				>
					{isSubmitting ? 'Adding beneficiary...' : 'Add beneficiary'}
				</button>
			</form>
		</section>
	);
}

type FieldProps = {
	label: string;
	value: string;
	onChange: (value: string) => void;
	placeholder?: string;
	type: 'text' | 'number';
	min?: string;
	step?: string;
};

function Field({
	label,
	value,
	onChange,
	placeholder,
	type,
	min,
	step,
}: FieldProps) {
	return (
		<label className='flex flex-col gap-2 text-sm text-slate-300'>
			<span>{label}</span>
			<input
				required
				type={type}
				value={value}
				onChange={(event) => onChange(event.target.value)}
				placeholder={placeholder}
				min={min}
				step={step}
				className='rounded-lg border border-slate-700 bg-slate-950 px-4 py-3 text-white outline-none transition placeholder:text-slate-600 focus:border-amber-400'
			/>
		</label>
	);
}
