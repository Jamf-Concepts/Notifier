//
//  Functions.swift
//  Notifier
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports
import Cocoa
import SystemConfiguration

/// Updates the icons of all Notifier app bundles and restarts Notification Center if a user is logged in.
///
/// Requires root privileges. Calls ``updateIcon(brandingImage:imageData:objectPath:parsedResult:)``
/// for each bundle and ``registerApplications(parsedResult:)`` to re-register with Notification Center.
///
/// - Parameters:
///   - brandingImage: Path to the image file to use as the new icon.
///   - loggedInUser: The username of the currently logged-in user.
///   - parsedResult: The parsed CLI arguments.
///
func changeIcons(brandingImage: String, loggedInUser: String, parsedResult: ArgParser) {
    // Confirm we're root before proceeding
    rootCheck(parsedResult: parsedResult, passedArg: "--rebrand")
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - brandingImage: \(brandingImage)")
    }
    // Get the details of the file at brandingImage
    let imageData = getImageDetails(brandingImage: brandingImage, parsedResult: parsedResult)
    // For each application in brandingArray
    for notifierApp in [GlobalVariables.mainAppPath, GlobalVariables.alertAppPath, GlobalVariables.bannerAppPath] {
        // Rebrand each app starting with the Notifier.app, this way if this fails the rest are skipped
        updateIcon(brandingImage: brandingImage, imageData: imageData!, objectPath: notifierApp,
                   parsedResult: parsedResult)
    }
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - Successfully rebranded Notifier")
    }
    // If someone is logged in...
    if loggedInUser != "" {
        // If we're logged in and/or Notification Center is running, register the applications with Notification Center
        registerApplications(parsedResult: parsedResult)
    // If no-one is logged in...
    } else {
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log
            NSLog("\(#function.components(separatedBy: "(")[0]) - Skipping registration as not logged in")
        }
    }
    // Exit
    exit(0)
}

/// Encodes ``MessageContent`` and ``RootElements`` into a base64-encoded JSON string.
///
/// The message content is first encoded to JSON and base64-encoded into `rootElements.messageContent`,
/// then the full ``RootElements`` is encoded to JSON and base64-encoded for passing to the helper app.
///
/// - Parameters:
///   - messageContent: The notification content to encode.
///   - parsedResult: The parsed CLI arguments, used for verbose logging.
///   - rootElements: The root-level notification metadata to encode.
///
/// - Returns:
///   A base64-encoded JSON string representing the full payload.
///
func createJSON(messageContent: MessageContent, parsedResult: ArgParser, rootElements: RootElements) -> String {
    // Var declaration
    var contentJSON = Data()
    var fullJSON = Data()
    var rootContent = rootElements
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - messageContent: \(messageContent)")
    }
    // Try to convert messageContent to JSON
    do {
        // Create a JSONEncoder object
        let jsonEncoder = JSONEncoder()
        // Set formatting to sortedKeys - to make sure that the base64 is static
        jsonEncoder.outputFormatting = .sortedKeys
        // Turn messageContent into JSON
        contentJSON = try jsonEncoder.encode(messageContent)
    // If encoding into JSON fails...
    } catch {
        // Post error
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: error.localizedDescription, functionName:
                             #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
    }
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("""
              \(#function.components(separatedBy: "(")[0]) - contentJSON: \(String(decoding: contentJSON,
                    as: UTF8.self))
              """)
    }
    // Add to contentJSON, but base64 encoded
    rootContent.messageContent = contentJSON.base64EncodedString()
    // Try to convert jsonContent to JSON
    do {
        // Create a JSONEncoder object
        let jsonEncoder = JSONEncoder()
        // Set formatting to sortedKeys - to make sure that the base64 is static
        jsonEncoder.outputFormatting = .sortedKeys
        // Turn jsonContent into JSON
        fullJSON = try jsonEncoder.encode(rootContent)
    // If encoding into JSON fails...
    } catch {
        // Post error
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: error.localizedDescription, functionName:
                             #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
    }
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - rootJSON: \(String(decoding: fullJSON, as: UTF8.self))")
    }
    // Return fullJSON, base64 encoded
    return fullJSON.base64EncodedString()
}

