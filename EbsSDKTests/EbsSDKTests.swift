//
//  EbsSDKTests.swift
//  EbsSDKTests
//
//  Created by Serge Rybchinsky on 06/06/2019.
//  Copyright © 2019 Vitalii Poponov. All rights reserved.
//

import XCTest
@testable import EbsSDK

// 1. Освной кейс.
//// sdk.set(...) Настройка сдк
//// sdk.requestEsiaSession -> success
//// sdk.requestAuthorization -> success
//// sdk.requestExtendedAuthorization -> success

// 2. Освной кейс.
//// sdk.set(...) Настройка сдк
//// sdk.requestEsiaSession -> success
//// sdk.requestAuthorization -> success
//// sdk.requestExtendedAuthorization -> cancel

// 3. Освной кейс.
//// sdk.set(...) Настройка сдк
//// sdk.requestEsiaSession -> success
//// sdk.requestAuthorization -> success
//// sdk.requestExtendedAuthorization -> failure

// 4. Освной кейс.
//// sdk.set(...) Настройка сдк
//// sdk.requestEsiaSession -> ebsNotInstalled

// 5. Освной кейс.
//// sdk.set(...) Настройка сдк
//// sdk.requestEsiaSession -> sdkIsNotConfigured

// 6. Освной кейс.
//// sdk.set(...) Настройка сдк
//// sdk.requestEsiaSession -> success
//// sdk.requestAuthorization -> cancel

// 7. Освной кейс.
//// sdk.set(...) Настройка сдк
//// sdk.requestEsiaSession -> success
//// sdk.requestAuthorization -> failure

// 8. Освной кейс.
//// sdk.set(...) Настройка сдк
//// sdk.requestEsiaSession -> cancel

// 9. Освной кейс.
//// sdk.set(...) Настройка сдк
//// sdk.requestEsiaSession -> failure

class EbsSDKTests: XCTestCase {

    private var mockApp: MockApplication!
    private var sdk: EbsSDKClient!

    private let appSchemeKey = "appScheme"
    private let testAppScheme = "com.test.app"
    private let ebsAppSource = "com.waveaccess.Ebs"
    private let appStoreUrl = "itms-apps://itunes.apple.com/app/id1024941703"
    private let cancelKey = "cancel"

    private func getUrlForProcess(items: [URLQueryItem]) -> URL {
        let urlComponents = NSURLComponents(string: "\(testAppScheme)://")!
        urlComponents.queryItems = [URLQueryItem(name: self.appSchemeKey, value: self.testAppScheme)] + items
        return urlComponents.url!
    }

