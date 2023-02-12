1. Design your own contracts such that you use at least one access(account) function that gets called in a contract within the same account. Explain why you had to use <code>access(account)</code>.

Okay, so I went on a bit of a tangent, a really long one actually, on this one. I was going through the initial contracts, the Bow, Shield and Sword ones, and realized that we setup a Collection for each one of these tokens. Besides having a lot of repeated contract code, because the NonFungibleToken interface defines the NFT specifications and the Collection specifications, which means that each of the NFT contracts are forced to also define their own Collections.

And so I wondered "Can I split the NonFungibleToken interface into two interfaces, one just for the NFT stuff and the other just for the Collection stuff?", just to avoid all the Collection stuff in the NFT contracts, which immediately raised another question: "Can I store multiple NFT types in one Collection?"

And there I went on my quest to find out... It took me a few days (mostly because I don't have as much free time as during the Beginner's Booth Camp) but the short answer is, Yes, kinda..

It is possible to create a NFT and Collection interfaces in independent files, create the NFT contracts without specifying a Collection in those files and then create a "general" Collection interface that can hold multiple NFT types. That's the good news. The bad news are that, code wise, the savings from not having to set up Collections in the individual contracts are lost by having to define a much more complicated Collection interface and respective implementations.

This is because, in order to save multiple NFT types in one collection, and keep all the deposit and retrieval functionalities as with the simpler implementation, I had to add a whole new layer of mechanics based on Types and getType() and such, as well as a new internal dictionary to keep track of which NFT id corresponds to which type.

The key to achieve this is that, when we deposit, lets say, a Bow.NFT type in a NonFungibleToken.Collection, the deposit function expects a @NonFungibleToken.NFT as input, it does kinda upcast the received token into NonFungibleToken.NFT upon deposit, but internally, in the self.ownedNFTs dictionary, the token maintains the Bow.NFT type!

So I kinda exploited this to create this a single Collection interface that could hold various NFT types... to a degree. I still need to define a priori which Types I'm going to store in there, but there are no limitations to how many.

So here is the code:
I started by spiting the NonFungibleToken interface into a NFT only interface, named NonFungibleTokenSimple:
* NonFungibleTokenSimple.cdc:

```cadence
/*
    This interface implements the rules to define NFTs only. There are no Collections set at this point. These should be set in a different interface
    @rdlalmeida 07/02/2023
*/
pub contract interface NonFungibleTokenSimple {
    // Simple interface to define the NFT resources
    pub resource interface INFT {
        /*
            Require only a unique id for each NFT. Now, here's the thing I need to consider: if I'm going to have different types of NFTs in the same collection, these need to
            have unique ids in that Collection at least. So, how can I enforce this given that these NFTs can be created by multiple independent contracts? Well, as an initial
            approach, why not set the id as a String that is the result of the concatenation of the NFT type (also as a String, duh...) and an uuid, as always? Let's try it
            out and see what happens
        */ 
        pub let id: String

        /*
            To enforce the new id setting, I'm going to add a new function to the interface that essentially builds the ID String as I've defined above. How can I be sure that
            the user implements this function properly? I can't... Just like implementing the original NonFungibleToken interface ensures that an NFT created under it does 
            ensure that the id UInt64 is unique for every NFT created. Developers are free to do whatever they want in that case. Anyone can create a contract that creates all
            NFTs with an id = 666 for all they care. But when they try to deposit these into a NonFungibleToken-based Collection, it blows up after the first deposit because
            dictionaries, which are used to store these NFTs internally, don't like repetitive keys. And the same applies to my case!
        */

        // Function the should be used to produce an unique String ID, ideally by concatenating the NFT type with a uuid value. But ultimately this detail falls on the contract developer.
        pub fun createID(): String
    }

    // And now the resource itself
    pub resource NFT: INFT {
        pub let id: String
        pub fun createID(): String
    }
}
```

