//
//  Authorization.swift.
//  Notifiers - Notifications.
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports.
import UserNotifications

/// Posts an authorisation error and exits when the app is not permitted to post notifications.
///
/// - Parameters:
///   - logLevel: The log level.
///   - statusDescription: A human-readable description of the authorisation status.
///   - verboseMode: A non-empty string enables verbose NSLog output.
///
func authorisationNotGranted(logLevel: String, statusDescription: String, verboseMode: String) {
    // Post error to NSLog and std out.
    postToNSLogAndStdOut(logLevel: logLevel, logMessage: """
                         Authorisation status: \(statusDescription). Either manually approve notifications for this \
                         application or deploy a Notification PPPCP to this Mac, and try posting the notification again.
                         """, functionName: #function.components(separatedBy: "(")[0],
                         verboseMode: verboseMode)
    // Exit.
    exit(1)
}

/// Checks the current notification authorisation status, requesting it if not yet determined.
///
/// - If already authorised (`.authorized`, `.provisional`, `.ephemeral`), re-registers the desired
///   options (alert, sound) so macOS can associate them with the app entry in System Settings.
///   This is required for MDM-managed settings such as `SoundsEnabled` to appear as managed.
/// - If `.notDetermined`, calls `requestAuthorization` so macOS registers the app in System Settings
///   and presents the user prompt. Exits if the request is denied or fails.
/// - If `.denied`, exits immediately without prompting.
///
/// - Parameters:
///   - verboseMode: A non-empty string enables verbose NSLog output.
///
func checkAuthorisation(verboseMode: String) async {
    // Retrieve the current notification authorisation status.
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    // Switch on the current authorisation status.
    switch settings.authorizationStatus {
    // Authorisation is already granted - re-register options so MDM-managed settings are reflected
    // in System Settings (e.g. SoundsEnabled). This call is a no-op for the user prompt.
    case .authorized, .provisional, .ephemeral:
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
        return
    // Authorisation was explicitly denied - exit without prompting.
    case .denied:
        authorisationNotGranted(logLevel: "ERROR", statusDescription: "denied", verboseMode: verboseMode)
    // Authorisation has not been requested yet - fire a non-blocking request to register the app in System Settings.
    default:
        // Submit the authorisation request without waiting for the user's response, so this invocation
        // is not blocked by the system prompt. macOS will show the prompt and register the app in
        // System Settings; the next invocation will see .authorized and proceed normally.
        Task.detached {
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        }
        // Exit with a message directing the user to approve in System Settings.
        authorisationNotGranted(logLevel: "WARNING",
                        statusDescription: "not yet approved - approve notifications in System Settings and try again",
                                verboseMode: verboseMode)
    }
}
