pub contract FlowHotel {
    pub event roomCreated(roomNumber: UInt64)
    pub event roomChecked(roomNumber: UInt64)
    pub event roomFree(roomNumber: UInt64)
    pub event accessDenied(roomNumber: UInt64)

    pub resource Room {
        pub let roomNumber: UInt64
        pub(set) var doorStatus: Bool
        pub(set) var checkedIn: Bool
        pub(set) var clientName: String?

        init(roomNumber: UInt64) {
            self.roomNumber = roomNumber

            // All rooms are set as closed by default
            self.doorStatus = false

            // Same for the check in status
            self.checkedIn = false

            // Set the client name to nil for any free room
            self.clientName = nil
        }
    }

    pub resource Hotel {
        pub(set) var Rooms: @{UInt64: Room}

        init () {
            // Simple trick to avoid having to insert an array whenever I need to create a new Hotel. Handy for testing
            let rooms: [UInt64] = [1, 2, 3, 4, 5, 6, 7, 8]
            self.Rooms <- self.createAllRooms(roomNumbers: rooms)
        }

        // Function to create a single room
        pub fun createRoom(roomNumber: UInt64): @Room {
            let newRoom: @Room <- create Room(roomNumber: roomNumber)

            emit roomCreated(roomNumber: roomNumber)

            return <- newRoom
        }

        // Function to check in a room to a specif client
        pub fun checkInRoom(roomNumber: UInt64, clientName: String): Void {
            pre {
                // Check first if the room in question is not checked in yet
                !self.getRoomCheckedInStatus(roomNumber: roomNumber): "Room ".concat(roomNumber.toString()).concat(" was already checked in to "
                    .concat(self.getRoomClientName(roomNumber: roomNumber)))
            }

            // All good. Proceed with the check in
            // To change the internal parameters I need to retrieve the Room resource first
            let roomToChange: @Room <- self.Rooms.remove(key: roomNumber) ?? panic("Room ".concat(roomNumber.toString()).concat(" does not exist in this Hotel!"))

            roomToChange.checkedIn = true
            roomToChange.clientName = clientName

            // Return the resource back to the Hotel array
            self.Rooms[roomNumber] <-! roomToChange
        }

        // Function to check out of a room
        pub fun checkOutRoom(roomNumber: UInt64): Void {
            pre{
                // The only pre condition is that the room door must be closed... out of cortesy rather than anything else
                !self.getRoomDoorStatus(roomNumber: roomNumber): "Room ".concat(roomNumber.toString()).concat(" still has its door wide open. Close it first and try again.")
            }

            let roomToChange: @Room <- self.Rooms.remove(key: roomNumber) ?? panic("Room ".concat(roomNumber.toString()).concat(" does not exist in this Hotel!"))

            roomToChange.clientName = nil
            roomToChange.checkedIn = false

            self.Rooms[roomNumber] <-! roomToChange
        }

        // Function to create a series of rooms based on an array of room numbers
        pub fun createAllRooms(roomNumbers: [UInt64]): @{UInt64: Room} {
            // Create an emtry dictionary to store all the rooms as they are created
            var rooms: @{UInt64: Room} <- {}

            // Cycle through the array of room numbers
            for roomNumber in roomNumbers {
                rooms[roomNumber] <-! self.createRoom(roomNumber: roomNumber)
            }

            return <- rooms
        }

        // Set of functions to retrieve various stats about a room.
        // In retrospective, I should've done this in a single function and return a status struct instead...
        pub fun getRoomCheckedInStatus(roomNumber: UInt64): Bool {
            return (&self.Rooms[roomNumber] as &Room?)!.checkedIn
        }

        pub fun getRoomDoorStatus(roomNumber: UInt64): Bool {
            return (&self.Rooms[roomNumber] as &Room?)!.doorStatus
        }

        pub fun getRoomClientName(roomNumber: UInt64): String {
            var clientName: String? = (&self.Rooms[roomNumber] as &Room?)!.clientName

            if (clientName == nil) {
                // This takes care of the situation where the room has not been checked yet,
                // so there's no client associated to it
                clientName = "Room does not have a client associeted yet"
            }

            // I still need to force cast this before returning because Cadence still looks at the
            // variable as String?, but there's no way it has a nil in it yet
            return clientName!
        }

        destroy() {
            destroy self.Rooms
        }
    }

    pub fun createHotel(roomNumbers: [UInt64]): @Hotel {
        return <- create Hotel()
    }

    pub resource RoomController {
        // Function to open the room door
        pub fun openRoom(hotel: &Hotel, roomNumber: UInt64, clientName: String): Void {
            pre {
                // Check first if the room was checked by this client
                hotel.getRoomClientName(roomNumber: roomNumber) == clientName: 
                    "Room ".concat(roomNumber.toString().concat(" is not registered to ".concat(clientName).concat("Please go and scream at the receptionist")))
                // And check if the room was properly checked in
                hotel.getRoomCheckedInStatus(roomNumber: roomNumber): 
                    "Room ".concat(roomNumber.toString()).concat(" was not checked in yet! Go see the idiot at the reception desk and break one of his kneecaps if needed") 
            }

            let roomToChange: @Room <- hotel.Rooms.remove(key: roomNumber) ?? panic("Room ".concat(roomNumber.toString()).concat(" does not exists in this hotel!"))

            // Open the door
            roomToChange.doorStatus = true

            // Put the room back into the main array
            let phantomRoom: @Room? <- hotel.Rooms.insert(key: roomNumber, <- roomToChange)

            if (phantomRoom != nil) {
                panic("CAUTION: There was a valid Room alread set in number ".concat(roomNumber.toString()).concat(". This should not have happened!"))
            }

            destroy phantomRoom
        }

        // The function to close the room is, understandibly so, much more permissive
        pub fun closeRoom(roomNumber: UInt64): Bool {
            // CONTINUE FROM HERE!
            return false
        }
    }
}
 