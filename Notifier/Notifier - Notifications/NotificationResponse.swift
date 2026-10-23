//
//  NotificationResponse.swift.
//  Notifiers - Notifications.
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports.
import UserNotifications

/// Handles a user interaction with a previously posted notification.
///
/// Resolves the action identifier, executes any associated action, removes the delivered notification,
/// and exits. Called when the app is re-launched via a notification response.
///
/// - Parameters:
///   - response: The `UNNotificationResponse` from the user's interaction.
///
func handleNotification(forResponse response: UNNotificationResponse) {
    // Retrieve userInfo from the response object.
    let userInfo = response.notification.request.content.userInfo
    // If verboseMode is set...
    if userInfo["verboseMode"] != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - message - interacted: \(userInfo)")
    }
    // Resolve the action identifier to a userInfo key and log message.
    let (actionKey, logMessage) = resolveNotificationAction(for: response.actionIdentifier)
    // If verbose mode is set and there is a log message for this action...
    if userInfo["verboseMode"] != nil, let logMessage = logMessage {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - \(logMessage)")
    }
    // If there is a userInfo key for this action, process the associated action...
    if let actionKey = actionKey {
        // Performs any actions set for this interaction type.
        processNotificationActions(userInfoKey: actionKey, userInfo: userInfo)
    }
    // If verbose mode is set...
    if userInfo["verboseMode"] != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - message - removing notification")
    }
    // Remove the delivered notification.
    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers:
                                                                        [response.notification.request.identifier])
    // If verbose mode is set...
    if userInfo["verboseMode"] != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - message - removing notification - done")
    }
    // Exit.
    exit(0)
}

/// Executes the action stored in `userInfo` for the given key when a notification is interacted with.
///
/// Handles the `logout` task path specially by calling ``gracefulLogout(userInfo:)``,
/// otherwise runs the task via ``runTask(taskPath:taskArguments:userInfo:)``.
///
/// - Parameters:
///   - userInfoKey: The key into `userInfo` identifying which action to run.
///   - userInfo: The notification's `userInfo` dictionary containing the action payload and verbose mode flag.
///
func processNotificationActions(userInfoKey: String, userInfo: [AnyHashable: Any]) {
    // Var declaration.
    var messageActionDict = [String: Any]()
    // If we have a userInfoKey in the notifications userinfo...
    if userInfo[userInfoKey] != nil {
        // If verbose mode is set...
        if userInfo["verboseMode"] != nil {
            // Progress log.
            NSLog("\(#function.components(separatedBy: "(")[0]) - \(userInfoKey) - \(userInfo[userInfoKey] ?? [])")
        }
        // Convert userInfo[userInfoKey] to a dict.
        messageActionDict = userInfo[userInfoKey] as? [String: Any] ?? [:]
        // If we have logout as taskPath...
        if messageActionDict["taskPath"] as? String == "logout" {
            // If verbose mode is set...
            if userInfo["verboseMode"] != nil {
                // Progress log.
                NSLog("\(#function.components(separatedBy: "(")[0]) - \(userInfoKey) - logout")
            }
            // Prompt to logout.
            gracefulLogout(userInfo: userInfo)
        // If we have an action that's not logout...
        } else {
            // If verbose mode is set...
            if userInfo["verboseMode"] != nil {
                // Progress log.
                NSLog("\(#function.components(separatedBy: "(")[0]) - \(userInfoKey) - \(userInfo[userInfoKey] ?? [])")
            }
            // Run the task, returning boolean.
            let (taskOutput, taskStatus) = runTask(taskPath: messageActionDict["taskPath"] as? String ?? "",
                                                   taskArguments: messageActionDict["taskArguments"]
                                                   as? [String] ?? [], userInfo: userInfo)
            // If verbose mode is set...
            if userInfo["verboseMode"] != nil {
                // If the task completed successfully...
                if taskStatus {
                    // Progress log.
                    NSLog("""
                          "\(messageActionDict["taskPath"] ?? "") \(messageActionDict["taskArguments"] ?? [])"
                          completed successfully, returned output: \(taskOutput)
                          """)
                // If task failed to run...
                } else {
                    // Post error.
                    postToNSLogAndStdOut(logLevel: "ERROR", logMessage:
                                            """
                                            Running: \(messageActionDict["taskPath"] ?? "")
                                            \(messageActionDict["taskArguments"] ?? []) failed with \(taskOutput).
                                            """, functionName: #function.components(separatedBy: "(")[0],
                                            verboseMode: "enabled")
                }
            }
        }
    }
}

/// Maps a `UNNotificationResponse` action identifier to a `userInfo` key and a verbose log message.
///
/// Handles the default click, dismiss, first button, and second button identifiers.
///
/// - Parameters:
///   - actionIdentifier: The `UNNotificationResponse.actionIdentifier` string.
///
/// - Returns:
///   A tuple of the `userInfo` key and log message, or `(nil, nil)` for unknown identifiers.
///
func resolveNotificationAction(for actionIdentifier: String) -> (userInfoKey: String?, logMessage: String?) {
    // Switch on the action identifier to determine which action to perform.
    switch actionIdentifier {
    // The notification message body was clicked.
    case "com.apple.UNNotificationDefaultActionIdentifier":
        // Return the messageAction key and its log message.
        return ("messageAction", "message - clicked")
    // The notification was dismissed without interaction.
    case "com.apple.UNNotificationDismissActionIdentifier":
        // Return the dismissAction key and its log message.
        return ("dismissAction", "message - dismissed")
    // The first message button was clicked.
    case "messagebutton":
        // Return the messageButtonAction key and its log message.
        return ("messageButtonAction", "message button - clicked")
    // The second message button was clicked.
    case "messagebutton2":
        // Return the messageButton2Action key and its log message.
        return ("messageButton2Action", "message button 2 - clicked")
    // Unknown action identifier - no action to perform.
    default:
        // Return nil for both - no known action or log message for this identifier.
        return (nil, nil)
    }
}
