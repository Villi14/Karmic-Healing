//
// Karmic Healing 2025
//

import XCTest
import Dependencies
@testable import Common

@MainActor
final class UserDefaultsClientTests: XCTestCase {
  
  func testTypeSafeKeys() {
    let boolKey = BoolKey("test_bool")
    let stringKey = StringKey("test_string")
    let intKey = IntKey("test_int")
    
    XCTAssertEqual(boolKey.rawValue, "test_bool")
    XCTAssertEqual(stringKey.rawValue, "test_string")
    XCTAssertEqual(intKey.rawValue, "test_int")
  }
  
  func testPredefinedKeys() {
    XCTAssertEqual(BoolKey.showedOnboarding.rawValue, "showed_onboarding")
    XCTAssertEqual(StringKey.userLanguage.rawValue, "user_language")
    XCTAssertEqual(IntKey.lastCompletedStep.rawValue, "last_completed_step")
    XCTAssertEqual(IntKey.appLaunchCount.rawValue, "app_launch_count")
  }
  
  func testSimpleKeys() {
    XCTAssertEqual(UserDefaultsClient.Keys.showedOnboarding, "showed_onboarding")
    XCTAssertEqual(UserDefaultsClient.Keys.userLanguage, "user_language")
    XCTAssertEqual(UserDefaultsClient.Keys.lastCompletedStep, "last_completed_step")
    XCTAssertEqual(UserDefaultsClient.Keys.appLaunchCount, "app_launch_count")
  }
  
  func testLiveValue() {
    let client = UserDefaultsClient.liveValue
    
    // Test setting and getting values
    client.setBool(true, "test_bool")
    XCTAssertTrue(client.boolForKey("test_bool"))
    
    client.setString("test_value", "test_string")
    XCTAssertEqual(client.stringForKey("test_string"), "test_value")
    
    client.setInteger(42, "test_int")
    XCTAssertEqual(client.integerForKey("test_int"), 42)
    
    // Clean up
    client.remove("test_bool")
    client.remove("test_string")
    client.remove("test_int")
  }
  
  func testConvenienceMethods() {
    let client = UserDefaultsClient.liveValue
    
    // Test convenience methods with type-safe keys
    client.set(true, for: BoolKey.showedOnboarding)
    XCTAssertTrue(client.bool(for: BoolKey.showedOnboarding))
    
    client.set("uk", for: StringKey.userLanguage)
    XCTAssertEqual(client.string(for: StringKey.userLanguage), "uk")
    
    client.set(5, for: IntKey.lastCompletedStep)
    XCTAssertEqual(client.integer(for: IntKey.lastCompletedStep), 5)
    
    // Clean up
    client.remove(BoolKey.showedOnboarding.rawValue)
    client.remove(StringKey.userLanguage.rawValue)
    client.remove(IntKey.lastCompletedStep.rawValue)
  }
  
  func testSimpleKeyConvenienceMethods() {
    let client = UserDefaultsClient.liveValue
    
    // Test convenience methods with simple keys
    client.set(true, for: UserDefaultsClient.Keys.showedOnboarding)
    XCTAssertTrue(client.bool(for: UserDefaultsClient.Keys.showedOnboarding))
    
    client.set("uk", for: UserDefaultsClient.Keys.userLanguage)
    XCTAssertEqual(client.string(for: UserDefaultsClient.Keys.userLanguage), "uk")
    
    client.set(5, for: UserDefaultsClient.Keys.lastCompletedStep)
    XCTAssertEqual(client.integer(for: UserDefaultsClient.Keys.lastCompletedStep), 5)
    
    // Clean up
    client.remove(UserDefaultsClient.Keys.showedOnboarding)
    client.remove(UserDefaultsClient.Keys.userLanguage)
    client.remove(UserDefaultsClient.Keys.lastCompletedStep)
  }
  
  func testTestValue() {
    let client = UserDefaultsClient.testValue
    
    // Test that test value returns default values
    XCTAssertFalse(client.boolForKey("any_key"))
    XCTAssertNil(client.stringForKey("any_key"))
    XCTAssertEqual(client.integerForKey("any_key"), 0)
    
    // Test convenience methods with test value
    XCTAssertFalse(client.bool(for: BoolKey.showedOnboarding))
    XCTAssertNil(client.string(for: StringKey.userLanguage))
    XCTAssertEqual(client.integer(for: IntKey.lastCompletedStep), 0)
  }
  
  func testAsyncMethods() async {
    let client = UserDefaultsClient.liveValue
    
    // Test async convenience methods
    await client.setAsync(true, for: BoolKey.showedOnboarding)
    XCTAssertTrue(client.bool(for: BoolKey.showedOnboarding))
    
    await client.setAsync("uk", for: StringKey.userLanguage)
    XCTAssertEqual(client.string(for: StringKey.userLanguage), "uk")
    
    await client.setAsync(5, for: IntKey.lastCompletedStep)
    XCTAssertEqual(client.integer(for: IntKey.lastCompletedStep), 5)
    
    // Test async simple key methods
    await client.setAsync(true, for: UserDefaultsClient.Keys.showedOnboarding)
    XCTAssertTrue(client.bool(for: UserDefaultsClient.Keys.showedOnboarding))
    
    // Clean up
    await client.removeAsync(BoolKey.showedOnboarding.rawValue)
    await client.removeAsync(StringKey.userLanguage.rawValue)
    await client.removeAsync(IntKey.lastCompletedStep.rawValue)
    await client.removeAsync(UserDefaultsClient.Keys.showedOnboarding)
  }
} 