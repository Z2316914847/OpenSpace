// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

// 这个是文件是其他正确的，其他三个都有瑕疵
contract BaseERC20 {
    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint256 public totalSupply;   // 设置供应量归部署者所有

    mapping (address => uint256) balances;  // 实现了查询授权额度的功能

    mapping (address => mapping (address => uint256)) allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor()  {
        name = 'BaseERC20';
        symbol = 'BERC20';
        decimals = 18;
        totalSupply = 100000000;
        balances[msg.sender] = totalSupply;
    }

    // 允许任何一个人查看某地址金额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // 从调用者地址想目标地址转账
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] < _value){
            revert("ERC20: transfer amount exceeds balance");
        } 
        balances[msg.sender]  =balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;
    }

    // 从 from地址向to地址转账(需要授权),转账者的地址其实是授权者地址
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // 判断地址和value输入是否符合要求
        require(_from!=address(0), "approve address to the zero address");
        require(_to!=address(0), "receive address to the zero address");
        require(_value>0,"ERC20: approve value less than zero");
        // 查询被授权人 spender 余额>value
        uint256  approveBalance= allowance(_from, msg.sender);
        require(approveBalance>_value,"ERC20: approve value greater than balance");
        // 授权的记录更新 + balances更新转账
        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _value;
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    // 允许 spender多次从调用者地址提款 ：允许 Token 的所有者批准某个地址消费他们的一部分Token（approve）
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // 授权地址要有效
        require(_spender!=address(0), "ERC20: approve to the zero address");
        // 授权value额度必须大于0
        require(_value>0,"ERC20: approve value less than zero");
        // 授权记录更新
        allowances[msg.sender][_spender] = allowances[msg.sender][_spender] + _value;
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    // 查询owner授权给 spender地址额度
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        return allowances[_owner][_spender];
    }
}


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