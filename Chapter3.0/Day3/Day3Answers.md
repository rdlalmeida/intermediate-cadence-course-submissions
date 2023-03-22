1. Take the script that we made in today's lesson to iterate over a user's storage paths and get all their NFT ids. Run that script on Mainnet with your address and see what it returns

* getNFTids.cdc
```cadence
// import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
import NonFungibleToken from 0x1d7e57aa55817448

pub fun main(user: Address): {Type: [UInt64]} {
    let answer: {Type: [UInt64]} = {}
    let authAccount: AuthAccount = getAuthAccount(user)

    let iterFunction = fun (path: StoragePath, type: Type): Bool {
        if (type.isSubtype(of: Type<@NonFungibleToken.Collection>())) {
            // If an element of the desired type is found
            // Borrow the respective collection resource and extract all the ids
            let collection: &NonFungibleToken.Collection = authAccount.borrow<&NonFungibleToken.Collection>(from: path)!
            let collectionIDs: [UInt64] = collection.getIDs()
            answer[type] = collectionIDs
        }

        // Run this function until all storage paths are exhausted
        return true
    }

    authAccount.forEachStored(iterFunction)

    return answer
}
```

* Running it with my Dapper mainnet account returns, essentially, how much money I've wasted on NFTs in the last couple of years...

![image](https://user-images.githubusercontent.com/39467168/226680591-4cee0ea9-4d8c-45f8-ac08-54b773acac25.png)

2. Take the script that we made in today's lesson to iterate over a user's storage paths and get all their NFT ids. Change this script to instead iterate public paths. 

* Before trying to answer these questions, I wrote a script to profile what I have in my public storage for my Dapper mainnet account using the concepts discussed thus far:

profilePublicStorage.cdc:

```cadence
/*
    Script to profile the Public Storage by producing a dictionary with the PublicPath as keys and the types stored there (as Capabilities) as values
*/
// import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
import NonFungibleToken from 0x1d7e57aa55817448


pub fun main(user: Address): {PublicPath: Type} {
    let account: PublicAccount = getAccount(user)

    let returnDict: {PublicPath: Type} = {}

    let iterFunction = fun (path: PublicPath, type: Type): Bool {
        // Store the entry to the return dictionary if it is a subtype of the NonFungibleToken.Collection
        if (type.isSubtype(of: Type<Capability<&AnyResource{NonFungibleToken.CollectionPublic}>>())) {
            returnDict[path] = type
        }

        return true
    }

    // Run the thing
    account.forEachPublic(iterFunction)

    return returnDict
}
```

Running it yields:

![image](https://user-images.githubusercontent.com/39467168/226700908-24027f2e-5b14-4b2e-8837-089985aad02b.png)

Here repeated after formating this for easier reading:

/public/PackNFTCollectionPub: Type<Capability<&AnyResource{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic}>>(), 
/public/AllDayNFTCollection: Type<Capability<&A.e4cf4bdc1751c65d.AllDay.Collection{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.e4cf4bdc1751c65d.AllDay.MomentNFTCollectionPublic}>>(), 
/public/UFC_NFTCollection: Type<Capability<&A.329feb3ab062d289.UFC_NFT.Collection{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.329feb3ab062d289.UFC_NFT.UFC_NFTCollectionPublic}>>(), 
/public/NFL_NFTCollection: Type<Capability<&A.329feb3ab062d289.NFL_NFT.Collection{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.329feb3ab062d289.NFL_NFT.NFL_NFTCollectionPublic}>>(), 
/public/ChainmonstersRewardCollection: Type<Capability<&AnyResource{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.93615d25d14fa337.ChainmonstersRewards.ChainmonstersRewardCollectionPublic,A.1d7e57aa55817448.MetadataViews.ResolverCollection}>>(), 
/public/MetaPandaCollection: Type<Capability<&AnyResource{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.1d7e57aa55817448.MetadataViews.ResolverCollection,A.7ba45bdcac17806a.AnchainUtils.ResolverCollection}>>(), 
/public/AllDaySeasonalCollection: Type<Capability<&A.91b4cc10b2aa0e75.AllDaySeasonal.Collection{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.91b4cc10b2aa0e75.AllDaySeasonal.AllDaySeasonalCollectionPublic}>>(), 
/public/FLOATCollectionPublicPath: Type<Capability<&A.2d4c3caffbeab845.FLOAT.Collection{A.1d7e57aa55817448.NonFungibleToken.Receiver,A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.1d7e57aa55817448.MetadataViews.ResolverCollection,A.2d4c3caffbeab845.FLOAT.CollectionPublic}>>()

* How do I know if the current iteration is an NFT collection?

Apparently, every developer has created his/her own flavour of Collection instance and connected it to the Public Storage. I was able to retrieve these, filtering out other stuff in that same Storage, by using a <code>if</code> inside the iteration function to filter for AnyResources that follow the NonFungibleToken.CollectionPublic interface. Following this interface assures me that certain functions and variables were implemented in each custom Collection created, and thus is a NFT Collection.

Once I've figured that out, how do I borrow the collection from the account? (Hint: use NonFungibleToken.CollectionPublic)


Once I do borrow it, how do I know the collection is actually a NFT collection, and not a random resource that implements NonFungibleToken.CollectionPublic?