The NFT interface is actually quite simple, but the Collection one... not so much...
* NonFungibleTokenCollection.cdc:
```cadence
/*
    This interface complements the NonFungibleTokenSimple in the sense that
    it implements a Collection resource used to store the NFTs defined in
    that other interface. The idea here is to establish Collections that 
    can store different types of NFTs.
    
    @rdlalmeida 07/02/2023
*/

// First main difference: this interface needs to import the Token exclusive one to set up the resources and such. This may be a limiting factor. Or not. We shall see...
import NonFungibleTokenSimple from "./NonFungibleTokenSimple.cdc"

pub contract interface NonFungibleTokenCollection {

    // Total amount of tokens in the collection. As opposed to the original NonFungibleToken,
    // this parameter accounts for all tokens in the collection, potentially from different 
    // types.
    pub var totalSupply: UInt64

    // Event emitted when the NFT contract is initialized
    pub event ContractInitialized()

    // Event for when a token is withdraw. Because I've changed the id type of the base NFT, this function receives a String as an ID now
    pub event Withdraw(id: String, from: Address?)

    // Event for when a token is deposited, with the id switched to a String as before.
    pub event Deposit(id: String, to: Address?)

    // Event for when a given token type was incremented in the Collection's tokenTypeCount
    pub event TokenTypeAdded(tokenType: Type, count: Int)

    // Event for when a given token type was decremented in the Collection's tokenTypeCount
    pub event TokenTypeRemoved(tokenType: Type, count: Int)

    // Event for when a user tries to remove an tokenID from an inexistent tokenType entry
    pub event InexistentTokenType(tokenType: Type)

    // Event for when a user tries to remove an inexistent tokenID from an existent tokenType, i.e., the dictionary entry is there but the corresponding
    // array does not have the tokenID to remove
    pub event InexistentTokenID(tokenType: Type, tokenID: String)

    // Now for the Provider and Receiver interfaces. In this case, they are pretty much the same as the original ones. The deposit and retrieval is type independent, in principle.
    // Time will tell if I'm right
    pub resource interface Provider {
        // Withdraw removes an NFT from the Collection and moves to the caller. NOTE: These functions accept an return an NFT that follows the
        // NonFungibleTokenSimple interface defined before. Because of the new (and slightly more complicated, I have to assume) paradigm, the id used to retrieve/deposit the NFT
        // is now a String that needs to conform to whatever id building rules the contract developer establishes. Hopefully all of this can be abstracted in a Smart Contract
        // to prevent regular users from having to build complex Strings just to retrieve an NFT 
        pub fun withdraw(withdrawID: String): @NonFungibleTokenSimple.NFT {
            post {
                result.id == withdrawID: "The ID of the withdraw token must be the same as the requested ID"
            }
        }
    }

    // Interface to mediate deposits to the Collection
    pub resource interface Receiver {
        // Deposit takes an NFT as an argument as adds it to the Collection. Again, the NFT type does not seems to be relevant so far
        pub fun deposit(token: @NonFungibleTokenSimple.NFT)
    }

    // Now for the main interface
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleTokenSimple.NFT)
        pub fun getIDs(): [String]
        pub fun borrowNFT(id: String): &NonFungibleTokenSimple.NFT
    }

    // Requirements for the concrete resource type, adapted to the new isolate NFT interface, to be declared in the implementing contract
    pub resource Collection: Provider, Receiver, CollectionPublic {
        // Dictionary to hold the NFTs in the Collection, again, with nothing that limits the NFT type so far
        pub var ownedNFTs: @{String: NonFungibleTokenSimple.NFT}

        // This dictionary is going to be used to keep track of how many NFTs exist in the Collection per Type. The dictionary key is the
        // result of token.getType() and the value is an array of Strings that keeps track of the token IDs per token Type
        pub var tokenTypeCount: {Type: [String]}

        // In order to maintain this token type dictionary, I need a set of support functions to create, add and remove elements to it
        // This function adds a tokenID to the tokenType entry array or initializes one with the provided tokenID if it does not exists yet. 
        // This function should be used whenever a token is deposited (added) to the Collection
        pub fun addTokenType(tokenType: Type, tokenId: String)

        // In opposition, this function removes the provided token ID from the associated tokenType entry in the dictionary. If the array value becomes
        // empty, the function removes the entry from the dictionary
        // This function should be called in every withdraw
        pub fun removeTokenType(tokenType: Type, tokenId: String)

        // And the typical function used to get all tokenTypes, a version of the getIDs() one, useful to cycle through all the elements of the Collection
        pub fun getAllTokenTypes(): [Type]

        // And a corresponding function to retrieve the array of tokenIds for a provided tokenType. The output is optional in case the tokeType entry does
        // not exists
        pub fun getAllTokenIDs(tokenType: Type): [String]?

        // Withdraw removes an NFT, regardless of the type, even though it is somewhat explicit in the id to provide
        pub fun withdraw(withdrawID: String): @NonFungibleTokenSimple.NFT

        // Deposit takes an NFT and adds it to the Collection dictionary. Any Cadence developer worth his salt should be able to
        // create logic to add the token into the proper position in the dictionary
        pub fun deposit(token: @NonFungibleTokenSimple.NFT)

        // getIDs returns an array of the IDs that are in the collection. So far is just a simple array with all the NFT types, concatenated with some uuids (hopefully)
        pub fun getIDs(): [String]

        // Returns a borrowed reference to an NFT in the Collection so that the caller can read data and call methods from it
        pub fun borrowNFT(id: String): &NonFungibleTokenSimple.NFT {
            pre {
                self.ownedNFTs[id] != nil: "NFT with id '".concat(id).concat("' does not exists in the Collection!")
            }
        }
    }

    // createEmptyCollection creates an empty Collection and returns it to the caller so that they can own NFTs. Nothing else to add to this one.
    pub fun createEmptyCollection(): @Collection {
        post {
            result.getIDs().length == 0: "The created Collection must be empty! This one has ".concat(result.getIDs().length.toString()).concat(" in it already!")
        }
    }

}
```

