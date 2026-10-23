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
///   - statusDescription: A human-readable description of the authorisation status.
///   - verboseMode: A non-empty string enables verbose NSLog output.
///
func authorisationNotGranted(statusDescription: String, verboseMode: String) {
    // Post error to NSLog and std out.
    postToNSLogAndStdOut(logLevel: "ERROR", logMessage: """
                         Authorisation status: \(statusDescription). Either manually approve notifications for this \
                         application or deploy a Notification PPPCP to this Mac, and try posting the notification again.
                         """, functionName: #function.components(separatedBy: "(")[0],
                         verboseMode: verboseMode)
    // Exit.
    exit(1)
}

/// Requests notification authorisation from the system, exiting if it is denied or not granted.
///
/// Calls ``authorisationNotGranted(statusDescription:verboseMode:)`` with a descriptive status string
/// if authorisation is not granted or an error occurs.
///
/// - Parameters:
///   - verboseMode: A non-empty string enables verbose NSLog output.
///
func requestAuthorisation(verboseMode: String) async {
    // Check the current authorisation status before requesting...
    let existingSettings = await UNUserNotificationCenter.current().notificationSettings()
    // If already authorised...
    if existingSettings.authorizationStatus == .authorized {
        // Return.
        return
    }
    // Attempt to request authorisation, catching any system-level errors.
    do {
        // Request authorization, capturing the result as a variable.
        let granted = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .providesAppNotificationSettings, .sound])
        // If authorisation was not granted...
        if !granted {
            // Check whether authorisation is denied or not yet determined.
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            // Declare a human-readable description of the authorisation status.
            let statusDescription: String
            // Switch on the status to produce a descriptive string.
            switch settings.authorizationStatus {
            // Authorisation was explicitly denied by the user.
            case .denied:
                statusDescription = "denied"
            // Authorisation has not been approved yet.
            case .notDetermined:
                statusDescription = "not approved"
            // Any other status that does not permit notifications.
            default:
                statusDescription = "not granted (status: \(settings.authorizationStatus.rawValue))"
            }
            // Post authorisation error.
            authorisationNotGranted(statusDescription: statusDescription, verboseMode: verboseMode)
        }
    // If the authorisation request threw an unexpected system-level error...
    } catch {
        // Post authorisation error with the underlying error description.
        authorisationNotGranted(statusDescription: "not determined: (\(error.localizedDescription))",
                                verboseMode: verboseMode)
    }
}
