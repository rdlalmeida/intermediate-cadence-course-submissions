Q1. Explain what a resource identifier is.

A Resource identifier is String composed by the concatenation between account address where the contract that contains that Resource definition is deployed, the contract name and Resource Type name. These elements are prefixed by an 'A' and separated with a '.'. This element is able to uniquely identify every Resource type in the Flow environment (the inclusion of the contract address makes it so)


Q2. Is it possible for two different resources, that have the same type, to have the same identifier?

Yes, if constructed from the same contract, which also implies being deployed in the same account. For example, if I have a contract that defines a Resource such as:

```cadence
pub contract ResourceTypes {
    pub resource ExampleResource {
        pub let name: String

        init(name: String) {
            self.name = name
        }
    }

    pub fun createExampleResource(name: String): @ExampleResource {
        return <- create ExampleResource(name: name)
    }
}
```

And then deploy it to the emulator admin account (0xf8d6e0586b0a20c7). If I then create two different Resources and log their identifiers:
```cadence
import ResourceTypes from "../contracts/ResourceTypes.cdc"

transaction(name1: String, name2: String) {
    prepare(signer: AuthAccount) {
        // Create two different resources from the same contract but with the same type 
        let resource01: @ResourceTypes.ExampleResource <- ResourceTypes.createExampleResource(name: name1)

        let resource02: @ResourceTypes.ExampleResource <- ResourceTypes.createExampleResource(name: name2)

        // Lets check their types then

        log("Resource 01 (name = ".concat(resource01.name).concat(") identifier: ".concat(resource01.getType().identifier)))
        log("Resource 02 (name = ".concat(resource02.name).concat(") identifier: ".concat(resource02.getType().identifier)))

        destroy resource01
        destroy resource02
    }

    execute {

    }
}
```
It returns:

![image](https://user-images.githubusercontent.com/39467168/214044424-f6080479-8204-473b-9f1f-45974ca1e578.png)

The 2 Resources have different names but their types are identical.

Q3. Is it possible for two different resources, that have a different type, to have the same identifier?

No, by the same reason above. If the types are different then the last element of the identifier String is different too, and so is the identifier itself since it is composed from them.

Q4. Based on the included comments:
- What is wrong with the following script? 
- Explain in detail how someone hack this script to always return `true`. 
- Then, what are two ways we could fix this script to make sure it is safe?


