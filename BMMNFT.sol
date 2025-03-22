// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BMMNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;
    uint256 public lockTime; // 全局锁仓时间

    IERC20 public usdt;
    IERC20 public esdt;

    enum NFTType {
        USDT,
        ESDT
    } // 定义NFT类型

    struct NFTAmount {
        address owner; //拥有人
        uint256 token; //tokenId
        uint256 amount; //购买数量
        uint256 createdAt; //购买时间
        uint256 lockTime; // 存储需要锁仓的时间
        NFTType nftType; // 存储NFT类型(0:USDT, 1:ESDT)
    }

    mapping(address => NFTAmount[]) ownerBMMNFT;
    mapping(uint256 => uint256) _tokenLocks;
    mapping(address => bool) private trustedContracts;

    function addTrustedContract(address contractAddress) public onlyOwner {
        trustedContracts[contractAddress] = true;
    }

    function removeTrustedContract(address contractAddress) public onlyOwner {
        trustedContracts[contractAddress] = false;
    }

    function isTrustedContract(
        address contractAddress
    ) public view returns (bool) {
        return trustedContracts[contractAddress];
    }

    event NFTCreated(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount,
        string uri,
        NFTType nftType,
        uint256 createdAt,
        uint256 lockTime
    );
    event NFTTransferred(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event NFTRedeemed(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount,
        NFTType nftType,
        uint256 createdAt
    );

    constructor(
        address initialOwner,
        uint256 _lockTime,
        address _usdtAddress,
        address _esdtAddress
    ) ERC721("BMMNFT", "BMMNFT") Ownable(initialOwner) {
        _nextTokenId = 0;
        lockTime = _lockTime; // 初始化锁仓时间
        usdt = IERC20(_usdtAddress);
        esdt = IERC20(_esdtAddress);
    }

    //change owner
    function changeOwner(address newOner) public onlyOwner{
        _transferOwnership(newOner);
    }

    modifier onlyUnlocked(uint256 tokenId) {
        require(_tokenLocks[tokenId] < block.timestamp, "NFT is locked");
        _;
    }

    function createNFT(
        address to,
        string memory uri,
        uint256 amount,
        NFTType nftType
    ) public returns (uint256, uint256) {
        require(
            msg.sender == owner() || isTrustedContract(msg.sender),
            "Caller is not owner or trusted contract"
        );
        NFTAmount memory nftAmount;
        uint256 _tokenId = safeMint(to, uri);
        nftAmount.owner = to;
        nftAmount.token = _tokenId;
        nftAmount.amount = amount;
        nftAmount.createdAt = block.timestamp;
        nftAmount.lockTime = lockTime;
        nftAmount.nftType = nftType;
        ownerBMMNFT[to].push(nftAmount);
        _tokenLocks[_tokenId] = block.timestamp + lockTime;
        emit NFTCreated(
            to,
            _tokenId,
            amount,
            uri,
            nftType,
            block.timestamp,
            lockTime
        );
        return (_tokenId, amount);
    }

    function safeMint(address to, string memory uri) public returns (uint256) {
        require(
            msg.sender == owner() || isTrustedContract(msg.sender),
            "Caller is not owner or trusted contract"
        );
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return (tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getLockTimestamp(uint256 tokenId) public view returns (uint256) {
        return _tokenLocks[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyUnlocked(tokenId) {
        super.transferFrom(from, to, tokenId);
        emit NFTTransferred(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyUnlocked(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
        emit NFTTransferred(from, to, tokenId);
    }

    function safeTransfer(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public onlyUnlocked(tokenId) {
        super.safeTransferFrom(address(this), to, tokenId, data);
        emit NFTTransferred(address(this), to, tokenId);
    }

    // 添加查询函数
    function getOwnerNFTs(
        address owner
    ) public view returns (NFTAmount[] memory) {
        return ownerBMMNFT[owner];
    }

    // 只有所有者可以修改锁仓时间
    function setLockTime(uint256 _lockTime) public onlyOwner {
        lockTime = _lockTime;
    }

    // 添加赎回函数
    function redeemNFT(uint256 tokenId) public onlyUnlocked(tokenId) {
        require(
            ownerOf(tokenId) == msg.sender,
            "Caller is not the owner of the NFT"
        );

        // 获取NFT信息
        NFTAmount memory nftAmount;
        for (uint256 i = 0; i < ownerBMMNFT[msg.sender].length; i++) {
            if (ownerBMMNFT[msg.sender][i].token == tokenId) {
                nftAmount = ownerBMMNFT[msg.sender][i];
                break;
            }
        }

        // 销毁NFT
        _burn(tokenId);

        // 从ownerBMMNFT中移除NFT信息
        for (uint256 i = 0; i < ownerBMMNFT[msg.sender].length; i++) {
            if (ownerBMMNFT[msg.sender][i].token == tokenId) {
                ownerBMMNFT[msg.sender][i] = ownerBMMNFT[msg.sender][
                    ownerBMMNFT[msg.sender].length - 1
                ];
                ownerBMMNFT[msg.sender].pop();
                break;
            }
        }
        emit NFTRedeemed(
            msg.sender,
            tokenId,
            nftAmount.amount,
            nftAmount.nftType,
            nftAmount.createdAt
        );
    }
}