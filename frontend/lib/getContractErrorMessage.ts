import { decodeErrorResult, type Hex } from 'viem';

import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

type ErrorLike = {
	data?: unknown;
	cause?: unknown;
	message?: unknown;
	shortMessage?: unknown;
	details?: unknown;
	reason?: unknown;
	errorName?: unknown;
};

function collectErrorData(
	error: unknown,
	visited = new Set<unknown>(),
): Hex | undefined {
	if (error === null || typeof error !== 'object') {
		return undefined;
	}

	if (visited.has(error)) {
		return undefined;
	}

	visited.add(error);

	const errorLike = error as ErrorLike;

	if (typeof errorLike.data === 'string' && errorLike.data.startsWith('0x')) {
		return errorLike.data as Hex;
	}

	return collectErrorData(errorLike.cause, visited);
}

function collectErrorText(
	error: unknown,
	visited = new Set<unknown>(),
): string {
	if (error === null || error === undefined) {
		return '';
	}

	if (typeof error === 'string') {
		return error;
	}

	if (typeof error !== 'object') {
		return String(error);
	}

	if (visited.has(error)) {
		return '';
	}

	visited.add(error);

	const errorLike = error as ErrorLike;

	return [
		errorLike.message,
		errorLike.shortMessage,
		errorLike.details,
		errorLike.reason,
		errorLike.errorName,
		collectErrorText(errorLike.cause, visited),
	]
		.filter((value): value is string => typeof value === 'string')
		.join(' ');
}

function getDecodedErrorName(error: unknown): string | undefined {
	const errorData = collectErrorData(error);

	if (!errorData) {
		return undefined;
	}

	try {
		const decodedError = decodeErrorResult({
			abi: tokenVestingAbi,
			data: errorData,
		});

		return decodedError.errorName;
	} catch {
		return undefined;
	}
}

export function getContractErrorMessage(error: unknown): string {
	const errorText = collectErrorText(error);
	const decodedErrorName = getDecodedErrorName(error);
	const combinedError = `${errorText} ${decodedErrorName ?? ''}`;

	if (combinedError.includes('TokenVesting__BeneficiaryAlreadyExists')) {
		return 'This beneficiary already has a vesting schedule.';
	}

	if (combinedError.includes('TokenVesting__InvalidBeneficiaryAddress')) {
		return 'The beneficiary address is invalid.';
	}

	if (combinedError.includes('TokenVesting__InsufficientFunding')) {
		return 'The contract does not have enough tokens to fund this allocation.';
	}

	if (combinedError.includes('TokenVesting__InvalidAllocationAmount')) {
		return 'The allocation must be greater than zero.';
	}

	if (combinedError.includes('TokenVesting__InvalidStartTime')) {
		return 'The start time is invalid.';
	}

	if (
		combinedError.includes(
			'TokenVesting__CliffDurationIsGreaterThanVestingDuration',
		)
	) {
		return 'The cliff duration must be shorter than the vesting duration.';
	}

	if (combinedError.includes('TokenVesting__InvalidVestingDuration')) {
		return 'The vesting duration is invalid.';
	}

	if (combinedError.includes('TokenVesting__UnvestedTokensAlreadyReclaimed')) {
		return 'The unvested tokens have already been reclaimed.';
	}

	if (combinedError.includes('TokenVesting__ScheduleAlreadyRevoked')) {
		return 'This vesting schedule has already been revoked.';
	}

	if (combinedError.includes('TokenVesting__NoExcessTokensToWithdraw')) {
		return 'There are no excess tokens available to withdraw.';
	}

	if (combinedError.includes('EnforcedPause')) {
		return 'The contract is already paused.';
	}

	if (combinedError.includes('ExpectedPause')) {
		return 'The contract is not paused.';
	}

	return 'The transaction failed. Please check the form values and try again.';
}
