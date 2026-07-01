import Foundation
import ObjectiveC

/// Enables switching the app's `Localizable.strings` language at runtime
/// (without relying on the system language) by routing `Bundle.main`'s
/// localized-string lookups through a chosen `.lproj` bundle.
extension Bundle {
    private static var associatedLanguageBundle: UInt8 = 0

    /// Point `Bundle.main` at the given language code's `.lproj`. Pass `nil`
    /// to fall back to the system language.
    static func setLanguage(_ language: String?) {
        // Swap the class of Bundle.main once so our override takes effect.
        object_setClass(Bundle.main, LanguageBundle.self)

        let bundle: Bundle?
        if let language,
           let path = Bundle.main.path(forResource: language, ofType: "lproj") {
            bundle = Bundle(path: path)
        } else {
            bundle = nil
        }
        objc_setAssociatedObject(Bundle.main, &Bundle.associatedLanguageBundle,
                                 bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    fileprivate var languageBundle: Bundle? {
        objc_getAssociatedObject(self, &Bundle.associatedLanguageBundle) as? Bundle
    }
}

/// A `Bundle` subclass whose localized-string lookups defer to the selected
/// language bundle when one has been chosen in-app.
private final class LanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = languageBundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}
