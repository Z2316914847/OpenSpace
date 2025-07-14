// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

/*
  首先代币所有者地址A授权给地址B100个代币，先应该执行approve(),更新 allowances 状态
  transferFrom(),应该加一个被授权的地址，不然不能跟新allowances
*/

contract BaseERC20{
    string public name; 
    string public symbol;   
    uint8 public decimals;   

    uint256 public totalSupply;   

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; // 实现了查询授权额度的功能

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = 'BaseERC20';
        symbol = 'BERC20';
        decimals = 18;
        totalSupply = 100000000;
        balances[msg.sender] = totalSupply;  
    }

    // 允许任何人查看任何地址的 Token 余额（balanceOf）
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // 允许 Token 的所有者将他们的 Token 发送给任何人（transfer）；转帐超出余额时抛出异常(require),并显示错误消息 “ERC20: transfer amount exceeds balance”。
    // 转帐超出余额时抛出异常(require)，异常信息：“ERC20: transfer amount exceeds balance”
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] < _value){
            revert("ERC20: transfer amount exceeds balance");
        } 
        balances[msg.sender]  =balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    // 允许被授权的地址消费他们被授权的 Token 数量（transferFrom）；from:授权地址，to：收账地址
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require( balances[_from]>=_value, "ERC20: transfer amount exceeds allowance" );
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        // 下面这段代码有问题，allowances[_from][_spender]  = allowances[_from][_spender] - _value;
        // allowances[_from][msg.sender]  = allowances[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    // 允许 Token 的所有者批准某个地址消费他们的一部分Token（approve），msg.sender:授权地址，_spender：被授权地址，
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value; 
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    // 允许任何人查看一个地址可以从其它账户中转账的代币数量（allowance）
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        return allowances[_owner][_spender];
    }
}

// 编写一个 TokenBank 合约，可以将自己的 Token 存入到 TokenBank， 和从 TokenBank 取出。
// TokenBank 有两个方法：
//   deposit() : 需要记录每个地址的存入数量；
//   withdraw(): 用户可以提取自己的之前存入的 token。
contract TokenBank{
    string public name; 
    string public symbol;
    uint256 public totalSupply;   
    uint public LESS_MONEY = 0.01 ether;   

    mapping (address => uint256) deposits; 
    event depositMoney( address, uint256 );
    event WithdrawMoney( address, uint256 );


    receive() external payable { }

    modifier lessMoney{
        require (msg.value > LESS_MONEY, " The deposit amount must not be less than 0.01!" );
        _;
    }


    function deposit() public lessMoney payable {
        deposits[msg.sender] = deposits[msg.sender] + msg.value;
        emit  depositMoney( msg.sender, msg.value );
    }

    function withdraw(address to,uint256 amount) public {
        require(deposits[msg.sender] > amount, "The balance amount less than deposit money!");
        deposits[msg.sender]  =deposits[msg.sender] - amount;
        payable(to).transfer(amount);
        emit WithdrawMoney(to, amount);  
    }    
}
