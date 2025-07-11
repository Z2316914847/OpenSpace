// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// Bank升级
//     编写一个 BigBank 合约继承自 Bank,要求:
//     仅 >0.001 ether(用 modifier 权限控制)可以存款
//     把管理员转移给 Admin 合约,Admin 调用 BigBank 的 withdraw().
contract BankUp{
    address owner;   // 设置部署合约的人为管理员
    mapping(address => uint256) public balances;
    address[] public total_top3;

    constructor() payable {
        // 设置部署合约的人为管理员
        owner = msg.sender;
    }

    receive() external payable {
        saveMeomey();
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
    function withdraw(address addr,uint256 money) public {
        // 判断money是不是数字，这里还没做，待会做
        // 判断是否是管理员  普通账户比较
        require(addr == owner,"you dont owner");
        require(money <= address(this).balance);
        payable(msg.sender).transfer(money);
    }

    // 查询合约余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 修改该管理员，只有在Bank合约才可以修改权限
    function modifyOwner(address addr) public  {
        require( msg.sender == owner,"only the previous admin can modify Permissions");
        owner = addr;
    }

}

contract BigBank is BankUp{

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

    // function modifyOwner(address addr) public {
    //     require( msg.sender == owner,"only the previous admin can modify Permissions");
    //     owner = addr;
    // }
}

contract Admin {
    address owner;

    // 调用 BigBank 的 withdraw()
    function withdraw(address addr,uint256 money) public {
        BigBank bigBank_address = new BigBank();
        bigBank_address.withdraw(addr,money);
    }

    
}
