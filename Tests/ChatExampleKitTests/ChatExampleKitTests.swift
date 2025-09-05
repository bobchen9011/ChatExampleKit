import XCTest
@testable import ChatExampleKit

final class ChatExampleKitTests: XCTestCase {
    func testPackageImport() throws {
        // 測試 Package 能否正常導入
        XCTAssertNotNil(ChatListView())
    }
}