import ExampleNFTAccess from "../contracts/ExampleNFTAccess.cdc"

transaction(user: Address) {
    let admin: &ExampleNFTAccess.Admin
    let userCollection: &ExampleNFTAccess.Collection{ExampleNFTAccess.CollectionPublic}
    prepare(signer: AuthAccount) {
        // In this case the collection was created and linked by a different user than the admin one. 
        // Assume its the emulator-account and the user is, like, account01
        // Borrow a reference for the admin reference from the signer account (this has to be the emulator-account)
        self.admin = signer.borrow<&ExampleNFTAccess.Admin>(from: ExampleNFTAccess.AdminStorage) ??
            panic("Unable to find a valid Admin resource in account ".concat(signer.address.toString()))

        // Use the prepare phase to borrow a reference to the user's collection, which should have been publicly linked before
        self.userCollection = 
            getAccount(user).getCapability<&ExampleNFTAccess.Collection{ExampleNFTAccess.CollectionPublic}>(ExampleNFTAccess.collectionPublicStorage)
            .borrow() ?? panic("Unable to retrive a Collection reference for account ".concat(user.toString()))
    }

    execute {
        // By default,the collection is unlocked. Check it
        log("Step 1: The collection is still unlocked. Lets try to withdraw a NFT from it...")
        var message: String = self.userCollection.withdraw(withdrawID: 1)
        log("Response: ".concat(message))

        // Cool, all works. Locking the collection now
        log("Locking collection...")
        self.admin.lockUserCollection(collection: self.userCollection)

        // Lets checked. Lets withdraw the same NFT again
        log("Step 2: The collection is now locked. Trying to withdraw a NFT from a locked collection...")
        message = self.userCollection.withdraw(withdrawID: 1)
        log("Response: ".concat(message))

        // Awesome. Unlock the damn thing again and withdraw the NFT again just to be sure
        log("Unlocking collection...")
        self.admin.unlockUserCollection(collection: self.userCollection)

        log("Step 3: Collection unlocked again. Lets withdraw the damn NFT again.")
        message = self.userCollection.withdraw(withdrawID: 1)
        log("Response: ".concat(message))        
    }

}
 