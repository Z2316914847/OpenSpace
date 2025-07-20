安装wsl->foundry

构建项目：
    1.forge init 项目名
    2.cd 项目名:因为要在对应项目下编译
编译项目
    1.forge build
        遇到错误：Failed to install Solc 0.8.30: error sending request for 
            url (https://binaries.soliditylang.org/linux-amd64/list.json) 
        因为网络问题导致编译失败，手动配置Solc 0.8.30
            1.# 创建目标目录:mkdir -p ~/.svm/0.8.30
            2.# 从 GitHub 官方发布下载:wget https://github.com/ethereum/
              solidity/releases/download/v0.8.30/solc-static-linux -O ~/.svm/0.8.30/solc-0.8.30
            3.# 设置可执行权限:chmod +x ~/.svm/0.8.30/solc-0.8.30
            4.# 验证安装:~/.svm/0.8.30/solc-0.8.30 --version # 应该输出: 0.
              8.30+commit.1abaa4ba
            5.启动cursor：cursor .
获取节点和环境：
    1.当前项目下：anvil
运行测试用例
    1.运行所有测试用例：forge test
    2.运行特定测试用例：forge test -m test/Counter.t.sol
    3.运行特定测试函数：forge test -m "test_Increment"








