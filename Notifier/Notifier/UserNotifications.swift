//
//  UserNotifications.swift
//  Notifiers - Alerts
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports
import UserNotifications

/// Returns the notification body string from the value passed to `--message`.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments.
///
/// - Returns:
///   The string passed to `--message`.
///
func setNotificationBody(parsedResult: ArgParser) -> String {
    // If verbose mode is enabled
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]): \(parsedResult.message)")
    }
    // Returns the value passed to --message
    return parsedResult.message
}

/// Returns the notification message button label from the value passed to `--messagebutton`.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments.
///
/// - Returns:
///   The string passed to `--messagebutton`.
///
func setNotificationMessageButton(parsedResult: ArgParser) -> String {
    // If verbose mode is enabled
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]): \(parsedResult.messagebutton)")
    }
    // Returns the value passed to --messagebutton
    return parsedResult.messagebutton
}

/// Returns the notification second message button label from the value passed to `--messagebutton2`.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments.
///
/// - Returns:
///   The string passed to `--messagebutton2`.
///
func setNotificationMessageButton2(parsedResult: ArgParser) -> String {
    // If verbose mode is enabled
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]): \(parsedResult.messagebutton2)")
    }
    // Returns the value passed to --messagebutton2
    return parsedResult.messagebutton2
}

/// Returns the notification sound name from the value passed to `--sound`.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments.
///
/// - Returns:
///   The string passed to `--sound`.
///
func setNotificationSound(parsedResult: ArgParser) -> String {
    // If verbose mode is enabled
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]): \(parsedResult.sound)")
    }
    // Returns the value passed to --sound
    return parsedResult.sound
}

/// Returns the notification subtitle from the value passed to `--subtitle`.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments.
///
/// - Returns:
///   The string passed to `--subtitle`.
///
func setNotificationSubtitle(parsedResult: ArgParser) -> String {
    // If verbose mode is enabled
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]): \(parsedResult.subtitle)")
    }
    // Returns the value passed to --subtitle
    return parsedResult.subtitle
}

/// Returns the notification title from the value passed to `--title`.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments.
///
/// - Returns:
///   The string passed to `--title`.
///
func setNotificationTitle(parsedResult: ArgParser) -> String {
    // If verbose mode is enabled
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]): \(parsedResult.title)")
    }
    // Returns the value passed to --title
    return parsedResult.title
}
