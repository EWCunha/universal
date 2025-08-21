# Universal questions

## #1 LayerZero: dual-lockbox liquidity trap

### Scenario

An edge case in LayerZero arises when an omnichain token uses two lockbox contracts (`OFTAdapter`) in its cross-chain mesh. Suppose `CoolToken` spans three chains:

Chain A: `OFTAdapter` (lockbox/escrow)

Chain B: `OFTAdapter` (lockbox/escrow)

Chain C: `OFT` (mint/burn)

A → C: Bob sends tokens from A to C. Tokens are locked on A and minted on C. ✅ Works.

C → B: Bob now sends from C to B. Tokens are burned on C (tx succeeds ✅), but the destination on B is a lockbox with no liquidity to release. The destination tx reverts, and Bob’s tokens are effectively stuck until liquidity is added and the message is retried.

![image](image.png)

### Why it happens

A lockbox (`OFTAdapter`) must hold escrowed tokens to release on inbound transfers. With more than one lockbox in the mesh, some routes will end at a lockbox that hasn’t been pre-funded, causing destination failure after a successful burn on the source.

### Solution

Prefer no lockboxes: Use `OFT` (mint/burn) on all chains to avoid liquidity dependencies.

If a lockbox is required: Use exactly one lockbox in the entire mesh and allow issuance only on the lockbox’s chain. All other chains should be mint/burn. This guarantees the destination is never an un-funded lockbox.

## #2 UniswapV2Fork: fee denominator bug → pool drain

See `src/UniswapV2Fork.sol`.

### How to reproduce

Run the tests and watch the logs:

```
forge test -vv
```

### Root cause

In `UniswapV2Fork.sol` [line 262](https://github.com/EWCunha/universal/blob/00b6161c7ed87f044021c03151bb4b36e6943e11/src/UniswapV2Fork.sol#L262), the code uses `1000` as the fee denominator while the protocol’s fee is configured in basis points (`16/10000`, i.e., 0.16%). Using `1000` breaks the constant-product invariant ($x \cdot y \ge k$) by over-crediting swaps, enabling a drain. Standard Uniswap v2 uses 0.3% (`3/1000`) and a 1000-based denominator; if you express fees in bps (like `16/10000`), the denominator must be `10000` consistently.

### Fix

Replace the hardcoded denominator with a constant that matches the chosen fee scale, e.g.:

```solidity
uint256 constant FEE_BPS = 16;       // 0.16%
uint256 constant BPS_DENOMINATOR = 10_000; // Use BPS_DENOMINATOR everywhere the fee is applied
```

Ensure every swap calculation uses the same denominator; re-run `forge test -vv`. The test will fail, which means the fix was effective.


