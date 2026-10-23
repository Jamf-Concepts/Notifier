//
//  AppDelegate.swift.
//  Notifier.
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports.
import Cocoa
import CoreFoundation
import UserNotifications

// Declaration.
@NSApplicationMain
// The apps class.
class AppDelegate: NSObject, NSApplicationDelegate {
    // IBOutlet declaration.
    @IBOutlet weak var window: NSWindow!
    /// Validates the logged-in user and handles early rebrand before the app fully loads.
    ///
    /// Exits early if no user is logged in and we are not rebranding.
    ///
    /// - Parameters:
    ///   - aNotification: The notification posted by the system before launch completes.
    ///
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        // Get the username of the logged in user.
        let loggedInUser = loggedInUser()
        // The first argument is always the executable, drop it.
        let passedArgs = Array(CommandLine.arguments.dropFirst())
        // Get the parsed args.
        let parsedResult = ArgParser.parseOrExit(passedArgs)
        // If rebrand has been passed...
        if parsedResult.rebrand != "" {
            // Rebrand Notifier apps.
            changeIcons(brandingImage: parsedResult.rebrand, loggedInUser: loggedInUser, parsedResult: parsedResult)
        // If we're not rebranding and no user is logged in, exit...
        } else if loggedInUser == "" {
            // Post message.
            print("INFO: No user logged in, and we're not rebranding... exiting...")
            // Exit.
            exit(0)
        }
    }
    /// Checks arguments passed to the app and dispatches to the appropriate notification flow.
    ///
    /// Handles rebrand, checks for a logged-in user, validates `--type`, confirms Notification Center
    /// is running, then either removes notifications or calls ``formatArgs(loggedInUser:notifierPath:parsedResult:)``.
    ///
    /// - Parameters:
    ///   - aNotification: The notification posted by the system once launch completes.
    ///
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // The first argument is always the executable, drop it.
        let passedArgs = Array(CommandLine.arguments.dropFirst())
        // Get the parsed args.
        let parsedResult = ArgParser.parseOrExit(passedArgs)
        // Get the username of the logged in user.
        let loggedInUser = loggedInUser()
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log.
            NSLog("\(#function.components(separatedBy: "(")[0]) - verbose enabled - arguments: \(parsedResult)")
        }
        // If rebrand has been passed...
        if parsedResult.rebrand != "" {
            // Rebrand Notifier apps.
            changeIcons(brandingImage: parsedResult.rebrand, loggedInUser: loggedInUser, parsedResult: parsedResult)
        // If we're not rebranding and no user is logged in, exit...
        } else if loggedInUser == "" {
            // Post message.
            postToNSLogAndStdOut(logLevel: "INFO", logMessage: "No user logged in, exiting...",
                                 functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
            // Exit.
            exit(0)
        // If we have no value passed to --type...
        } else if parsedResult.type == "" {
            // Show help.
            _ = ArgParser.parseOrExit(["--help"])
            // Exit.
            exit(1)
        }
        // Exit if Notification Center isn't running for the user.
        isNotificationCenterRunning(parsedResult: parsedResult)
        // Check that we have all the needed arguments and that they are valid options, exiting if not.
        checkArgs(parsedResult: parsedResult)
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log.
            NSLog("\(#function.components(separatedBy: "(")[0]) - type - \(parsedResult.type)")
        }
        // Var declaration.
        var notifierPath = String()
        // If we're looking for the alert app...
        if parsedResult.type == "alert" {
            // Get the alert apps path.
            notifierPath = GlobalVariables.alertAppPath + "/Contents/MacOS/Notifier - Alerts"
        // If we're looking for the notifications app...
        } else {
            // Get the alert apps path.
            notifierPath = GlobalVariables.bannerAppPath + "/Contents/MacOS/Notifier - Notifications"
        }
        // If --remove all has been passed...
        if parsedResult.remove.lowercased() == "all" {
            // Initialize a rootElements object.
            var rootElements = RootElements(removeOption: "all")
            // Initialize a messageContent object.
            let messageContent = MessageContent()
            // If verbose mode is enabled...
            if parsedResult.verbose {
                // Set verboseMode.
                rootElements.verboseMode = "enabled"
            }
            // Create the JSON to pass to the notifying app.
            let commandJSON = createJSON(messageContent: messageContent, parsedResult: parsedResult,
                                         rootElements: rootElements)
            // Pass commandJSON to the relevant app, exiting afterwards.
            passToApp(commandJSON: commandJSON, loggedInUser: loggedInUser, notifierPath: notifierPath,
                      parsedResult: parsedResult)
        } else {
            // Format the args as needed.
            formatArgs(loggedInUser: loggedInUser, notifierPath: notifierPath, parsedResult: parsedResult)
        }
    }
}

