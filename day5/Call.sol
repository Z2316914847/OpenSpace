// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// contract ABIEncoder {
//     uint public number; 
    
//     function encodeUint(uint256 value) public pure returns (bytes memory) {
//         return abi.encode(uint(value));
//     }

//     function encodeMultiple( uint num, string memory text ) public pure returns (bytes memory) {
//        return abi.encode(num, text);
//     }
// }

// contract ABIDecoder {
//     function decodeUint(bytes memory data) public pure returns (uint) {
//         (uint decodedValue) =abi.decode(data, ( uint ));
//         return decodedValue;
//     }

//     function decodeMultiple( bytes memory data ) public pure returns (uint, string memory) {
//         (uint num, string memory text) = abi.decode(data, (uint, string));
//         return (num,text);
//     }
// }


// contract FunctionSelector {
//     uint256 private storedValue;

//     function getValue() public view returns (uint) {
//         return storedValue;
//     }

//     function setValue(uint value) public {
//         storedValue = value;
//     }

//     function getFunctionSelector1() public pure returns (bytes4) {
//         // 返回个体getValue的函数签名、keccak256("getValue(uint)")：返回一个getValue(uint)的hash，这个hash我们称为函数签名，hsh前四个字节称为函数选择器
//         return bytes4(keccak256("getValue()"));
//     }

//     function getFunctionSelector2() public pure returns (bytes4) {
//         // 返回个体setValue的函数签名
//         return bytes4(keccak256("setValue(uint)"));
//     }

// }



// contract DataStorage {
//     string private data;

//     function setData(string memory newData) public {
//         data = newData;
//     }

//     function getData() public view returns (string memory) {
//         return data;
//     }
// }

// contract DataConsumer {
//     address private dataStorageAddress;

//     constructor(address _dataStorageAddress) {
//         dataStorageAddress = _dataStorageAddress;
//     }

//     function getDataByABI() public returns (string memory) {
//         // 签名+编码，编码数据可读性不好，所以要解码，底层调用用编码
//         bytes memory payload = abi.encodeWithSignature("getData()");
//         // 调用函数
//         (bool success, bytes memory data) = dataStorageAddress.call(payload);
//         require(success, "call function failed");
//         return abi.decode(data, (string));
//     }

//     function setDataByABI1(string calldata newData) public returns (bool) {
//         // 补充完整setDataByABI1，使用abi.encodeWithSignature()编码调用setData函数，确保调用能够成功
//         bytes memory payload = abi.encodeWithSignature("setData(string)",newData);
//         (bool success, ) = dataStorageAddress.call(payload);
//         return success;
//     }

//     function setDataByABI2(string calldata newData) public returns (bool) {
//         // 补充完整setDataByABI2，使用abi.encodeWithSelector()编码调用setData函数，确保调用能够成
//         bytes4 selector = bytes4(keccak256("setData(string)"));
//         bytes memory payload = abi.encodeWithSelector(selector,newData);
//         (bool success, ) = dataStorageAddress.call(payload);
//         return success;
//     }

//     function setDataByABI3(string calldata newData) public returns (bool) {
//         // 补充完整setDataByABI3，使用abi.encodeCall()编码调用setData函数，确保调用能够成功
//         bytes memory playload = abi.encode(bytes4(keccak256("setData(string)")), newData);
//         (bool success, ) = dataStorageAddress.call(playload);
//         return success;
//     }
// }


// 补充完整 Caller 合约的 callGetData 方法，使用 staticcall 
//   调用 Callee 合约中 getData 函数，并返回值。当调用失败时，抛出“staticcall function failed”异常。
// 补充完整 Caller 合约 的 sendEther 方法，用于向指定地址发送 Ether。要求：
//   使用 call 方法发送 Ether,如果发送失败，抛出“sendEther failed”异常并回滚交易。如果发送成功，则返回 true
// 补充完整 Caller 合约的 callSetValue 方法，用于设置 Callee 合约的 value 值。要求：
//   使用 call/delegatecall 方法调用用 Callee 的 setValue 方法，并附带 1 Ether
//   如果发送失败，抛出“call/delegatecall function failed”异常并回滚交易。如果发送成功，则返回 true
contract Callee {
     uint256 value;
    function getData() public pure returns (uint256) {
        return 42;
    }
    receive() external payable {}

    function getValue() public view returns (uint256) {
        return value;
    }

    function setValue(uint256 value_) public payable {
        require(msg.value > 0);
        value = value_;
    }

}

contract Caller {
    function callGetData(address callee) public view returns (uint256 number) {
        bytes4 selector = bytes4(keccak256("getData()"));
        // try不能使用低级调用,交易都是编码数据,返回也是编码
        (bool success, bytes memory data) = callee.staticcall(abi.encodeWithSelector(selector));
        require(success, "staticcall function failed");
        return abi.decode(data, (uint256));
    }

    function sendEther(address to, uint256 value) public returns (bool) {
        // 使用 call 发送 ether
        ( bool success, ) = to.call{value:value}(new bytes(0));
        require( success, "sendEther failed" );
        return success;
    }

    function callSetValue(address callee, uint256 value) public returns (bool) {
        (bool success,)= callee.call{value: value}(abi.encodeWithSelector(bytes4(keccak256("setValue(uint256)")), value ));
        require(success, " call function failed ");
    }

    constructor() payable {}

    receive() external payable {}

}

