1. Explain the self.owner!.address pattern.

The <code>self</code> part relates to the resource in question, where the function may be written into. <code>owner</code> is an implicit field that, according to the documentation, is of the PublicAccount? type. <code>address</code> is a subfield of the <code>owner</code> and it is of the <code>Address</code> type. Since the owner is a PublicAccount?, i.e., it can be a nil, the '!' operator must be used when accessing this one.
When a resource is saved into storage, this field is associated to a reference retrieved from it. The <code>owner</code> part refers to the Account where the resource is stored.

2. You may be wondering: "Why do we have to add a force-unwrap operator (!) after self.owner?" Good question! Can you make a guess as to when self.owner would be nil?

If the resource in question is not saved into a storage path, this field is nil. Actually, this field is actually in references obtained to that resource, but never in the resource itself. For example, if I create a transaction that creates an Identity from the Profile contract and try to create a new Profile without saving it first and invoking the createProfile function from the reference instead, i.e., invoking the createProfile function directly from resource itself, the transactions is going to fail in the precondition, not because of the condition itself, but because it tries to index the Profile dictionary with a <code>self.owner!.address</code> while <code>self.owner</code> is still nill. Only a reference to an Identity resource that was previously saved to storage has this field properly set. 

3. Come up with your own example where you utilize self.owner!.address, and explain why you had to use it there.

4. Take a look at the FLOAT contract on Mainnet here. Find an example of self.owner!.address and explain what it is doing there (hint: look at the createEvent function).