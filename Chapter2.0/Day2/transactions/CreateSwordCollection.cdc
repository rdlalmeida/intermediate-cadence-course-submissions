import StandardShield from "../contracts/StandardNFTInterface/StandardSword.cdc"

transaction() {
    let randomCollection: @AnyResource <- signer.load<@AnyResource>(from: StandardSword.collectionStorage)
    destroy randomCollection
    signer.unlink(StandardSword.collectionPublic)

    let collection: @StandardSword.Collection <- StandardSword.createEmptyCollection()
    signer.save(<- collection, to: StandardSword.collectionStorage)
    signer.link<&StandardSword.Collection>(StandardSword.collectionPublic, target: StandardSword.collectionStorage)
}

execute {

}