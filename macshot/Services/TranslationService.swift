import Foundation

enum TranslationProvider: String {
    case apple = "apple"
    case google = "google"
}

// Both Google requests and Apple language-pack downloads are excluded.
enum TranslationService {
    static var provider: TranslationProvider {
        get {
            TranslationProvider(rawValue: UserDefaults.standard.string(forKey: "translationProvider") ?? "") ?? .apple
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "translationProvider") }
    }
    static let appleTranslationAvailable = false

    static var targetLanguage: String {
        get { UserDefaults.standard.string(forKey: "translateTargetLang") ?? "en" }
        set { UserDefaults.standard.set(newValue, forKey: "translateTargetLang") }
    }

    static let availableLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("it", "Italian"),
        ("pt", "Portuguese"),
        ("nl", "Dutch"),
        ("pl", "Polish"),
        ("ru", "Russian"),
        ("zh-CN", "Chinese (Simplified)"),
        ("zh-TW", "Chinese (Traditional)"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("ar", "Arabic"),
        ("tr", "Turkish"),
        ("sv", "Swedish"),
        ("da", "Danish"),
        ("fi", "Finnish"),
        ("nb", "Norwegian"),
        ("uk", "Ukrainian"),
        ("cs", "Czech"),
        ("ro", "Romanian"),
        ("hu", "Hungarian"),
        ("sk", "Slovak"),
        ("bg", "Bulgarian"),
        ("hr", "Croatian"),
        ("id", "Indonesian"),
        ("hi", "Hindi"),
        ("th", "Thai"),
        ("vi", "Vietnamese"),
    ]

    @available(macOS 15.0, *)
    static func checkAppleLanguageAvailability(completion: @escaping ([String: Bool]) -> Void) {
        completion(Dictionary(uniqueKeysWithValues: availableLanguages.map { ($0.code, false) }))
    }

    static func translateBatch(texts: [String], targetLang: String,
                               completion: @escaping (Result<[String], Error>) -> Void) {
        DispatchQueue.main.async {
            completion(.failure(TranslationError.networkDisabled))
        }
    }
}

enum TranslationError: LocalizedError {
    case networkDisabled
    var errorDescription: String? {
        "Translation is disabled in the no-network build."
    }
}
