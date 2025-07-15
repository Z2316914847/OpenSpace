// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "111/day6/ERC20.sol";

contract TokenBank{
    string public name; 
    string public symbol;
    BaseERC20 public token;   
    uint public LESS_MONEY = 0.01 ether;   

    mapping (address => uint256) deposits; 
    event depositMoney( address, uint256 );
    event WithdrawMoney( address, uint256 );
    event tranferSuccess(string);
    
    constructor(){

        token = new BaseERC20();
    }

    receive() external payable { }

    modifier lessMoney{
        require (msg.value > LESS_MONEY, " The deposit amount must not be less than 0.01!" );
        _;
    }


    function deposit(uint256 amount) public lessMoney payable {
        // 外部合约转账 + Bank添加记录
        try token.transferFrom(msg.sender, address(this), amount) returns(bool){
            emit  tranferSuccess("tranfer success!");
            deposits[msg.sender] = deposits[msg.sender] + amount;
        }catch{
            revert("tranfer failed!");
        } 
        emit  depositMoney( msg.sender, amount );
    }

    function withdraw(address to,uint256 amount) public {
        require(deposits[msg.sender] > amount, "The balance amount less than deposit money!");
        deposits[msg.sender]  = deposits[msg.sender] - amount;
        try token.transfer(msg.sender, amount) returns (bool){
            emit tranferSuccess("tranfer success");
        }catch {
            revert("tranfer fail");
        }
        emit WithdrawMoney(to, amount);  
    }    
}