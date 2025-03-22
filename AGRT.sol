// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AGRT is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("AGRT", "AGRT")
        Ownable(initialOwner)
    {}

    //change owner
    function changeOwner(address newOner) public onlyOwner{
        _transferOwnership(newOner);
    }
   

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // 新的转账方法，接受一个额外的参数
    function transferWithExtraData(address to, uint256 amount, string memory extraData) public returns (bool) {
        // 调用原来的 transfer 方法
        bool success = transfer(to, amount);
        require(success, "Transfer failed");
        // 处理额外的数据（这里我们只是简单地记录事件）
        emit TransferWithExtraData(msg.sender, to, amount, extraData);
        return true;
    }
    // 记录带有额外数据的转账事件
    event TransferWithExtraData(address indexed from, address indexed to, uint256 value, string extraData);
}