/// Applies message button fields from the parsed CLI arguments to a ``MessageContent`` object.
///
/// Sets `messageButton`, `messageButtonAction`, `messageButton2`, and `messageButton2Action`
/// when the corresponding options are present. The second button is only set if the first is also present.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments.
///   - messageContent: The ``MessageContent`` object to mutate with button fields.
///
func applyMessageButtons(parsedResult: ArgParser, to messageContent: inout MessageContent) {
    // If we've been passed a messagebutton...
    if parsedResult.messagebutton != "" {
        // Set messageButton.
        messageContent.messageButton = setNotificationMessageButton(parsedResult: parsedResult)
        // If we've been passed a messagebuttonaction, only set if a messagebutton was passed too...
        if parsedResult.actionOptions.messagebuttonaction != "" {
            // Set messageButtonAction.
            messageContent.messageButtonAction = parseAction(actionString:
                                                                parsedResult.actionOptions.messagebuttonaction,
                                                                parsedResult: parsedResult)
        }
        // If we've been passed a messagebutton2, only set if a messagebutton was also passed...
        if parsedResult.messagebutton2 != "" {
            // Set messageButton2.
            messageContent.messageButton2 = setNotificationMessageButton2(parsedResult: parsedResult)
            // If we've been passed a messagebutton2action, only set if a messagebutton2 was passed too...
            if parsedResult.actionOptions.messagebutton2action != "" {
                // Set messageButton2Action.
                messageContent.messageButton2Action = parseAction(actionString:
                                                                    parsedResult.actionOptions.messagebutton2action,
                                                                    parsedResult: parsedResult)
            }
        }
    }
}

/// Builds a ``MessageContent`` object from the parsed CLI arguments.
///
/// Populates message body, action, dismiss action, sound, subtitle, title, and button fields.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments.
///
/// - Returns:
///   A populated ``MessageContent`` instance.
///
func buildMessageContent(parsedResult: ArgParser) -> MessageContent {
    // Initialize a messageContent object.
    var messageContent = MessageContent()
    // Set the message body - required for all non-remove notifications.
    messageContent.messageBody = setNotificationBody(parsedResult: parsedResult)
    // If we've been passed a messageaction...
    if parsedResult.actionOptions.messageaction != "" {
        // Set messageAction.
        messageContent.messageAction = parseAction(actionString: parsedResult.actionOptions.messageaction,
                                                    parsedResult: parsedResult)
    }
    // If we've been passed a dismissaction...
    if parsedResult.actionOptions.dismissaction != "" {
        // Set dismissAction.
        messageContent.dismissAction = parseAction(actionString: parsedResult.actionOptions.dismissaction,
                                                   parsedResult: parsedResult)
    }
    // If we've been passed a sound...
    if parsedResult.sound != "" {
        // Set messageSound.
        messageContent.messageSound = setNotificationSound(parsedResult: parsedResult)
    }
    // If we've been passed a subtitle...
    if parsedResult.subtitle != "" {
        // Set messageSubtitle.
        messageContent.messageSubtitle = setNotificationSubtitle(parsedResult: parsedResult)
    }
    // If we've been passed a title...
    if parsedResult.title != "" {
        // Set messageTitle.
        messageContent.messageTitle = setNotificationTitle(parsedResult: parsedResult)
    }
    // Apply any message button fields.
    applyMessageButtons(parsedResult: parsedResult, to: &messageContent)
    // Return the populated messageContent object.
    return messageContent
}

