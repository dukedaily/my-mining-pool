// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
import "./YouSwapFactory.sol";
import "../interface/IYouSwapInviteV1.sol";
// import "hardhat/console.sol";

contract YouSwapFactoryCreator {

    /// @notice 新建矿池合约: 项目方管理员，矿池外围合约地址，矿池core合约地址， 是否在前端展示
    event YouswapFactoryCreatorEvent(address indexed owner, address indexed factory, address indexed core, bool isVisible);

    /// @notice oldOwner：旧Owner， newOwner：新Owner
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// @notice clone模板合约
    event CloneEvent(address indexed clone);

    /// @notice 支持币种，创建矿池佣金，创建邀请关系费用，是否支持
    event CommissionEvent(address indexed token, uint256 poolCommAmount, uint256 inviteCommAmount, bool state);

    /// @notice 设置factory模板
    event PoolFactoryTemplateEvent(address indexed oldTemplate, address indexed newTemplate);

    /// @notice 设置core模板
    event CoreTemplateEvent(address indexed oldTemplate, address indexed newTemplate);

    /// @notice 设置invite模板
    event InviteTemplateEvent(address indexed oldTemplate, address indexed newTemplate);

    /// @notice 设置运营权限
    event OperateOwnerEvent(address indexed user, bool state);

    /// @notice 设置财务权限
    event FinanceOwnerEvent(address indexed user, bool state);

    /// @notice 获取佣金
    event withdrawCommissionEvent(address indexed dst);

    /// @notice 对于所有矿池，平台收取挖矿奖励抽成比例
    event BenefitRateEvent(uint256 oldBenefitRate, uint256 newBenefitRate);

    /// @notice 重开一期冷却时间
    event ReopenPeriodEvent(uint256 oldReopenPeriod, uint256 newReopenPeriod);

    /// @notice 调整区块奖励最大调整幅度
    event ChangeRPBRateMaxEvent(address indexed creator, address indexed factory, uint256 rateMax);

    /// @notice 调整区块奖励修改周期
    event ChangeRPBIntervalEvent(address indexed creator, address indexed factory, uint256 interval);

    /// @notice 设置创建白名单
    event WhiteListEvent(address indexed superAddr, bool state);

    address public admin; // 平台管理员
    mapping(address => bool) public operateOwner; //运营权限
    mapping(address => bool) public financeOwner; //财务权限
    mapping(address => bool) public whiteList; //创建人白名单，可免费创建矿池

    struct Commission { //佣金结构
        uint256 poolCommAmount; //创建矿池佣金
        uint256 inviteCommAmount; //创建邀请关系佣金
        bool isSupported; //是否支持
    }

    mapping(address => Commission) supportCommissions; //佣金集合
    address[] supportCommTokenArr; //支持的佣金Tokens

    ITokenYou public you; //默认支持you

    address public poolFactoryTemplate; //factory模板合约
    address public coreTemplate; //core模板合约
    address public inviteTemplate; //invite模板合约

    mapping(address=> address) creatorFactories; //项目方=>矿池工厂
    mapping(address=> address) factoryCore; //矿池工厂=>Core合约
    mapping(address=> address) factoryInvite; //矿池工厂=>Invite合约
    mapping(address=> uint256) poolIDRange; //项目方-> 矿池ID range系数
    uint256 public rangeGlobal = 2000000; //当前range系数

    address[] internal allFactories; //所有矿池工厂
    address internal constant ZERO = address(0);

    uint256 public benefitRate; //平台抽成，10: 0.1%, 100: 1%, 1000: 10%, 10000: 100%（默认：0)
    uint256 public reopenPeriod = 24 * 60 *3; //再开一期冷却时间（默认：3天)

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(ITokenYou _you) {
        you = _you;
        admin = msg.sender;
        _setOperateOwner(admin, true); 
        setSupportCommTokens(address(_you), 0, 0, true);
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // 校验admin权限
    modifier onlyAdmin() {
        require(admin == msg.sender, "YouSwap:FORBIDDEN_NOT_PLATFORM_ADMIN");
        _;
    }

    // 校验运营权限
    modifier onlyOperater() {
        require(operateOwner[msg.sender], "YouSwap:FORBIDDEN_NOT_OPERATER");
        _;
    }

    // 校验财务权限
    modifier onlyFinanceOwner() {
        require(financeOwner[msg.sender], "YouSwap:FORBIDDEN_NOT_FINANCE_OWNER");
        _;
    }

    // 修改owner
    function transferOwnership(address _admin) external onlyAdmin {
        require(ZERO != _admin, "YouSwap:INVALID_ADDRESSES");
        emit TransferOwnership(admin, _admin);
        admin = _admin;
    }

    function _setOperateOwner(address user, bool state) internal {
        operateOwner[user] = state; //设置运营权限
        emit OperateOwnerEvent(user, state);
    }

    // 设置运营权限
    function setOperateOwner(address user, bool state) external onlyAdmin {
        _setOperateOwner(user, state);
    }

    // 设置财务权限
    function setFinanceOwner(address user, bool state) external onlyAdmin {
        financeOwner[user] = state;
        emit FinanceOwnerEvent(user, state);
    }

    ////////////////////////////////////////////////////////////////////////////////////

    // 矿池合约模板， 供clone使用
    function setPoolFactoryTemplate(YouSwapFactory _newTemplate) external onlyAdmin {
        require(ZERO != address(_newTemplate), "YouSwap:INVALID_ADDRESSES");
        address oldFactoryTemp = poolFactoryTemplate;
        poolFactoryTemplate = address(_newTemplate);
        emit PoolFactoryTemplateEvent(oldFactoryTemp, poolFactoryTemplate);
    }

    // 矿池核心数据模板， 供clone使用
    function setCoreTemplate(address _newCore) external onlyAdmin {
        require(ZERO != _newCore, "YouSwap:INVALID_ADDRESSES");
        address oldCoreTemp = coreTemplate;
        coreTemplate = _newCore;
        emit CoreTemplateEvent(oldCoreTemp, _newCore);
    }

    // 矿池邀请合约模板， 供clone使用
    function setInviteTemplate(address _newInvite) external onlyAdmin {
        require(ZERO != _newInvite, "YouSwap:INVALID_ADDRESSES");
        address oldInviteTemp = inviteTemplate;
        inviteTemplate = _newInvite;
        emit InviteTemplateEvent(oldInviteTemp, inviteTemplate);
    }

    struct FactoryCreatorLocalVars {
        uint256 prePoolId;
        address token;
        address commissionToken;
        address pFactory;
        address core;
        address invite;
        uint256 commissionTotal;
        uint256 benefitAmount;
        uint256 newTotal;
        uint256 balance;
        uint256 tvl;
        uint256 poolType;
        uint256 lockSeconds;
        uint256 maxStakeAmount;
        bool enableInvite;
        uint256 endTime;
    }
    
    /**
        @notice 创建矿池
        @param prePoolId 旧矿池Id
        @param token 矿池质押币种
        @param commissionToken 支付费用币种
        @param enableInvite 是否启用邀请关系
        @param poolParams poolType: 0矿池类型
            powerRatio: 1用算力兑换比例
            startTimeDelay: 2矿池启动延时秒数
            priority: 3优先级
            maxStakeAmount: 4最大质押数量
            lockSeconds: 5锁仓秒数
            multiple: 6挖矿倍数
            selfReward: 7自邀奖励
            uppper1Reward: 8一级奖励
            upper2Reward: 9二级奖励
            withdrawRewardAllow: 10定期期间是否允许领取奖励(0:不允许，非零:允许)
        @param tokens 挖矿奖励币种
        @param rewardTotals 挖矿奖励币种数量
        @param rewardPerBlocks 单个区块奖励数量
    */
    function createPool(
        uint256 prePoolId,
        address token,
        address commissionToken,
        bool enableInvite,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) public {
        FactoryCreatorLocalVars memory vars;
        vars.prePoolId = prePoolId;
        vars.token = token;
        vars.commissionToken = commissionToken;
        vars.enableInvite = enableInvite;
        Commission memory commTmp = supportCommissions[vars.commissionToken];
        require(commTmp.isSupported, "YouSwap:COMMISSION_TOKEN_NOT_SUPPORTED");

        require(poolParams[0] < 4, "YouSwap:INVALID_POOL_TYPE"); //poolType
        require(poolParams[1] > 0, "YouSwap:POWERRATIO_MUST_GREATER_THAN_ZERO"); //powerRatio
        require(poolParams[4] > 0, "YouSwap:MAX_STAKE_AMOUNT_MUST_GREATER_THAN_ZERO"); //maxStakeAmount

        //重开校验
        if (vars.prePoolId != 0) {
            vars.core = getCore(msg.sender);
            IYouSwapFactoryCore(vars.core).checkPIDValidation(vars.prePoolId);
            IYouSwapFactoryCore(vars.core).refresh(vars.prePoolId);

            (vars.token, 
            vars.enableInvite,
            vars.tvl,, 
            vars.poolType, 
            vars.lockSeconds, 
            vars.maxStakeAmount,,
            vars.endTime,) = YouSwapFactory(creatorFactories[msg.sender]).getPoolStakeDetail(vars.prePoolId);
            require(vars.endTime != 0, "YouSwap:MINING_POOL_IS_IN_PROCESS");
            {
                //in case stack too deep
                uint256 poolType = poolParams[0];
                uint256 startTimeDelay = poolParams[2];
                uint256 maxStakeAmount = poolParams[4];
                uint256 lockSeconds = poolParams[5];

                if (maxStakeAmount < vars.tvl) {
                    poolParams[4] = vars.tvl;
                }

                //定期：锁仓时长不变，开始时间至少延后3天，质押币种无法改变，最大质押数量取大值
                if (uint256(BaseStruct.PoolLockType.SINGLE_TOKEN_FIXED) == vars.poolType || 
                    uint256(BaseStruct.PoolLockType.LP_TOKEN_FIXED) == vars.poolType) {
                    if (startTimeDelay < DefaultSettings.ONEMINUTE.mul(reopenPeriod)) { //默认3天
                        poolParams[2] = DefaultSettings.ONEMINUTE.mul(reopenPeriod);
                    }
                    require(vars.lockSeconds == lockSeconds, "YouSwap:LOCKSECONDS_SHOULD_NOT_CHANGED!");
                } 
                require(vars.poolType == poolType, "YouSwap:POOLTYPE_SHOULD_NOT_CHANGED!");
            }
        }

        vars.pFactory = creatorFactories[msg.sender];
        vars.commissionTotal = commTmp.poolCommAmount;

        if (vars.pFactory == ZERO) {
            vars.pFactory = createClone(poolFactoryTemplate);
            vars.core = createClone(coreTemplate);
            vars.invite = createClone(inviteTemplate);
            require(ZERO != vars.pFactory && ZERO != vars.core && ZERO != vars.invite, "YouSwap:CLONE_FACTORY_OR_CORE_FAILED_OR_INVITE_FAILED");

            rangeGlobal = rangeGlobal.add(1);
            poolIDRange[msg.sender] = rangeGlobal;

            YouSwapFactory(vars.pFactory).initialize(msg.sender, address(this), benefitRate, address(vars.invite), vars.core);
            creatorFactories[msg.sender] = vars.pFactory;
            factoryCore[vars.pFactory] = vars.core;
            factoryInvite[vars.pFactory] = vars.invite;
            allFactories.push(vars.pFactory);
            vars.prePoolId = 0;
            emit YouswapFactoryCreatorEvent(msg.sender, vars.pFactory, vars.core, true);
        }

        if (vars.enableInvite) {
            vars.commissionTotal = vars.commissionTotal.add(commTmp.inviteCommAmount);
        }

        if (!whiteList[msg.sender]) {
            if (vars.commissionTotal > 0) {
                IERC20(address(vars.commissionToken)).safeTransferFrom(msg.sender, address(this), vars.commissionTotal);
            }
        }

        vars.core = factoryCore[vars.pFactory];
        uint256[] memory newTotals = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            require((ZERO != tokens[i]) && (address(this) != tokens[i]), "YouSwap:PARAMETER_ERROR_TOKEN");
            require(0 < rewardTotals[i], "YouSwap:PARAMETER_ERROR_REWARD_TOTAL");
            require(0 < rewardPerBlocks[i], "YouSwap:PARAMETER_ERROR_REWARD_PER_BLOCK");
            vars.balance = IERC20(tokens[i]).balanceOf(vars.core);
            newTotals[i] = rewardTotals[i];

            vars.benefitAmount = rewardTotals[i].mul(benefitRate).div(DefaultSettings.TEN_THOUSAND);
            if (!whiteList[msg.sender]) {
                if (vars.benefitAmount > 0) {
                    IERC20(tokens[i]).safeTransferFrom(msg.sender, address(this), vars.benefitAmount);
                    newTotals[i] = rewardTotals[i].sub(vars.benefitAmount);
                }
            }
            if (newTotals[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, vars.core, newTotals[i]);
            }

            //实际转入core金额，兼容燃烧币种
            newTotals[i] = IERC20(tokens[i]).balanceOf(vars.core).sub(vars.balance);
        }

        require((ZERO != vars.token) && (address(this) != vars.token) && (vars.pFactory != vars.token), "YouSwap:PARAMETER_ERROR_TOKEN");
        uint256 range = poolIDRange[msg.sender].mul(DefaultSettings.EACH_FACTORY_POOL_MAX);
        YouSwapFactory(vars.pFactory).addPool(vars.prePoolId, range, vars.token, vars.enableInvite, poolParams, tokens, newTotals, rewardPerBlocks);

        if (whiteList[msg.sender]) {
           YouSwapFactory(vars.pFactory).setWhiteList(msg.sender, true);
        }
    }

    struct ReopenLocalVars {
        address token;
        uint256 tvl;
        uint256 poolType;
        uint256 lockSeconds;
        uint256 maxStakeAmount;
        bool enableInvite;
        uint256 endTime;
    }

    /**
        @notice 再开一期
        @param prePoolId 旧矿池Id
        @param commissionToken 支付费用币种
        @param poolParams poolType: 0矿池类型
            powerRatio: 1用算力兑换比例
            startTimeDelay: 2矿池开启时间
            priority: 3优先级
            maxStakeAmount: 4最大质押数量
            lockSeconds: 5锁仓秒数
            multiple: 6挖矿倍数
            selfReward: 7自邀奖励
            uppper1Reward: 8一级奖励
            upper2Reward: 9二级奖励
        @param tokens 挖矿奖励币种
        @param rewardTotals 挖矿奖励币种数量
        @param rewardPerBlocks 单个区块奖励数量
    */
    function reopen(
        uint256 prePoolId,
        address commissionToken,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) external {
        //方法统一，在createPool里面校验
        createPool(prePoolId, ZERO, commissionToken, true, poolParams, tokens, rewardTotals, rewardPerBlocks);
    }

    /**
        @notice 一键领取收益
        @param factoryArr 矿池合约数组
     */
    function withdrawAllRewards(YouSwapFactory[] memory factoryArr) external {
        for (uint256 i = 0; i < factoryArr.length; i++) {
            YouSwapFactory factory = factoryArr[i];
            factory.withdrawRewards2(factory.poolIds(), msg.sender);
        }
    }

    /**
      * 获取获得的费用数量
      * (tokens, amounts) 支持佣金币种，当前持有数量
     */
    function getBalance() external view returns (address[] memory tokens, uint256[] memory amounts) {
        uint256[] memory balances = new uint256[](supportCommTokenArr.length);
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            uint256 b = IERC20(address(supportCommTokenArr[i])).balanceOf(address(this));
            balances[i] = b;
        }

        tokens = supportCommTokenArr;
        amounts = balances;
    }

    /**
        @notice 获取所有矿池工厂
        @return 所有工厂合约
     */
    function getAllFactories() external view returns (address[] memory) {
        return allFactories;
    }

    /**
        @notice 获取当前用户创建的矿池工厂
        @param user 用户地址
        @return 当前用户持有的矿池合约
     */
    function getMyFactory(address user) external view returns (address) {
        return creatorFactories[user];
    }

    /**
        @notice 获取当前用户创建的邀请合约
        @param user 用户地址
        @return 当前用户持有的邀请合约
     */
    function getMyInvite(address user) external view returns (address) {
        return factoryInvite[creatorFactories[user]];
    }

    /**
        @notice 获取支持支付的币种和状态
     */
    function getSupportCommTokens() external view returns (address[] memory supportCommTokenArrRet, uint256[] memory poolAmounts, uint256[] memory inviteAmounts, bool[] memory states) {
        supportCommTokenArrRet = new address[](supportCommTokenArr.length);
        poolAmounts = new uint256[](supportCommTokenArr.length);
        inviteAmounts = new uint256[](supportCommTokenArr.length);
        states = new bool[](supportCommTokenArr.length);
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            supportCommTokenArrRet[i] = supportCommTokenArr[i];
            poolAmounts[i] = supportCommissions[supportCommTokenArr[i]].poolCommAmount;
            inviteAmounts[i] = supportCommissions[supportCommTokenArr[i]].inviteCommAmount;
            states[i] = supportCommissions[supportCommTokenArr[i]].isSupported;
        }
    }

    /**
        @notice 获取矿池合约数量
        @return 所有矿池合约数量
     */
    function getFactoryCounts() external view returns(uint256) {
        return allFactories.length;
    }

    /**
        @notice 获取抽成比例
        @return 抽成比例，基数1w
     */
    function getBenefitRate() external view returns(uint256, uint256) {
        return (benefitRate, DefaultSettings.TEN_THOUSAND);
    }

    /**
        @notice 设置支付币种和数量
        @param _token 支持佣金币种
        @param _poolCommAmount 创建矿池费用
        @param _inviteCommAmount 创建邀请关系费用
        @param _state 币种支持状态
     */
    function setSupportCommTokens(address _token, uint256 _poolCommAmount, uint256 _inviteCommAmount, bool _state) public onlyOperater {
        require(ZERO != _token, "YouSwap:INVALID_ADDRESS");
        Commission memory comm;
        comm.poolCommAmount = _poolCommAmount;
        comm.inviteCommAmount = _inviteCommAmount;
        comm.isSupported = _state;
        supportCommissions[_token] = comm;

        emit CommissionEvent(_token, _poolCommAmount, _inviteCommAmount, _state);
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            if (_token == supportCommTokenArr[i]) {
                return;
            }
        }
        supportCommTokenArr.push(_token);
    }

    /**
        @notice 一键获取所有佣金
        @param _dst 接收佣金地址
     */
    function withdrawCommission(address _dst) external onlyFinanceOwner {
        require(ZERO != _dst, "YouSwap:INVALID_ADDRESS");
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            uint256 b = IERC20(supportCommTokenArr[i]).balanceOf(address(this));
            if (b > 0) {
                IERC20(supportCommTokenArr[i]).safeTransfer(_dst, b);
            }
        }
        emit withdrawCommissionEvent(_dst);
    }

    /**
        @notice 对于所有矿池，平台收取挖矿奖励抽成比例
        @param _newBenefitRate 平台抽成比例
     */
    function setBenefitRate(uint256 _newBenefitRate) external onlyOperater {
        require(_newBenefitRate >= DefaultSettings.BENEFIT_RATE_MIN && _newBenefitRate <= DefaultSettings.BENEFIT_RATE_MAX, "YouSwap:PARAMETER_ERROR_INPUT");
        for (uint256 i = 0; i < allFactories.length; i++) {
            YouSwapFactory(allFactories[i]).setBenefitRate(_newBenefitRate);
        }
        uint256 preBenefitRate = benefitRate;
        benefitRate = _newBenefitRate;
        emit BenefitRateEvent(preBenefitRate, benefitRate);
    }

    /**
        @notice 再开一期冷却时间
        @param _period 冷却天数
     */
    function setReopenPeriod(uint256 _period) external onlyOperater {
        uint256 oldPeriod = reopenPeriod;
        reopenPeriod = _period;
        emit ReopenPeriodEvent(oldPeriod, reopenPeriod);
    }

    /** 
        @notice 调整区块奖励最大调整幅度
        @param _creator 项目方地址
        @param _rateMax 调整上限
    */
    function setChangeRPBRateMax(address _creator, uint256 _rateMax) external onlyOperater {
        address factory = creatorFactories[_creator];
        require(ZERO != factory, "YouSwap:CREATOR_FACTORY_NOT_FOUND");
        YouSwapFactory(factory).setChangeRPBRateMax(_rateMax);
        emit ChangeRPBRateMaxEvent(_creator, factory, _rateMax);
    }

    /** 
        @notice 调整区块奖励修改周期，默认7天
        @param _interval 周期
    */
    function setChangeRPBIntervalMin(address _creator, uint256 _interval) external onlyOperater {
        address factory = creatorFactories[_creator];
        require(ZERO != factory, "YouSwap:CREATOR_FACTORY_NOT_FOUND");
        YouSwapFactory(factory).setChangeRPBIntervalMin(_interval);
        emit ChangeRPBIntervalEvent(_creator, factory, _interval);
    }

    /**
        @notice 修改矿池名字
        @param _creator 项目方
        @param _poolId 矿池id
        @param _name 矿池新名字
     */
    function setName(address _creator, uint256 _poolId, string memory _name) external onlyOperater {
        IYouSwapFactoryCore core = IYouSwapFactoryCore(getCore(_creator));
        core.checkPIDValidation(_poolId);
        core.setName(_poolId, _name);
    }

    /**
        @notice 修改矿池倍数
        @param _creator 项目方
        @param _poolId 矿池id
        @param _multiple 新倍数
     */
    function setMultiple(address _creator, uint256 _poolId, uint256 _multiple) external onlyOperater {
        IYouSwapFactoryCore core = IYouSwapFactoryCore(getCore(_creator));
        core.checkPIDValidation(_poolId);
        core.setMultiple(_poolId, _multiple);
    }

    /**
        @notice 修改矿池排序
        @param _creator 项目方
        @param _poolId 矿池id
        @param _priority 新优先级
     */
    function setPriority(address _creator, uint256 _poolId, uint256 _priority) external onlyOperater {
        IYouSwapFactoryCore core = IYouSwapFactoryCore(getCore(_creator));
        core.checkPIDValidation(_poolId);
        core.setPriority(_poolId, _priority);
    }

    function getCore(address _creator) internal view returns(address) {
        address factory = creatorFactories[_creator];
        require(ZERO != factory, "YouSwap:CREATOR_FACTORY_NOT_FOUND");
        return factoryCore[factory];
    }

    /**
        @notice 设置创建白名单
        @param _super 白名单
        @param _state 白名单支持状态
     */
    function setWhiteList(address _super, bool _state) external onlyOperater {
        require(ZERO != _super, "YouSwap:INVALID_ADDRESS");
        whiteList[_super] = _state;
        address factory = creatorFactories[_super];
        if(ZERO != factory) {
            YouSwapFactory(factory).setWhiteList(_super, _state);
        }
        emit WhiteListEvent(_super, _state);
    }

    /**
        @notice 查询是否在白名单中
        @param _creator 白名单
     */
    function isWhiteList(address _creator) external view returns(bool) {
        return whiteList[_creator];
    }

    /**
        @notice 克隆模板合约
        @param _prototype 克隆模板
        @return proxy 新合约
     */
    function createClone(address _prototype) internal returns (address proxy) {
        bytes20 targetBytes = bytes20(_prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
            add(clone, 0x28),
            0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }

        emit CloneEvent(proxy);
        return proxy;
    }
}