/// Loads and validates the image at the given path for use as a branding icon.
///
/// Exits with an error if the file does not exist or is not a valid image.
///
/// - Parameters:
///   - brandingImage: The path to the image file.
///   - parsedResult: The parsed CLI arguments, used for verbose logging.
///
/// - Returns:
///   An `NSImage` loaded from the given path, or exits on failure.
///
func getImageDetails(brandingImage: String, parsedResult: ArgParser) -> (NSImage?) {
    // Var declaration
    var imageData: NSImage?
    // If the file exists...
    if FileManager.default.fileExists(atPath: brandingImage) {
        // Create imageData from the file passed to brandingImage
        imageData = NSImage(contentsOfFile: brandingImage)
        // If imageData isValid is nil, then brandingImage is not a valid icon...
        if (imageData?.isValid) == nil {
            // Post error
            postToNSLogAndStdOut(logLevel: "ERROR", logMessage: "\(brandingImage) is not a valid image...",
                                 functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
            // Exit
            exit(1)
        }
        // Return the image data
        return imageData
    // If the file doesn't exist...
    } else {
        // Post error
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: "Cannot locate: \(brandingImage)....", functionName:
                             #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        // Exit
        exit(1)
    }
}

/// Checks that Notification Center is running for the current user, exiting if it is not.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments, used for verbose logging.
///
func isNotificationCenterRunning(parsedResult: ArgParser) {
    // Exit if Notification Center isn't running for the user
    guard !NSRunningApplication.runningApplications(withBundleIdentifier:
                                                        "com.apple.notificationcenterui").isEmpty else {
        // Post warning
        postToNSLogAndStdOut(logLevel: "WARNING", logMessage: "Notification Center is not running...",
                             functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        // Exit
        exit(1)
    }
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - Notification Center is running")
    }
}

/// Returns the username of the currently logged-in console user.
///
/// - Returns:
///   The username string, or an empty string if at the login window or no user is logged in.
///
func loggedInUser() -> String {
    // Get the name of the logged in user
    let loggedInUser = SCDynamicStoreCopyConsoleUser(nil, nil, nil)! as String
    // If no-one or loginwindow is returned...
    if loggedInUser == "loginwindow" || loggedInUser == "" {
        return ""
    // Else if we have someone logged in
    } else {
        // Return their username
        return loggedInUser
    }
}

/// Parses an action string into an argv-compatible ``MessageContent/TaskObject`` array.
///
/// Handles quoted arguments with spaces, single-item paths (opened via `/usr/bin/open`),
/// the special `logout` keyword, and multi-argument commands where the first element is a binary path.
///
/// - Parameters:
///   - actionString: The raw action string passed via a CLI action option.
///   - parsedResult: The parsed CLI arguments, used for verbose logging.
///
/// - Returns:
///   An array containing a single ``MessageContent/TaskObject`` with `taskPath` and `taskArguments` set.
///
func parseAction(actionString: String, parsedResult: ArgParser) -> [MessageContent.TaskObject] {
    // Var declaration
    var regexDict = [String: String]()
    var taskArguments = [String]()
    var taskPath = String()
    var tempActionString = actionString
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - actionString: \(actionString)")
    }
    // The regex pattern we're to use
    let regexPattern = try? NSRegularExpression(pattern: "\'(.*?)\'|\"(.*?)\"")
    // Apply pattern to actionText, returning matches
    let regexMatches = regexPattern?.matches(in: actionString, options: [],
                                            range: NSRange(location: 0, length: actionString.utf16.count))
    // Iterate over each match
    for regexMatch in regexMatches! {
        // Set the range
        let regexRange = regexMatch.range(at: 1)
        // Create a Range object
        if let swiftRange = Range(regexRange, in: actionString) {
            // Create key in regex dict with the  and %20 escape spaces
            regexDict[actionString[swiftRange].description] =
            actionString[swiftRange].description.replacingOccurrences(of: " ", with: "%20")
        }
    }
    // If we have items in regexDict...
    if !regexDict.isEmpty {
        // For each key value pair we have in regexDict
        for (matchedKey, matchedValue) in regexDict {
            // Replace the occurences of matchedKey with matchedValue
            tempActionString = tempActionString.replacingOccurrences(of: matchedKey, with: matchedValue)
        }
        // Set taskArguments to the amended string
        taskArguments = Array(tempActionString.components(separatedBy: " "))
        // Iterate over the array elements which contain %20
        for arrayElement in taskArguments where arrayElement.contains("%20") {
            // Get the index of the element
            let arrayIndex = taskArguments.firstIndex(of: arrayElement)
            // Update the element in the array, removing %20, single and double quotes
            taskArguments[arrayIndex!] = arrayElement.replacingOccurrences(of: "%20", with: " ")
                .replacingOccurrences(of: "\'", with: "").replacingOccurrences(of: "\"", with: "")
        }
    // If regexDict is empty...
    } else {
        // Set taskArguments to the passed action
        taskArguments = Array(tempActionString.components(separatedBy: " "))
    }
    // If we only have a single task...
    if taskArguments.count == 1 {
        // If we've been passed logout...
        if taskArguments[0].lowercased() == "logout" {
            // Set the tasks path to open, this is to mimic pre-3.0 behaviour
            taskPath = "logout"
            // Clear taskArguments
            taskArguments = []
        // If one item and not passed logout...
        } else {
            // Set the tasks path to open, this is to mimic pre-3.0 behaviour
            taskPath = "/usr/bin/open"
        }
    // If we have more than one task, the 1st argument starts with /...
    } else if taskArguments[0].hasPrefix("/") {
        // Set the tasks path to the 1st item within the taskArguments
        taskPath = taskArguments[0]
        // Remove the above from the taskArguments
        taskArguments.remove(at: 0)
    // If we have more than one task, and the 1st argument does not start with /...
    } else {
        // Post warning
        postToNSLogAndStdOut(logLevel: "WARNING", logMessage: """
            \(taskArguments[0]) is not a path to a binary, not adding to notification...
            """, functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        // Return an empty TaskObject
        return [MessageContent.TaskObject(taskPath: "", taskArguments: [])]
    }
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - taskPath: \(taskPath), taskArguments: \(taskArguments)")
    }
    // Return a TaskObject with taskPath and taskArguments set
    return [MessageContent.TaskObject(taskPath: taskPath, taskArguments: taskArguments)]
}

