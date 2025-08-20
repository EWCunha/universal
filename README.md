# Universal questions

## #1

An edge case for LayerZero protocol happens when there are two lockbox (`OFTAdapter`) contracts in the cross-chain mesh of an omnichain project. Imagine token `CoolToken` is deployed on 3 chains: two `OFTAdapter`s on chains A and B, and an `OFT` (mint and burn liquidity) on chain C. Let's say Bob wants to transfer `CoolToken` from chain A to chain C. So, tokens are locked on chain A and minted on chain C. The transfer is successful. Now he wants to transfer from chain C to chain B. Tokens are then burned on chain C (tx on chain C successful ✅), but since there is no liquidity on chain B, the transaction on the destination chain will revert and funds will be lost on chain C.

![image](image.png)

## #2

Check `src/UniswapV2Fork.sol`.

