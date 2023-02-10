import NonFungibleTokenCollection from "../../../../../common_resources/contracts/NonFungibleTokenCollection.cdc"
import NonFungibleTokenSimple from "../../../../../common_resources/contracts/NonFungibleTokenSimple.cdc"
import MyBow from "./MyBow.cdc"
import MyShield from "./MyShield.cdc"
import MySword from "./MySword.cdc"

pub contract MyCollection: NonFungibleTokenCollection {
    pub var totalSupply: UInt64
    
    pub event ContractInitialized()
    pub event Withdraw(id: String, from: Address?)
    pub event Deposit(id: String, to: Address?)

    pub event MyCollectionCreated()
    pub event MintMyNFT(id: String)

    pub let myCollectionStorage: StoragePath
    pub let myCollectionPrivate: PrivatePath

    // Use this interface to add custom functions tailored to this context, or limit the usage of others
    // In this particular case, because I want to store Bow, Shield and Sword NFTs in the same collection, I'm going to add three specific borrow functions,
    // one per NFT type to return. I tried to write it first in a single function, but I'm not sure that is possible. 
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleTokenSimple.NFT)
        pub fun getIDs(): [String]
        pub fun borrowNFT(id: String): &NonFungibleTokenSimple.NFT
        // pub fun borrowBowNFT(id: String): &MyBow.NFT
        // pub fun borrowShieldNFT(id: String): &MyShield.NFT
        // pub fun borrowSwordNFT(id: String): &MySword.NFT
    }

    // Now the main Collection
    pub resource Collection: NonFungibleTokenCollection.Provider, NonFungibleTokenCollection.Receiver, NonFungibleTokenCollection.CollectionPublic, CollectionPublic {
        pub var ownedNFTs: @{String: NonFungibleTokenSimple.NFT}

        pub fun getIDs(): [String] {
            return self.ownedNFTs.keys
        }

        // I antecipate that most of my problems are going to be coming for this deposit function, so go ahead and write it at the top
        // Unlike the other Collections, this one cannot downcast the received NFT, i.e., tokens, by default, are stored as NonFungibleTokenSimple.NFT
        pub fun deposit(token: @NonFungibleTokenSimple.NFT) {
            emit Deposit(id: token.id, to: self.owner!.address)
            self.ownedNFTs[token.id] <-! token
        }

        // // Next, the specific borrow functions
        // pub fun borrowBowNFT(id: String): &MyBow.NFT {
        //     // Check first if anything is in that storage spot
        //     let tokenRef: &NonFungibleTokenSimple.NFT? = &self.ownedNFTs[id] as &NonFungibleTokenSimple.NFT?
        //     if (tokenRef == nil) {
        //         panic("The Collection does not have any NFT with id ".concat(id))
        //     }

        //     // Check if the id is compatible with the NFT to return. The isInstace function should be perfect for this
        //     if (!tokenRef!.isInstace(Type<MyBow.NFT>())) {
        //         panic("The token with id ".concat(id).concat(" is not of the required type: Type<MyBow.NFT>()"))
        //     }

        //     // Seems that everything is in order if the code gets to this point. Downcast and return the reference
        //     return tokenRef as! &MyBow.NFT
            
        // }

        pub fun withdraw(withdrawID: String): @NonFungibleTokenSimple.NFT {
            let token: @NonFungibleTokenSimple.NFT <- self.ownedNFTs.remove(key: withdrawID) ??
                panic("NFT with id ".concat(withdrawID).concat(" does not exist in this collection!"))
            emit Withdraw(id: withdrawID, from: self.owner?.address)
            return <- token
        }

        pub fun borrowNFT(id: String): &NonFungibleTokenSimple.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleTokenSimple.NFT?)!
        }

        init() {
            self.ownedNFTs <- {}
        }

        destroy () {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @Collection {
        let newCollection: @Collection <- create Collection()
        emit MyCollectionCreated()
        return <- newCollection
    }

    init() {
        self.totalSupply = 0
        self.myCollectionStorage = /storage/myCollection
        self.myCollectionPrivate = /private/myCollection

        emit ContractInitialized()
    }
}