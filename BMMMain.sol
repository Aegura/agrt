// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface MyIERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external;
}



interface IBMMNFT {
    enum NFTType { USDT, ESDT } // 定义NFT类型
    
    function createNFT(
        address to, 
        string memory uri, 
        uint256 amount, 
        NFTType nftType
    ) external returns (uint256, uint256);
}


contract BMMMain {
    IBMMNFT public nftContract;
    MyIERC20 public usdt;
    IERC20 public esdt;
    address public owner;
    mapping(address => bool) public withdrawers;

    event Deposited(
        address indexed user,
        uint256 amount,
        uint256 tokenId,
        uint256 value,
        string currency
    );
    event Withdrawn(address indexed withdrawer, uint256 amount, string currency);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyWithdrawer() {
        require(withdrawers[msg.sender], "Not an authorized withdrawer");
        _;
    }

    constructor(address _nftContractAddress, address _usdtAddress, address _esdtAddress,address _owner) {
        nftContract = IBMMNFT(_nftContractAddress);
        usdt = MyIERC20(_usdtAddress);
        esdt = IERC20(_esdtAddress);
        owner = _owner;
        withdrawers[_owner] = true; // 默认合约拥有者为提现者
    }


    // 添加提现者地址
    function addWithdrawer(address _withdrawer) external onlyOwner {
        withdrawers[_withdrawer] = true;
    }

    // 移除提现者地址
    function removeWithdrawer(address _withdrawer) external onlyOwner {
        withdrawers[_withdrawer] = false;
    }

    // 存钱方法（USDT）
    function depositUSDT(uint256 amount,string memory uri) public returns (uint256 tokenId, uint256 value)  {
        require(amount > 0, "Must send some USDT");
        usdt.transferFrom(msg.sender, address(this), amount);
        (tokenId, value) = nftContract.createNFT(
            msg.sender,
            uri,
            amount,
            IBMMNFT.NFTType.USDT
        );
        emit Deposited(msg.sender, amount, tokenId, value, "USDT");
        return (tokenId, value);
    }

    // 存钱方法（ESDT）
    function depositESDT(uint256 amount,string memory uri) public returns (uint256 tokenId, uint256 value) {
        require(amount > 0, "Must send some ESDT");
        require(esdt.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        (tokenId, value) = nftContract.createNFT(
            msg.sender,
            uri,
            amount,
            IBMMNFT.NFTType.ESDT
        );
        emit Deposited(msg.sender, amount, tokenId, value, "ESDT");
        return (tokenId, value);
    }

    // 提现方法（USDT）
    function withdrawUSDT(uint256 amount) external onlyWithdrawer {
        require(amount <= usdt.balanceOf(address(this)), "Insufficient balance");
        usdt.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, "USDT");
    }

    // 提现方法（ESDT）
    function withdrawESDT(uint256 amount) external onlyWithdrawer {
        require(amount <= esdt.balanceOf(address(this)), "Insufficient balance");
        require(esdt.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount, "ESDT");
    }

    // 获取合约余额（USDT）
    function getBalanceUSDT() external view returns (uint256) {
        return usdt.balanceOf(address(this));
    }

    // 获取合约余额（ESDT）
    function getBalanceESDT() external view returns (uint256) {
        return esdt.balanceOf(address(this));
    }
}