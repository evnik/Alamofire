//
//  ConcurrencyTests.swift
//
//  Copyright (c) 2021 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if swift(>=5.5)

import Alamofire
import XCTest

@available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
final class DataConcurrencyTests: BaseTestCase {
    func testDataTaskResponse() async {
        // Given, When
        let response = await AF.request(.get).decode(TestResponse.self).response

        // Then
        XCTAssertNotNil(response.value)
    }

    func testDataTaskCancellation() async {
        // Given
        let task = AF.request(.get).decode(TestResponse.self)

        // When
        task.cancel()
        let response = await task.response

        // Then
        XCTAssertTrue(response.error?.isExplicitlyCancelledError == true)
        XCTAssertTrue(task.isCancelled, "Underlying DataRequest should be cancelled.")
    }

    func testDataTaskResult() async {
        // Given, When
        let result = await AF.request(.get).decode(TestResponse.self).result

        // Then
        XCTAssertNotNil(result.success)
    }

    func testDataTaskValue() async throws {
        // Given, When
        let value = try await AF.request(.get).decode(TestResponse.self).value

        // Then
        XCTAssertEqual(value.url, "http://127.0.0.1:8080/get")
    }

    func testConcurrentRequests() async {
        // Given
        let session = Session(); defer { withExtendedLifetime(session) {} }

        // When
        async let first = session.request(.get).decode(TestResponse.self).response
        async let second = session.request(.get).decode(TestResponse.self).response
        async let third = session.request(.get).decode(TestResponse.self).response

        // Then
        let values = await [first.value, second.value, third.value].compactMap { $0 }
        XCTAssertEqual(values.count, 3)
    }

    func testTaskString() async {
        // Given
        let session = Session(); defer { withExtendedLifetime(session) {} }

        // When
        let result = await session.request(.get).string().result

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func testTaskData() async {
        // Given
        let session = Session(); defer { withExtendedLifetime(session) {} }

        // When
        let result = await session.request(.get).data().result

        // Then
        XCTAssertTrue(result.isSuccess)
    }
}

@available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
final class DownloadConcurrencyTests: BaseTestCase {
    func testThatDownloadTaskSerializesResponseFromSerializer() async throws {
        // Given, When
        let url = try await AF.download(.get).serialize(using: URLResponseSerializer()).value

        // Then
        XCTAssertNotNil(url)
    }

    func testThatDownloadTaskSerializesDecodable() async throws {
        // Given, When
        let value = try await AF.download(.get).decode(TestResponse.self).value

        // Then
        XCTAssertNotNil(value)
    }

    func testThatDownloadTaskSerializesString() async throws {
        // Given, When
        let value = try await AF.download(.get).string().value

        // Then
        XCTAssertNotNil(value)
    }

    func testThatDownloadTaskSerializesData() async throws {
        // Given, When
        let value = try await AF.download(.get).data().value

        // Then
        XCTAssertNotNil(value)
    }

    func testThatDownloadTaskSerializesURL() async throws {
        // Given, When
        let url = try await AF.download(.get).downloadedFileURL().value

        // Then
        XCTAssertNotNil(url)
    }

    func testThatDownloadTaskCancelsRequest() async {
        // Given
        let task = AF.download(.get).decode(TestResponse.self)

        // When
        task.cancel()
        let response = await task.response

        // Then
        XCTAssertTrue(response.error?.isExplicitlyCancelledError == true)
        XCTAssertTrue(task.isCancelled, "Underlying DownloadRequest should be cancelled.")
    }

    func testThatDownloadTaskCancelsWhenTaskCancels() async {
        // Given
        let request = AF.download(.get)
        let task = Task {
            let task = request.decode(TestResponse.self)
            _ = await task.response
        }

        // When
        task.cancel()
        _ = await task.value

        // Then
        XCTAssertTrue(request.isCancelled)
    }

    func testDownloadTaskProducesResponse() async {
        // Given, When
        let response = await AF.download(.get).decode(TestResponse.self).response

        // Then
        XCTAssertNotNil(response)
    }

    func testDownloadTaskProducesResult() async {
        // Given, When
        let result = await AF.download(.get).decode(TestResponse.self).result

        // Then
        XCTAssertNotNil(result)
    }

    func testDownloadTaskProducesValue() async throws {
        // Given, When
        let value = try await AF.download(.get).decode(TestResponse.self).value

        // Then
        XCTAssertNotNil(value)
    }

    func testThatDownloadTasksCanOperateConcurrently() async throws {
        // Given
        let session = Session(); defer { withExtendedLifetime(session) {} }

        // When
        async let first = session.download(.get).decode(TestResponse.self).value
        async let second = session.download(.get).decode(TestResponse.self).value
        async let third = session.download(.get).decode(TestResponse.self).value

        // Then
        let values = try await [first, second, third].compactMap { $0 }
        XCTAssertEqual(values.count, 3)
    }
}

@available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
final class DataStreamConcurrencyTests: BaseTestCase {
    func testThatDataStreamTaskCanStreamData() async {
        // Given
        let session = Session(); defer { _ = session }

        // When
        let task = session.streamRequest(.payloads(2)).task()
        var datas: [Data] = []

        for await data in task.streamData().compactMap(\.value) {
            datas.append(data)
        }

        // Then
        XCTAssertEqual(datas.count, 2)
    }

    func testThatDataStreamTaskCanStreamStrings() async {
        // Given
        let session = Session(); defer { _ = session }

        // When
        let task = session.streamRequest(.payloads(2)).task()
        var strings: [String] = []

        for await string in task.streamStrings().compactMap(\.value) {
            strings.append(string)
        }

        // Then
        XCTAssertEqual(strings.count, 2)
    }

    func testThatDataStreamTaskCanStreamDecodable() async {
        // Given
        let session = Session(); defer { _ = session }

        // When
        let task = session.streamRequest(.payloads(2)).task()
        let stream = task.stream(serializedUsing: DecodableStreamSerializer<TestResponse>())
        var responses: [TestResponse] = []

        for await response in stream.compactMap(\.value) {
            responses.append(response)
        }

        // Then
        XCTAssertEqual(responses.count, 2)
    }

    func testThatDataStreamTaskCanBeDirectlyCancelled() async {
        // Given
        let session = Session(); defer { withExtendedLifetime(session) {} }

        // When
        let expectedPayloads = 2
        let request = session.streamRequest(.payloads(expectedPayloads))
        let task = request.task()
        var datas: [Data] = []

        for await data in task.streamData().compactMap(\.value) {
            datas.append(data)
            if datas.count == 1 {
                task.cancel()
            }
        }

        // Then
        XCTAssertTrue(request.isCancelled)
        XCTAssertTrue(datas.count < expectedPayloads)
    }

    func testThatDataStreamTaskCanBeImplicitlyCancelled() async {
        // Given
        let session = Session(); defer { withExtendedLifetime(session) {} }

        // When
        let expectedPayloads = 100
        let request = session.streamRequest(.payloads(expectedPayloads))
        let task = Task {
            let task = request.task()
            var datas: [Data] = []

            for await data in task.streamData().compactMap(\.value) {
                datas.append(data)
            }

            XCTAssertTrue(datas.isEmpty)
        }
        task.cancel()
        let void: Void = await task.value

        // Then
        XCTAssertTrue(request.isCancelled)
        XCTAssertNotNil(void)
    }
}

#endif
