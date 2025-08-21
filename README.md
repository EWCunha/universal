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

## #2 UniswapV2Fork

See `src/UniswapV2Fork.sol`.

