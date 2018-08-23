//: Playground - noun: a place where people can play

import UIKit
import XCTest


protocol BeverageRepresentable {
    var name: String { get set }
    var isEmpty: Bool { get set }
    mutating func drink()
}

protocol BeverageDispensable {
    var drinks: [BeverageRepresentable] { get set }
    var capacity: Int { get set }
    mutating func add(drink: BeverageRepresentable) throws
    mutating func take(drinkWith name: String) throws -> BeverageRepresentable
}

enum BeverageDispensingError: Error {
    case empty
    case full
    case noMore(name: String)
    case cantStore(beverage: BeverageRepresentable)
}

struct Water: BeverageRepresentable {
    var name: String = "Water"
    var isEmpty: Bool = false
    mutating func drink() {
        self.isEmpty = true
    }
}

struct Refridgerator: BeverageDispensable {
    var drinks: [BeverageRepresentable] = []
    var capacity: Int = 10
    mutating func add(drink: BeverageRepresentable) throws {
        
        let currentCount = drinks.count
        
        guard currentCount <= capacity else {
            print("Can't add any more")
            throw BeverageDispensingError.full
        }
        
        drinks.append(drink)
    }
    
    mutating func take(drinkWith name: String) throws -> BeverageRepresentable {
        
        guard let index = drinks.index(where: { $0.name == name }) else {
            throw BeverageDispensingError.noMore(name: name)
        }
        
        return drinks.remove(at: index)
        
    }
    
}

struct Store {
    
    var dispenser: BeverageDispensable
    
    init(with dispenser: BeverageDispensable = Refridgerator()) {
        self.dispenser = dispenser
    }
    
    mutating func get(beverageWith name: String) -> BeverageRepresentable? {
        return try? dispenser.take(drinkWith: name)
    }
    
    mutating func refillDispenser(with: BeverageRepresentable) throws {
        
        let count = dispenser.drinks.count
        let capacity = dispenser.capacity
        
        guard count <= (capacity - 1) else {
            throw BeverageDispensingError.full
        }
        
        for _ in dispenser.drinks.count...(dispenser.capacity - 1) {
            try dispenser.add(drink: Water())
        }
        
    }
    
}

let workingRefridgerator = Refridgerator()
var store = Store(with: workingRefridgerator)
var newStore = Store()

store.dispenser.drinks.count

try store.refillDispenser(with: Water())

store.dispenser.drinks.count

let water = store.get(beverageWith: "Water")

store.dispenser.drinks.count

/// TESTS
class StoreTests: XCTestCase {
    
    struct BrokenRefridgerator: BeverageDispensable {
        var drinks: [BeverageRepresentable] = []
        
        var capacity: Int = 0
        
        func add(drink: BeverageRepresentable) throws {
            throw BeverageDispensingError.cantStore(beverage: drink)
        }
        
        func take(drinkWith name: String) throws -> BeverageRepresentable {
            throw BeverageDispensingError.noMore(name: name)
        }
        
    }
    
    func test_store_canRefillRegridgerator() {
        // Arrange
        var store = Store(with: Refridgerator())
        
        // Act // Assert
        XCTAssertNoThrow(try store.refillDispenser(with: Water()), "Dispenser shouldn't be full")
    }
    
    func test_store_refillsDispenserToCapacity() throws {
        // Arrange
        var store = Store(with: Refridgerator())
        let expected = store.dispenser.capacity
        
        // Act
        try store.refillDispenser(with: Water())
        
        // Assert
        let actual = store.dispenser.drinks.count
        XCTAssertEqual(expected, actual, "Should only refill the dispenser to its capacity")
    }
    
    func test_store_canGetItemFromRefridgerator() throws {
        // Arrange
        var store = Store(with: Refridgerator())
        try store.refillDispenser(with: Water())
        
        // Act // Assert
        let actual = store.get(beverageWith: "Water")
        XCTAssertNotNil(actual, "Water should return as valid")
    }
    
    func test_store_gettingItemDecrementsDrinkCount() throws {
        // Arrange
        var store = Store(with: Refridgerator())
        try store.refillDispenser(with: Water())
        let expected = store.dispenser.capacity - 1
        
        // Act // Assert
        let _ = store.get(beverageWith: "Water")
        
        // Assert
        let actual = store.dispenser.drinks.count
        XCTAssertEqual(expected, actual, "Getting a beverage did not correctly decrement the count")
    }
    
    func test_store_correctlyFailsToGetDrinkWithIncorrectName() throws {
        // Arrange
        var store = Store(with: Refridgerator())
        try store.refillDispenser(with: Water())
        
        // Act // Assert
        let actual = store.get(beverageWith: "Soda")
        XCTAssertNil(actual, "Soda should return nil")
    }

    func test_store_correctlyFailsToFill(){
        // Arrange
        var store = Store(with: BrokenRefridgerator())
        
        // Act // Assert
        XCTAssertThrowsError(try store.refillDispenser(with: Water()), "Broken refridgerator should cause failures")
    }
    
    func test_store_correctlyFailsOnGet() {
        // Arrange
        var store = Store(with: BrokenRefridgerator())
        
        // Act // Assert
        let actual = store.get(beverageWith: "Soda")
        XCTAssertNil(actual, "Broken refridgerator should always return nothing")
    }
}

/// TEST OBSERVER
class PlaygroundTestingObserver: NSObject, XCTestObservation {
    @objc func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: Int) {
        assertionFailure(description, line: UInt(lineNumber))
    }
}

let observer = PlaygroundTestingObserver()
XCTestObservationCenter.shared.addTestObserver(PlaygroundTestingObserver())
StoreTests.defaultTestSuite.run()
