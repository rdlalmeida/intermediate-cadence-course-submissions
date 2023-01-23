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