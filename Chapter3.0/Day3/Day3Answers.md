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

2a. How do I know if the current iteration is an NFT collection?

Apparently, every developer has created his/her own flavour of Collection instance and connected it to the Public Storage. I was able to retrieve these, filtering out other stuff in that same Storage, by using a <code>if</code> inside the iteration function to filter for AnyResources that follow the NonFungibleToken.CollectionPublic interface. Following this interface assures me that certain functions and variables were implemented in each custom Collection created, and thus is a NFT Collection.

2b. Once I've figured that out, how do I borrow the collection from the account? (Hint: use NonFungibleToken.CollectionPublic)

In this particular case, because each Collection has its own flavour, I have to borrow these as &AnyResources{NonFungibleToken.CollectionPublic}, i.e., I cannot specify the Collection type - that one neccessarily needs to as vague as &AnyResources - only the interface that it should follow, namely, NonFungibleToken.CollectionPublic, which guarantees the presence of the neccessary function needed to confirm that I have a propoer NFT Collection and nothing else.

2c. Once I do borrow it, how do I know the collection is actually a NFT collection, and not a random resource that implements NonFungibleToken.CollectionPublic?

This one is tricky, but in my honest opinion, with the limited options available, I can borrow the Collection (as an &AnyResources), and then use borrowNFT function to get a reference that, if the Collection reference obtained is indeed a NFT Collection, should be a NonFungibleToken.NFT, which confirms that the Collection resource does contains NFTs, therefore is a NFT Collection.

I've created the following script to validate that:
* borrowNFTs.cdc

```cadence
// import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
import NonFungibleToken from 0x1d7e57aa55817448

/*
    This script starts by listing all Collections linked to the Public Storage that follow the NonFungibleToken.CollectionPublic, borrow a reference to it and then
    borrow a NFT from it, using the borrowNFT function that I know exists due to the CollectionPublic interface. From there I can validate if that "thing" that I've
    borrowed is indeed a NonFungibleToken.NFT or something else. At this point I can only guarantee that the stuff that is stored in the Collection are proper
    NFTs that follow the standard. This script returns a dictionary with the type of the Collection as key and either a Reference to a NonFungibleToken.NFT if valid
    one was found or a nil otherwise
*/

pub fun main(user: Address): {Type: &NonFungibleToken.NFT?} {
    let account: PublicAccount = getAccount(user)

    let returnDict: {Type: &NonFungibleToken.NFT?} = {}

    let iterFunction = fun (path: PublicPath, type: Type): Bool {
        if (type.isSubtype(of: Type<Capability<&AnyResource{NonFungibleToken.CollectionPublic}>>())) {
            // If a valid collection reference was found, proceed to get a reference to it and borrow a NFT from it
            let collectionReference: &AnyResource{NonFungibleToken.CollectionPublic} = account.getCapability<&AnyResource{NonFungibleToken.CollectionPublic}>(path).borrow() ??
                panic("Unable to borrow a Collection with type ".concat(type.identifier).concat(" from account ".concat(user.toString())))

            // Use the reference to get the array of NFT ids in the collection
            let NFTids: [UInt64] = collectionReference.getIDs()

            // Check that there's at least one ID, i.e., one NFT in the collection
            if (NFTids.length == 0) {
                // If the collection is still empty, move to the next one
                return true
            }
            else {
                // Borrow the NFT for the first ID in this array and set it in the proper position in the return array
                returnDict[type] = collectionReference.borrowNFT(id: NFTids[0])
            }
        }

        return true
    }

    account.forEachPublic(iterFunction)

    return returnDict
}
```

* Running this with my mainnet Dapper account returns:

