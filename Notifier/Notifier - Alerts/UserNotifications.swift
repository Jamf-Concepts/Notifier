//
//  UserNotifications.swift.
//  Notifiers - Alerts.
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports.
import UserNotifications

/// Builds a `userInfo`-compatible action dictionary from the first element of a ``MessageContent/TaskObject`` array.
///
/// - Parameters:
///   - taskObjects: An array of ``MessageContent/TaskObject`` values; only the first element is used.
///   - verboseLabel: A label string used in verbose log output to identify the action type.
///   - rootElements: Used to check verbose mode.
///
/// - Returns:
///   A dictionary with `taskPath` and `taskArguments` keys.
///
func buildButtonActionDict(taskObjects: [MessageContent.TaskObject],
                           verboseLabel: String, rootElements: RootElements) -> [AnyHashable: Any] {
    // Var declaration.
    var actionDict = [AnyHashable: Any]()
    // Add taskPath to the action dictionary.
    actionDict["taskPath"] = taskObjects[0].taskPath
    // Add taskArguments to the action dictionary.
    actionDict["taskArguments"] = taskObjects[0].taskArguments
    // If verbose mode is enabled...
    if rootElements.verboseMode != nil {
        // Progress log.
        NSLog("""
              \(#function.components(separatedBy: "(")[0]) - \(verboseLabel) - taskPath: \
              \(actionDict["taskPath"] ?? ""),
              taskArguments: \(actionDict["taskArguments"] ?? [])
              """)
    }
    // Return the populated action dictionary.
    return actionDict
}

/// Returns the notification body string from the decoded message content.
///
/// - Parameters:
///   - messageContent: The decoded notification content.
///   - rootElements: Used to check verbose mode.
///
/// - Returns:
///   The `messageBody` string.
///
func getNotificationBody(messageContent: MessageContent, rootElements: RootElements) -> String {
    // If verbose mode is enabled...
    if rootElements.verboseMode != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - messageBody: \(messageContent.messageBody!)")
    }
    // Return messageBody, forcing as this is set unless we remove all.. and if we aren't we won't get here.
    return messageContent.messageBody!
}

/// Builds and returns the action dictionary for the notification body click action.
///
/// - Parameters:
///   - messageContent: The decoded notification content containing `messageAction`.
///   - rootElements: Used to check verbose mode.
///
/// - Returns:
///   A dictionary with `taskPath` and `taskArguments` keys for the message action.
///
func getNotificationBodyAction(messageContent: MessageContent, rootElements: RootElements) -> [AnyHashable: Any] {
    // Var declaration.
    var messageAction = [AnyHashable: Any]()
    // Add taskPath from messagAction to messageAction.
    messageAction["taskPath"] = messageContent.messageAction?[0].taskPath
    // Add taskArguments from messageAction.
    messageAction["taskArguments"] = messageContent.messageAction?[0].taskArguments
    // If verbose mode is enabled...
    if rootElements.verboseMode != nil {
        // Progress log.
        NSLog("""
              \(#function.components(separatedBy: "(")[0]) - messageAction - taskPath: \
              \(messageAction["taskPath"] ?? ""), taskArguments: \(messageAction["taskArguments"] ?? [])
              """)
    }
    // Return messageAction.
    return messageAction
}

/// Returns the `UNNotificationSound` to use, falling back to the default sound if `"default"` is specified.
///
/// - Parameters:
///   - messageContent: The decoded notification content containing `messageSound`.
///   - rootElements: Used to check verbose mode.
///
/// - Returns:
///   A `UNNotificationSound` instance for the specified sound name.
///
func getNotificationSound(messageContent: MessageContent, rootElements: RootElements) -> UNNotificationSound {
    // Var declaration.
    var tempSound = UNNotificationSound.default
    // If we're not using macOS's default sound...
    if messageContent.messageSound?.lowercased() != "default" {
        // Set the notifications sound.
        tempSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: messageContent.messageSound ?? ""))
    }
    // If verbose mode is enabled...
    if rootElements.verboseMode != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - messageSound - set to: \(tempSound)")
    }
    // Return tempSound.
    return tempSound
}

/// Returns the notification subtitle string from the decoded message content.
///
/// - Parameters:
///   - messageContent: The decoded notification content containing `messageSubtitle`.
///   - rootElements: Used to check verbose mode.
///
/// - Returns:
///   The `messageSubtitle` string, or an empty string if not set.
///
func getNotificationSubtitle(messageContent: MessageContent, rootElements: RootElements) -> String {
    // If verbose mode is enabled...
    if rootElements.verboseMode != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - messageBody: \(messageContent.messageSubtitle ?? "")")
    }
    // Return messageSubtitle.
    return messageContent.messageSubtitle ?? ""
}