Now for the Bow, Shield and Sword contracts, implemented with the simpler NFT interface (which implement the <code>access(account)</code> functions, as requested):
* MyBow.cdc
```cadence
import NonFungibleTokenSimple from "../../../../../common_resources/contracts/NonFungibleTokenSimple.cdc"

pub contract MyBow: NonFungibleTokenSimple {
    pub resource NFT: NonFungibleTokenSimple.INFT {
        pub let id: String
        pub let name: String

        pub fun createID(): String {
            // As expected, for these kinds of NFTs, the id String is going to be a concatenation of the contract type, which is also the NFT type,
            // concatenated with an uuid to ensure uniqueness within this NFT type
            return (self.getType().identifier).concat(self.uuid.toString())
        }

        init() {
            // The NFT is is now obtained with the createID function created above.
            self.name = "Bow"
            self.id = self.createID()
            
        }
    }

    // If all goes well, I can define the minting function just like with the other standardized way, limiting it also to access(account) as before
    access(account) fun createBow(): @NFT {
        return <- create NFT()
    }

    // And its done! This is the reason why I wanted to split the NonFungibleToken contract interface into two, so that I don't need to implement
    // all the remaining crap, which is useless in this context.
    // I have to setup another "extra" contract to setup the Collection but, overall, I only need to implement the Collection stuff in a single contract
    // instead of having to repeat that code in each NFT contract
}
```

* MyShield.cdc
```cadence
import NonFungibleTokenSimple from "../../../../../common_resources/contracts/NonFungibleTokenSimple.cdc"

pub contract MyShield: NonFungibleTokenSimple {
    // This one is just a reply of the Bow.cdc contract. Check that one for detais
    pub resource NFT: NonFungibleTokenSimple.INFT {
        pub let id: String
        pub let name: String

        pub fun createID(): String {
            return (self.getType().identifier).concat(self.uuid.toString())
        }

        init() {
            self.name = "Shield"
            self.id = self.createID()
        }
    }

    access(account) fun createShield(): @NFT {
        return <- create NFT()
    }
}
```

* MySword.cdc
```cadence
import NonFungibleTokenSimple from "../../../../../common_resources/contracts/NonFungibleTokenSimple.cdc"

pub contract MySword: NonFungibleTokenSimple {
    // This one is just a reply of the Bow.cdc contract. Check that one for detais
    pub resource NFT: NonFungibleTokenSimple.INFT {
        pub let id: String
        pub let name: String

        pub fun createID(): String {
            return (self.getType().identifier).concat(self.uuid.toString())
        }

        init() {
            self.name = "Sword"
            self.id = self.createID()
        }
    }

    access(account) fun createSword(): @NFT {
        return <- create NFT()
    }

}
```

The star of this exercise is the implementation of the Collection contract, under the NonFungibleTokenCollection interface. As expected, it is enormous and super complex, just like I like it:

