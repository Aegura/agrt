// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./AGRT.sol";
import "./a1/ISwapRouter02.sol";

contract Exchange {
    address constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    ISwapRouter02 constant uniswapRouter2 =
        ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    AGRT constant esdt = AGRT(0x28741655c578c888Bca330aAe9d7f176DA1346DF);
    address public owner;

    event Debug(string message, uint256 value);
    event swapInfo(address indexed sender,address inToken,uint256 tokenInAmount,address outToken,uint256 tokenOutAmount,address recipient);

    constructor() {
        owner = msg.sender;
    }

    function swapIn(
        address tokenIn,
        address tokenOut,
        uint256 tokenInAmount,
        address recipient
    ) public returns (uint256) {
        uint256 _numTokensAcquired = 0;
        if (tokenIn == USDT_ADDRESS && tokenOut == address(esdt)) {
            //调用人转入
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                tokenInAmount
            );
            uint256 tokenOutAmount = tokenInAmount * 10**12;
            //合约拥有人转入
            TransferHelper.safeTransferFrom(
                tokenOut,
                owner,
                address(this),
                tokenOutAmount 
            );

            //授权转出esdt
            TransferHelper.safeApprove(tokenOut, recipient, tokenOutAmount);
            //转给接收者
            TransferHelper.safeTransfer(tokenOut, recipient, tokenOutAmount);
            //授权转入代币给合约拥有者
            TransferHelper.safeApprove(tokenIn, owner, tokenInAmount);
            //转入给合约者
            TransferHelper.safeTransfer(tokenIn, owner, tokenInAmount);
            _numTokensAcquired = tokenOutAmount;
        } else if (tokenIn == address(esdt) && tokenOut == USDT_ADDRESS) {
            require(tokenInAmount >= 1000000, "value you entered is too small");
            //调用人转入
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                tokenInAmount
            );
            uint256 tokenOutAmount = tokenInAmount / 10**12;
            //合约拥有人转入
            TransferHelper.safeTransferFrom(
                tokenOut,
                owner,
                address(this),
                tokenOutAmount 
            );
            //授权转出esdt
            TransferHelper.safeApprove(tokenOut, recipient, tokenOutAmount);
            //转给接收者
            TransferHelper.safeTransfer(tokenOut, recipient, tokenOutAmount);
            //授权转入代币给合约拥有者
            TransferHelper.safeApprove(tokenIn, owner, tokenInAmount);
            //转入给合约者
            TransferHelper.safeTransfer(tokenIn, owner, tokenInAmount);
            _numTokensAcquired = tokenOutAmount;
        } else {
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                tokenInAmount
            );
            _numTokensAcquired = callUniswap2(
                tokenIn,
                tokenOut,
                tokenInAmount,
                recipient
            );
        }
        //加入兑换事件(兑换代币地址,数量,输出地址和数量)
        emit swapInfo(msg.sender,tokenIn, tokenInAmount, tokenOut, _numTokensAcquired,recipient);
        return _numTokensAcquired;
    }

    function callUniswap2(
        address _tokenIn,
        address _tokenOut,
        uint256 _tokenInAmount,
        address _recipient
    ) private returns (uint256) {
        TransferHelper.safeApprove(
            _tokenIn,
            address(uniswapRouter2),
            _tokenInAmount
        );
        ISwapRouter02.ExactInputSingleParams memory params = IV3SwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: 3000,
                recipient: _recipient,
                amountIn: _tokenInAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        uint256 numTokensAcquired = uniswapRouter2.exactInputSingle(params);
        return numTokensAcquired;
    }
}