/// Builds a ``RootElements`` object from the parsed CLI arguments.
///
/// Sets `verboseMode` and `removeOption` when the corresponding flags are present.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments.
///
/// - Returns:
///   A populated ``RootElements`` instance.
///
func buildRootElements(parsedResult: ArgParser) -> RootElements {
    // Initialize a rootElements object.
    var rootElements = RootElements()
    // If verbose mode is enabled...
    if parsedResult.verbose {
        // Set verboseMode.
        rootElements.verboseMode = "enabled"
    }
    // If we're to remove a prior posted notification...
    if parsedResult.remove.lowercased() == "prior" {
        // Set removeOption.
        rootElements.removeOption = "prior"
        // If verbose mode is enabled...
        if parsedResult.verbose {
            // Progress log.
            NSLog("\(#function.components(separatedBy: "(")[0]) - removeOption: \(rootElements.removeOption!))")
        }
    }
    // Return the populated rootElements object.
    return rootElements
}

/// Validates that all required CLI arguments are present and hold valid values.
///
/// Exits with an error and prints `--help` if `--type`, `--remove`, or `--message` are invalid or missing.
///
/// - Parameters:
///   - parsedResult: The parsed CLI arguments.
///
func checkArgs(parsedResult: ArgParser) {
    // If an invalid value for --type has been passed...
    if parsedResult.type.lowercased() != "alert" && parsedResult.type.lowercased() != "banner" {
        // Post message.
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: "incorrect argument passed to --type, exiting...\n",
                             functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        // Show help.
        _ = ArgParser.parseOrExit(["--help"])
        // Exit.
        exit(1)
    }
    // If an invalid value for --remove has been passed...
    if parsedResult.remove != "" && parsedResult.remove.lowercased() != "all" && parsedResult.remove.lowercased()
          != "prior" {
        // Post message.
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: "incorrect argument passed to --remove, exiting...\n",
                              functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        // Show help.
        _ = ArgParser.parseOrExit(["--help"])
        // Exit.
        exit(1)
    }
    // If we've got here and no --message has been passed and we're not removing...
    if parsedResult.remove == "" && parsedResult.message == "" {
        // Post message.
        postToNSLogAndStdOut(logLevel: "ERROR", logMessage: """
                        missing value for --message and we're neither rebranding nor removing, exiting...\n
                        """, functionName: #function.components(separatedBy: "(")[0], parsedResult: parsedResult)
        // Show help.
        _ = ArgParser.parseOrExit(["--help"])
        // Exit.
        exit(1)
    }
}

/// Formats the CLI arguments into JSON and passes it to the appropriate notifying helper app.
///
/// Orchestrates ``buildRootElements(parsedResult:)``, ``buildMessageContent(parsedResult:)``,
/// ``createJSON(messageContent:parsedResult:rootElements:)``, and
/// ``passToApp(commandJSON:loggedInUser:notifierPath:parsedResult:)``.
///
/// - Parameters:
///   - loggedInUser: The username of the currently logged-in user.
///   - notifierPath: The path to the notifying helper app binary.
///   - parsedResult: The parsed CLI arguments.
///
func formatArgs(loggedInUser: String, notifierPath: String, parsedResult: ArgParser) {
    // Build rootElements from the parsed arguments.
    let rootElements = buildRootElements(parsedResult: parsedResult)
    // Build messageContent from the parsed arguments.
    let messageContent = buildMessageContent(parsedResult: parsedResult)
    // Create the JSON to pass to the notifying app.
    let commandJSON = createJSON(messageContent: messageContent, parsedResult: parsedResult,
                                 rootElements: rootElements)
    // Pass commandJSON to the relevant app, exiting afterwards.
    passToApp(commandJSON: commandJSON, loggedInUser: loggedInUser, notifierPath: notifierPath,
              parsedResult: parsedResult)
}
