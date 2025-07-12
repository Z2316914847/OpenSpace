// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// 在 该挑战 的 Bank 合约基础之上，编写 IBank 接口及BigBank 合约，使其满足 Bank 实现 IBank， BigBank 继承自 Bank ， 同时 BigBank 有附加要求：
//     要求存款金额 >0.001 ether（用modifier权限控制）
//     BigBank 合约支持转移管理员

//     编写一个 Admin 合约， Admin 合约有自己的 Owner ，同时有一个取款函数 adminWithdraw(IBank bank) , 
//     adminWithdraw 中会调用 IBank 接口的 withdraw 方法从而把 bank 合约内的资金转移到 Admin 合约地址。
//     BigBank 和 Admin 合约 部署后，把 BigBank 的管理员转移给 Admin 合约地址，模拟几个用户的存款，然后
//     Admin 合约的Owner地址调用 adminWithdraw(IBank bank) 把 BigBank 的资金转移到 Admin 地址。


//===================================================
//                    IBank接口
//===================================================
interface IBank{
    function saveMoney() external payable;
    function withdraw(uint256 amount) external;
    function getBalance() external view returns (uint256);

}


//===================================================
//                    实现IBank
//===================================================
contract BankUp2 is IBank {
    address owner;   // 设置部署合约的人为管理员
    mapping(address => uint256) public balances;
    address[] public total_top3;

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable {
        // saveMoney();
    }

    // 记录每个地址的存款金额，并排序数组
    function saveMoney() public payable virtual override {
        // 存入金额必须大于0
        require(msg.value > 0,"money must>0");

        // 当msg.value有数据时，会自动将金额存入合约的balance
        // 判断是否为新用户，是新用户则添加到mapping中
        balances[msg.sender] =balances[msg.sender]+ msg.value;

        // 更新前三
        setBalanceTop(msg.sender, balances[msg.sender]);
    }

    // 数组记录存款金额的前 3 名用户
    function setBalanceTop(address addr, uint256 amount) public {
        // 方法二:找出最小索引
        if(total_top3.length < 3) {
            total_top3.push(addr);
            return;
        }
        uint min_index =0; 
        for(uint j=1; j<total_top3.length; j++){
            if (balances[total_top3[min_index]] >balances[total_top3[j]]){
                min_index = j;
            }
        }

        if(amount > balances[total_top3[min_index]]) {
            total_top3[min_index] = addr;
        }

    }

    //获取top3用户地址
    function getBalanceTop() public view returns (address[] memory addr){
        return total_top3;
    }


    /*
    *   仅管理员可以通过该方法提取资金。
    *   改善：假如不是管理员想提取金额，要得到管理员许可
    */ 
    function withdraw(uint256 money) public override {
        require(msg.sender == owner);
        require(money <= address(this).balance);
        payable(owner).transfer(money);
    }

    // 查询合约余额
    function getBalance() public view override  returns (uint256) {
        return address(this).balance;
    }


}

contract BigBank is BankUp2{

    uint256 public Min_money = 0.01 ether;

    event AdminTransferStarted(address, address);

    modifier minMoney{
        require( msg.value > Min_money, "deposit money must>0.001 ether");
        _;
    }

    // 要求存款金额 >0.001 ether（用modifier权限控制）
    function saveMoney() public override payable minMoney{
        balances[msg.sender] =balances[msg.sender]+ msg.value;
        setBalanceTop(msg.sender, balances[msg.sender]);
    }

    // 
    function if_owner()public view returns(address,address){
        return (msg.sender,owner);
    }

    // BigBank 合约支持转移管理员
    function modifyOwner(address newAdmin) public {
        require( msg.sender == owner,"only the previous admin can modify Permissions");
        require(newAdmin != address(0), "Invalid new admin");
        emit AdminTransferStarted(owner, newAdmin);
        owner = newAdmin; // 这里简化处理，没等上一任管理员确认，就更新新管理员，不安全，没有撤会余地。可以加一个确认按钮
    }

    
}

//===================================================
//                    Admin
//===================================================
contract Admin {
    // owner
    address owner;

    event WithdrawalSuccess(address, uint256);
    event WithdrawalFailed(address, string);


    constructor() {
        owner = msg.sender; // 部署时设置owner
    }

    // 取款函数 adminWithdraw(IBank bank)，通过IBank接口调用withdraw函数，从而把Bank中的资金转移到Admin合约中
    function adminWithdraw(IBank bank)public {
        require(address(bank) != address(0), "input vaild address please");
        uint256 balance = bank.getBalance();
        require(balance >0, "balance is zero");
        try bank.withdraw(balance) {
            emit WithdrawalSuccess(address(bank), balance);
        }catch Error(string memory reason) {
            emit WithdrawalFailed(address(bank), reason);
        }catch{
            revert("Withdraw failed (low-level)");
        }
    }
}