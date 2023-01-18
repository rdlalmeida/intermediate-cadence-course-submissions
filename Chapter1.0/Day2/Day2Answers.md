Q1. In the very last transaction of the Using Private Capabilities section in today's lesson, there was this line:

```cadence
// Borrow the capability
let minter = &ExampleNFT.NFTMinter = minterCapability.borrow() ?? panic("The capability is no longer valid.")
```
Explain in what scenario this would panic.

This code panics if the owner(administrator) of the ExampleNFT.NFTMinter resource decides to invalidate the Capability (unlink it from the private storage path) that was, at some point, deposited by himself to the Minter Proxy source that the current user has access. Once the Capability is unlinked, its path now points to a nil value, which is what it is going to be returned by the borrow above, which in turn triggers the panic statement.

Q2. Explain two reasons why passing around a private capability to a resource you own is different from simply giving users a resource to store in their account.

R1 - By keeping a resource "useless", as the case of the MinterProxy Resource considered which gets its NFT minter initialized as nil, one retains control of who can use the resource as it was intended. If the Capability necessary to make the resource work was kept in a public storage path instead, anyone could generate the missing element. But if it is stored in its private counterpart, only the user that can access this storage can produce the Capability required.

R2 - Storing Capabilities in private storage paths also allows the owner to control future usage of the resource because he's able to revoke its "usefulness" by unlinking the Capability from the private storage path. This type of revoke control can disappear easily if the public storage path is used to link the Capability instead. Any user can borrow it at will and activate as many minting resources (going back to the example considered). True, the owner can unlink it from the public storage path to stop the uncontrolled minting from that point onwards, but he cannot do anything to any resources generated by any user up to there.

Q3. Write (in words) a scenario where you would use private capabilities. It cannot be the same NFT example we saw today.

Humm, though one given that Cadence is all about NFTs...
Imagine a Flow based Hotel. The Hotel itself is a resource, just as every room in it. Rooms can be checked in by a person by associating a certain Room resource to a client (via its name, credit card number, passport number, etc). After successfully checked in, a client controls the room door, namely opening and closing it, by executing the dedicated functions in the resource that he/she has checked in into.
This is made available by the hotel receptionist saving a capability into the room resource that makes the open and close functions available. Once a client checks out, the capability is automatically removed from the checked out Room resource (the check out function deals with this).
This is handy for a case where a client misses the checkout deadline. If the client is still in the room, easy, just call the police or set the heating to max levels to sweat him out of it. If not, by removing the capability, he loses the ability to open the door, even if he still has the Room resource in his possession. A new Room resource can then be easily created by the hotel admin to replace the one lost to that crappy client... unless he really wants his luggage back.

I'm going to create an Hotel with an admin account (this emulates the Hotel administrator), use another account to create the RoomKeyHolder(the Hotel client) and the check in that client in the Hotel, which associates a Room Capability, of a Room resource previously saved and linked to a Private Storage path