//
//  Rebranding.swift.
//  Notifier.
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports.
import Cocoa

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
    // Confirm we're root before proceeding.
    rootCheck(parsedResult: parsedResult, passedArg: "--rebrand")
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - brandingImage: \(brandingImage)")
    }
    // Get the details of the file at brandingImage.
    let imageData = getImageDetails(brandingImage: brandingImage, parsedResult: parsedResult)
    // For each application in brandingArray.
    for notifierApp in [GlobalVariables.mainAppPath, GlobalVariables.alertAppPath, GlobalVariables.bannerAppPath] {
        // Rebrand each app starting with the Notifier.app, this way if this fails the rest are skipped.
        updateIcon(brandingImage: brandingImage, imageData: imageData!, objectPath: notifierApp,
                   parsedResult: parsedResult)
    }
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - Successfully rebranded Notifier")
    }
    // If someone is logged in...
    if loggedInUser != "" {
        // If we're logged in and/or Notification Center is running, register the applications with Notification Center.
        registerApplications(parsedResult: parsedResult)
    // If no-one is logged in...
    } else {
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log.
            NSLog("\(#function.components(separatedBy: "(")[0]) - Skipping registration as not logged in")
        }
    }
    // Exit.
    exit(0)
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
    // Var declaration.
    var imageData: NSImage?
    // If the file exists...
    if FileManager.default.fileExists(atPath: brandingImage) {
        // Create imageData from the file passed to brandingImage.
        imageData = NSImage(contentsOfFile: brandingImage)
        // If imageData isValid is nil, then brandingImage is not a valid icon...
        if (imageData?.isValid) == nil {
            // Post error.
            postToNSLogAndStdOut(logLevel: "ERROR", logMessage: "\(brandingImage) is not a valid image...",
                                 functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
            // Exit.
            exit(1)
        }
        // Return the image data.
        return imageData
    // If the file doesn't exist...
    } else {
        // Post error.
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: "Cannot locate: \(brandingImage)....", functionName:
                             #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        // Exit.
        exit(1)
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
    // Var declaration.
    var taskArguments = [String]()
    var taskPath = String()
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0])")
    }
    // Get the username of the logged in user.
    let loggedInUser = loggedInUser()
    // Initialize a rootElements object.
    let rootElements = RootElements(removeOption: "prior")
    // Initialize a messageContent object with a message body of a UUID.
    let messageContent = MessageContent(messageBody: UUID().uuidString)
    // Create the JSON to pass to the notifying app.
    let commandJSON = createJSON(messageContent: messageContent, parsedResult: parsedResult,
                                 rootElements: rootElements)
    for notifierPath in [GlobalVariables.alertAppPath + "/Contents/MacOS/Notifier - Alerts",
                         GlobalVariables.bannerAppPath + "/Contents/MacOS/Notifier - Notifications"] {
        // Pass commandJSON to the relevant app, exiting afterwards.
        passToApp(commandJSON: commandJSON, loggedInUser: loggedInUser, notifierPath: notifierPath,
                  parsedResult: parsedResult)
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log.
            NSLog("""
                  \(#function.components(separatedBy: "(")[0]) - commandJSON: \(commandJSON), notifierPath: \
                  \(notifierPath)
                  """)
        }
    }
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - restarting Notification Center")
    }
    // If we're logged in...
    if loggedInUser != "" {
        // Path for the task.
        taskPath = "/usr/bin/su"
        // Arguments for the task.
        taskArguments = ["-l", loggedInUser, "-c", "/usr/bin/killall -u \(loggedInUser) NotificationCenter"]
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log.
            NSLog("""
                  \(#function.components(separatedBy: "(")[0]) - taskPath: \(taskPath), taskArguments: \(taskArguments)
                  """)
        }
        // Run the task, ignoring returned exit status.
        runTask(parsedResult: parsedResult, taskArguments: taskArguments, taskPath: taskPath)
    // If we're not logged in...
    } else {
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log.
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
        // Post error.
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: """
            The argument: \(passedArg), requires root privileges, exiting...
            """, functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        // Exit.
        exit(1)
    }
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
    // Revert the icon, always returns false and this helps the OS realise that ther has been an icon change.
    NSWorkspace.shared.setIcon(nil, forFile: objectPath, options: NSWorkspace.IconCreationOptions([]))
    // Set the icon, returns bool.
    let rebrandStatus = NSWorkspace.shared.setIcon(imageData, forFile: objectPath, options:
                                                   NSWorkspace.IconCreationOptions([]))
    // If we have successfully branded the item at objectPath...
    if rebrandStatus {
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log.
            NSLog("""
                  \(#function.components(separatedBy: "(")[0]) - Successfully updated icon for \(objectPath), \
                  with icon: \(brandingImage)
                  """)
        }
    // If we encountered an issue when rebranding...
    } else {
        // Post error.
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: """
            Failed to update icon for \(objectPath), with icon: \(brandingImage). Please make sure that the calling \
            process has the needed App Management or Full Disk Access PPPCP deployed, and try again.
            """, functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        // Exit.
        exit(1)
    }
}
