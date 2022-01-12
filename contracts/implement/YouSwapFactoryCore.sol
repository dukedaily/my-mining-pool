// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./../implement/YouSwapInviteV1.sol";
import "./../interface/IYouSwapFactory.sol";
// import "hardhat/console.sol";

contract YouSwapFactoryCore is IYouSwapFactoryCore {
    /**
    自邀请
    self：Sender地址
     */
    event InviteRegister(address indexed self);

    /**
    更新矿池信息

    action：true(新建矿池)，false(更新矿池)
    factory：factory合约
    poolId：矿池ID
    name：矿池名称
    token：质押token合约地址
    startBlock：矿池开始挖矿块高
    tokens：挖矿奖励token合约地址
    rewardTotal：挖矿总奖励数量
    rewardPerBlock：区块奖励数量
    enableInvite：是否启用邀请关系
    poolBasicInfos: uint256[] 包含如下：
        multiple：矿池奖励倍数
        priority：矿池排序
        powerRatio：质押数量到算力系数=最小质押数量
        maxStakeAmount：最大质押数量
        poolType：矿池类型(定期，活期): 0,1,2,3
        lockSeconds：定期锁仓时间: 60s
        selfReward：邀请自奖励比例: 5
        invite1Reward：邀请1级奖励比例: 15
        invite2Reward：邀请2级奖励比例: 10
     */
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

    /**
    矿池挖矿结束
    
    factory：factory合约
    poolId：矿池ID
     */
    event EndPool(address factory, uint256 poolId);

    /**
    质押

    factory：factory合约
    poolId：矿池ID
    token：token合约地址
    from：质押转出地址
    amount：质押数量
     */
    event Stake(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed from,
        uint256 amount
    );

    /**
    算力

    factory：factory合约
    poolId：矿池ID
    token：token合约地址
    totalPower：矿池总算力
    owner：用户地址
    ownerInvitePower：用户邀请算力
    ownerStakePower：用户质押算力
    upper1：上1级地址
    upper1InvitePower：上1级邀请算力
    upper2：上2级地址
    upper2InvitePower：上2级邀请算力
     */
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

    /**
    解质押
    
    factory：factory合约
    poolId：矿池ID
    token：token合约地址
    to：解质押转入地址
    amount：解质押数量
     */
    event UnStake(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
    提取奖励

    factory：factory合约
    poolId：矿池ID
    token：token合约地址
    to：奖励转入地址
    inviteAmount：奖励数量
    stakeAmount：奖励数量
    benefitAmount: 平台抽成
     */
    event WithdrawReward(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed to,
        uint256 inviteAmount,
        uint256 stakeAmount,
        uint256 benefitAmount
    );

    /**
    挖矿

    factory：factory合约
    poolId：矿池ID
    token：token合约地址
    amount：奖励数量
     */
    event Mint(address factory, uint256 poolId, address indexed token, uint256 amount);

    /**
    当单位算力发放奖励为0时触发
    factory：factory合约
    poolId：矿池ID
    rewardTokens：挖矿奖励币种
    rewardPerShares：单位算力发放奖励数量
     */
    event RewardPerShareEvent(address factory, uint256 poolId, address[] indexed rewardTokens, uint256[] rewardPerShares);

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool initialized;
    address internal constant ZERO = address(0);
    address public factory; //core合约管理员
    YouSwapInviteV1 internal invite; // contract

    uint256 poolCount; //矿池数量
    uint256[] poolIds; //矿池ID
    address internal platform; //平台，addPool权限
    mapping(uint256 => PoolViewInfo) internal poolViewInfos; //矿池可视化信息，poolID->PoolViewInfo
    mapping(uint256 => PoolStakeInfo) internal poolStakeInfos; //矿池质押信息，poolID->PoolStakeInfo
    mapping(uint256 => PoolRewardInfo[]) internal poolRewardInfos; //矿池奖励信息，poolID->PoolRewardInfo[]
    mapping(uint256 => mapping(address => UserStakeInfo)) internal userStakeInfos; //用户质押信息，poolID->user-UserStakeInfo

    mapping(address => uint256) public tokenPendingRewards; //现存token奖励数量，token-amount
    mapping(address => mapping(address => uint256)) internal userReceiveRewards; //用户已领取数量，token->user->amount
    // mapping(uint256 => mapping(address => uint256)) public platformBenefits; //平台抽成数量

    //校验owner权限
    modifier onlyFactory() {
        require(factory == msg.sender, "YouSwapCore:FORBIDDEN_CALLER_NOT_FACTORY");
        _;
    }

    //校验platform权限
    modifier onlyPlatform() {
        require(platform == msg.sender, "YouSwap:FORBIDFORBIDDEN_CALLER_NOT_PLATFORM");
        _;
    }

    /**
    @notice clone YouSwapFactoryCore初始化
    @param _owner YouSwapFactory合约
    @param _platform FactoryCreator平台
    @param _invite clone邀请合约
    */
    function initialize(address _owner, address _platform, address _invite) external override {
        require(!initialized,  "YouSwapCore:ALREADY_INITIALIZED!");
        initialized = true;
        factory = _owner;
        platform = _platform;
        invite = YouSwapInviteV1(_invite);
    }

    /** 获取挖矿奖励结构 */
    function getPoolRewardInfo(uint256 poolId) external view override returns (PoolRewardInfo[] memory) {
        return poolRewardInfos[poolId];
    }

    /** 获取用户质押信息 */
    function getUserStakeInfo(uint256 poolId, address user) external view override returns (UserStakeInfo memory) {
        return userStakeInfos[poolId][user];
    }

    /** 获取矿池信息 */
    function getPoolStakeInfo(uint256 poolId) external view override returns (PoolStakeInfo memory) {
        return poolStakeInfos[poolId];
    }

    /** 获取矿池展示信息 */
    function getPoolViewInfo(uint256 poolId) external view override returns (PoolViewInfo memory) {
        return poolViewInfos[poolId];
    }

    /** 质押 */
    function stake(uint256 poolId, uint256 amount, address user) external onlyFactory override {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        if (0 == userStakeInfo.stakePower) {
            poolStakeInfo.participantCounts = poolStakeInfo.participantCounts.add(1);
        }

        address upper1;
        address upper2;
        if (poolStakeInfo.enableInvite) {
            (, uint256 startBlock) = invite.inviteUserInfoV2(user); //sender是否注册邀请关系
            if (0 == startBlock) {
                invite.register(); //sender注册邀请关系
                emit InviteRegister(user);
            }
            (upper1, upper2) = invite.inviteUpper2(user); //获取上2级邀请关系
        }

        initRewardInfo(poolId, user, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId); //计算单位算力奖励
        provideReward(poolId, rewardPerShares, user, upper1, upper2); //给sender发放收益，给upper1，upper2增加待领取收益

        addPower(poolId, user, amount, poolStakeInfo.powerRatio, upper1, upper2); //增加sender，upper1，upper2算力
        setRewardDebt(poolId, rewardPerShares, user, upper1, upper2); //重置sender，upper1，upper2负债
        emit Stake(factory, poolId, poolStakeInfo.token, user, amount);
    }

    /** 矿池ID */
    function getPoolIds() external view override returns (uint256[] memory) {
        return poolIds;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    struct addPoolLocalVars {
        uint256 prePoolId;
        uint256 range;
        uint256 poolId;
        uint256 startBlock;
        bool enableInvite;
        address token;
        uint256 poolType;
        uint256 powerRatio;
        uint256 startTimeDelay;
        uint256 startTime;
        uint256 currentTime;
        uint256 priority;
        uint256 maxStakeAmount;
        uint256 lockSeconds;
        uint256 multiple;
        uint256 selfReward;
        uint256 invite1Reward;
        uint256 invite2Reward;
        bool isReopen;
        uint256 withdrawRewardAllow;
    }

    /**
    新建矿池(prePoolId 为0) 
    重启矿池(prePoolId 非0)
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
    ) external override onlyFactory {
        addPoolLocalVars memory vars;
        vars.currentTime = block.timestamp;
        vars.prePoolId = prePoolId;
        vars.range = range;
        vars.token = token;
        vars.enableInvite = enableInvite;
        vars.poolType = poolParams[0];
        vars.powerRatio = poolParams[1];
        vars.startTimeDelay = poolParams[2];
        vars.startTime = vars.startTimeDelay.add(vars.currentTime);
        vars.priority = poolParams[3];
        vars.maxStakeAmount = poolParams[4];
        vars.lockSeconds = poolParams[5];
        vars.multiple = poolParams[6];
        vars.selfReward = poolParams[7];
        vars.invite1Reward = poolParams[8];
        vars.invite2Reward = poolParams[9];
        vars.withdrawRewardAllow = poolParams[10];

        if (vars.startTime <= vars.currentTime) { //开始时间是当前
            vars.startTime  = vars.currentTime;
            vars.startBlock = block.number;
        } else { //开始时间在未来
            vars.startBlock =  block.number.add(vars.startTimeDelay.div(3)); //预估的合法开始块高: heco: 3s，eth：13s
        }

        if (vars.prePoolId != 0) { //矿池重启
            vars.poolId = vars.prePoolId;
            vars.isReopen = true;
        } else { //新建矿池
            vars.poolId = poolCount.add(vars.range); //从1w开始
            poolIds.push(vars.poolId); //全部矿池ID
            poolCount = poolCount.add(1); //矿池总数量
            vars.isReopen = false;
        }

        PoolViewInfo storage poolViewInfo = poolViewInfos[vars.poolId]; //矿池可视化信息
        poolViewInfo.token = vars.token; //矿池质押token
        // poolViewInfo.name = vars.name; //矿池名称，默认是空
        poolViewInfo.multiple = vars.multiple; //矿池倍数
        if (0 < vars.priority) {
            poolViewInfo.priority = vars.priority; //矿池优先级
        } else {
            poolViewInfo.priority = poolIds.length.mul(100).add(75); //矿池优先级 //TODO
        }

        /********** 更新矿池质押信息 *********/
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[vars.poolId];
        poolStakeInfo.startBlock = vars.startBlock; //开始块高
        poolStakeInfo.startTime = vars.startTime; //开始时间
        poolStakeInfo.enableInvite = vars.enableInvite; //是否启用邀请关系
        poolStakeInfo.token = vars.token; //矿池质押token
        // poolStakeInfo.amount; //矿池质押数量，不要重置!!!
        // poolStakeInfo.participantCounts; //参与质押玩家数量，不要重置!!!
        poolStakeInfo.poolType = BaseStruct.PoolLockType(vars.poolType); //矿池类型
        poolStakeInfo.lockSeconds = vars.lockSeconds; //挖矿锁仓时间
        poolStakeInfo.lockUntil = vars.startTime.add(vars.lockSeconds); //锁仓持续时间
        poolStakeInfo.lastRewardBlock = vars.startBlock - 1;
        // poolStakeInfo.totalPower = 0; //矿池总算力，不要重置!!!
        poolStakeInfo.powerRatio = vars.powerRatio; //质押数量到算力系数
        poolStakeInfo.maxStakeAmount = vars.maxStakeAmount; //最大质押数量
        poolStakeInfo.endBlock = 0; //矿池结束块高
        poolStakeInfo.endTime = 0; //矿池结束时间
        poolStakeInfo.selfReward = vars.selfReward; //质押自奖励
        poolStakeInfo.invite1Reward = vars.invite1Reward; //1级邀请奖励
        poolStakeInfo.invite2Reward = vars.invite2Reward; //2级邀请奖励
        poolStakeInfo.isReopen = vars.isReopen; //是否为重启矿池
        poolStakeInfo.withdrawRewardAllow = vars.withdrawRewardAllow; //是否允许领取奖励
        uint256 minRewardPerBlock = uint256(0) - uint256(1); //最小区块奖励

        bool existFlag;
        PoolRewardInfo[] storage _poolRewardInfosStorage = poolRewardInfos[vars.poolId];//重启后挖矿币种
        PoolRewardInfo[] memory _poolRewardInfosMemory = poolRewardInfos[vars.poolId]; //旧矿池挖矿币种

        uint256 extandRatio = 100; 
        if (poolStakeInfo.enableInvite) {
            extandRatio = extandRatio.add(poolStakeInfo.selfReward.add(poolStakeInfo.invite1Reward).add(poolStakeInfo.invite2Reward));
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            existFlag = false;
            tokenPendingRewards[tokens[i]] = tokenPendingRewards[tokens[i]].add(rewardTotals[i]);
            require(IERC20(tokens[i]).balanceOf(address(this)) >= tokenPendingRewards[tokens[i]], "YouSwapCore:BALANCE_INSUFFICIENT"); //奖励数量是否足额

            //对已有的挖矿奖励币种更新
            for (uint256 j = 0; j < _poolRewardInfosMemory.length; j++) {
                if (tokens[i] == _poolRewardInfosMemory[j].token) {
                    existFlag = true;
                    _poolRewardInfosStorage[j].rewardTotal = rewardTotals[i];
                    _poolRewardInfosStorage[j].rewardPerBlock = rewardPerBlocks[i];
                    _poolRewardInfosMemory[j].rewardPerBlock = rewardPerBlocks[i]; //为了计算最大质押
                    _poolRewardInfosStorage[j].rewardProvide = 0; //重置已发放奖励
                    // _poolRewardInfosStorage[j].rewardPerShare; //不要重置!!!
                }

                if (minRewardPerBlock > _poolRewardInfosMemory[j].rewardPerBlock) {
                    minRewardPerBlock = _poolRewardInfosMemory[j].rewardPerBlock;
                    poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e41).mul(poolStakeInfo.powerRatio).div(extandRatio);
                    if (vars.maxStakeAmount < poolStakeInfo.maxStakeAmount) {
                        poolStakeInfo.maxStakeAmount = vars.maxStakeAmount;
                    }
                }
            }

            //对新挖矿币种进行添加
            if (!existFlag) {
                PoolRewardInfo memory poolRewardInfo; //矿池奖励信息
                poolRewardInfo.token = tokens[i]; //奖励token
                poolRewardInfo.rewardTotal = rewardTotals[i]; //总奖励
                poolRewardInfo.rewardPerBlock = rewardPerBlocks[i]; //区块奖励，递减模式会每日按比例减少
                // poolRewardInfo.rewardProvide //默认为零
                // poolRewardInfo.rewardPerShare //默认为零
                poolRewardInfos[vars.poolId].push(poolRewardInfo);

                if (minRewardPerBlock > poolRewardInfo.rewardPerBlock) {
                    minRewardPerBlock = poolRewardInfo.rewardPerBlock;
                    poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e41).mul(poolStakeInfo.powerRatio).div(extandRatio);
                    if (vars.maxStakeAmount < poolStakeInfo.maxStakeAmount) {
                        poolStakeInfo.maxStakeAmount = vars.maxStakeAmount;
                    }
                }
            }
        }

        require(_poolRewardInfosStorage.length <= DefaultSettings.REWARD_TOKENTYPE_MAX, "YouSwap:REWARD_TOKEN_TYPE_REACH_MAX");
        sendUpdatePoolEvent(true, vars.poolId);
    }

    /**
    修改矿池名称
     */
    function setName(uint256 poolId, string memory name) external override onlyPlatform {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        poolViewInfo.name = name;//修改矿池名称
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }

    /** 修改矿池倍数 */
    function setMultiple(uint256 poolId, uint256 multiple) external override onlyPlatform {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        poolViewInfo.multiple = multiple;//修改矿池倍数
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }

    /** 修改矿池排序 */
    function setPriority(uint256 poolId, uint256 priority) external override onlyPlatform {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        poolViewInfo.priority = priority;//修改矿池排序
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }

    /**
    修改矿池区块奖励
     */
    function setRewardPerBlock(
        uint256 poolId,
        address token,
        uint256 rewardPerBlock
    ) external override onlyFactory {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        bool existFlag;
        uint256 minRewardPerBlock = uint256(0) - uint256(1); //最小区块奖励

        uint256 extandRatio = 100; 
        if (poolStakeInfo.enableInvite) {
            extandRatio = extandRatio.add(poolStakeInfo.selfReward.add(poolStakeInfo.invite1Reward).add(poolStakeInfo.invite2Reward));
        }

        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            if (_poolRewardInfos[i].token == token) {
                _poolRewardInfos[i].rewardPerBlock = rewardPerBlock; //修改矿池区块奖励
                sendUpdatePoolEvent(false, poolId); //更新矿池信息事件
                existFlag = true;
            } 
            if (minRewardPerBlock > _poolRewardInfos[i].rewardPerBlock) {
                minRewardPerBlock = _poolRewardInfos[i].rewardPerBlock;
                poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e41).mul(poolStakeInfo.powerRatio).div(extandRatio);
            }
        }

        if (!existFlag) {
            // 新增币种逻辑
            PoolRewardInfo memory poolRewardInfo; //矿池奖励信息
            poolRewardInfo.token = token; //奖励token
            poolRewardInfo.rewardPerBlock = rewardPerBlock; //区块奖励
            _poolRewardInfos.push(poolRewardInfo);
            sendUpdatePoolEvent(false, poolId); //更新矿池信息事件

            if (minRewardPerBlock > rewardPerBlock) {
                minRewardPerBlock = rewardPerBlock;
                poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e41).mul(poolStakeInfo.powerRatio).div(extandRatio);
            }
        }
    }

    /** 修改矿池总奖励: 更新总奖励，更新剩余奖励(rewardTotal和rewardPerBlock都是增加，而非替换) */
    function setRewardTotal(
        uint256 poolId,
        address token,
        uint256 rewardTotal
    ) external override onlyFactory {
        // computeReward(poolId);//计算单位算力奖励
        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        bool existFlag = false;

        for(uint i = 0; i < _poolRewardInfos.length; i++) {
            if (_poolRewardInfos[i].token == token) {
                existFlag = true;
                require(_poolRewardInfos[i].rewardProvide <= rewardTotal, "YouSwapCore:REWARDTOTAL_LESS_THAN_REWARDPROVIDE");//新总奖励是否超出已发放奖励
                tokenPendingRewards[token] = tokenPendingRewards[token].add(rewardTotal.sub(_poolRewardInfos[i].rewardTotal));//增加新旧差额，新总奖励一定大于旧总奖励
                _poolRewardInfos[i].rewardTotal = rewardTotal;//修改矿池总奖励
            } 
        }

        if (!existFlag) {
            //新币种
            tokenPendingRewards[token] = tokenPendingRewards[token].add(rewardTotal);
            PoolRewardInfo memory newPoolRewardInfo;
            newPoolRewardInfo.token = token;
            newPoolRewardInfo.rewardProvide = 0;
            newPoolRewardInfo.rewardPerShare = 0;
            newPoolRewardInfo.rewardTotal = rewardTotal;
            _poolRewardInfos.push(newPoolRewardInfo);
        }

        require(_poolRewardInfos.length <= DefaultSettings.REWARD_TOKENTYPE_MAX, "YouSwap:REWARD_TOKEN_TYPE_REACH_MAX");
        require(IERC20(token).balanceOf(address(this)) >= tokenPendingRewards[token], "YouSwapCore:BALANCE_INSUFFICIENT");//奖励数量是否足额
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }

    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external override onlyFactory {
        uint256 _maxStakeAmount;
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        uint256 minRewardPerBlock = uint256(0) - uint256(1);//最小区块奖励
        uint256 extandRatio = 100; 
        if (poolStakeInfo.enableInvite) {
            extandRatio = extandRatio.add(poolStakeInfo.selfReward.add(poolStakeInfo.invite1Reward).add(poolStakeInfo.invite2Reward));
        }

        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[poolId];
        for(uint i = 0; i < _poolRewardInfos.length; i++) {
            if (minRewardPerBlock > _poolRewardInfos[i].rewardPerBlock) {
                minRewardPerBlock = _poolRewardInfos[i].rewardPerBlock;
                _maxStakeAmount = minRewardPerBlock.mul(1e41).mul(poolStakeInfo.powerRatio).div(extandRatio);
            }
        }
        require(maxStakeAmount <= _maxStakeAmount, "YouSwapCore:MAX_STAKE_AMOUNT_REACH_CALCULATED_LIMIT");
        poolStakeInfo.maxStakeAmount = maxStakeAmount;
        sendUpdatePoolEvent(false, poolId);//更新矿池信息事件
    }

    ////////////////////////////////////////////////////////////////////////////////////
    /** 计算单位算力奖励 */
    function computeReward(uint256 poolId) internal returns (uint256[] memory) {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        uint256[] memory rewardPerShares = new uint256[](_poolRewardInfos.length);
        address[] memory rewardTokens = new address[](_poolRewardInfos.length);
        bool rewardPerShareZero;

        if (0 < poolStakeInfo.totalPower) {
            uint256 finishRewardCount;
            uint256 reward;
            uint256 blockCount;
            bool poolFinished;

            //矿池奖励发放完毕，新开一期
            if (block.number < poolStakeInfo.lastRewardBlock) {
                poolFinished = true;
            } else {
                blockCount = block.number.sub(poolStakeInfo.lastRewardBlock); //待发放的区块数量
            }
            for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
                PoolRewardInfo storage poolRewardInfo = _poolRewardInfos[i]; //矿池奖励信息
                reward = blockCount.mul(poolRewardInfo.rewardPerBlock); //两次快照之间总奖励

                if (poolRewardInfo.rewardProvide.add(reward) >= poolRewardInfo.rewardTotal) {
                    reward = poolRewardInfo.rewardTotal.sub(poolRewardInfo.rewardProvide); //核减超出奖励
                    finishRewardCount = finishRewardCount.add(1); //挖矿结束token计数
                }
                poolRewardInfo.rewardProvide = poolRewardInfo.rewardProvide.add(reward); //更新已发放奖励数量  
                poolRewardInfo.rewardPerShare = poolRewardInfo.rewardPerShare.add(reward.mul(1e41).div(poolStakeInfo.totalPower)); //更新单位算力奖励
                if (0 == poolRewardInfo.rewardPerShare) {
                    rewardPerShareZero = true;
                }
                rewardPerShares[i] = poolRewardInfo.rewardPerShare;
                rewardTokens[i] = poolRewardInfo.token;
                if (0 < reward) {
                    emit Mint(factory, poolId, poolRewardInfo.token, reward); //挖矿事件
                }
            }

            if (!poolFinished) {
                poolStakeInfo.lastRewardBlock = block.number; //更新快照块高
            }

            if (finishRewardCount == _poolRewardInfos.length && !poolFinished) {
                poolStakeInfo.endBlock = block.number; //挖矿结束块高
                poolStakeInfo.endTime = block.timestamp; //结束时间
                emit EndPool(factory, poolId); //挖矿结束事件
            }
        } else {
            //最开始的时候
            for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
                rewardPerShares[i] = _poolRewardInfos[i].rewardPerShare;
            }
        }

        if (rewardPerShareZero) {
            emit RewardPerShareEvent(factory, poolId, rewardTokens, rewardPerShares);
        }
        return rewardPerShares;
    }    

    /** 增加算力 */
    function addPower(
        uint256 poolId,
        address user,
        uint256 amount,
        uint256 powerRatio,
        address upper1,
        address upper2
    ) internal {
        uint256 power = amount.div(powerRatio);
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId]; //矿池质押信息
        poolStakeInfo.amount = poolStakeInfo.amount.add(amount); //更新矿池质押数量
        poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(power); //更新矿池总算力
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user]; //sender质押信息
        userStakeInfo.amount = userStakeInfo.amount.add(amount); //更新sender质押数量
        userStakeInfo.stakePower = userStakeInfo.stakePower.add(power); //更新sender质押算力
        if (0 == userStakeInfo.startBlock) {
            userStakeInfo.startBlock = block.number; //挖矿开始块高
        }
        uint256 upper1InvitePower = 0; //upper1邀请算力
        uint256 upper2InvitePower = 0; //upper2邀请算力
        if (ZERO != upper1) {
            uint256 inviteSelfPower = power.mul(poolStakeInfo.selfReward).div(100); //新增sender自邀请算力
            userStakeInfo.invitePower = userStakeInfo.invitePower.add(inviteSelfPower); //更新sender邀请算力
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(inviteSelfPower); //更新矿池总算力
            uint256 invite1Power = power.mul(poolStakeInfo.invite1Reward).div(100); //新增upper1邀请算力
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1]; //upper1质押信息
            upper1StakeInfo.invitePower = upper1StakeInfo.invitePower.add(invite1Power); //更新upper1邀请算力
            upper1InvitePower = upper1StakeInfo.invitePower;
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(invite1Power); //更新矿池总算力
            if (0 == upper1StakeInfo.startBlock) {
                upper1StakeInfo.startBlock = block.number; //挖矿开始块高
            }
        }
        if (ZERO != upper2) {
            uint256 invite2Power = power.mul(poolStakeInfo.invite2Reward).div(100); //新增upper2邀请算力
            UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2]; //upper2质押信息
            upper2StakeInfo.invitePower = upper2StakeInfo.invitePower.add(invite2Power); //更新upper2邀请算力
            upper2InvitePower = upper2StakeInfo.invitePower;
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(invite2Power); //更新矿池总算力
            if (0 == upper2StakeInfo.startBlock) {
                upper2StakeInfo.startBlock = block.number; //挖矿开始块高
            }
        }
        emit UpdatePower(factory, poolId, poolStakeInfo.token, poolStakeInfo.totalPower, user, userStakeInfo.invitePower, userStakeInfo.stakePower, upper1, upper1InvitePower, upper2, upper2InvitePower); //更新算力事件
    }

    /** 减少算力 */
    function subPower(
        uint256 poolId,
        address user,
        uint256 amount,
        uint256 powerRatio,
        address upper1,
        address upper2
    ) internal {
        uint256 power = amount.div(powerRatio);
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId]; //矿池质押信息
        if (poolStakeInfo.amount <= amount) {
            poolStakeInfo.amount = 0; //减少矿池总质押数量
        } else {
            poolStakeInfo.amount = poolStakeInfo.amount.sub(amount); //减少矿池总质押数量
        }
        if (poolStakeInfo.totalPower <= power) {
            poolStakeInfo.totalPower = 0; //减少矿池总算力
        } else {
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(power); //减少矿池总算力
        }
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user]; //sender质押信息
        userStakeInfo.amount = userStakeInfo.amount.sub(amount); //减少sender质押数量
        if (userStakeInfo.stakePower <= power) {
            userStakeInfo.stakePower = 0; //减少sender质押算力
        } else {
            userStakeInfo.stakePower = userStakeInfo.stakePower.sub(power); //减少sender质押算力
        }
        uint256 upper1InvitePower = 0;
        uint256 upper2InvitePower = 0;
        if (ZERO != upper1) {
            uint256 inviteSelfPower = power.mul(poolStakeInfo.selfReward).div(100); //sender自邀请算力
            if (poolStakeInfo.totalPower <= inviteSelfPower) {
                poolStakeInfo.totalPower = 0; //减少矿池sender自邀请算力
            } else {
                poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(inviteSelfPower); //减少矿池sender自邀请算力
            }
            if (userStakeInfo.invitePower <= inviteSelfPower) {
                userStakeInfo.invitePower = 0; //减少sender自邀请算力
            } else {
                userStakeInfo.invitePower = userStakeInfo.invitePower.sub(inviteSelfPower); //减少sender自邀请算力
            }
            uint256 invite1Power = power.mul(poolStakeInfo.invite1Reward).div(100); //upper1邀请算力
            if (poolStakeInfo.totalPower <= invite1Power) {
                poolStakeInfo.totalPower = 0; //减少矿池upper1邀请算力
            } else {
                poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(invite1Power); //减少矿池upper1邀请算力
            }
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
            if (upper1StakeInfo.invitePower <= invite1Power) {
                upper1StakeInfo.invitePower = 0; //减少upper1邀请算力
            } else {
                upper1StakeInfo.invitePower = upper1StakeInfo.invitePower.sub(invite1Power); //减少upper1邀请算力
            }
            upper1InvitePower = upper1StakeInfo.invitePower;
        }
        if (ZERO != upper2) {
            uint256 invite2Power = power.mul(poolStakeInfo.invite2Reward).div(100); //upper2邀请算力
            if (poolStakeInfo.totalPower <= invite2Power) {
                poolStakeInfo.totalPower = 0; //减少矿池upper2邀请算力
            } else {
                poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(invite2Power); //减少矿池upper2邀请算力
            }
            UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
            if (upper2StakeInfo.invitePower <= invite2Power) {
                upper2StakeInfo.invitePower = 0; //减少upper2邀请算力
            } else {
                upper2StakeInfo.invitePower = upper2StakeInfo.invitePower.sub(invite2Power); //减少upper2邀请算力
            }
            upper2InvitePower = upper2StakeInfo.invitePower;
        }
        emit UpdatePower(factory, poolId, poolStakeInfo.token, poolStakeInfo.totalPower, user, userStakeInfo.invitePower, userStakeInfo.stakePower, upper1, upper1InvitePower, upper2, upper2InvitePower);
    }

    struct baseLocalVars {
        uint256 poolId;
        address user;
        address upper1;
        address upper2;
        uint256 reward;
        uint256 benefitAmount;
        uint256 remainAmount;
        uint256 newBenefit;
    }

    /** 给sender发放收益，给upper1，upper2增加待领取收益 */
    function provideReward(
        uint256 poolId,
        uint256[] memory rewardPerShares,
        address user,
        address upper1,
        address upper2
    ) internal {
        baseLocalVars memory vars;
        vars.poolId = poolId;
        vars.user = user;
        vars.upper1 = upper1;
        vars.upper2 = upper2;
        uint256 inviteReward = 0;
        uint256 stakeReward = 0;
        uint256 rewardPerShare = 0;
        address token;

        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[vars.poolId];
        UserStakeInfo storage userStakeInfo = userStakeInfos[vars.poolId][vars.user];
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[vars.poolId];

        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            token = _poolRewardInfos[i].token; //挖矿奖励token
            rewardPerShare = rewardPerShares[i]; //单位算力奖励系数

            inviteReward = userStakeInfo.invitePower.mul(rewardPerShare).sub(userStakeInfo.inviteRewardDebts[i]).div(1e41); //邀请奖励
            stakeReward = userStakeInfo.stakePower.mul(rewardPerShare).sub(userStakeInfo.stakeRewardDebts[i]).div(1e41); //质押奖励

            inviteReward = userStakeInfo.invitePendingRewards[i].add(inviteReward); //待领取奖励
            stakeReward = userStakeInfo.stakePendingRewards[i].add(stakeReward); //待领取奖励
            vars.reward = inviteReward.add(stakeReward);

            if (0 < vars.reward) {
                userStakeInfo.invitePendingRewards[i] = 0; //重置待领取奖励
                userStakeInfo.stakePendingRewards[i] = 0; //重置待领取奖励
                userReceiveRewards[token][vars.user] = userReceiveRewards[token][vars.user].add(vars.reward); //增加已领取奖励

                if ((poolStakeInfo.poolType == PoolLockType.SINGLE_TOKEN_FIXED || poolStakeInfo.poolType == PoolLockType.LP_TOKEN_FIXED)&& //锁仓类型
                    poolStakeInfo.endTime == 0 &&  //矿池未结束
                    (block.timestamp >= poolStakeInfo.startTime &&  //矿池已经开始
                    block.timestamp <= poolStakeInfo.lockUntil &&  //矿池在锁仓阶段
                    poolStakeInfo.withdrawRewardAllow == 0)) { //不允许领取
                        userStakeInfo.invitePendingRewards[i] = inviteReward; //在锁仓阶段，如果不允许领取，不发放奖励
                        userStakeInfo.stakePendingRewards[i] = stakeReward; //在锁仓阶段，如果不允许领取，不发放奖励
                } else {
                    userStakeInfo.inviteClaimedRewards[i] = userStakeInfo.inviteClaimedRewards[i].add(inviteReward);
                    userStakeInfo.stakeClaimedRewards[i] = userStakeInfo.stakeClaimedRewards[i].add(stakeReward);
                    tokenPendingRewards[token] = tokenPendingRewards[token].sub(vars.reward); //减少奖励总额
                    IERC20(token).safeTransfer(vars.user, vars.reward); //发放奖励
                    emit WithdrawReward(factory, vars.poolId, token, vars.user, inviteReward, stakeReward, 0);
                }
            }

            if (ZERO != vars.upper1) {
                UserStakeInfo storage upper1StakeInfo = userStakeInfos[vars.poolId][vars.upper1];
                if ((0 < upper1StakeInfo.invitePower) || (0 < upper1StakeInfo.stakePower)) {
                    inviteReward = upper1StakeInfo.invitePower.mul(rewardPerShare).sub(upper1StakeInfo.inviteRewardDebts[i]).div(1e41); //邀请奖励
                    stakeReward = upper1StakeInfo.stakePower.mul(rewardPerShare).sub(upper1StakeInfo.stakeRewardDebts[i]).div(1e41); //质押奖励
                    upper1StakeInfo.invitePendingRewards[i] = upper1StakeInfo.invitePendingRewards[i].add(inviteReward); //待领取奖励
                    upper1StakeInfo.stakePendingRewards[i] = upper1StakeInfo.stakePendingRewards[i].add(stakeReward); //待领取奖励
                }
            }
            if (ZERO != vars.upper2) {
                UserStakeInfo storage upper2StakeInfo = userStakeInfos[vars.poolId][vars.upper2];
                if ((0 < upper2StakeInfo.invitePower) || (0 < upper2StakeInfo.stakePower)) {
                    inviteReward = upper2StakeInfo.invitePower.mul(rewardPerShare).sub(upper2StakeInfo.inviteRewardDebts[i]).div(1e41); //邀请奖励
                    stakeReward = upper2StakeInfo.stakePower.mul(rewardPerShare).sub(upper2StakeInfo.stakeRewardDebts[i]).div(1e41); //质押奖励
                    upper2StakeInfo.invitePendingRewards[i] = upper2StakeInfo.invitePendingRewards[i].add(inviteReward); //待领取奖励
                    upper2StakeInfo.stakePendingRewards[i] = upper2StakeInfo.stakePendingRewards[i].add(stakeReward); //待领取奖励
                }
            }
        }
    }

    /** 重置负债 */
    function setRewardDebt(
        uint256 poolId,
        uint256[] memory rewardPerShares,
        address user,
        address upper1,
        address upper2
    ) internal {
        uint256 rewardPerShare;
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];

        for (uint256 i = 0; i < rewardPerShares.length; i++) {
            rewardPerShare = rewardPerShares[i]; //单位算力奖励系数
            userStakeInfo.inviteRewardDebts[i] = userStakeInfo.invitePower.mul(rewardPerShare); //重置sender邀请负债
            userStakeInfo.stakeRewardDebts[i] = userStakeInfo.stakePower.mul(rewardPerShare); //重置sender质押负债

            if (ZERO != upper1) {
                UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
                upper1StakeInfo.inviteRewardDebts[i] = upper1StakeInfo.invitePower.mul(rewardPerShare); //重置upper1邀请负债
                upper1StakeInfo.stakeRewardDebts[i] = upper1StakeInfo.stakePower.mul(rewardPerShare); //重置upper1质押负债
                if (ZERO != upper2) {
                    UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
                    upper2StakeInfo.inviteRewardDebts[i] = upper2StakeInfo.invitePower.mul(rewardPerShare); //重置upper2邀请负债
                    upper2StakeInfo.stakeRewardDebts[i] = upper2StakeInfo.stakePower.mul(rewardPerShare); //重置upper2质押负债
                }
            }
        }
    }

    /** 矿池信息更新事件 */
    function sendUpdatePoolEvent(bool action, uint256 poolId) internal {
        PoolViewInfo memory poolViewInfo = poolViewInfos[poolId];
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[poolId];
        address[] memory tokens = new address[](_poolRewardInfos.length);
        uint256[] memory _rewardTotals = new uint256[](_poolRewardInfos.length);
        uint256[] memory rewardPerBlocks = new uint256[](_poolRewardInfos.length);

        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            tokens[i] = _poolRewardInfos[i].token;
            _rewardTotals[i] = _poolRewardInfos[i].rewardTotal;
            rewardPerBlocks[i] = _poolRewardInfos[i].rewardPerBlock;
        }

        uint256[] memory poolBasicInfos = new uint256[](12);
        poolBasicInfos[0] = poolViewInfo.multiple;
        poolBasicInfos[1] = poolViewInfo.priority;
        poolBasicInfos[2] = poolStakeInfo.powerRatio;
        poolBasicInfos[3] = poolStakeInfo.maxStakeAmount;
        poolBasicInfos[4] = uint256(poolStakeInfo.poolType);
        poolBasicInfos[5] = poolStakeInfo.lockSeconds;
        poolBasicInfos[6] = poolStakeInfo.selfReward;
        poolBasicInfos[7] = poolStakeInfo.invite1Reward;
        poolBasicInfos[8] = poolStakeInfo.invite2Reward;
        poolBasicInfos[9] = poolStakeInfo.startTime;
        poolBasicInfos[10] = poolStakeInfo.withdrawRewardAllow;
        poolBasicInfos[11] = uint256(uint160(address(invite)));

        emit UpdatePool(
            action,
            factory,
            poolId,
            poolViewInfo.name,
            poolStakeInfo.token,
            poolStakeInfo.startBlock,
            tokens,
            _rewardTotals,
            rewardPerBlocks,
            poolStakeInfo.enableInvite,
            poolBasicInfos
        );
    }

    /**
    解质押
     */
    function _unStake(uint256 poolId, uint256 amount, address user) override onlyFactory external {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        address upper1;
        address upper2;
        if (poolStakeInfo.enableInvite) {
            (upper1, upper2) = invite.inviteUpper2(user);
        }
        initRewardInfo(poolId, user, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId); //计算单位算力奖励系数

        if ((poolStakeInfo.poolType == PoolLockType.SINGLE_TOKEN_FIXED || poolStakeInfo.poolType == PoolLockType.LP_TOKEN_FIXED)&&
        poolStakeInfo.endTime == 0) {
            if ((poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number)) {
                require(block.timestamp >= poolStakeInfo.lockUntil, "YouSwap:POOL_NONE_REOPEN_UNSTAKE_LOCKED_DENIED!");
            }
        }

        provideReward(poolId, rewardPerShares, user, upper1, upper2); //给sender发放收益，给upper1，upper2增加待领取收益
        subPower(poolId, user, amount, poolStakeInfo.powerRatio, upper1, upper2); //减少算力

        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        if (0 != poolStakeInfo.startBlock && 0 == userStakeInfo.stakePower) {
            poolStakeInfo.participantCounts = poolStakeInfo.participantCounts.sub(1);
        }
        setRewardDebt(poolId, rewardPerShares, user, upper1, upper2); //重置sender，upper1，upper2负债
        IERC20(poolStakeInfo.token).safeTransfer(user, amount); //解质押token
        emit UnStake(factory, poolId, poolStakeInfo.token, user, amount);
    }

    function _withdrawReward(uint256 poolId, address user) override onlyFactory external {
        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        if (0 == userStakeInfo.startBlock) {
            return; //user未质押，未邀请
        }

        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];

        address upper1;
        address upper2;
        if (poolStakeInfo.enableInvite) {
            (upper1, upper2) = invite.inviteUpper2(user);
        }

        initRewardInfo(poolId, user, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId); //计算单位算力奖励系数

        provideReward(poolId, rewardPerShares, user, upper1, upper2); //给sender发放收益，给upper1，upper2增加待领取收益
        setRewardDebt(poolId, rewardPerShares, user, upper1, upper2); //重置sender，upper1，upper2负债
    }

    function initRewardInfo(
        uint256 poolId,
        address user,
        address upper1,
        address upper2
    ) internal {
        uint256 count = poolRewardInfos[poolId].length;
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];

        if (userStakeInfo.invitePendingRewards.length != count) {
            require(count >= userStakeInfo.invitePendingRewards.length, "YouSwap:INITREWARD_INFO_COUNT_ERROR");
            uint256 offset = count.sub(userStakeInfo.invitePendingRewards.length);
            for (uint256 i = 0; i < offset; i++) {
                userStakeInfo.invitePendingRewards.push(0); //初始化待领取数量
                userStakeInfo.stakePendingRewards.push(0); //初始化待领取数量
                userStakeInfo.inviteRewardDebts.push(0); //初始化邀请负债
                userStakeInfo.stakeRewardDebts.push(0); //初始化质押负债
                userStakeInfo.inviteClaimedRewards.push(0); //已领取邀请奖励
                userStakeInfo.stakeClaimedRewards.push(0); //已领取质押奖励
            }
        }
        if (ZERO != upper1) {
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
            if (upper1StakeInfo.invitePendingRewards.length != count) {
                uint256 offset = count.sub(upper1StakeInfo.invitePendingRewards.length);
                for (uint256 i = 0; i < offset; i++) {
                    upper1StakeInfo.invitePendingRewards.push(0); //初始化待领取数量
                    upper1StakeInfo.stakePendingRewards.push(0); //初始化待领取数量
                    upper1StakeInfo.inviteRewardDebts.push(0); //初始化邀请负债
                    upper1StakeInfo.stakeRewardDebts.push(0); //初始化质押负债
                    upper1StakeInfo.inviteClaimedRewards.push(0); //已领取邀请奖励
                    upper1StakeInfo.stakeClaimedRewards.push(0); //已领取质押奖励
                }
            }
            if (ZERO != upper2) {
                UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
                if (upper2StakeInfo.invitePendingRewards.length != count) {
                    uint256 offset = count.sub(upper2StakeInfo.invitePendingRewards.length);
                    for (uint256 i = 0; i < offset; i++) {
                        upper2StakeInfo.invitePendingRewards.push(0); //初始化待领取数量
                        upper2StakeInfo.stakePendingRewards.push(0); //初始化待领取数量
                        upper2StakeInfo.inviteRewardDebts.push(0); //初始化邀请负债
                        upper2StakeInfo.stakeRewardDebts.push(0); //初始化质押负债
                        upper2StakeInfo.inviteClaimedRewards.push(0); //已领取邀请奖励
                        upper2StakeInfo.stakeClaimedRewards.push(0); //已领取质押奖励
                    }
                }
            }
        }
    }

    /**交易矿池id有效性 */
    function checkPIDValidation(uint256 _poolId) external view override {
        PoolStakeInfo memory poolStakeInfo = this.getPoolStakeInfo(_poolId);
        require((ZERO != poolStakeInfo.token) && (poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_EXIST_OR_MINT_NOT_START"); //是否开启挖矿
    }

    /** 更新结束时间 */
    function refresh(uint256 _poolId) external override {
        computeReward(_poolId);
    }
}
