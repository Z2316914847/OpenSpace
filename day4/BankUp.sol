// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// 编写一个 BigBank 合约继承自 Bank,要求:
//     仅 >0.001 ether(用 modifier 权限控制)可以存款
//     把管理员转移给 Admin 合约,Admin 调用 BigBank 的 withdraw().

// 在 该挑战 的 Bank 合约基础之上，编写 IBank 接口及BigBank 合约，使其满足 Bank 实现 IBank， BigBank 继承自 Bank ， 同时 BigBank 有附加要求：
//     要求存款金额 >0.001 ether（用modifier权限控制）
//     BigBank 合约支持转移管理员

//     编写一个 Admin 合约， Admin 合约有自己的 Owner ，同时有一个取款函数 adminWithdraw(IBank bank) , 
//     adminWithdraw 中会调用 IBank 接口的 withdraw 方法从而把 bank 合约内的资金转移到 Admin 合约地址。
//     BigBank 和 Admin 合约 部署后，把 BigBank 的管理员转移给 Admin 合约地址，模拟几个用户的存款，然后
//     Admin 合约的Owner地址调用 adminWithdraw(IBank bank) 把 BigBank 的资金转移到 Admin 地址。

// interface IBank{
// }

contract day4 {
    address owner;   // 设置部署合约的人为管理员
    mapping(address => uint256) public balances;
    address[] public total_top3;

    constructor() payable {
        // 设置部署合约的人为管理员
        owner = msg.sender;
    }

    receive() external payable {
        // saveMeomey();
    }

    // 记录每个地址的存款金额，并排序数组
    function saveMeomey() public payable virtual {
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
        // 方法一
        // uint i = 0;
        // while (i < 3){
        //     if (amount > balances[total_top3[i]]){
        //         address Dropped = total_top3[i];    // 被替换的地址被标记
        //         uint amountDropped = balances[total_top3[i]];   //获取被替换的金额
        //         total_top3[i] = addr;   //新地址被添加到top3里
        //         setBalanceTop(Dropped,amountDropped);
        //         break;
        //     }
        //     i++;
        // }



    }

    //获取top3用户地址
    function getBalanceTop() public view returns (address[] memory addr){
        return total_top3;
    }

    // withdraw() 方法，仅管理员可以通过该方法提取资金。
    // 参数：管理地址，接受地址，接受金额
    function withdraw(address admin, address addr, uint256 money) public{
        // 判断money是不是数字，这里还没做，待会做
        // 判断是不是管理员  普通账户比较

        require(admin == owner,"you dont owner");
        require(money <= address(this).balance,"The withdrawal amount must be less than the balance");
        payable(addr).transfer(money);
    }

    // 查询合约余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 修改该管理员，只有在上一任管理员地址才可以修改权限,addr是下一任管理员地址
    // admin 是管理员地址，admin 准备把权限移交给 addr 地址
    // 有一个问题上一任合约地址，随处可见，那这样写，就没有安全性了，
    function modifyOwner(address admin,address addr) public {
        require( admin == owner,"only the previous admin can modify Permissions");
        owner = addr;
    }

}

contract BigBank is day4{

    // 存款金额必须大于0.001 ether
    modifier saveMeomey_modifier{
        require(msg.value > 0.001 ether,"deposit money must>0.001 ether");
        _;
    }

    // 重写父类方法
    function saveMeomey() public saveMeomey_modifier payable override {
        balances[msg.sender] =balances[msg.sender]+ msg.value;
        setBalanceTop(msg.sender, balances[msg.sender]);
    }
}

contract Admin {
    address owner;

     constructor()  {
        owner = 0xA591DE23ef8245D6B1dbd63dEc1f323cfA3217Ca;
    }

    // 参数adimin管理员地址，addr接受地址，money接受金额
    function withdraw(address admin, address addr,uint256 money) public {
        // BigBank bigBank_address = new BigBank();   每次调用都新创建一个合约，不是上面上面特有的合约，应该用构造函数规定上面特定合约
        // 前端传入地址
        (bool success, ) = owner.call(abi.encodeWithSignature("withdraw(address,address,uint256)", admin, addr, money));
        require(success,"fail");
    }

    // 接受ETh必须
    receive() external payable { }
}