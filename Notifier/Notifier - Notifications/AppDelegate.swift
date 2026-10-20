//
//  AppDelegate.swift.
//  Notifier - Notifications.
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports.
import Cocoa
import UserNotifications

// Declaration.
@NSApplicationMain
// The apps class.
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    // IBOutlet declaration.
    @IBOutlet weak var window: NSWindow!
    /// Handles launch, processing any pending notification response or dispatching CLI argument handling.
    ///
    /// If launched via a notification interaction, delegates to ``handleNotification(forResponse:)``.
    /// Otherwise decodes the CLI JSON payload and processes the notification request.
    ///
    /// - Parameters:
    ///   - aNotification: The notification posted by the system once launch completes.
    ///
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // If .userInfo is populated, we've been launched by interaction with a prior posted notification...
        if let response = (aNotification as NSNotification).userInfo?[
            NSApplication.launchUserNotificationUserInfoKey] as? UNNotificationResponse {
            // Handle the notification - handleNotification exits internally so no exit needed here.
            handleNotification(forResponse: response)
        }
        // Get the args passed to the binary.
        let passedCLIArguments = Array(CommandLine.arguments)
        // If no args passed, exit...
        if passedCLIArguments.count == 1 {
            // Print error.
            print("ERROR: No arguments passed to binary, exiting...")
            // Exit.
            exit(0)
        // If we have args passed...
        } else {
            // Get the passed base64 string at commandline argument at index 1.
            let (messageContent, passedBase64, rootElements) = decodeJSON(passedJSON: passedCLIArguments[1])
            // Exit if Notification Center isn't running.
            isNotificationCenterRunning(verboseMode: rootElements.verboseMode ?? "")
            // Create a notification center object.
            let notificationCenter = UNUserNotificationCenter.current()
            // Set delegate before any notification center interactions.
            notificationCenter.delegate = self
            // Check auth status then process arguments sequentially in async context.
            let workTask = Task {
                // Retrieve the current notification authorization settings.
                let settings = await notificationCenter.notificationSettings()
                // Switch on the current authorization status.
                switch settings.authorizationStatus {
                    // Already authorized - skip requesting and proceed directly.
                case .authorized, .provisional, .ephemeral:
                    // If sound was requested but soundSetting is not enabled...
                    if messageContent.messageSound != nil, settings.soundSetting != .enabled {
                        // Log a warning..
                        postToNSLogAndStdOut(logLevel: "WARNING",
                                             logMessage: "Sound is disabled for this application in System Settings > Notifications. Sound will not play.",
                                             functionName: #function.components(separatedBy: "(")[0],
                                             verboseMode: rootElements.verboseMode ?? "")
                    }
                    break
                    // Not determined or denied - request or report authorization.
                default:
                    // Request authorisation - exits internally if denied or on error.
                    await requestAuthorisation(verboseMode: rootElements.verboseMode ?? "")
                }
                // Process the arguments as needed.
                processArguments(messageContent: messageContent, notificationCenter: notificationCenter,
                                 passedBase64: passedBase64, rootElements: rootElements)
            }
            // Watchdog task - cancels work and exits if it exceeds 5 seconds.
            Task {
                // Wait 5 seconds before intervening.
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                // Cancel the work task if it is still running.
                workTask.cancel()
                // If we timeout, then the status is: "not approved"...
                authorisationNotGranted(statusDescription: "not approved", verboseMode: rootElements.verboseMode ?? "")
            }
        }
    }
}

/// Processes the decoded notification arguments and either removes or posts a notification.
///
/// Handles `removeOption` for both "all" and "prior" cases, or builds and posts a new banner notification
/// with any applicable action, button, sound, subtitle, and title content.
///
/// - Parameters:
///   - messageContent: The decoded notification content.
///   - notificationCenter: The `UNUserNotificationCenter` instance to use.
///   - passedBase64: The base64 identifier used to reference this notification.
///   - rootElements: The decoded root-level notification metadata.
///
func processArguments(messageContent: MessageContent, notificationCenter: UNUserNotificationCenter,
                      passedBase64: String, rootElements: RootElements) {
    // Create a notification content object.
    let notificationContent = UNMutableNotificationContent()
    // Add category identifier to notificationContent required anyway so setting here.
    notificationContent.categoryIdentifier = "banner"
    // If verbose mode is set...
    if rootElements.verboseMode != nil {
        // Add verboseMode to userInfo.
        notificationContent.userInfo["verboseMode"] = "enabled"
        // Progress log.
        NSLog("\(#function.components(separatedBy: "(")[0]) - verbose enabled")
    }
    // If we're to remove all delivered notifications...
    if rootElements.removeOption == "all" {
        // Remove all notifications.
        removeAllPriorNotifications(notificationCenter: notificationCenter, messageContent: messageContent,
                                    rootElements: rootElements)
    // If we're to remove a specific prior posted notification...
    } else if rootElements.removeOption == "prior" {
        // Remove a specific prior posted notification.
        removePriorNotification(notificationCenter: notificationCenter, messageContent: messageContent,
                                passedBase64: passedBase64, rootElements: rootElements)
    // Otherwise build the notification content and post.
    } else {
        // Set the message to the body of the notification as not removing all, we have to have this.
        notificationContent.body = getNotificationBody(messageContent: messageContent, rootElements: rootElements)
        // If we have a value for messageAction passed...
        if messageContent.messageAction != nil {
            // Add messageAction to userInfo.
            notificationContent.userInfo["messageAction"] = getNotificationBodyAction(messageContent: messageContent,
                                                                                      rootElements: rootElements)
        }
        // If we have a value for messageDismissAction passed...
        if messageContent.messageDismissAction != nil {
            // Build the dismiss action dictionary and add to userInfo.
            notificationContent.userInfo["messageDismissAction"] = buildButtonActionDict(
                taskObjects: messageContent.messageDismissAction!, verboseLabel: "messageDismissAction",
                rootElements: rootElements)
        }
        // messageButton needs defining, even when not called. So processing it here along with messageButtonAction.
        let (tempMessageButtonAction, tempMessageButton2Action, tempCategory) = processMessageButton(
            notificationCenter: notificationCenter, messageContent: messageContent, rootElements: rootElements)
        // Set the notifications category.
        notificationCenter.setNotificationCategories([tempCategory])
        // If tempMessageButtonAction has a value...
        if !tempMessageButtonAction.isEmpty {
            // Add messageButtonAction to userInfo.
            notificationContent.userInfo["messageButtonAction"] = tempMessageButtonAction
        }
        // If tempMessageButton2Action has a value...
        if !tempMessageButton2Action.isEmpty {
            // Add messageButton2Action to userInfo.
            notificationContent.userInfo["messageButton2Action"] = tempMessageButton2Action
        }
        // If we have a value for messageSound passed...
        if messageContent.messageSound != nil {
            // Set the notifications sound.
            notificationContent.sound = getNotificationSound(messageContent: messageContent, rootElements: rootElements)
        }
        // If we've been passed a messageSubtitle...
        if messageContent.messageSubtitle != nil {
            // Set the notifications subtitle.
            notificationContent.subtitle = getNotificationSubtitle(messageContent: messageContent,
                                                                   rootElements: rootElements)
        }
        // If we have a value for messageTitle...
        if messageContent.messageTitle != nil {
            // Set the notifications title.
            notificationContent.title = getNotificationTitle(messageContent: messageContent, rootElements: rootElements)
        }
        // Post the notification.
        postNotification(notificationCenter: notificationCenter, notificationContent: notificationContent,
                         messageContent: messageContent, passedBase64: passedBase64, rootElements: rootElements)
    }
}
