// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "111/day6/TokenBank.sol";
// token和tokenBank关系：货币资产(token)和银行(tokenBank)，在区块链上，token的发行量由token约定，转账只不过是钱从这个地址转到另一个地址

// 继承 TokenBank 编写 TokenBankV2，支持存入扩展的 ERC20 Token，用户可以直接调用 
//   transferWithCallback 将 扩展的 ERC20 Token 存入到 TokenBankV2 中。
//  （备注：TokenBankV2 需要实现 tokensReceived 来实现存款记录工作）
contract tokenBankV2 is TokenBank {
    // tokensReceived方法用户记录转账
    function tokensReceived(uint256 amount) public {
        // 判断用户是否的真转账到tokenBankV2合约中
        require(msg.sender != address(token),"Only baseToken can be modified");
        deposits[msg.sender] = deposits[msg.sender] + amount;
        emit  depositMoney( msg.sender, amount );
    }
}

