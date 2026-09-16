import { formatUnits } from 'viem';

export function formatTokenAmount(amount: bigint): string {
	const formattedAmount = formatUnits(amount, 18);
	const numericAmount = Number(formattedAmount);

	return new Intl.NumberFormat('en-GB', {
		maximumFractionDigits: 2,
	}).format(numericAmount);
}
