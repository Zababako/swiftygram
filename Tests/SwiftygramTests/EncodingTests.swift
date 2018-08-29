//
// Created by Zap on 29.08.2018.
//

import Foundation
import XCTest

@testable import Swiftygram

final class ReceiverTests: XCTestCase {

    let encoder = JSONEncoder()

    func test_Receiver_with_id_is_encoded_into_number() throws {

        let receiver: Receiver = 3125
        let message = APIMethod.SendMessage(chatId: receiver, text: "Brb")

        let data = try encoder.encode(message)

        let resultString = String(data: data, encoding: .utf8)!

        XCTAssert(resultString.contains("\"chatId\":3125"))
    }

    func test_Receiver_with_channelName_is_encoded_into_string() throws {

        let receiver: Receiver = "some_channel"
        let message = APIMethod.SendMessage(chatId: receiver, text: "Brb")

        let data = try encoder.encode(message)

        let resultString = String(data: data, encoding: .utf8)!

        XCTAssert(resultString.contains("\"chatId\":\"@some_channel\""))
    }
}
