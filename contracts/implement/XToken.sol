// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _amount
    ) ERC20(_name, _symbol) {
        mint(msg.sender, _amount);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