![image](https://user-images.githubusercontent.com/39467168/226981493-725017a1-d6c0-4499-8859-1a1310ee6761.png)

Reformating this for easier reading:

Type<Capability<&AnyResource{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.1d7e57aa55817448.MetadataViews.ResolverCollection,A.7ba45bdcac17806a.AnchainUtils.ResolverCollection}>>(): A.f2af175e411dfff8.MetaPanda.NFT(uuid: 189541970, 
id: 3036, 
metadata: A.f2af175e411dfff8.MetaPanda.Metadata(clothesAccessories: "", 
facialAccessories: "Fox mask purple hair", 
facialExpression: "Serious", 
headAccessories: "", 
handAccessories: "Championship Trophy", 
clothesBody: "MPC W Wear", 
background: "D4", 
foreground: "", 
basePanda: "Pandabasic"), 
file: A.7ba45bdcac17806a.AnchainUtils.File(extension: ".png", 
thumbnail: A.1d7e57aa55817448.MetadataViews.IPFSFile(cid: "QmehfYrtExPtBgEDLEbX3qqW7cfWuXHedfk1ddukDZkkfA", 
path: ""))), 
Type<Capability<&AnyResource{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic}>>(): A.e4cf4bdc1751c65d.PackNFT.NFT(uuid: 555455317, 
id: 806797, 
commitHash: "57e4f6e0f321097e9fa8583c29be39e28a94d8a4ebaaf2164e5803c103b0de0a", 
issuer: 0xe4cf4bdc1751c65d), 
Type<Capability<&A.2d4c3caffbeab845.FLOAT.Collection{A.1d7e57aa55817448.NonFungibleToken.Receiver,A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.1d7e57aa55817448.MetadataViews.ResolverCollection,A.2d4c3caffbeab845.FLOAT.CollectionPublic}>>(): A.2d4c3caffbeab845.FLOAT.NFT(uuid: 587085771, 
id: 587085771, 
dateReceived: 1663695335.00000000, 
eventDescription: "Claim this participation NFT to commemorate International NFT Day! \nJoin the celebration on social media by using #NFTDay.", 
eventHost: 0x07ccd4bb872a7790, 
eventId: 583967214, 
eventImage: "bafkreia536gxvuwqp552g3td5cylmhw3f6557dpr6s7dutsksvamovadg4", 
eventName: "International NFT Day 2022", 
originalRecipient: 0x37f3f5b3e0eaf6ca, 
serial: 42334, 
eventsCap: Capability<&A.2d4c3caffbeab845.FLOAT.FLOATEvents{A.2d4c3caffbeab845.FLOAT.FLOATEventsPublic,A.1d7e57aa55817448.MetadataViews.ResolverCollection}>(address: 0x07ccd4bb872a7790, 
path: /public/FLOATEventsPublicPath)), 
Type<Capability<&A.329feb3ab062d289.NFL_NFT.Collection{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.329feb3ab062d289.NFL_NFT.NFL_NFTCollectionPublic}>>(): A.329feb3ab062d289.NFL_NFT.NFT(uuid: 134939960, 
id: 787980, 
setId: 12, 
editionNum: 294), 
Type<Capability<&AnyResource{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.93615d25d14fa337.ChainmonstersRewards.ChainmonstersRewardCollectionPublic,A.1d7e57aa55817448.MetadataViews.ResolverCollection}>>(): A.93615d25d14fa337.ChainmonstersRewards.NFT(uuid: 743860308, 
id: 651957, 
data: A.93615d25d14fa337.ChainmonstersRewards.NFTData(rewardID: 73, 
serialNumber: 3257)), 
Type<Capability<&A.91b4cc10b2aa0e75.AllDaySeasonal.Collection{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.91b4cc10b2aa0e75.AllDaySeasonal.AllDaySeasonalCollectionPublic}>>(): A.91b4cc10b2aa0e75.AllDaySeasonal.NFT(uuid: 447081893, 
id: 447081893, 
editionID: 1), 
Type<Capability<&A.e4cf4bdc1751c65d.AllDay.Collection{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.e4cf4bdc1751c65d.AllDay.MomentNFTCollectionPublic}>>(): A.e4cf4bdc1751c65d.AllDay.NFT(uuid: 179947301, 
id: 2458344, 
editionID: 830, 
serialNumber: 4815, 
mintingDate: 1648524957.00000000), 
Type<Capability<&A.329feb3ab062d289.UFC_NFT.Collection{A.1d7e57aa55817448.NonFungibleToken.CollectionPublic,A.329feb3ab062d289.UFC_NFT.UFC_NFTCollectionPublic}>>(): A.329feb3ab062d289.UFC_NFT.NFT(uuid: 387990195, 
id: 1732000, 
setId: 187, 
editionNum: 29823)

As far as I can confirm, each one of the returned entries are NonFungibleToken.NFTs, though shapped according to the projects that issued them (like FLOATs, Chainmonsters, TopShot, etc). Does this validate that these are NFT Collections? I believe so.
