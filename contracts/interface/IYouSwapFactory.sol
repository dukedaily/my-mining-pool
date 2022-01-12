// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./../interface/ITokenYou.sol";

interface BaseStruct {

    /** 矿池四种类型 */
     enum PoolLockType {
        SINGLE_TOKEN, //单币挖矿
        LP_TOKEN, //lp挖矿
        SINGLE_TOKEN_FIXED, //单币定期挖矿
        LP_TOKEN_FIXED //lp定期挖矿
    }

    /** 矿池可视化信息 */
    struct PoolViewInfo {
        address token; //token合约地址
        string name; //名称
        uint256 multiple; //奖励倍数
        uint256 priority; //排序
    }

    /** 矿池质押信息 */
    struct PoolStakeInfo {
        uint256 startBlock; //挖矿开始块高
        uint256 startTime; //挖矿开始时间
        bool enableInvite; //是否启用邀请关系
        address token; //token合约地址，单币，lp都是这个
        uint256 amount; //质押数量，这个就是TVL
        uint256 participantCounts; //参与质押玩家数量
        PoolLockType poolType; //单币挖矿，lp挖矿，单币定期，lp定期
        uint256 lockSeconds; //锁仓持续时间
        uint256 lockUntil; //锁仓结束时间（秒单位）
        uint256 lastRewardBlock; //最后发放奖励块高
        uint256 totalPower; //总算力
        uint256 powerRatio; //质押数量到算力系数，数量就是算力吧
        uint256 maxStakeAmount; //最大质押数量
        uint256 endBlock; //挖矿结束块高
        uint256 endTime; //挖矿结束时间
        uint256 selfReward; //质押自奖励
        uint256 invite1Reward; //1级邀请奖励
        uint256 invite2Reward; //2级邀请奖励
        bool isReopen; //是否为重启矿池
        uint256 withdrawRewardAllow; //定期期间是否允许领取奖励(0：不允许, 非0：允许)
    }

    /** 矿池奖励信息 */
    struct PoolRewardInfo {
        address token; //挖矿奖励币种:A/B/C
        uint256 rewardTotal; //矿池总奖励
        uint256 rewardPerBlock; //单个区块奖励
        uint256 rewardProvide; //矿池已发放奖励
        uint256 rewardPerShare; //单位算力奖励
    }

    /** 用户质押信息 */
    struct UserStakeInfo {
        uint256 startBlock; //质押开始块高
        uint256 amount; //质押数量
        uint256 invitePower; //邀请算力
        uint256 stakePower; //质押算力
        uint256[] invitePendingRewards; //待领取奖励
        uint256[] stakePendingRewards; //待领取奖励
        uint256[] inviteRewardDebts; //邀请负债
        uint256[] stakeRewardDebts; //质押负债
        uint256[] inviteClaimedRewards; //已领取邀请奖励
        uint256[] stakeClaimedRewards; //已领取质押奖励
    }
}

////////////////////////////////// 挖矿Core合约 //////////////////////////////////////////////////
interface IYouSwapFactoryCore is BaseStruct {
    function initialize(address _owner, address _platform, address _invite) external;

    function getPoolRewardInfo(uint256 poolId) external view returns (PoolRewardInfo[] memory);

    function getUserStakeInfo(uint256 poolId, address user) external view returns (UserStakeInfo memory);

    function getPoolStakeInfo(uint256 poolId) external view returns (PoolStakeInfo memory);

    function getPoolViewInfo(uint256 poolId) external view returns (PoolViewInfo memory);

    function stake(uint256 poolId, uint256 amount, address user) external;

    function _unStake(uint256 poolId, uint256 amount, address user) external;

    function _withdrawReward(uint256 poolId, address user) external;

    function getPoolIds() external view returns (uint256[] memory);

    function addPool(
        uint256 prePoolId,
        uint256 range,
        address token,
        bool enableInvite,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) external;

    /** 
    修改矿池总奖励
    */
    function setRewardTotal(uint256 poolId, address token, uint256 rewardTotal) external;

    /**
    修改矿池区块奖励
     */
    function setRewardPerBlock(uint256 poolId, address token, uint256 rewardPerBlock) external;

    /**
    修改矿池名称
     */
    function setName(uint256 poolId, string memory name) external;

    /**
    修改矿池倍数
     */
    function setMultiple(uint256 poolId, uint256 multiple) external;

    /**
    修改矿池排序
     */
    function setPriority(uint256 poolId, uint256 priority) external;

    /**
    修改矿池最大可质押数量
     */
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external;

    /**
    矿池ID有效性校验
     */
    function checkPIDValidation(uint256 poolId) external view;

    /**
    刷新矿池，确保结束时间被设置
     */
    function refresh(uint256 _poolId) external;
}

////////////////////////////////// 挖矿外围合约 //////////////////////////////////////////////////
interface IYouSwapFactory is BaseStruct {
    /**
    修改OWNER
     */
    function transferOwnership(address owner) external;

    /**
    质押
    */
    function stake(uint256 poolId, uint256 amount) external;

    /**
    解质押并提取奖励
     */
    function unStake(uint256 poolId, uint256 amount) external;

    /**
    批量解质押并提取奖励
     */
    function unStakes(uint256[] memory _poolIds) external;

    /**
    提取奖励
     */
    function withdrawReward(uint256 poolId) external;

    /**
    批量提取奖励，供平台调用
     */
    function withdrawRewards2(uint256[] memory _poolIds, address user) external;

    /**
    待领取的奖励
     */
    function pendingRewardV3(uint256 poolId, address user) external view returns (address[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    矿池ID
     */
    function poolIds() external view returns (uint256[] memory);

    /**
    质押数量范围
     */
    function stakeRange(uint256 poolId) external view returns (uint256, uint256);

    /**
    设置RewardPerBlock修改最大幅度
     */
    function setChangeRPBRateMax(uint256 _rateMax) external;

    /** 
    调整区块奖励修改周期 
    */
    function setChangeRPBIntervalMin(uint256 _interval) external;

    /** 
    调整平台抽成比例
    */
    function setBenefitRate(uint256 _newRate) external;

    /*
    矿池名称，质押币种，是否启用邀请，总锁仓，地址数，矿池类型，锁仓时间，最大质押数量，开始时间，结束时间，锁仓期间是否允许领取奖励
    */
    function getPoolStakeDetail(uint256 poolId) external view returns (address, bool, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    /**
    用户质押详情 
    */
    function getUserStakeInfo(uint256 poolId, address user) external view returns (uint256, uint256, uint256, uint256);

    /**
    用户奖励详情 
    */
    function getUserRewardInfo(uint256 poolId, address user, uint256 index) external view returns ( uint256, uint256, uint256, uint256);

    /**
    获取矿池奖励详情 
    */
    function getPoolRewardInfoDetail(uint256 poolId) external view returns (address[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    矿池奖励详情 
    */
    function getPoolRewardInfo(uint poolId) external view returns (PoolRewardInfo[] memory);

    /**
    增加奖励APR 
    */
    function addRewardThroughAPR(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals, uint256[] memory addRewardPerBlocks) external;
    
    /**
    延长矿池奖励时间 
    */
    function addRewardThroughTime(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals) external;

    /** 
    设置运营权限 
    */
    function setOperateOwner(address user, bool state) external;

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
    ) external;

    /**
    修改矿池区块奖励
     */
    function updateRewardPerBlock(uint256 poolId, bool increaseFlag, uint256 percent) external;

    /**
    修改矿池最大可质押数量
     */
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external;
}
