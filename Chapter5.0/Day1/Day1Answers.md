## Part 1

a) Write your own Fungible Token contract that implements the `FungibleToken` standard on Flow. Name the contract whatever you want. *NOTE: It is okay to find an example implementation online. But that implementation may overcomplicate the solution. So you may want to be careful.*

* I create a token contract - RicardoCoin.cdc - very inspired in the FlowToken.cdc contract:


b) Inside the contract, define a resource that handles minting. Make it so that only the contract owner can mint tokens.

c) You will find that inside your `deposit` function inside the `Vault` resource you have to set the incoming vault's balance to `0.0` before destroying it. Explain why.