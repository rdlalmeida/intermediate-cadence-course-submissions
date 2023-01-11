I had to change a few things in the Record contract to make it work as intended.
Here's the revised Record contract:
```cadence
```

Q1. Write a transaction to save a @Record.Collection to the signer's account, making sure to link the appropriate interfaces to the public path.

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

Q2. Write a transaction to mint some @Record.NFTs to the user's @Record.Collection

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

Q3. Write a script to return an array of all the user's &Record.NFT? in their @Record.Collection

getAllRecords.cdc:
```cadence
import Record from "../contracts/Record.cdc"

pub fun main(userAddress: Address) {
    // Start by retrieving the user's Collection (as a reference)
    let userCollection: &Record.Collection{Record.CollectionPublic} = 
        getAccount(userAddress).getCapability(Record.CollectionPublicPath).borrow<&Record.Collection{Record.CollectionPublic}>() ??
            panic("User ".concat(userAddress.toString()).concat(" does not have a Record.Collection configured yet!"))

    // Then use the collection to retrieve the IDs of all NFTs stored in it, as an array
    let collectionIDs: [UInt64] = userCollection.getIDs()

    // Use a for loop to cycle through all IDs retrieved above and use the borrowRecordNFT function to get a reference to the NFT with that ID
    var currentNFTRef: &Record.NFT? = nil
    for id in collectionIDs {
        currentNFTRef = userCollection.borrowRecordNFT(id: id)

        log("Record NFT with id = ".concat(id.toString()).concat(" contains the song: ".concat(currentNFTRef?.songName!)))
    }
}
```

Execution:

![image](https://user-images.githubusercontent.com/39467168/211922155-465c8364-f0c8-4c7c-9aba-0973aaa044fe.png)

Q4. Write a transaction to save a @Artist.Profile to the signer's account, making sure to link it to the public so we can read it

createArtistProfile.cdc

```cadence
import Artist from "../contracts/Artist.cdc"
import Record from "../contracts/Record.cdc"

transaction(artistName: String) {
    prepare(signer: AuthAccount) {
        // Retrieve a capability to an existing collection from the address provided, since I need one to create the Profile
        let collectionCapability: Capability<&Record.Collection{Record.CollectionPublic}> = 
            signer.getCapability<&Record.Collection{Record.CollectionPublic}>(Record.CollectionPublicPath)

        // Create the Profile resource
        let artistProfile: @Artist.Profile <- Artist.createProfile(name: artistName, recordCollection: collectionCapability)

        // Save the profile to storage
        signer.save(<- artistProfile, to: Artist.profileStoragePath)

        // And link it
        signer.link<&Artist.Profile>(Artist.profilePublicPath, target: Artist.profileStoragePath)
    }

    execute {

    }
}
```

Execution:
![image](https://user-images.githubusercontent.com/39467168/211931783-32682b08-de89-44df-b393-fbf2c3949d69.png)

Q5. Write a script to fetch a user's &Artist.Profile, borrow their recordCollection, and return an array of all the user's &Record.NFT? in their @Record.Collection from the recordCollection

getArtistRecords.cdc
```cadence
import Artist from "../contracts/Artist.cdc"
import Record from "../contracts/Record.cdc"

pub fun main(user: Address) {
    // Start by retrieving a reference to the Artist Profile from the user's address
    let artistProfile: &Artist.Profile = getAccount(user).getCapability(Artist.profilePublicPath).borrow<&Artist.Profile>() ??
        panic("User ".concat(user.toString()).concat(" does not have a valid artist profile configured yet!"))
    
    // Use the Capability stored in the artistProfile to get a reference to its collection
    let artistCollectionRef: &Record.Collection{Record.CollectionPublic} = 
        artistProfile.recordCollection.borrow() ??
            panic("Artist Profile with name ".concat(artistProfile.name).concat("does not have a proper Capability configured yet!"))

    // Repeat the same steps as with the getAllRecords.cdc script
    let nftIDs: [UInt64] = artistCollectionRef.getIDs()

    var tempNFTRef: &Record.NFT? = nil

    log("Artist Profile named ".concat(artistProfile.name).concat(" has the following Record NFTs in its Collection: "))
    for id in nftIDs {
        tempNFTRef = artistCollectionRef.borrowRecordNFT(id: id)!

        log("Record NFT id = ".concat(tempNFTRef!.id.toString()).concat(", song name = ".concat(tempNFTRef!.songName)))
    }
}
```

Execution:
![image](https://user-images.githubusercontent.com/39467168/211935154-c8699371-55a1-4275-95fe-f234dfab35b2.png)

Q6. Write a transaction to unlink a user's @Record.Collection from the public path


