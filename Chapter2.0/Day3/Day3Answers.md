1. Define your own contract interface and a contract that implements it. Inside the contract, have one function that mutates data and one function that reads that data.

* Contract Interface: IPizza.cdc
```cadence
pub contract interface IPizza {
    pub var size: UInt64
    pub var toppings: [String]

    pub fun addTopping(ingredient: String): Void
    pub fun removeTopping(): String
    pub fun getToppings(): [String]

    pub fun setSize(size: UInt64): Void
    pub fun getSize(): UInt64
}
```

* Contract: Pizza.cdc
```cadence
import IPizza from "./IPizza.cdc"

pub contract Pizza: IPizza {
    pub var size: UInt64
    pub var toppings: [String]

    pub fun addTopping(ingredient: String): Void {
        self.toppings.append(ingredient)
    }

    pub fun removeTopping(): String {
        return self.toppings.removeLast()
    }

    pub fun getToppings(): [String] {
        return self.toppings
    }

    pub fun setSize(size: UInt64): Void {
        self.size = size
    }

    pub fun getSize(): UInt64 {
        return self.size
    }

    init() {
        // Initiate a simple medium size Hawaian pizza
        self.size = 12
        self.toppings = ["TomatoSauce", "Cheese", "Ham", "Pineapple"]
    }
}
```

2. In a script, attempt to call the read function inside the contract without importing it.

* Read script: checkPizza.cdc
```cadence
import IPizza from "../contracts/IPizza.cdc"
pub fun main(): Void {
    // Import the emulator account
    let account: PublicAccount = getAccount(0xf8d6e0586b0a20c7)
    let contractName: String = "Pizza"

    let borrowedPizza: &IPizza = account.contracts.borrow<&IPizza>(name: contractName) ??
        panic("Unable to borrow ".concat(contractName).concat(" contract"))

    log(
        "Contract "
        .concat(contractName)
        .concat(" has size ")
        .concat(borrowedPizza.getSize().toString())
        .concat(" and is filled with: ")
        )
    
    for topping in borrowedPizza.getToppings() {
        log(topping)
    }
}
```

Result:

3. In a transaction, attempt to call the mutate function inside the contract without importing it.