/// Returns the notification title string from the decoded message content.
///
/// - Parameters:
///   - messageContent: The decoded notification content containing `messageTitle`.
///   - rootElements: Used to check verbose mode.
///
/// - Returns:
///   The `messageTitle` string, or an empty string if not set.
///
func getNotificationTitle(messageContent: MessageContent, rootElements: RootElements) -> String {
    // If verbose mode is enabled...
    if rootElements.verboseMode != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - messageBody: \(messageContent.messageTitle ?? "")")
    }
    // Return messageTitle.
    return messageContent.messageTitle ?? ""
}

/// Schedules the notification request with Notification Center and returns on success.
///
/// Uses `passedBase64` as the notification identifier so it can be removed later.
/// Exits with code `1` on scheduling error, returning to the caller on successful delivery.
///
/// - Parameters:
///   - notificationCenter: The `UNUserNotificationCenter` instance to post to.
///   - notificationContent: The fully populated `UNMutableNotificationContent`.
///   - messageContent: The decoded notification content, reserved for future use.
///   - passedBase64: The base64 string used as the notification identifier.
///   - rootElements: Used to check verbose mode and pass the `verboseMode` string to inner calls.
///
func postNotification(notificationCenter: UNUserNotificationCenter, notificationContent: UNMutableNotificationContent,
                      messageContent: MessageContent, passedBase64: String, rootElements: RootElements) async {
    // If we're in verbose mode...
    if rootElements.verboseMode != nil {
        // Progress log.
        NSLog("""
              \(#function.components(separatedBy: "(")[0]) - notification \
              request - notificationContent - \(notificationContent).
              """)
    }
    // Create the request object.
    let notificationRequest = UNNotificationRequest(identifier: passedBase64, content: notificationContent,
                                                    trigger: nil)
    // Post the notification, handling any scheduling errors.
    do {
        try await notificationCenter.add(notificationRequest)
    } catch {
        // Post error.
        postToNSLogAndStdOut(logLevel: "ERROR",
                             logMessage: "Failed to post notification: \(error.localizedDescription)",
                             functionName: #function.components(separatedBy: "(")[0],
                             verboseMode: rootElements.verboseMode ?? "")
        // Exit.
        exit(1)
    }
    // If we're in verbose mode...
    if rootElements.verboseMode != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - notification scheduled")
    }
    // Sleep, so we don't exit before macOS has delivered the notification.
    sleep(1)
}

