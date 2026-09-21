export const demoTokenVestingAbi = [
	{
		type: 'function',
		name: 'createDemoSchedule',
		stateMutability: 'nonpayable',
		inputs: [],
		outputs: [],
	},
	{
		type: 'function',
		name: 'claimDemoTokens',
		stateMutability: 'nonpayable',
		inputs: [],
		outputs: [
			{
				name: 'amountClaimed',
				type: 'uint256',
			},
		],
	},
	{
		type: 'function',
		name: 'hasDemoSchedule',
		stateMutability: 'view',
		inputs: [
			{
				name: 'beneficiary',
				type: 'address',
			},
		],
		outputs: [
			{
				name: '',
				type: 'bool',
			},
		],
	},
	{
		type: 'function',
		name: 'getClaimableAmount',
		stateMutability: 'view',
		inputs: [
			{
				name: 'beneficiary',
				type: 'address',
			},
		],
		outputs: [
			{
				name: '',
				type: 'uint256',
			},
		],
	},
	{
		type: 'function',
		name: 'getVestingSchedule',
		stateMutability: 'view',
		inputs: [
			{
				name: 'beneficiary',
				type: 'address',
			},
		],
		outputs: [
			{
				name: '',
				type: 'tuple',
				components: [
					{
						name: 'totalAllocation',
						type: 'uint256',
					},
					{
						name: 'startTime',
						type: 'uint256',
					},
					{
						name: 'cliffDuration',
						type: 'uint256',
					},
					{
						name: 'vestingDuration',
						type: 'uint256',
					},
					{
						name: 'amountClaimed',
						type: 'uint256',
					},
				],
			},
		],
	},
] as const;
