import ExampleNFTAccess from "../contracts/ExampleNFTAccess.cdc"

transaction(collectionName: String) {
    let admin: &ExampleNFTAccess.Admin

    prepare(signer: AuthAccount) {
        // Borrow the Admin resource from storage
        self.admin = signer.borrow<&ExampleNFTAccess.Admin>(from: ExampleNFTAccess.AdminStorage)!

        // Create and save a new Collection to the user's account
        let newCollection: @ExampleNFTAccess.Collection{ExampleNFTAccess.CollectionPublic} <- ExampleNFTAccess.createEmptyCollection(collectionName: collectionName)

        // Save and link it to the user's account
        signer.save(<- newCollection, to: ExampleNFTAccess.collectionStorage)
        signer.link<&ExampleNFTAccess.Collection{ExampleNFTAccess.CollectionPublic}>(ExampleNFTAccess.collectionPublicStorage, target: ExampleNFTAccess.collectionStorage)
    }

    execute {
    }
}