/// Builds the `UNNotificationCategory` for the notification, including any defined button actions.
///
/// Always returns a category (required by the notification system). Delegates to
/// ``processMessageButton2(notificationAction:messageContent:rootElements:)`` when a second button is defined.
///
/// - Parameters:
///   - notificationCenter: The `UNUserNotificationCenter` instance, reserved for future use.
///   - messageContent: The decoded notification content containing button labels and actions.
///   - rootElements: Used to check verbose mode.
///
/// - Returns:
///   A tuple of the first button action dictionary, second button action dictionary
///   (empty if not defined), and the `UNNotificationCategory`.
///
func processMessageButton(notificationCenter: UNUserNotificationCenter, messageContent: MessageContent,
                          rootElements: RootElements) ->
        ([AnyHashable: Any], [AnyHashable: Any], UNNotificationCategory) {
    // Var declaration.
    var tempCategory = UNNotificationCategory(identifier: "alert", actions: [], intentIdentifiers: [],
                                              options: .customDismissAction)
    // Var declaration for the second message button action.
    var messageButton2Action = [AnyHashable: Any]()
    // If we have a value for messageButton passed...
    if messageContent.messageButton != nil {
        // Create an action object for the first button.
        let notificationAction = UNNotificationAction(identifier: "messagebutton",
                                                      title: messageContent.messageButton ?? "",
                                                      options: [])
        // Amend tempCategory to include the first button action.
        tempCategory = UNNotificationCategory(identifier: "alert", actions: [notificationAction],
                                              intentIdentifiers: [],
                                              options: .customDismissAction)
        // If verbose mode is enabled...
        if rootElements.verboseMode != nil {
            // Progress log.
            NSLog("\(#function.components(separatedBy: "(")[0]) - messagebutton processed")
        }
        // If a second message button label was also passed...
        if messageContent.messageButton2 != nil {
            // Process the second button, updating the category to include both buttons.
            (messageButton2Action, tempCategory) = processMessageButton2(notificationAction: notificationAction,
                                                                         messageContent: messageContent,
                                                                         rootElements: rootElements)
        }
        // If we have values for messageButton and messageButtonAction passed...
        if messageContent.messageButtonAction != nil {
            // Build the first button action dictionary.
            let messageButtonAction = buildButtonActionDict(taskObjects: messageContent.messageButtonAction!,
                                                            verboseLabel: "messageButtonAction",
                                                            rootElements: rootElements)
            // Return messageButtonAction, messageButton2Action and tempCategory.
            return (messageButtonAction, messageButton2Action, tempCategory)
        }
    // If we don't have a value for messageButton...
    } else {
        // If verbose mode is enabled...
        if rootElements.verboseMode != nil {
            // Progress log.
            NSLog("\(#function.components(separatedBy: "(")[0]) - no messagebutton defined")
        }
    }
    // Return empty dicts for messageButtonAction and messageButton2Action, along with tempCategory.
    return ([:], [:], tempCategory)
}

/// Creates the second notification button action and returns an updated category containing both buttons.
///
/// - Parameters:
///   - notificationAction: The first button's `UNNotificationAction`, included in the updated category.
///   - messageContent: The decoded notification content containing the second button label and optional action.
///   - rootElements: Used to check verbose mode.
///
/// - Returns:
///   A tuple of the second button's action dictionary (empty if no action set)
///   and the updated `UNNotificationCategory`.
///
func processMessageButton2(notificationAction: UNNotificationAction, messageContent: MessageContent,
                           rootElements: RootElements) ->
        ([AnyHashable: Any], UNNotificationCategory) {
    // Create an action object for the second button.
    let notificationAction2 = UNNotificationAction(identifier: "messagebutton2",
                                                   title: messageContent.messageButton2 ?? "",
                                                   options: [])
    // Build a category that includes both button actions.
    let updatedCategory = UNNotificationCategory(identifier: "alert",
                                                 actions: [notificationAction, notificationAction2],
                                                 intentIdentifiers: [],
                                                 options: .customDismissAction)
    // If verbose mode is enabled...
    if rootElements.verboseMode != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - messagebutton2 processed")
    }
    // If a second button action was also passed, build and return the action dictionary...
    if messageContent.messageButton2Action != nil {
        // Build the second button action dictionary.
        let messageButton2Action = buildButtonActionDict(taskObjects: messageContent.messageButton2Action!,
                                                        verboseLabel: "messageButton2Action",
                                                        rootElements: rootElements)
        // Return the second button action dict and the updated category.
        return (messageButton2Action, updatedCategory)
    }
    // Return an empty action dict and the updated category.
    return ([:], updatedCategory)
}

/// Removes all prior delivered notifications and exits.
///
/// - Parameters:
///   - notificationCenter: The `UNUserNotificationCenter` instance to use.
///   - messageContent: The decoded notification content, reserved for future use.
///   - rootElements: Used to check verbose mode.
///
func removeAllPriorNotifications(notificationCenter: UNUserNotificationCenter, messageContent: MessageContent,
                                 rootElements: RootElements) {
    // If we're in verbose mode...
    if rootElements.verboseMode != nil {
        // Verbose message.
        NSLog("\(#function.components(separatedBy: "(")[0]) - remove all")
    }
    // Remove all delivered notifications.
    notificationCenter.removeAllDeliveredNotifications()
    // If we're in verbose mode...
    if rootElements.verboseMode != nil {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - removed all prior delivered alert notifications.")
    }
    // Sleep, so we don't exit before notification(s) have been removed.
    sleep(1)
    // Exit.
    exit(0)
}

/// Removes the specific prior posted notification matching `passedBase64` and exits.
///
/// - Parameters:
///   - notificationCenter: The `UNUserNotificationCenter` instance to use.
///   - messageContent: The decoded notification content, reserved for future use.
///   - passedBase64: The base64 identifier of the notification to remove.
///   - rootElements: Used to check verbose mode.
///
func removePriorNotification(notificationCenter: UNUserNotificationCenter, messageContent: MessageContent,
                             passedBase64: String, rootElements: RootElements) {
    // If we're in verbose mode...
    if rootElements.verboseMode != nil {
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - remove prior - passedBase64 - [\(passedBase64)]")
    }
    // Remove any prior notifications with the same identifier as ncContentbase64.
    notificationCenter.removeDeliveredNotifications(withIdentifiers: [passedBase64])
    // If we're in verbose mode...
    if rootElements.verboseMode != nil {
        // Progress log
        NSLog("\(#function.components(separatedBy: "(")[0]) - removed prior delivered alert notification.")
    }
    // Sleep, so we don't exit before notification(s) have been removed.
    sleep(1)
    // Exit.
    exit(0)
}
