// import NonFungibleToken from 0xNFTADDRESS
// import TopShot from 0xTOPSHOTADDRESS
// import MetadataViews from 0xMETADATAVIEWSADDRESS

import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
import TopShot from "../../../../common_resources/contracts/TopShot.cdc"
import MetadataViews from "../../../../common_resources/contracts/MetadataViews.cdc"

// This transaction sets up an account to use Top Shot
// by storing an empty moment collection and creating
// a public capability for it
transaction {

    prepare(acct: AuthAccount) {

        // First, check to see if a moment collection already exists
        if acct.borrow<&TopShot.Collection>(from: /storage/MomentCollection) == nil {

            // create a new TopShot Collection
            let collection: @TopShot.Collection <- TopShot.createEmptyCollection() as! @TopShot.Collection

            // Put the new Collection in storage
            acct.save(<-collection, to: /storage/MomentCollection)

            // create a public capability for the collection
            acct.link<&{NonFungibleToken.CollectionPublic, TopShot.MomentCollectionPublic, MetadataViews.ResolverCollection}>(/public/MomentCollection, target: /storage/MomentCollection)
        }
    }
}
 