* MyCollection.cdc
```cadence
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

    pub event TokenTypeAdded(tokenType: Type, count: Int)
    pub event TokenTypeRemoved(tokenType: Type, count: Int)
    pub event InexistentTokenType(tokenType: Type)
    pub event InexistentTokenID(tokenType: Type, tokenID: String)

    pub event MyCollectionCreated()
    pub event MintMyNFT(id: String)

    pub let myCollectionStorage: StoragePath
    pub let myCollectionPublic: PublicPath

    // Use this interface to add custom functions tailored to this context, or limit the usage of others
    // In this particular case, because I want to store Bow, Shield and Sword NFTs in the same collection, I'm going to add three specific borrow functions,
    // one per NFT type to return. I tried to write it first in a single function, but I'm not sure that is possible. 
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleTokenSimple.NFT)
        pub fun getIDs(): [String]
        pub fun getAllTokenTypes(): [Type]
        pub fun getAllTokenIDs(tokenType: Type): [String]?
        pub fun borrowNFT(id: String): &NonFungibleTokenSimple.NFT
        pub fun borrowBowNFT(id: String): &MyBow.NFT
        pub fun borrowShieldNFT(id: String): &MyShield.NFT
        pub fun borrowSwordNFT(id: String): &MySword.NFT
    }

    // Now the main Collection
    pub resource Collection: NonFungibleTokenCollection.Provider, NonFungibleTokenCollection.Receiver, NonFungibleTokenCollection.CollectionPublic, CollectionPublic {
        pub var ownedNFTs: @{String: NonFungibleTokenSimple.NFT}
        pub var tokenTypeCount: {Type: [String]}

        // Implement the new set of functions to deal with the tokenType dictionary
        pub fun addTokenType(tokenType: Type, tokenId: String): Void {
            // Check if the entry already exists.
            if (self.tokenTypeCount[tokenType] != nil) {
                // Increment the entry by 1 in this case
                self.tokenTypeCount[tokenType]!.append(tokenId)
                emit TokenTypeAdded(tokenType: tokenType, count: self.tokenTypeCount[tokenType]!.length)
            }
            else {
                // Initialize a new dictionary entry to 1 in this case
                self.tokenTypeCount[tokenType] = [tokenId]
                emit TokenTypeAdded(tokenType: tokenType, count: 1)
            }
        }

        pub fun removeTokenType(tokenType: Type, tokenId: String): Void {
            // In this one, check if the entry already exists first
            if (self.tokenTypeCount[tokenType] == nil) {
                // Emit the corresponding event
                emit InexistentTokenType(tokenType: tokenType)
                // Nothing else to do in this case.
                return
            }
            else {
                // There are some entries in the dictionary. Check if any matches the tokenID to remove
                if (self.tokenTypeCount[tokenType]!.contains(tokenId)) {
                    // Remove the element and emit the event
                    self.tokenTypeCount[tokenType]!.remove(at: self.tokenTypeCount[tokenType]!.firstIndex(of: tokenId)!)

                    // Check if the array for that tokenType became empty after the last remove. If so, remove the dictionary entry too and
                    // emit the Event accordingly
                    if (self.tokenTypeCount[tokenType]!.length == 0) {
                        emit TokenTypeRemoved(tokenType: tokenType, count: 0)

                        // I've only did this branch in order to remove the dictionary entry
                        self.tokenTypeCount.remove(key: tokenType)
                    }
                    else {
                        // In this case, emit the event with the new array size
                        emit TokenTypeRemoved(tokenType: tokenType, count: self.tokenTypeCount[tokenType]!.length)
                    }
                }
                else {
                    // In this case, the tokenType dictionary entry exists but does not have the provided tokenID.
                    // Emit the corresponding event and move on
                    emit InexistentTokenID(tokenType: tokenType, tokenID: tokenId)
                }
            }

        }

        pub fun getAllTokenTypes(): [Type] {
            // This one is easy, just like the getIDs one
            return self.tokenTypeCount.keys
        }

        pub fun getAllTokenIDs(tokenType: Type): [String]? {
            // If the tokenType entry does not exists yet, the function returns a nil instead
            return self.tokenTypeCount[tokenType]
        }

        pub fun getIDs(): [String] {
            return self.ownedNFTs.keys
        }

        // I anticipate that most of my problems are going to be coming for this deposit function, so go ahead and write it at the top
        // Unlike the other Collections, this one cannot downcast the received NFT, i.e., tokens, by default, are stored as NonFungibleTokenSimple.NFT
        pub fun deposit(token: @NonFungibleTokenSimple.NFT) {
            // Start by adding the new type to the tokenTypeCount
            self.addTokenType(tokenType: token.getType(), tokenId: token.id)

            // Every token,regardless of the type, is stored as a NonFungibleTokenSimple.NFT type. I've tested it and this do not removes the
            // underlying, more specific type
            let token: @NonFungibleTokenSimple.NFT <- token
            emit Deposit(id: token.id, to: self.owner!.address)

            // Add it to the main dictionary lastly
            self.ownedNFTs[token.id] <-! token
        }

        // Next, the specific borrow functions
        pub fun borrowBowNFT(id: String): &MyBow.NFT {
            // Check first if anything is in that storage spot
            let tokenOptionalRef: auth &NonFungibleTokenSimple.NFT? = &self.ownedNFTs[id] as auth &NonFungibleTokenSimple.NFT?
            if (tokenOptionalRef == nil) {
                panic("The Collection does not have any Bow NFT with id ".concat(id))
            }

            // Now that I know that there's something there, remove the optional
            let tokenRef: auth &NonFungibleTokenSimple.NFT = tokenOptionalRef!

            // Check if the id is compatible with the NFT to return. The isInstance function should be perfect for this
            if (!tokenRef.isInstance(Type<@MyBow.NFT>())) {
                panic("The token with id ".concat(id).concat(" is not of the required type: ").concat(Type<@MyBow.NFT>().identifier))
            }

            // Seems that everything is in order if the code gets to this point. Downcast and return the reference
            return tokenRef as! &MyBow.NFT
        }

        // Rinse and repeat for the remaining NFT types
        pub fun borrowShieldNFT(id: String): &MyShield.NFT {
            let tokenOptionalRef: auth &NonFungibleTokenSimple.NFT? = &self.ownedNFTs[id] as auth &NonFungibleTokenSimple.NFT?
            if (tokenOptionalRef == nil) {
                panic("The Collection does not have any Shield NFT with id ".concat(id))
            }

            let tokenRef: auth &NonFungibleTokenSimple.NFT = tokenOptionalRef!

            if (!tokenRef.isInstance(Type<@MyShield.NFT>())) {
                panic("The token with id ".concat(id).concat(" is not of the required type: ").concat(Type<@MyShield.NFT>().identifier))
            }

            return tokenRef as! &MyShield.NFT
        }

        pub fun borrowSwordNFT(id: String): &MySword.NFT {
            let tokenOptionalRef: auth &NonFungibleTokenSimple.NFT? = &self.ownedNFTs[id] as auth &NonFungibleTokenSimple.NFT?
            if (tokenOptionalRef == nil) {
                panic("The Collection does not have any Sword NFT with id ".concat(id))
            }

            let tokenRef: auth &NonFungibleTokenSimple.NFT = tokenOptionalRef!

            if (!tokenRef.isInstance(Type<@MySword.NFT>())) {
                panic("The token with id ".concat(id).concat(" is not of the required type: ").concat(Type<@MySword.NFT>().identifier))
            }

            return tokenRef as! &MySword.NFT
        }

        pub fun withdraw(withdrawID: String): @NonFungibleTokenSimple.NFT {
            let token: @NonFungibleTokenSimple.NFT <- self.ownedNFTs.remove(key: withdrawID) ??
                panic("NFT with id ".concat(withdrawID).concat(" does not exist in this collection!"))
            emit Withdraw(id: withdrawID, from: self.owner?.address)

            // Remove the token entry from the tokenTypeCount dictionary too, before returning the token
            self.removeTokenType(tokenType: token.getType(), tokenId: token.id)

            // Return the token
            return <- token
        }

        pub fun borrowNFT(id: String): &NonFungibleTokenSimple.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleTokenSimple.NFT?)!
        }

        init() {
            self.ownedNFTs <- {}
            self.tokenTypeCount = {}
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
        self.myCollectionPublic = /public/myCollection

        emit ContractInitialized()
    }
}
```