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


A few questions will arise:

How do I know if the current iteration is an NFT collection?
Once I've figured that out, how do I borrow the collection from the account? (Hint: use NonFungibleToken.CollectionPublic)
Once I do borrow it, how do I know the collection is actually a NFT collection, and not a random resource that implements NonFungibleToken.CollectionPublic?