import NonFungibleToken from "../../../../../common_resources/contracts/NonFungibleToken.cdc"

pub contract StandardSword: NonFungibleToken {
    pub var totalSupply: UInt64
    pub event ContractInitialized()

    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let collectionStorage: StoragePath
    pub let collectionPublic: PublicPath

    pub event SwordCollectionCreated()

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64
        pub let type: String

        init() {
            self.id = self.uuid
            self.type = "Sword"
        }
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let nftToRemove: @NonFungibleToken.NFT <- self.ownedNFTs.remove(key: withdrawID) ??
                panic("NFT with id ".concat(withdrawID.toString()).concat(" does not exist in this collection"))

                return <- nftToRemove
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            self.ownedNFTs[token.id] <-! token
        }

        init() {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // Use this function to create a Sword NFT
    access(account) fun createSword(): @NFT {
        return <- create NFT()
    }

    pub fun createEmptyCollection(): @Collection {
        let collection: @Collection <- create Collection()
        emit SwordCollectionCreated()
        return <- collection
    }

    init() {
        self.totalSupply = 0
        self.collectionStorage = /storage/standardSwordStorage
        self.collectionPublic = /public/standardSwordStorage
        emit ContractInitialized()

    }
}
