// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

library ErrorCode {

    string constant FORBIDDEN = 'YouSwap:FORBIDDEN';
    string constant IDENTICAL_ADDRESSES = 'YouSwap:IDENTICAL_ADDRESSES';
    string constant ZERO_ADDRESS = 'YouSwap:ZERO_ADDRESS';
    string constant INVALID_ADDRESSES = 'YouSwap:INVALID_ADDRESSES';
    string constant BALANCE_INSUFFICIENT = 'YouSwap:BALANCE_INSUFFICIENT';
    string constant REWARDTOTAL_LESS_THAN_REWARDPROVIDE = 'YouSwap:REWARDTOTAL_LESS_THAN_REWARDPROVIDE';
    string constant PARAMETER_TOO_LONG = 'YouSwap:PARAMETER_TOO_LONG';
    string constant REGISTERED = 'YouSwap:REGISTERED';
    string constant MINING_NOT_STARTED = 'YouSwap:MINING_NOT_STARTED';
    string constant END_OF_MINING = 'YouSwap:END_OF_MINING';
    string constant POOL_NOT_EXIST_OR_END_OF_MINING = 'YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING';
    
}

library DefaultSettings {
    uint256 constant BENEFIT_RATE_MIN = 0; // 0% 平台抽成最小比例, 10: 0.1%, 100: 1%, 1000: 10%, 10000: 100%
    uint256 constant BENEFIT_RATE_MAX = 10000; //100% 平台抽成最大比例
    uint256 constant TEN_THOUSAND = 10000; //100% 平台抽成最大比例
    uint256 constant EACH_FACTORY_POOL_MAX = 10000; //每个矿池合约创建合约上限
    uint256 constant CHANGE_RATE_MAX = 30; //调整区块发放数量幅度单次最大30%
    uint256 constant DAY_INTERVAL_MIN = 7; //调整单个区块奖励数量频率
    uint256 constant SECONDS_PER_DAY = 86400; //每天秒数
    uint256 constant ONEMINUTE = 1 minutes;
    uint256 constant REWARD_TOKENTYPE_MAX = 10; //奖励币种最大数量
}