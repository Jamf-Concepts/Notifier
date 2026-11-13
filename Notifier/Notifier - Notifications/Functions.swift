//
//  Functions.swift.
//  Notifier - Notifications.
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports.
import Cocoa

/// Decodes a base64-encoded string, exiting with an error if decoding fails.
///
/// - Parameters:
///   - base64String: The base64-encoded string to decode.
///
/// - Returns:
///   The decoded UTF-8 string.
///
func base64Decode(base64String: String) -> String {
    // Create a data object from the string, and decode to string.
    guard let base64EncodedData = base64String.data(using: .utf8),
        let encodedData = Data(base64Encoded: base64EncodedData)
    else {
        // Post error.
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: "Failed to decode: \(base64String) from base64...",
                             functionName: #function.components(separatedBy: "(")[0], verboseMode: "enabled")
        // Exit.
        exit(1)
    }
    // Return's a string decoded from base64.
    return String(decoding: encodedData, as: UTF8.self)
}

/// Decodes the base64-encoded JSON payload passed to the helper app binary.
///
/// Decodes the outer ``RootElements`` first, then the inner ``MessageContent`` if present.
/// Exits with an error if either decoding step fails.
///
/// - Parameters:
///   - passedJSON: The base64-encoded JSON string passed as a CLI argument.
///
/// - Returns:
///   A tuple of the decoded ``MessageContent``, the raw base64 content string, and the decoded ``RootElements``.
///
func decodeJSON(passedJSON: String) -> (MessageContent, String, RootElements) {
    // Var declaration.
    var messageContent = MessageContent()
    var passedBase64 = String()
    var rootElements = RootElements()
    // Try to convert RootElements to JSON from base64...
    do {
        // Decode from base64, exiting if fails.
        let tempDecoded = base64Decode(base64String: passedJSON)
        // Turn parsedArguments into JSON.
        rootElements = try JSONDecoder().decode(RootElements.self, from: Data(tempDecoded.utf8))
        // If verbose mode is set...
        if rootElements.verboseMode != nil {
            // Progress log.
            NSLog("\(#function.components(separatedBy: "(")[0]) - \(rootElements)")
        }
    // If encoding into JSON fails...
    } catch {
        // Post error.
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: "Failed to decode: \(rootElements) from JSON...",
                             functionName: #function.components(separatedBy: "(")[0], verboseMode: "enabled")
        // Exit.
        exit(1)
    }
    // If we have messageContent...
    if rootElements.messageContent != nil {
        // Try to convert RootElements to JSON from base64...
        do {
            // Set to the base64 passed to the app.
            passedBase64 = rootElements.messageContent ?? ""
            // Decode from base64, exiting if fails.
            let tempDecoded = base64Decode(base64String: passedBase64)
            // Turn messageContent into JSON.
            messageContent = try JSONDecoder().decode(MessageContent.self, from: Data(tempDecoded.utf8))
            // If verbose mode is set...
            if rootElements.verboseMode != nil {
                // Progress log.
                NSLog("\(#function.components(separatedBy: "(")[0]) - \(messageContent)")
            }
        // If encoding into JSON fails...
        } catch {
            // Post error.
            postToNSLogAndStdOut(logLevel: "ERROR", logMessage: "Failed to decode: \(messageContent) from JSON...",
                                 functionName: #function.components(separatedBy: "(")[0], verboseMode: "enabled")
            // Exit.
            exit(1)
        }
    }
    // Return messageContent and parsedArguments.
    return (messageContent, passedBase64, rootElements)
}

/// Prompts the user to log out gracefully using an AppleScript `loginwindow` event.
///
/// - Parameters:
///   - userInfo: The notification's `userInfo` dictionary, used to check verbose mode.
///
func gracefulLogout(userInfo: [AnyHashable: Any]) {
    // Var declaration.
    var error: NSDictionary?
    // If verbose mode is set...
    if userInfo["verboseMode"] != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - logout prompting")
    }
    // Create an NSAppleScript object with the logout command.
    if let scriptObject = NSAppleScript(source: "tell application \"loginwindow\" to «event aevtlogo»") {
        // If we receive output from the prior command...
        if let outputString = scriptObject.executeAndReturnError(&error).stringValue {
            // If verbose mode is set...
            if userInfo["verboseMode"] != nil {
                // Progress log.
                NSLog("\(#function.components(separatedBy: "(")[0]) - logout - \(outputString)")
            }
        // If we have an error from the prior command...
        } else if error != nil {
            // Post error.
            postToNSLogAndStdOut(logLevel: "ERROR", logMessage: "\(error!)",
                                 functionName: #function.components(separatedBy: "(")[0], verboseMode: "enabled")
            // Exit.
            exit(1)
        }
    }
}

/// Checks that Notification Center is running for the current user, exiting if it is not.
///
/// - Parameters:
///   - verboseMode: A non-empty string enables verbose logging.
///
func isNotificationCenterRunning(verboseMode: String) {
    // Exit if Notification Center isn't running for the user.
    guard !NSRunningApplication.runningApplications(withBundleIdentifier:
                                                        "com.apple.notificationcenterui").isEmpty else {
        // Post warning.
        postToNSLogAndStdOut(logLevel: "WARNING", logMessage: "Notification Center is not running...",
                             functionName: #function.components(separatedBy: "(")[0], verboseMode: verboseMode)
        // Exit.
        exit(0)
    }
    // If verbose mode is enabled...
    if verboseMode != "" {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - Notification Center is running...")
    }
}

/// Posts a log message to NSLog (when verbose) or stdout (when not verbose).
///
/// - Parameters:
///   - logLevel: The severity level string (e.g. `"INFO"`, `"WARNING"`, `"ERROR"`).
///   - logMessage: The message to log.
///   - functionName: The name of the calling function, included in verbose output.
///   - verboseMode: A non-empty string enables verbose NSLog output.
///
func postToNSLogAndStdOut(logLevel: String, logMessage: String, functionName: String, verboseMode: String) {
    // If verbose mode is enabled...
    if verboseMode != "" {
        // Progress log.
        NSLog("\(logLevel): \(functionName) - \(logMessage)")
    // verbose mode isn't enabled.
    } else {
        // Print to stdout.
        print("\(logLevel): \(logMessage)")
    }
}

/// Resolves runtime placeholders in a task path and its arguments.
///
/// Supported placeholders:
///   - `{loggedInUser}` — replaced with the name of the currently logged-in user at action execution time.
///
/// - Parameters:
///   - taskPath: The path to the executable, which may contain placeholders.
///   - taskArguments: The arguments array, each element of which may contain placeholders.
///
/// - Returns:
///   A tuple of the resolved task path and resolved arguments array.
///
func resolveActionPlaceholders(taskPath: String, taskArguments: [String]) -> (String, [String]) {
    // Get the logged-in user's name.
    let loggedInUser = NSUserName()
    // Replace {loggedInUser} in the task path.
    let resolvedPath = taskPath.replacingOccurrences(of: "{loggedInUser}", with: loggedInUser)
    // Replace {loggedInUser} in each argument.
    let resolvedArguments = taskArguments.map { $0.replacingOccurrences(of: "{loggedInUser}", with: loggedInUser) }
    // Return the resolved path and arguments.
    return (resolvedPath, resolvedArguments)
}

/// Launches a subprocess at the given path with the given arguments and returns immediately.
///
/// Fire-and-forget: the process runs independently and is adopted by launchd when the helper exits.
///
/// - Parameters:
///   - taskPath: The path to the executable.
///   - taskArguments: The arguments to pass to the executable.
///   - userInfo: The notification's `userInfo` dictionary, used to check verbose mode.
///
/// - Returns:
///   A tuple of an error description and `false` if the task failed to launch, or `("", true)` on success.
///
func runTask(taskPath: String, taskArguments: [String], userInfo: [AnyHashable: Any]) -> (String, Bool) {
    // If verbose mode is enabled...
    if userInfo["verboseMode"] != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - taskPath: \(taskPath), taskArguments: \(taskArguments)")
    }
    // Create Task.
    let task = Process()
    // Set task to call the binary.
    task.executableURL = URL(fileURLWithPath: taskPath)
    // Set task arguments.
    task.arguments = taskArguments
    // Launch the task.
    do {
        try task.run()
    } catch {
        // If verbose mode is enabled...
        if userInfo["verboseMode"] != nil {
            // Post error.
            postToNSLogAndStdOut(logLevel: "ERROR", logMessage: "Failed to launch: \(taskPath), error: \(error.localizedDescription)",
                                 functionName: #function.components(separatedBy: "(")[0], verboseMode: "enabled")
        }
        // Return early - task failed to launch.
        return (error.localizedDescription, false)
    }
    // Return success - task launched, running independently.
    return ("", true)
}