/// Launches the notifying helper app with the encoded command JSON, running as the logged-in user if needed.
///
/// Uses `/usr/bin/su` when the current process runs as a different user (e.g. root).
/// Exits with the helper app's exit code unless rebranding.
///
/// - Parameters:
///   - commandJSON: The base64-encoded JSON payload to pass to the helper app.
///   - loggedInUser: The username of the currently logged-in user.
///   - notifierPath: The path to the notifying helper app binary.
///   - parsedResult: The parsed CLI arguments, used for verbose logging.
///
func passToApp(commandJSON: String, loggedInUser: String, notifierPath: String, parsedResult: ArgParser) {
    // Var declaration
    var taskArguments = [String]()
    var taskPath = String()
    // If the user running the app isn't the logged in user (root for example)...
    if NSUserName() != loggedInUser {
        // Set taskPath to su as we need to use that to run as the user
        taskPath = "/usr/bin/su"
        // Create taskArguments
        taskArguments = [
            "-l", "\(loggedInUser)", "-c", "\'\(notifierPath)\' \(commandJSON)"
        ]
    // If the person running the app is the logged in user...
    } else {
        // Set taskPath to the notifying apps path
        taskPath = notifierPath
        // Set taskArguments to the base64 of messageContentJSON
        taskArguments = [commandJSON]
    }
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - taskPath: \(taskPath), taskArguments: \(taskArguments)")
    }
    // Launch the wanted notification app as the user
    let exitCode = runTask(parsedResult: parsedResult, taskArguments: taskArguments, taskPath: taskPath)
    // If we're not rebranding...
    if parsedResult.rebrand == "" {
        // If we get an exit code that isn't 0-2...
        if ![0, 1, 2].contains(exitCode) {
            // Post to NSLog and stdout
            postToNSLogAndStdOut(logLevel: "ERROR",
                                 logMessage: "helper app exited with unexpected code: \(exitCode)",
                                 functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        }
        // Exit with the helper app's exit code
        exit(exitCode)
    }
}

/// Posts a log message to NSLog (when verbose) or stdout (when not verbose).
///
/// - Parameters:
///   - logLevel: The severity level string (e.g. `"INFO"`, `"WARNING"`, `"ERROR"`).
///   - logMessage: The message to log.
///   - functionName: The name of the calling function, included in verbose output.
///   - parsedResult: The parsed CLI arguments, used to determine verbose mode.
///
func postToNSLogAndStdOut(logLevel: String, logMessage: String, functionName: String, parsedResult: ArgParser) {
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(logLevel): \(functionName) - \(logMessage)")
    // verbose mode isn't enabled
    } else {
        // Print to stdout
        print("\(logLevel): \(logMessage)")
    }
}

