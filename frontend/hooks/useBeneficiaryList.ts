'use client';

import { useReadContract, useReadContracts } from 'wagmi';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

export type BeneficiarySchedule = {
	beneficiary: `0x${string}`;
	totalAllocation: bigint;
	amountClaimed: bigint;
	revoked: boolean;
	unvestedTokensReclaimed: boolean;
	amountVestedAtRevocation: bigint;
};

export function useBeneficiaryList(isOwner: boolean) {
	const { data: beneficiaryCount, isLoading: isCountLoading } = useReadContract(
		{
			address: TOKEN_VESTING_ADDRESS,
			abi: tokenVestingAbi,
			functionName: 'getBeneficiariesLength',
			query: {
				enabled: isOwner,
			},
		},
	);

	const count = Number(beneficiaryCount ?? BigInt(0));

	const beneficiaryContracts = Array.from({ length: count }, (_, index) => ({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'beneficiaries' as const,
		args: [BigInt(index)] as const,
	}));

	const { data: beneficiaryResults, isLoading: isBeneficiaryLoading } =
		useReadContracts({
			contracts: beneficiaryContracts,
			query: {
				enabled: isOwner && count > 0,
			},
		});

	const addresses =
		beneficiaryResults
			?.map((result) =>
				result.status === 'success' ? result.result : undefined,
			)
			.filter(
				(beneficiary): beneficiary is `0x${string}` =>
					beneficiary !== undefined,
			) ?? [];

	const scheduleContracts = addresses.map((beneficiary) => ({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'getVestingSchedule' as const,
		args: [beneficiary] as const,
	}));

	const { data: scheduleResults, isLoading: isScheduleLoading } =
		useReadContracts({
			contracts: scheduleContracts,
			query: {
				enabled: isOwner && addresses.length > 0,
			},
		});

	const beneficiaries: BeneficiarySchedule[] =
		scheduleResults?.flatMap((result, index) => {
			if (result.status !== 'success') {
				return [];
			}

			const schedule = result.result;

			return [
				{
					beneficiary: addresses[index],
					totalAllocation: schedule.totalAllocation,
					amountClaimed: schedule.amountClaimed,
					revoked: schedule.revoked,
					unvestedTokensReclaimed: schedule.unvestedTokensReclaimed,
					amountVestedAtRevocation: schedule.amountVestedAtRevocation,
				},
			];
		}) ?? [];

	return {
		beneficiaries,
		isLoading: isCountLoading || isBeneficiaryLoading || isScheduleLoading,
	};
}
