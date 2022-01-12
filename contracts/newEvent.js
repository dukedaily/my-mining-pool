HECO:
合约名：YouSwapInviteV1，地址：0x28700f00B343e1e257F061F3E1Ef6683de84bc30
	event InviteV1(address indexed owner, address indexed upper, uint256 indexed height);

合约名：YouSwapFactoryCreator，地址：TODO
    event YouswapFactoryCreatorEvent(address indexed owner, address indexed factory, address indexed core, bool isVisible);
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);
    event CloneEvent(address indexed clone);
    event CommissionEvent(address indexed token, uint256 poolCommAmount, uint256 inviteCommAmount, bool state);
    event PoolFactoryTemplateEvent(address indexed oldTemplate, address indexed newTemplate);
    event CoreTemplateEvent(address indexed oldTemplate, address indexed newTemplate);
    event OperateOwnerEvent(address indexed user, bool state);
    event FinanceOwnerEvent(address indexed user, bool state);
    event withdrawCommissionEvent(address indexed dst);
    event BenefitRateEvent(uint256 oldBenefitRate, uint256 newBenefitRate);
    event ReopenPeriodEvent(uint256 oldReopenPeriod, uint256 newReopenPeriod);
    event ChangeRPBRateMaxEvent(address indexed creator, address indexed factory, uint256 rateMax);
    event ChangeRPBIntervalEvent(address indexed creator, address indexed factory, uint256 interval);
    event WhiteListEvent(address indexed superAddr, bool state);

合约名：YouSwapFactoryCore
	event InviteRegister(address indexed self);
    event UpdatePool(
        bool action,
        address factory,
        uint256 poolId,
        string name,
        address indexed token,
        uint256 startBlock,
        address[] tokens,
        uint256[] _rewardTotals,
        uint256[] rewardPerBlocks,
        bool enableInvite,
        uint256[] poolBasicInfos
    );
	event EndPool(address factory, uint256 poolId);
    event Stake(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed from,
        uint256 amount
    );
	event UpdatePower(
        address factory,
        uint256 poolId,
        address token,
        uint256 totalPower,
        address indexed owner,
        uint256 ownerInvitePower,
        uint256 ownerStakePower,
        address indexed upper1,
        uint256 upper1InvitePower,
        address indexed upper2,
        uint256 upper2InvitePower
    );
    event UnStake(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event WithdrawReward(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed to,
        uint256 inviteAmount,
        uint256 stakeAmount,
        uint256 benefitAmount
    );
	event Mint(address factory, uint256 poolId, address indexed token, uint256 amount);
	event RewardPerShareEvent(address factory, uint256 poolId, address[] indexed rewardTokens, uint256[] rewardPerShares);

合约名：YouSwapFactory
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);
    event OperateOwnerEvent(address indexed user, bool state);
    event UpdateRewardPerBlockEvent(uint256 poolId, bool increaseFlag, uint256 percent);
    event AddRewardThroughAPREvent(uint256 poolId, address[] tokens, uint256[] addRewardTotals, uint256[]addRewardPerBlocks);
    event AddRewardThroughTimeEvent(uint256 poolId, address[] tokens, uint256[] addRewardTotals);
    event BenefitRateEvent(uint256 preRate, uint256 newRate);