import XCTest

final class NoNetworkTests: XCTestCase {
    func testExternalSchemesCannotLaunchOtherApplications() throws {
        for address in ["https://example.com", "http://127.0.0.1:8080", "ftp://example.com",
                        "mailto:test@example.com", "custom-handler://send", "smb://example.com",
                        "file://example.com/share/capture.png"] {
            XCTAssertFalse(LocalWorkspace.permits(try XCTUnwrap(URL(string: address))))
        }
        XCTAssertTrue(LocalWorkspace.permits(URL(fileURLWithPath: "/tmp/capture.png")))
        XCTAssertTrue(LocalWorkspace.permits(try XCTUnwrap(
            URL(string: "x-apple.systempreferences:com.apple.preference.security"))))
    }

    func testTranslationRejectsEveryProviderIncludingStoredGooglePreference() {
        let finished = expectation(description: "Translation is refused")
        withDefaults(["translationProvider": "google"]) {
            XCTAssertEqual(TranslationService.provider, .google)
            TranslationService.translateBatch(texts: ["private screenshot text"], targetLang: "en") { result in
                switch result {
                case .success: XCTFail("No-network translation must never succeed")
                case .failure(let error): XCTAssertTrue(error is TranslationError)
                }
                finished.fulfill()
            }
            wait(for: [finished], timeout: 2)
        }
        XCTAssertFalse(TranslationService.appleTranslationAvailable)
    }
}
