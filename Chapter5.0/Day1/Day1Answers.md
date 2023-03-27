## Part 1

a) Write your own Fungible Token contract that implements the `FungibleToken` standard on Flow. Name the contract whatever you want. *NOTE: It is okay to find an example implementation online. But that implementation may overcomplicate the solution. So you may want to be careful.*

* I create a token contract - RicardoCoin.cdc - very inspired in the FlowToken.cdc contract:

https://github.com/rdlalmeida/intermediate-cadence-course-submissions/blob/main/Chapter5.0/Day1/contract/RicardoCoin.cdc

b) Inside the contract, define a resource that handles minting. Make it so that only the contract owner can mint tokens.

* Like with already happens with the FlowToken contact, minting in RicardoCoin is done with a Minter Resource that can only be created by an Administrator Resource that lives in the contract deployer's account:

- The Minter Resource
```cadence
pub resource Minter {
    // The amount of tokens that are allowed to be mint
    pub var allowedAmount: UFix64

    /*
        mintTokens

        The function that creates new token, creating them inside a Vault,
        as the usual vessel used for these porposes. Each mint updates the
        total amount of tokens set at the contract level
    */
    pub fun mintTokens(amount: UFix64): @RicardoCoin.Vault {
        pre{
            amount > UFix64(0): "Amount of RicardoCoin to mint must be greater than 0!"
            amount <= self.allowedAmount: "This Minter can only mint up to "
                .concat(self.allowedAmount.toString())
                .concat(" tokens so far. Unable to mint more than this value.")
        }
        // Update the total supply of the contract
        RicardoCoin.totalSupply = RicardoCoin.totalSupply + amount

        // Update the allowed amount in the Minter
        self.allowedAmount = self.allowedAmount - amount

        // Emit the relevant Event
        emit TokensMinted(amount: amount)

        // Return a new Vault with the balance = amount minted. This is how the
        // new tokens are really created
        return <- create RicardoCoin.Vault(balance: amount)
    }

    // Initialize the Minter resource by setting the allowed amount
    init(allowedAmount: UFix64) {
        self.allowedAmount = allowedAmount
    }
}
```

The only way to create a Minter is by executing a function from the Administrator resource:

```cadence
pub resource Administrator {
    /*
        createNewMinter

        Function to create a new Minter resource
    */
    pub fun createNewMinter(allowedAmount: UFix64): @RicardoCoin.Minter {
        // Emit the relevant event
        emit MinterCreated(allowedAmount: allowedAmount)

        // Create and return a Minter resource
        return <- create Minter(allowedAmount: allowedAmount)
    }
}
```

c) You will find that inside your `deposit` function inside the `Vault` resource you have to set the incoming vault's balance to `0.0` before destroying it. Explain why.

This imposition is not set in the FungibleToken.cdc but it is defined in the FlowToken.cdc contract and makes perfect sense. In my opinion, there are two reasons for this:
1. One of the most important things to take into account when dealing with token economics - cryptocurrencies even - is to make sure that token creation happens only at very regulated points and that the total supply is always accounted for. In the deposit function, there is a very brief point where, technically, we duplicate the number of tokens involved in the transaction. After this instruction:

```cadence
self.balance = self.balance + inVault.balance
```
The total supply of RicardoCoin in the universe is, well, wrong, because we've added the incoming vault's balance to the receiver's one, but the tokens are still in the incoming vault. Setting those to 0.0 in the next couple of instructions ensures that the total amount of those tokens in the Universe remains correct.

2. The second reason deals with the `if` condition in the destroy function, namely:

```cadence
destroy() {
    // If the Vault being destroyed has some RicardoCoins still in it for whatever reason
    if (self.balance > 0.0) {
        // Subtract the tokens that are going to be destroyed from the total supply to keep
        // the total balance of RicardoCoins out there correct.
        RicardoCoin.totalSupply = RicardoCoin.totalSupply - self.balance
    }
}
```
At the end of the deposit function, the incoming Vault needs to be destroyed since it is a resource and there's no point in saving it after it has been used. It is a temporary Vault after all. If that vault isn't emptied first, the destroy function is going to subtract its balance from the total supply, which is wrong and its going to mess up the accounting, since that balance has been added to the receiver's balance already. So it is imperative that the balance of the temporary vault is set to 0.0 right after the receiver's balance is adjusted in the deposit function.

## Part 2

a) Write the following transactions:
- MINT: Mint tokens to a recipient.
- SETUP: Properly sets up a vault inside a user's account storage.
- TRANSFER: Allows a user to transfer tokens to a different address.

b) Write the following scripts:
- READ BALANCE: Reads the balance of a user's vault.
- SETUP CORRECTLY?: Returns `true` if the user's vault is set up correctly, and `false` if it's not.
- TOTAL SUPPLY: Returns the total supply of tokens in existence.