/// Registers both notifying helper apps with Notification Center by sending and removing a dummy notification.
///
/// Also restarts Notification Center for the logged-in user if one is present.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments, used for verbose logging.
///
func registerApplications(parsedResult: ArgParser) {
    // Var declaration
    var taskArguments = [String]()
    var taskPath = String()
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0])")
    }
    // Get the username of the logged in user
    let loggedInUser = loggedInUser()
    // Initialize a rootElements object
    let rootElements = RootElements(removeOption: "prior")
    // Initialize a messageContent object with a message body of a UUID
    let messageContent = MessageContent(messageBody: UUID().uuidString)
    // Create the JSON to pass to the notifying app
    let commandJSON = createJSON(messageContent: messageContent, parsedResult: parsedResult,
                                 rootElements: rootElements)
    for notifierPath in [GlobalVariables.alertAppPath + "/Contents/MacOS/Notifier - Alerts",
                         GlobalVariables.bannerAppPath + "/Contents/MacOS/Notifier - Notifications"] {
        // Pass commandJSON to the relevant app, exiting afterwards
        passToApp(commandJSON: commandJSON, loggedInUser: loggedInUser, notifierPath: notifierPath,
                  parsedResult: parsedResult)
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log
            NSLog("""
                  \(#function.components(separatedBy: "(")[0]) - commandJSON: \(commandJSON), notifierPath: \
                  \(notifierPath)
                  """)
        }
    }
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - restarting Notification Center")
    }
    // If we're logged in...
    if loggedInUser != "" {
        // Path for the task
        taskPath = "/usr/bin/su"
        // Arguments for the task
        taskArguments = ["-l", loggedInUser, "-c", "/usr/bin/killall -u \(loggedInUser) NotificationCenter"]
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log
            NSLog("""
                  \(#function.components(separatedBy: "(")[0]) - taskPath: \(taskPath), taskArguments: \(taskArguments)
                  """)
        }
        // Run the task, ignoring returned exit status
        runTask(parsedResult: parsedResult, taskArguments: taskArguments, taskPath: taskPath)
    // If we're not logged in...
    } else {
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log
            NSLog("\(#function.components(separatedBy: "(")[0]) - not logged in, skipping Notification Center restart")
        }
    }
}

/// Verifies that the current process is running as root, exiting with an error if not.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments, used for verbose logging.
///   - passedArg: The CLI argument that requires root, included in the error message.
///
func rootCheck(parsedResult: ArgParser, passedArg: String) {
    // If we're not root...
    if NSUserName() != "root" {
        // Post error
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: """
            The argument: \(passedArg), requires root privileges, exiting...
            """, functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        // Exit
        exit(1)
    }
}

/// Runs a subprocess at the given path with the given arguments and waits for it to exit.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments, used for verbose logging.
///   - taskArguments: The arguments to pass to the executable.
///   - taskPath: The path to the executable.
///
/// - Returns:
///   The process termination status code.
///
@discardableResult
func runTask(parsedResult: ArgParser, taskArguments: [String], taskPath: String) -> Int32 {
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - taskPath: \(taskPath), taskArguments: \(taskArguments)")
    }
    // Create Task
    let task = Process()
    // Set task to call the binary
    task.executableURL = URL(fileURLWithPath: taskPath)
    // Set task arguments
    task.arguments = taskArguments
    // Run the task
    try? task.run()
    // Wait until task exits
    task.waitUntilExit()
    // Return the exit code
    return task.terminationStatus
}

/// Attempts to replace the icon of the app bundle at the given path with the provided image.
///
/// First clears the existing icon to ensure macOS detects the change, then applies the new image.
/// Exits with an error if the icon update fails.
///
/// - Parameters:
///   - brandingImage: The path to the source image, included in log messages.
///   - imageData: The `NSImage` to apply as the new icon.
///   - objectPath: The path to the app bundle to rebrand.
///   - parsedResult: The parsed CLI arguments, used for verbose logging.
///
func updateIcon(brandingImage: String, imageData: NSImage, objectPath: String, parsedResult: ArgParser) {
    // Revert the icon, always returns false and this helps the OS realise that ther has been an icon change
    NSWorkspace.shared.setIcon(nil, forFile: objectPath, options: NSWorkspace.IconCreationOptions([]))
    // Set the icon, returns bool
    let rebrandStatus = NSWorkspace.shared.setIcon(imageData, forFile: objectPath, options:
                                                   NSWorkspace.IconCreationOptions([]))
    // If we have successfully branded the item at objectPath...
    if rebrandStatus {
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log
            NSLog("""
                  \(#function.components(separatedBy: "(")[0]) - Successfully updated icon for \(objectPath), \
                  with icon: \(brandingImage)
                  """)
        }
    // If we encountered an issue when rebranding...
    } else {
        // Post error
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: """
            Failed to update icon for \(objectPath), with icon: \(brandingImage). Please make sure that the calling \
            process has the needed App Management or Full Disk Access PPPCP deployed, and try again.
            """, functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        // Exit
        exit(1)
    }
}
