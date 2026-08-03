//
//  TDLocalizedLabeling.swift
//  CineSet
//
//  Created by edgar kosyan on 03/08/2026.
//

import Foundation

/// A protocol that provides functionality for retrieving and formatting localized strings with arguments.
public protocol TDLocalizedLabeling {
    /// A static property that provides access to localized strings for the conforming type.
    static var localized: Self { get }

    /// Returns a formatted string by replacing format specifiers in the localized string at the specified key path with the provided arguments.
    ///
    /// ## Format Specifiers
    ///
    /// In Swift, `String(format:)` uses format specifiers that are similar to those in C's `printf` function. Here are some commonly used format specifiers:
    ///
    /// ### Strings:
    /// - `%@` - String object
    ///
    /// ### Characters:
    /// - `%c` - Single character
    ///
    /// ### Integers:
    /// - `%d` - Signed decimal integer
    /// - `%i` - Signed decimal integer
    /// - `%u` - Unsigned decimal integer
    /// - `%o` - Unsigned octal
    /// - `%x` - Unsigned hexadecimal (lowercase)
    /// - `%X` - Unsigned hexadecimal (uppercase)
    ///
    /// ### Floating-point numbers:
    /// - `%f` - Decimal floating-point (lowercase)
    /// - `%F` - Decimal floating-point (uppercase)
    /// - `%e` - Scientific notation (lowercase)
    /// - `%E` - Scientific notation (uppercase)
    /// - `%g` - Use the shortest representation: %e or %f
    /// - `%G` - Use the shortest representation: %E or %F
    ///
    /// ### Pointers:
    /// - `%p` - Pointer address
    ///
    /// ### Percentage:
    /// - `%%` - Literal `%` character
    ///
    /// ### Width and precision:
    /// - `%5d` - Minimum width of 5 for an integer (right-justified by default)
    /// - `%-5d` - Minimum width of 5 for an integer (left-justified)
    /// - `%5.2f` - Minimum width of 5 and 2 decimal places for a floating-point number
    ///
    /// ## Usage
    ///
    /// To conform to `TDLocalizedLabeling`, a type must provide a static property `localized` and can use the `withArguments(keyPath:_:)` method to format strings with arguments.
    ///
    /// ### Example
    ///
    /// ```swift
    /// struct TDSomeFeatureLabels: TDLocalizedLabeling {
    ///     let welcomeMessage: String
    ///     let itemCountMessage: String
    ///     let detailedMessage: String
    ///     let complexMessage: String
    /// }
    ///
    /// extension TDSomeFeatureLabels: TDLocalizedLabeling {
    ///     static let localized: Self = .init(
    ///         welcomeMessage: "Welcome, %@!",
    ///         itemCountMessage: "You have %d items.",
    ///         detailedMessage: "User %@ has %d items and %.2f credits.",
    ///         complexMessage: "Event on %02d/%02d/%04d at %02d:%02d"
    ///     )
    /// }
    ///
    /// // Example with a single argument
    /// let formattedWelcome = TDSomeFeatureLabels.withArguments(keyPath: \.welcomeMessage, "John")
    /// print(formattedWelcome)  // Output: "Welcome, John!"
    ///
    /// // Example with a single argument
    /// let formattedItemCount = TDSomeFeatureLabels.withArguments(keyPath: \.itemCountMessage, 5)
    /// print(formattedItemCount)  // Output: "You have 5 items."
    ///
    /// // Example with two arguments
    /// let formattedDetailedMessage = TDSomeFeatureLabels.withArguments(keyPath: \.detailedMessage, "Alice", 42, 1234.56)
    /// print(formattedDetailedMessage)  // Output: "User Alice has 42 items and 1234.56 credits."
    ///
    /// // Example with three arguments
    /// let formattedComplexMessage = TDSomeFeatureLabels.withArguments(keyPath: \.complexMessage, 7, 6, 2024, 14, 30)
    /// print(formattedComplexMessage)  // Output: "Event on 07/06/2024 at 14:30"
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: A key path to a property of type `String` in the conforming type. This property contains the localized string with format specifiers.
    ///   - arguments: A variadic list of arguments (`CVarArg...`) to replace the format specifiers in the localized string.
    /// - Returns: A formatted string where the format specifiers in the localized string are replaced with the provided arguments.
    func withArguments(keyPath: KeyPath<Self, String>, _ arguments: CVarArg...) -> String
}

public extension TDLocalizedLabeling {
    func withArguments(keyPath: KeyPath<Self, String>, _ arguments: CVarArg...) -> String {
        String(format: self[keyPath: keyPath], arguments)
    }
}
