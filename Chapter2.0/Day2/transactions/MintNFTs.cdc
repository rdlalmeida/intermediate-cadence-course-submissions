// This transaction uses the single Admin resource to mint a couple of NFTs into the various collections
import StandardAdmin from "../contracts/StandardNFTInterface/StandardAdmin.cdc"
import StandardSword from "../contracts/StandardNFTInterface/StandardSword.cdc"
import StandardBow from "../contracts/StandardNFTInterface/StandardBow.cdc"
import StandardShield from "../contracts/StandardNFTInterface/StandardShield.cdc"

transaction(recipient: Address) {
    let swordCollection: &StandardSword.Collection
    let bowCollection: &StandardBow.Collection
    let shieldCollection: &StandardShield.Collection

    let adminMinter: &StandardAdmin.NFTMinter

    prepare(signer: AuthAccount) {
        // Get the references to each Collection
        let userAccount: PublicAccount = getAccount(recipient)

        self.swordCollection = userAccount.getCapability<&StandardSword.Collection>(StandardSword.collectionPublic).borrow() ??
            panic("Account ".concat(recipient.toString()).concat(" does not have a proper Sword Collection set up yet!"))

        self.bowCollection = userAccount.getCapability<&StandardBow.Collection>(StandardBow.collectionPublic).borrow() ??
            panic("Account ".concat(recipient.toString()).concat(" does not have a proper Bow Collection set up yet!"))

        self.shieldCollection = userAccount.getCapability<&StandardShield.Collection>(StandardShield.collectionPublic).borrow() ??
            panic("Account ".concat(recipient.toString()).concat(" does not have a proper Shield Collection set up yet!"))

        // Retrieve the NFT Minter to the internal variable
        self.adminMinter = signer.getCapability<&StandardAdmin.NFTMinter>(StandardAdmin.minterPrivate).borrow() ??
            panic("Account ".concat(signer.address.toString()).concat(" does not have a proper NFT Minter set up in private storage yet!"))

    }

    execute {
        // Mint and deposit a couple of NFT into each Collection
        let sword1: @StandardSword.NFT <- self.adminMinter.mintSword()
        let sword2: @StandardSword.NFT <- self.adminMinter.mintSword()

        self.swordCollection.deposit(token: <- sword1)
        self.swordCollection.deposit(token: <- sword2)

        let bow1: @StandardBow.NFT <- self.adminMinter.mintBow()
        let bow2: @StandardBow.NFT <- self.adminMinter.mintBow()
        let bow3: @StandardBow.NFT <- self.adminMinter.mintBow()

        self.bowCollection.deposit(token: <- bow1)
        self.bowCollection.deposit(token: <- bow2)
        self.bowCollection.deposit(token: <- bow3)

        let shield1: @StandardShield.NFT <- self.adminMinter.mintShield()
        let shield2: @StandardShield.NFT <- self.adminMinter.mintShield()
        let shield3: @StandardShield.NFT <- self.adminMinter.mintShield()

        self.shieldCollection.deposit(token: <- shield1)
        self.shieldCollection.deposit(token: <- shield2)

        // Now, just for shit and giggles,try to store a Shield NFT into the Sword Collection, just to see what happens
        self.swordCollection.deposit(token: <- shield3)
    }
}
 