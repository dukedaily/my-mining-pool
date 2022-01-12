// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/IYouSwapFactory.sol";
import "./../utils/constant.sol";
// import "hardhat/console.sol";

contract YouSwapFactory is IYouSwapFactory {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool initialized;
    address private constant ZERO = address(0);

    address public owner; //所有权限
    address internal platform; //平台

    IYouSwapFactoryCore public core; //core合约
    mapping(address => bool) public operateOwner; //运营权限
    mapping(uint256 => uint256) public lastSetRewardPerBlockTime; //最后一次设置区块奖励数时间，poolid->timestamp

    uint256 public changeRewardPerBlockRateMax; //调整区块最大比例，default: 30%
    uint256 public changeRewardPerBlockIntervalMin; //调整区块最小时间间隔，default: 7 days
    uint256 public benefitRate; //平台抽成比例
    mapping(address => bool) public whiteList; //创建人白名单，可免费增加APR，延时矿池

    //校验owner权限
    modifier onlyOwner() {
        require(owner == msg.sender, "YouSwap:FORBIDDEN_NOT_OWNER");
        _;
    }

    //校验platform权限
    modifier onlyPlatform() {
        require(platform == msg.sender, "YouSwap:FORBIDFORBIDDEN_NOT_PLATFORM");
        _;
    }

    //校验运营权限
    modifier onlyOperater() {
        require(operateOwner[msg.sender], "YouSwap:FORBIDDEN_NOT_OPERATER");
        _;
    }

    /**
    @notice clone YouSwapFactory初始化
    @param _owner 项目方
    @param _platform FactoryCreator平台
    @param _benefitRate 抽成比例
    @param _invite 邀请合约，直接透传
    @param _core clone核心合约
    */
    function initialize(address _owner, address _platform, uint256 _benefitRate, address _invite, address _core) external {
        require(!initialized,  "YouSwap:ALREADY_INITIALIZED!");
        initialized = true;
        core = IYouSwapFactoryCore(_core);
        core.initialize(address(this), _platform, _invite);

        owner = _owner; //owner权限
        platform = _platform; //平台权限
        benefitRate = _benefitRate;

        changeRewardPerBlockRateMax = DefaultSettings.CHANGE_RATE_MAX; //默认值设置
        changeRewardPerBlockIntervalMin = DefaultSettings.DAY_INTERVAL_MIN;
        _setOperateOwner(_owner, true); 
    }

    /**
     @notice 转移owner权限
     @param oldOwner：旧Owner
     @param newOwner：新Owner
     */
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /**
     @notice 设置运营权限
     @param user：营运地址
     @param state：权限状态
     */
    event OperateOwnerEvent(address indexed user, bool state);

    /**
    @notice 调整单块奖励调整比例
    @param poolId 矿池id
    @param increaseFlag 是否增加
    @param percent 调整比例
     */
    event UpdateRewardPerBlockEvent(uint256 poolId, bool increaseFlag, uint256 percent);

    /**
    @notice 加奖励APR
    @param poolId 矿池id
    @param tokens 调整奖励币种
    @param addRewardTotals 增加奖励币种总量
    @param addRewardPerBlocks 增加单块奖励数量
     */
    event AddRewardThroughAPREvent(uint256 poolId, address[] tokens, uint256[] addRewardTotals, uint256[]addRewardPerBlocks);

    /**
    @notice 加奖励APR
    @param poolId 矿池id
    @param tokens 调整奖励币种
    @param addRewardTotals 增加奖励币种总量
     */
    event AddRewardThroughTimeEvent(uint256 poolId, address[] tokens, uint256[] addRewardTotals);

    /**
    @notice 更新平台币抽成比例
    @param preRate 旧抽成比例
    @param newRate 新抽成比例
     */
    event BenefitRateEvent(uint256 preRate, uint256 newRate);

    /**
     @notice 修改OWNER
     @param _owner：新Owner
     */
    function transferOwnership(address _owner) external override onlyOwner {
        require(ZERO != _owner, "YouSwap:INVALID_ADDRESSES");
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }

    /**
    设置运营权限
     */
    function setOperateOwner(address user, bool state) external override onlyOwner {
        _setOperateOwner(user, state);
    }

    /**
     @notice 设置运营权限
     @param user 运营地址
     @param state 权限状态
     */
    function _setOperateOwner(address user, bool state) internal {
        operateOwner[user] = state; //设置运营权限
        emit OperateOwnerEvent(user, state);
    }

    ////////////////////////////////////////////////////////////////////////////////////
    /**
    @notice 质押
    @param poolId 质押矿池
    @param amount 质押数量
    */
    function stake(uint256 poolId, uint256 amount) external override {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require((ZERO != poolStakeInfo.token) && (poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_EXIST_OR_MINT_NOT_START"); //是否开启挖矿
        require((poolStakeInfo.powerRatio <= amount) && (poolStakeInfo.amount.add(amount) <= poolStakeInfo.maxStakeAmount), "YouSwap:STAKE_AMOUNT_TOO_SMALL_OR_TOO_LARGE");

        uint256 balance = IERC20(poolStakeInfo.token).balanceOf(address(core));
        IERC20(poolStakeInfo.token).safeTransferFrom(msg.sender, address(core), amount); //转移sender的质押资产到this
        //实际转入core金额，兼容燃烧币种
        amount = IERC20(poolStakeInfo.token).balanceOf(address(core)).sub(balance);
        core.stake(poolId, amount, msg.sender);
    }

    /**
    @notice 解质押
    @param poolId 解质押矿池
    @param amount 解质押数量
     */
    function unStake(uint256 poolId, uint256 amount) external override {
        checkOperationValidation(poolId);
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId, msg.sender);
        require((amount > 0) && (userStakeInfo.amount >= amount), "YouSwap:BALANCE_INSUFFICIENT");
        core._unStake(poolId, amount, msg.sender);
    }

    /**
    @notice 批量解质押并提取奖励
    @param _poolIds 解质押矿池
     */
    function unStakes(uint256[] memory _poolIds) external override {
        require((0 < _poolIds.length) && (50 >= _poolIds.length), "YouSwap:PARAMETER_ERROR_TOO_SHORT_OR_LONG");
        uint256 amount;
        uint256 poolId;
        BaseStruct.UserStakeInfo memory userStakeInfo;

        for (uint256 i = 0; i < _poolIds.length; i++) {
            poolId = _poolIds[i];
            checkOperationValidation(poolId);
            userStakeInfo = core.getUserStakeInfo(poolId, msg.sender);
            amount = userStakeInfo.amount; //sender的质押数量

            if (0 < amount) {
                core._unStake(poolId, amount, msg.sender);
            }
        }
    }

    /**
    @notice 提取奖励
    @param poolId 矿池id
     */
    function withdrawReward(uint256 poolId) public override {
        checkOperationValidation(poolId);
        core._withdrawReward(poolId, msg.sender);
    }

    /**
    批量提取奖励，供平台使用
     */
    function withdrawRewards2(uint256[] memory _poolIds, address user) external onlyPlatform override {
        for (uint256 i = 0; i < _poolIds.length; i++) {
            BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(_poolIds[i]);
            if (poolStakeInfo.startTime > block.timestamp && !poolStakeInfo.isReopen) {
                continue;
            }
            core._withdrawReward(_poolIds[i], user);
        }
    }

    /**
    校验重&&开锁仓有效性
     */
     function checkOperationValidation(uint256 poolId) internal view {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require((ZERO != poolStakeInfo.token), "YouSwap:POOL_NOT_EXIST"); //是否开启挖矿
        if (!poolStakeInfo.isReopen) {
            require((poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_START"); //是否开启挖矿
        } 
     }

    struct PendingLocalVars {
        uint256 poolId;
        address user;
        uint256 inviteReward;
        uint256 stakeReward;
        uint256 rewardPre;
    }

    /**
    待领取的奖励: tokens，invite待领取，质押待领取，invite已领取，质押已领取
     */
    function pendingRewardV3(uint256 poolId, address user) external view override returns (
                            address[] memory tokens, 
                            uint256[] memory invitePendingRewardsRet, 
                            uint256[] memory stakePendingRewardsRet, 
                            uint256[] memory inviteClaimedRewardsRet, 
                            uint256[] memory stakeClaimedRewardsRet) {
        PendingLocalVars memory vars;
        vars.poolId = poolId;
        vars.user = user;
        BaseStruct.PoolRewardInfo[] memory _poolRewardInfos = core.getPoolRewardInfo(vars.poolId);
        tokens = new address[](_poolRewardInfos.length);
        invitePendingRewardsRet = new uint256[](_poolRewardInfos.length);
        stakePendingRewardsRet = new uint256[](_poolRewardInfos.length);
        inviteClaimedRewardsRet = new uint256[](_poolRewardInfos.length);
        stakeClaimedRewardsRet = new uint256[](_poolRewardInfos.length);

        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(vars.poolId);
        if (ZERO != poolStakeInfo.token) {
            BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(vars.poolId,vars.user);

            uint256 i = userStakeInfo.invitePendingRewards.length;
            for (uint256 j = 0; j < _poolRewardInfos.length; j++) {
                BaseStruct.PoolRewardInfo memory poolRewardInfo = _poolRewardInfos[j];
                vars.inviteReward = 0;
                vars.stakeReward = 0;

                if (0 < poolStakeInfo.totalPower) {
                    //矿池未结束或重启后开始挖矿，rewardPerShare有可能增加
                    if (block.number > poolStakeInfo.lastRewardBlock) {
                        vars.rewardPre = block.number.sub(poolStakeInfo.lastRewardBlock).mul(poolRewardInfo.rewardPerBlock); //待快照奖励
                        if (poolRewardInfo.rewardProvide.add(vars.rewardPre) >= poolRewardInfo.rewardTotal) {
                            vars.rewardPre = poolRewardInfo.rewardTotal.sub(poolRewardInfo.rewardProvide); //核减超出奖励
                        }
                        poolRewardInfo.rewardPerShare = poolRewardInfo.rewardPerShare.add(vars.rewardPre.mul(1e41).div(poolStakeInfo.totalPower)); //累加待快照的单位算力奖励
                    }
                }

                if (i > j) {
                    //统计旧奖励币种
                    vars.inviteReward = userStakeInfo.invitePendingRewards[j]; //待领取奖励
                    vars.stakeReward = userStakeInfo.stakePendingRewards[j]; //待领取奖励
                    vars.inviteReward = vars.inviteReward.add(userStakeInfo.invitePower.mul(poolRewardInfo.rewardPerShare).sub(userStakeInfo.inviteRewardDebts[j]).div(1e41)); //待快照的邀请奖励
                    vars.stakeReward = vars.stakeReward.add(userStakeInfo.stakePower.mul(poolRewardInfo.rewardPerShare).sub(userStakeInfo.stakeRewardDebts[j]).div(1e41)); //待快照的质押奖励
                    inviteClaimedRewardsRet[j] = userStakeInfo.inviteClaimedRewards[j]; //已领取邀请奖励(累计)
                    stakeClaimedRewardsRet[j] = userStakeInfo.stakeClaimedRewards[j]; //已领取质押奖励(累计)
                } else {
                    //统计新奖励币种
                    vars.inviteReward = userStakeInfo.invitePower.mul(poolRewardInfo.rewardPerShare).div(1e41); //待快照的邀请奖励
                    vars.stakeReward = userStakeInfo.stakePower.mul(poolRewardInfo.rewardPerShare).div(1e41); //待快照的质押奖励
                }

                invitePendingRewardsRet[j] = vars.inviteReward;
                stakePendingRewardsRet[j] = vars.stakeReward;
                tokens[j] = poolRewardInfo.token;
            }
        }
    }

    /**
    矿池ID
     */
    function poolIds() external view override returns (uint256[] memory poolIDs) {
        poolIDs = core.getPoolIds();
    }

    /**
    质押数量范围
     */
    function stakeRange(uint256 poolId) external view override returns (uint256 powerRatio, uint256 maxStakeAmount) {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        if (ZERO == poolStakeInfo.token) {
            return (0, 0);
        }
        powerRatio = poolStakeInfo.powerRatio;
        maxStakeAmount = poolStakeInfo.maxStakeAmount.sub(poolStakeInfo.amount);
    }

    /*
    质押币种，是否启用邀请，总锁仓，地址数，矿池类型，锁仓时间，最大质押数量，开始时间，结束时间
    */
    function getPoolStakeDetail(uint256 poolId) external view override returns (
                        // string memory name, 
                        address token, 
                        bool enableInvite, 
                        uint256 stakeAmount, 
                        uint256 participantCounts, 
                        uint256 poolType, 
                        uint256 lockSeconds, 
                        uint256 maxStakeAmount, 
                        uint256 startTime, 
                        uint256 endTime, 
                        uint256 withdrawRewardAllow) {
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        // PoolViewInfo memory poolViewInfo = core.getPoolViewInfo(poolId);

        // name = poolViewInfo.name;
        token = poolStakeInfo.token;
        enableInvite = poolStakeInfo.enableInvite;
        stakeAmount = poolStakeInfo.amount;
        participantCounts = poolStakeInfo.participantCounts;
        poolType = uint256(poolStakeInfo.poolType); 
        lockSeconds = poolStakeInfo.lockSeconds;
        maxStakeAmount = poolStakeInfo.maxStakeAmount;
        startTime = poolStakeInfo.startTime;
        endTime = poolStakeInfo.endTime;
        withdrawRewardAllow = poolStakeInfo.withdrawRewardAllow;
    }

    /**用户质押详情 */
    function getUserStakeInfo(uint256 poolId, address user) external view override returns (
                        uint256 startBlock, 
                        uint256 stakeAmount, 
                        uint256 invitePower,
                        uint256 stakePower) {
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId,user);
        startBlock = userStakeInfo.startBlock;
        stakeAmount = userStakeInfo.amount;
        invitePower = userStakeInfo.invitePower;
        stakePower = userStakeInfo.stakePower;
    }

    /*
    获取奖励详情
    */
    function getUserRewardInfo(uint256 poolId, address user, uint256 index) external view override returns (
                        uint256 invitePendingReward,
                        uint256 stakePendingReward, 
                        uint256 inviteRewardDebt, 
                        uint256 stakeRewardDebt) {
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId,user);
        invitePendingReward = userStakeInfo.invitePendingRewards[index];
        stakePendingReward = userStakeInfo.stakePendingRewards[index];
        inviteRewardDebt = userStakeInfo.inviteRewardDebts[index];
        stakeRewardDebt = userStakeInfo.stakeRewardDebts[index];
    }

    /**
    获取挖矿奖励详情 
    */
    function getPoolRewardInfo(uint poolId) external view override returns (PoolRewardInfo[] memory) {
        return core.getPoolRewardInfo(poolId);
    }

    /* 
    获取多挖币种奖励详情 
    */
    function getPoolRewardInfoDetail(uint256 poolId) external view override returns (
                        address[] memory tokens, 
                        uint256[] memory rewardTotals, 
                        uint256[] memory rewardProvides, 
                        uint256[] memory rewardPerBlocks,
                        uint256[] memory rewardPerShares) {
        BaseStruct.PoolRewardInfo[] memory _poolRewardInfos = core.getPoolRewardInfo(poolId);
        tokens = new address[](_poolRewardInfos.length);
        rewardTotals = new uint256[](_poolRewardInfos.length);
        rewardProvides = new uint256[](_poolRewardInfos.length);
        rewardPerBlocks = new uint256[](_poolRewardInfos.length);
        rewardPerShares = new uint256[](_poolRewardInfos.length);

        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        uint256 newRewards;
        uint256 blockCount;
        if(block.number > poolStakeInfo.lastRewardBlock) { //尚未重开
            blockCount = block.number.sub(poolStakeInfo.lastRewardBlock); //待发放的区块数量
        }

        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            newRewards = blockCount.mul(_poolRewardInfos[i].rewardPerBlock); //两次快照之间总奖励
            tokens[i] = _poolRewardInfos[i].token;
            rewardTotals[i] = _poolRewardInfos[i].rewardTotal;

            if (_poolRewardInfos[i].rewardProvide.add(newRewards) > rewardTotals[i]) {
                rewardProvides[i] = rewardTotals[i];
            } else {
                rewardProvides[i] = _poolRewardInfos[i].rewardProvide.add(newRewards);
            }

            rewardPerBlocks[i] = _poolRewardInfos[i].rewardPerBlock;
            rewardPerShares[i] = _poolRewardInfos[i].rewardPerShare;
        }
    }

    /** 
    新建矿池 
    */
    function addPool(
        uint256 prePoolId,
        uint256 range,
        address token,
        bool enableInvite,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) external override onlyPlatform {
        require((0 < tokens.length) && (DefaultSettings.REWARD_TOKENTYPE_MAX >= tokens.length) && (tokens.length == rewardTotals.length) && (tokens.length == rewardPerBlocks.length), "YouSwap:PARAMETER_ERROR_REWARD");
        require(core.getPoolIds().length < DefaultSettings.EACH_FACTORY_POOL_MAX, "YouSwap:FACTORY_CREATE_MINING_POOL_MAX_REACHED");
        core.addPool(prePoolId, range, token, enableInvite, poolParams, tokens, rewardTotals, rewardPerBlocks); 
    }

    /**
    @notice 修改矿池区块奖励，限7天设置一次，不转入资金
    @param poolId 矿池ID
    @param increaseFlag 是否增加
    @param percent 调整比例
     */
    function updateRewardPerBlock(uint256 poolId, bool increaseFlag, uint256 percent) external override onlyOperater {
        require(percent <= changeRewardPerBlockRateMax, "YouSwap:CHANGE_RATE_INPUT_TOO_BIG");
        core.checkPIDValidation(poolId);
        core.refresh(poolId);
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require(0 == poolStakeInfo.endBlock, "YouSwapCore:POOL_END_OF_MINING");

        uint256 lastTime = lastSetRewardPerBlockTime[poolId];
        require(block.timestamp >= lastTime.add(DefaultSettings.SECONDS_PER_DAY.mul(changeRewardPerBlockIntervalMin)), "YouSwap:SET_REWARD_PER_BLOCK_NOT_READY!");
        lastSetRewardPerBlockTime[poolId] = block.timestamp;

        BaseStruct.PoolRewardInfo[] memory _poolRewardInfos = core.getPoolRewardInfo(poolId);
        for (uint i = 0; i < _poolRewardInfos.length; i++) {
            uint256 preRewardPerBlock = _poolRewardInfos[i].rewardPerBlock;
            uint256 newRewardPerBlock;

            if (increaseFlag) {
                newRewardPerBlock = preRewardPerBlock.add(preRewardPerBlock.mul(percent).div(100));
            } else {
                newRewardPerBlock = preRewardPerBlock.sub(preRewardPerBlock.mul(percent).div(100));
            }

            core.setRewardPerBlock(poolId, _poolRewardInfos[i].token, newRewardPerBlock);
        }
        emit UpdateRewardPerBlockEvent(poolId, increaseFlag, percent);
    }

    /** 
    调整区块奖励最大调整幅度 
    */
    function setChangeRPBRateMax(uint256 _rateMax) external override onlyPlatform {
        require(_rateMax <= 100, "YouSwap:SET_CHANGE_REWARD_PER_BLOCK_RATE_MAX_TOO_BIG");
        changeRewardPerBlockRateMax = _rateMax;
    }

    /** 
    调整区块奖励修改周期 
    */
    function setChangeRPBIntervalMin(uint256 _interval) external override onlyPlatform {
        changeRewardPerBlockIntervalMin = _interval;
    }

    /** 
    调整平台抽成比例
    */
    function setBenefitRate(uint256 _newRate) external override onlyPlatform {
        uint256 preRate = benefitRate;
        if (preRate == _newRate) return;
        benefitRate = _newRate;
        emit BenefitRateEvent(preRate, benefitRate);
    }

    /**
        @notice 设置白名单
        @param _super 白名单
        @param _state 白名单支持状态
     */
    function setWhiteList(address _super, bool _state) external onlyPlatform {
        whiteList[_super] = _state;
    }

    /**
    修改矿池最大可质押数量
     */
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external override onlyOperater {
        core.checkPIDValidation(poolId);
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require(poolStakeInfo.powerRatio <= maxStakeAmount && poolStakeInfo.amount <= maxStakeAmount, "YouSwapCore:MAX_STAKE_AMOUNT_INVALID");
        core.setMaxStakeAmount(poolId, maxStakeAmount);
    }

    struct APRLocalVars {
        uint256 balance;
        bool existFlag;
        bool existEmptyFlag;
    }

    /** 
    @notice 增加奖励APR 两种模式：1. 已有资产 2. 新增币种
    @param poolId uint256, 矿池ID
    @param tokens address[] 奖励币种
    @param addRewardTotals uint256[] 挖矿总奖励，total是新增加数量
    @param addRewardPerBlocks uint256[] 单个区块奖励，rewardPerBlock是增加数量
    */
    function addRewardThroughAPR(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals, uint256[] memory addRewardPerBlocks) external override onlyOperater {
        require((0 < tokens.length) && (DefaultSettings.REWARD_TOKENTYPE_MAX >= tokens.length) && (tokens.length == addRewardTotals.length) && (tokens.length == addRewardPerBlocks.length), "YouSwap:PARAMETER_ERROR_REWARD");
        core.checkPIDValidation(poolId);
        core.refresh(poolId);
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require(0 == poolStakeInfo.endBlock, "YouSwapCore:POOL_END_OF_MINING");

        BaseStruct.PoolRewardInfo[] memory poolRewardInfos = core.getPoolRewardInfo(poolId);
        APRLocalVars memory vars;
        uint256 _newRewardTotal;
        uint256 _newRewardPerBlock;

        uint256[] memory newTotals = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(ZERO != tokens[i], "YouSwap:INVALID_TOKEN_ADDRESS");
            _newRewardTotal = 0;
            _newRewardPerBlock = 0;
            vars.existFlag = false; //已存在，未发完
            vars.existEmptyFlag = false; //已存在，已发完
            vars.balance = IERC20(tokens[i]).balanceOf(address(core));
            newTotals[i] = addRewardTotals[i];

            uint256 benefitAmount = addRewardTotals[i].mul(benefitRate).div(DefaultSettings.TEN_THOUSAND);
            if (!whiteList[msg.sender]) {
                if (benefitAmount > 0) {
                    IERC20(tokens[i]).safeTransferFrom(msg.sender, address(platform), benefitAmount);
                    newTotals[i] = addRewardTotals[i].sub(benefitAmount);
                }
            }
            if (newTotals[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(core), newTotals[i]);
            }

            //实际转入core金额，兼容燃烧币种
            newTotals[i] = IERC20(tokens[i]).balanceOf(address(core)).sub(vars.balance);

            uint256 rewardLeft;
            for (uint256 j = 0; j < poolRewardInfos.length; j++) {
                if (tokens[i] == poolRewardInfos[j].token) {
                    vars.existFlag = true;

                    _newRewardTotal = poolRewardInfos[j].rewardTotal.add(newTotals[i]);
                    rewardLeft = poolRewardInfos[j].rewardTotal.sub(poolRewardInfos[j].rewardProvide);
                    if (rewardLeft == 0) {
                        vars.existEmptyFlag = true;
                        break;
                    }

                    // 区块发放数量 = 当前区块发放数量 *（增加挖矿奖励/剩余挖矿奖励+1）
                    uint256 scale = (newTotals[i].add(rewardLeft)).mul(1e18).div(rewardLeft);
                    _newRewardPerBlock = poolRewardInfos[j].rewardPerBlock.mul(scale).div(1e18);
                    //break; 不提前break
                }
            }

            if (!vars.existFlag) {
               _newRewardTotal = newTotals[i];
               _newRewardPerBlock = addRewardPerBlocks[i];
            } else if (vars.existEmptyFlag) {
               _newRewardPerBlock = addRewardPerBlocks[i];
            }

            core.setRewardTotal(poolId, tokens[i], _newRewardTotal);
            core.setRewardPerBlock(poolId, tokens[i], _newRewardPerBlock);
        }
        emit AddRewardThroughAPREvent(poolId, tokens, addRewardTotals, addRewardPerBlocks);
    }

    /** 
    @notice 通过延长时间，设置矿池总奖励，同时转入代币，需要获取之前币种的数量，加上增加数量，然后设置新的Totals
    @param poolId uint256, 矿池ID
    @param tokens address[] 奖励币种
    @param addRewardTotals uint256[] 挖矿总奖励
    */
    function addRewardThroughTime(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals) external override onlyOperater {
        require((0 < tokens.length) && (10 >= tokens.length) && (tokens.length == addRewardTotals.length), "YouSwap:PARAMETER_ERROR_REWARD");
        core.checkPIDValidation(poolId);
        core.refresh(poolId);
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require(0 == poolStakeInfo.endBlock, "YouSwapCore:POOL_END_OF_MINING");

        BaseStruct.PoolRewardInfo[] memory poolRewardInfos = core.getPoolRewardInfo(poolId);
        uint256 _newRewardTotal;
        uint256 _balance;
        bool _existFlag;

        uint256[] memory newTotals = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(ZERO != tokens[i], "YouSwap:INVALID_TOKEN_ADDRESS");
            require(addRewardTotals[i] > 0, "YouSwap:ADD_REWARD_AMOUNT_SHOULD_GT_ZERO");
            _newRewardTotal = 0;
            _existFlag = false;
            _balance = IERC20(tokens[i]).balanceOf(address(core));
            newTotals[i] = addRewardTotals[i];

            uint256 benefitAmount = addRewardTotals[i].mul(benefitRate).div(DefaultSettings.TEN_THOUSAND);
            if (!whiteList[msg.sender]) {
                if (benefitAmount > 0) {
                    IERC20(tokens[i]).safeTransferFrom(msg.sender, address(platform), benefitAmount);
                    newTotals[i] = addRewardTotals[i].sub(benefitAmount);
                }
            }
            if (newTotals[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(core), newTotals[i]);
            }

            newTotals[i] = IERC20(tokens[i]).balanceOf(address(core)).sub(_balance);
            for (uint256 j = 0; j < poolRewardInfos.length; j++) {
                if (tokens[i] == poolRewardInfos[j].token) {
                    _newRewardTotal = poolRewardInfos[j].rewardTotal.add(newTotals[i]);
                    _existFlag = true;
                    //break; 不提前break
                }
            }

            require(_existFlag, "YouSwap:REWARD_TOKEN_NOT_EXIST");
            core.setRewardTotal(poolId, tokens[i], _newRewardTotal);
        }
        emit AddRewardThroughTimeEvent(poolId, tokens, addRewardTotals);
    }
}