    override func setUp() {
        mockApp = MockApplication()
        sdk = EbsSDKClient(application: mockApp)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testField_EbsAppIsInstalled() {
        mockApp.canOpenURLExpected = false
        XCTAssertEqual(sdk.ebsAppIsInstalled, false)

        mockApp.canOpenURLExpected = true
        XCTAssertEqual(sdk.ebsAppIsInstalled, true)
    }

    func testOpenEbsInAppStore() {
        let expectationOpenEbs = self.expectation(description: "Waiting while SDK opens mp EBS app store page")
        expectationOpenEbs.expectedFulfillmentCount = 1

        sdk.set(scheme: testAppScheme, title: "testApp", infoSystem: "testInfo", presenting: nil)
        mockApp.urlDidOpen = { (url, _) in
            guard url == URL(string: self.appStoreUrl)! else {
                XCTAssertThrowsError("Unexpected url: \(url)")
                return
            }

            expectationOpenEbs.fulfill()
        }

        sdk.openEbsInAppStore()
        wait(for: [expectationOpenEbs], timeout: 5)
    }

    // 1.
    func testMainCase() {
        let expectationOpenEbs = self.expectation(description: "Waiting while SDK opens mp EBS")
        expectationOpenEbs.expectedFulfillmentCount = 3

        mockApp.canOpenURLExpected = true
        sdk.set(scheme: testAppScheme, title: "appTitle", infoSystem: "infoSystem", presenting: nil)
        testMainCase(expectedResult: .success(esiaResult: .init(code: "", state: "")), expectations: [expectationOpenEbs]) { (_, urlDidOpenCount) in
            switch urlDidOpenCount {
            case 1, 3:
                expectationOpenEbs.fulfill()
                let url = self.getUrlForProcess(items: [
                    URLQueryItem(name: EsiaToken.CodingKeys.code.rawValue, value: "token.code"),
                    URLQueryItem(name: EsiaToken.CodingKeys.state.rawValue, value: "token.state")
                ])
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            case 2:
                let url = self.getUrlForProcess(items: [
                    URLQueryItem(name: EbsToken.CodingKeys.verifyToken.rawValue, value: "token.verifyToken"),
                    URLQueryItem(name: EbsToken.CodingKeys.expired.rawValue, value: "token.expired")
                ])
                expectationOpenEbs.fulfill()
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            default: break
            }
        }
    }

    // 2.
    func testMainCase_VerificationFinishedCancelled() {
        let expectationOpenEbs = self.expectation(description: "Waiting while SDK opens mp EBS")
        expectationOpenEbs.expectedFulfillmentCount = 3

        mockApp.canOpenURLExpected = true
        sdk.set(scheme: testAppScheme, title: "appTitle", infoSystem: "infoSystem", presenting: nil)
        testMainCase(expectedResult: .cancel, expectations: [expectationOpenEbs]) { (_, urlDidOpenCount) in
            switch urlDidOpenCount {
            case 1:
                expectationOpenEbs.fulfill()
                let url = self.getUrlForProcess(items: [
                    URLQueryItem(name: EsiaToken.CodingKeys.code.rawValue, value: "token.code"),
                    URLQueryItem(name: EsiaToken.CodingKeys.state.rawValue, value: "token.state")
                ])
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            case 2:
                let url = self.getUrlForProcess(items: [
                    URLQueryItem(name: EbsToken.CodingKeys.verifyToken.rawValue, value: "token.verifyToken"),
                    URLQueryItem(name: EbsToken.CodingKeys.expired.rawValue, value: "token.expired")
                ])
                expectationOpenEbs.fulfill()
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            case 3:
                expectationOpenEbs.fulfill()
                let url = self.getUrlForProcess(items: [
                    URLQueryItem(name: self.cancelKey, value: self.cancelKey)
                ])
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            default: break
            }
        }
    }

    // 3.
    func testMainCase_VerificationFinishedFailure() {
        let expectationOpenEbs = self.expectation(description: "Waiting while SDK opens mp EBS")
        expectationOpenEbs.expectedFulfillmentCount = 3

        mockApp.canOpenURLExpected = true
        sdk.set(scheme: testAppScheme, title: "appTitle", infoSystem: "infoSystem", presenting: nil)
        testMainCase(expectedResult: .failure, expectations: [expectationOpenEbs]) { (_, urlDidOpenCount) in
            switch urlDidOpenCount {
            case 1:
                expectationOpenEbs.fulfill()
                let url = self.getUrlForProcess(items: [
                    URLQueryItem(name: EsiaToken.CodingKeys.code.rawValue, value: "token.code"),
                    URLQueryItem(name: EsiaToken.CodingKeys.state.rawValue, value: "token.state")
                ])
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            case 2:
                let url = self.getUrlForProcess(items: [
                    URLQueryItem(name: EbsToken.CodingKeys.verifyToken.rawValue, value: "token.verifyToken"),
                    URLQueryItem(name: EbsToken.CodingKeys.expired.rawValue, value: "token.expired")
                ])
                expectationOpenEbs.fulfill()
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            case 3:
                expectationOpenEbs.fulfill()
                let url = self.getUrlForProcess(items: [])
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            default: break
            }
        }
    }

    // 4.
    func testMainCase_VerificationFinishedEbsNotInstalled() {
        let expectationVerificationResult = self.expectation(description: "Waiting requestEBSVerification result. Expected .sdkIsNotConfigured error")
        expectationVerificationResult.expectedFulfillmentCount = 1

        var urlDidOpenCount = 0
        mockApp.urlDidOpen = nil
        sdk.set(scheme: testAppScheme, title: "appTitle", infoSystem: "infoSystem", presenting: nil)
        sdk.requestEsiaSession(urlString: "esiaLoginUrl") { result in
            switch result {
            case .ebsNotInstalled :
                expectationVerificationResult.fulfill()
            default:
                XCTAssertThrowsError("(requestEsiaSession) Unexpected result: \(result)")
            }
        }

        wait(for: [expectationVerificationResult], timeout: 15)
    }

    // 5.
    func testMainCase_VerificationFinishedSdkIsNotConfigured() {
        let expectationVerificationResult = self.expectation(description: "Waiting requestEBSVerification result. Expected .sdkIsNotConfigured error")
        expectationVerificationResult.expectedFulfillmentCount = 1

        var urlDidOpenCount = 0
        mockApp.urlDidOpen = nil
        sdk.requestEsiaSession(urlString: "esiaLoginUrl") { result in
            switch result {
            case .sdkIsNotConfigured:
                expectationVerificationResult.fulfill()

            default:
                XCTAssertThrowsError("(requestEsiaSession) Unexpected result: \(result)")
            }
        }

        wait(for: [expectationVerificationResult], timeout: 15)
    }

    // 6.
    func testMainCase_RequestAuthorizationCancelled() {
        let expectationVerificationResult = self.expectation(description: "Waiting requestEBSVerification result. Expected .sdkIsNotConfigured error")
        expectationVerificationResult.expectedFulfillmentCount = 1

        let expectationOpenEbs = self.expectation(description: "Waiting while SDK opens mp EBS")
        expectationOpenEbs.expectedFulfillmentCount = 2

        sdk.set(scheme: testAppScheme, title: "appTitle", infoSystem: "infoSystem", presenting: nil)
        mockApp.canOpenURLExpected = true
        mockApp.urlDidOpen = { (url, urlDidOpenCount) in
            switch urlDidOpenCount {
            case 1:
                expectationOpenEbs.fulfill()
                let url = self.getUrlForProcess(items: [
                    URLQueryItem(name: EsiaToken.CodingKeys.code.rawValue, value: "token.code"),
                    URLQueryItem(name: EsiaToken.CodingKeys.state.rawValue, value: "token.state")
                ])
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            case 2:
                let url = self.getUrlForProcess(items: [URLQueryItem(name: self.cancelKey, value: self.cancelKey)])
                expectationOpenEbs.fulfill()
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            default: break
            }
        }

        sdk.requestEsiaSession(urlString: "esiaLoginUrl") { result in
            switch result {
            case .failure, .ebsNotInstalled, .sdkIsNotConfigured, .cancel:
                XCTAssertThrowsError("(requestEsiaSession) Unexpected result: \(result)")

            case .success(let esiaResult):
                self.sdk.requestAuthorization(sessionId: "sessionID") { result in
                    switch result {
                    case .cancel:
                        expectationVerificationResult.fulfill()

                    case .failure, .success:
                        XCTAssertThrowsError("(requestAuthorization) Unexpected result: \(result)")

                    }
                }
            }
        }

        wait(for: [expectationVerificationResult, expectationOpenEbs], timeout: 15)
    }

    // 7.
    func testMainCase_RequestAuthorizationFailure() {
        let expectationVerificationResult = self.expectation(description: "Waiting requestEBSVerification result. Expected .sdkIsNotConfigured error")
        expectationVerificationResult.expectedFulfillmentCount = 1

        let expectationOpenEbs = self.expectation(description: "Waiting while SDK opens mp EBS")
        expectationOpenEbs.expectedFulfillmentCount = 2

        sdk.set(scheme: testAppScheme, title: "appTitle", infoSystem: "infoSystem", presenting: nil)
        mockApp.canOpenURLExpected = true
        mockApp.urlDidOpen = { (url, urlDidOpenCount) in
            switch urlDidOpenCount {
            case 1:
                expectationOpenEbs.fulfill()
                let url = self.getUrlForProcess(items: [
                    URLQueryItem(name: EsiaToken.CodingKeys.code.rawValue, value: "token.code"),
                    URLQueryItem(name: EsiaToken.CodingKeys.state.rawValue, value: "token.state")
                ])
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            case 2:
                let url = self.getUrlForProcess(items: [])
                expectationOpenEbs.fulfill()
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            default: break
            }
        }

        sdk.requestEsiaSession(urlString: "esiaLoginUrl") { result in
            switch result {
            case .failure, .ebsNotInstalled, .sdkIsNotConfigured, .cancel:
                XCTAssertThrowsError("(requestEsiaSession) Unexpected result: \(result)")

            case .success(let esiaResult):
                self.sdk.requestAuthorization(sessionId: "sessionID") { result in
                    switch result {
                    case .failure:
                        expectationVerificationResult.fulfill()

                    case .cancel, .success:
                        XCTAssertThrowsError("(requestAuthorization) Unexpected result: \(result)")

                    }
                }
            }
        }

        wait(for: [expectationVerificationResult, expectationOpenEbs], timeout: 15)
    }

    // 8.
    func testMainCase_RequestEsiaSessionCancel() {
        let expectationVerificationResult = self.expectation(description: "Waiting requestEBSVerification result. Expected .sdkIsNotConfigured error")
        expectationVerificationResult.expectedFulfillmentCount = 1

        let expectationOpenEbs = self.expectation(description: "Waiting while SDK opens mp EBS")
        expectationOpenEbs.expectedFulfillmentCount = 1

        sdk.set(scheme: testAppScheme, title: "appTitle", infoSystem: "infoSystem", presenting: nil)
        mockApp.canOpenURLExpected = true
        mockApp.urlDidOpen = { (url, urlDidOpenCount) in
            switch urlDidOpenCount {
            case 1:
                expectationOpenEbs.fulfill()
                let url = self.getUrlForProcess(items: [URLQueryItem(name: self.cancelKey, value: self.cancelKey)])
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            default: break
            }
        }

        sdk.requestEsiaSession(urlString: "esiaLoginUrl") { result in
            switch result {
            case .success, .ebsNotInstalled, .sdkIsNotConfigured, .failure:
                XCTAssertThrowsError("(requestEsiaSession) Unexpected result: \(result)")

            case .cancel:
                expectationVerificationResult.fulfill()
            }
        }

        wait(for: [expectationVerificationResult, expectationOpenEbs], timeout: 15)
    }

    // 9.
    func testMainCase_RequestEsiaSessionFailure() {
        let expectationVerificationResult = self.expectation(description: "Waiting requestEBSVerification result. Expected .sdkIsNotConfigured error")
        expectationVerificationResult.expectedFulfillmentCount = 1

        let expectationOpenEbs = self.expectation(description: "Waiting while SDK opens mp EBS")
        expectationOpenEbs.expectedFulfillmentCount = 1

        sdk.set(scheme: testAppScheme, title: "appTitle", infoSystem: "infoSystem", presenting: nil)
        mockApp.canOpenURLExpected = true
        mockApp.urlDidOpen = { (url, urlDidOpenCount) in
            switch urlDidOpenCount {
            case 1:
                expectationOpenEbs.fulfill()
                let url = self.getUrlForProcess(items: [])
                self.sdk.process(openUrl: url, from: self.ebsAppSource)

            default: break
            }
        }

        sdk.requestEsiaSession(urlString: "esiaLoginUrl") { result in
            switch result {
            case .success, .ebsNotInstalled, .sdkIsNotConfigured, .cancel:
                XCTAssertThrowsError("(requestEsiaSession) Unexpected result: \(result)")

            case .failure:
                expectationVerificationResult.fulfill()
            }
        }

        wait(for: [expectationVerificationResult, expectationOpenEbs], timeout: 15)
    }

    private func testMainCase(expectedResult: EbsSDKClient.EsiaRequestResult, expectations: [XCTestExpectation], urlDidOpen: @escaping ((URL, Int) -> Void)) {
        let expectationVerificationResult = self.expectation(description: "Waiting requestEBSVerification result. Expected .sdkIsNotConfigured error")
        expectationVerificationResult.expectedFulfillmentCount = 1

        var urlDidOpenCount = 0
        mockApp.urlDidOpen = urlDidOpen

        sdk.requestEsiaSession(urlString: "esiaLoginUrl") { result in
            switch result {
            case .failure, .ebsNotInstalled, .sdkIsNotConfigured, .cancel:
                XCTAssertThrowsError("(requestEsiaSession) Unexpected result: \(result)")

            case .success(let esiaResult):
                self.sdk.requestAuthorization(sessionId: "sessionID") { result in
                    switch result {
                    case .failure, .cancel:
                        XCTAssertThrowsError("(requestAuthorization) Unexpected result: \(result)")

                    case .success(let token):
                        self.sdk.requestExtendedAuthorization(location: "ExtendedAuthorizationUrl") { result in
                           switch (result, expectedResult) {
                           case (.success, .success),
                                (.cancel, .cancel),
                                (.failure, .failure),
                                (.ebsNotInstalled, .ebsNotInstalled),
                                (.sdkIsNotConfigured, .sdkIsNotConfigured):
                               expectationVerificationResult.fulfill()

                           default:
                               XCTAssertThrowsError("(requestExtendedAuthorization) Unexpected result: \(result)")
                           }
                        }
                    }
                }
            }
        }

        wait(for: [expectationVerificationResult] + expectations, timeout: 15)
    }
}

class MockApplication: UIApplicationProtocol {
    public var urlDidOpen: ((URL, Int) -> Void)?
    public var canOpenURLExpected: Bool = false
    public var urlDidOpenNumber = 0
    func open(_ url: URL) {
        urlDidOpenNumber += 1
        urlDidOpen?(url, urlDidOpenNumber)
    }

    func canOpenURL(_ url: URL) -> Bool {
        if url.scheme != "ebs" {
            XCTAssertThrowsError("Scheme of url must be \"ebs:\"")
        }

        return canOpenURLExpected
    }
}
