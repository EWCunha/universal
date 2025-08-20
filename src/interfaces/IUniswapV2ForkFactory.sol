// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniswapV2Factory} from "@uniswap-v2/contracts/interfaces/IUniswapV2Factory.sol";

interface IUniswapV2ForkFactory is IUniswapV2Factory {
    function feeAmount() external view returns (uint16);
}
