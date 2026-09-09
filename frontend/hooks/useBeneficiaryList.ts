'use client';

import { useReadContracts } from 'wagmi';

import { TOKEN_VESTING_ADDRESS } from '@/lib/contracts/addresses';
import { tokenVestingAbi } from '@/lib/contracts/tokenVestingAbi';

export function useBeneficiaryList(isOwner: boolean) {
	const { data: beneficiaryCount } = useReadContracts({
		contracts: [
			{
				address: TOKEN_VESTING_ADDRESS,
				abi: tokenVestingAbi,
				functionName: 'getBeneficiariesLength',
			},
		],
		query: {
			enabled: isOwner,
		},
	});

	const count = Number(beneficiaryCount?.[0]?.result ?? BigInt(0));

	const contracts = Array.from({ length: count }, (_, index) => ({
		address: TOKEN_VESTING_ADDRESS,
		abi: tokenVestingAbi,
		functionName: 'beneficiaries' as const,
		args: [BigInt(index)] as const,
	}));

	const { data: beneficiaryResults, isLoading } = useReadContracts({
		contracts,
		query: {
			enabled: isOwner && count > 0,
		},
	});

	return {
		beneficiaries:
			beneficiaryResults
				?.map((result) =>
					result.status === 'success' ? result.result : undefined,
				)
				.filter(
					(beneficiary): beneficiary is `0x${string}` =>
						beneficiary !== undefined,
				) ?? [],
		isLoading,
	};
}
