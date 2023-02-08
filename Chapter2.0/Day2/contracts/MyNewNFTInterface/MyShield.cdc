import NonFungibleTokenSimple from "../../../../../common_resources/contracts/NonFungibleTokenSimple.cdc"

pub contract Shield: NonFungibleTokenSimple {
    // This one is just a reply of the Bow.cdc contract. Check that one for detais
    pub resource NFT: NonFungibleTokenSimple.INFT {
        pub let id: String

        pub fun createID(): String {
            return (self.getType().identifier).concat(self.uuid.toString())
        }

        init() {
            self.id = self.createID()
        }
    }

    access(account) fun createShield(): @NFT {
        return <- create NFT()
    }
}