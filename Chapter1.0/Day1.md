I had to change a few things in the Record contract to make it work as intended.
Here's the revised Record contract:
```cadence
```

Q1.

createCollection.cdc:
```cadence
import Record from "../contracts/Record.cdc"
import NonFungibleToken from "../../../common_resources/contracts/NonFungibleToken.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Before saving the new collection, retrieve any stuff that might be still stored in the path to ensure that the save goes well
        // NOTE: If a valid collection already exists in this path, its going to get smoked, along with any NFTs in it. This is only advisable
        // for this training stuff (This allows me to change the Collection parameters in the contract and re test the whole thing with minimal hassle)
        signer.unlink(Record.CollectionPublicPath)
        let randomResource: @AnyResource <- signer.load<@AnyResource>(from: Record.CollectionStoragePath)
        destroy randomResource

        // Storage is clean again. Carry on

        // Create the collection. Force cast it to the desired type since the function returns a NonFungibleToken.CollectionPublic as default
        let myCollection: @Record.Collection <- Record.createEmptyCollection()

        log("Collection created for user ".concat(signer.address.toString()))

        // Store the created resource into storage
        signer.save(<- myCollection, to: Record.CollectionStoragePath)

        log("Saved a collection to ".concat(Record.CollectionStoragePath.toString()))

        // Link it to the public path too
        signer.link<&Record.Collection{Record.CollectionPublic}>(Record.CollectionPublicPath, target: Record.CollectionStoragePath)

        log("Collection linked to the public path at ".concat(Record.CollectionPublicPath.toString()).concat(" for user ").concat(signer.address.toString()))
    }

    execute {

    }
}
```

Execution:
![image](https://user-images.githubusercontent.com/39467168/211902265-2307b03d-ba15-4e11-90cb-60c0fb5cf5ac.png)

Q2.

mintNFTs.cdc
```cadence
import Record from "../contracts/Record.cdc"
import NonFungibleToken from "../../../common_resources/contracts/NonFungibleToken.cdc"

transaction(recipient: Address) {
    prepare(signer: AuthAccount) {
        // Retrieve the Minter from Storage
        let minter: &Record.Minter = signer.borrow<&Record.Minter>(from: Record.MinterStoragePath) ??
            panic("User ".concat(signer.address.toString()).concat(" does not has a Minter configured!"))

        // Mint the NFTs and deposit them in the user's collection
        // Get a reference to their collection first
        let recipientCollection: &Record.Collection{Record.CollectionPublic} = 
            getAccount(recipient).getCapability(Record.CollectionPublicPath).borrow<&Record.Collection{Record.CollectionPublic}>() ??
                panic("User ".concat(recipient.toString()).concat(" does not has a collection configured yet!"))

        // Mint and save the NFTs into the collection
        // NFT #1
        recipientCollection.deposit(token: <- minter.createRecord(songName: "Sympathy for the Devil"))

        // NFT #2
        recipientCollection.deposit(token: <- minter.createRecord(songName: "Bodysnatchers"))

        // NFT #3
        recipientCollection.deposit(token: <- minter.createRecord(songName: "I Might Be Wrong"))
    }

    execute {

    }
}
```

Execution:
![image](https://user-images.githubusercontent.com/39467168/211902512-8d918ec7-d682-40e0-a37a-f2518bb3b0b7.png)
