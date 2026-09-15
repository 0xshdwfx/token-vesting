import type { Abi } from 'viem';

export const erc20Abi = [
	{
		type: 'function',
		name: 'balanceOf',
		inputs: [
			{
				name: 'account',
				type: 'address',
				internalType: 'address',
			},
		],
		outputs: [
			{
				name: '',
				type: 'uint256',
				internalType: 'uint256',
			},
		],
		stateMutability: 'view',
	},
] as const satisfies Abi;
