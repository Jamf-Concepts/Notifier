//
//  Structures.swift.
//  Notifier.
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports.
import Foundation

// Variables to be used globally.
struct GlobalVariables {
    // Path to the main apps bundle.
    static let mainAppPath = Bundle.main.bundlePath
    // Path to the alert apps bundle.
    static let alertAppPath = mainAppPath + "/Contents/Helpers/Notifier - Alerts.app"
    // Path to the banner apps bundle.
    static let bannerAppPath = mainAppPath + "/Contents/Helpers/Notifier - Notifications.app"
}

// Structure of MessageContent.
struct MessageContent: Codable {
    // Optional - action to perform when the message is clicked.
    var messageAction: [TaskObject]?
    // The notifications message (required).
    var messageBody: String?
    // Optional - message button label.
    var messageButton: String?
    // Optional - action to perform when the message button is clicked.
    var messageButtonAction: [TaskObject]?
    // Optional - second message button label (requires messageButton to also be set).
    var messageButton2: String?
    // Optional - action to perform when the second message button is clicked.
    var messageButton2Action: [TaskObject]?
    // Optional - action to perform when the notification is dismissed.
    var messageDismissAction: [TaskObject]?
    // Optional - the sound played when the notification has been delivered.
    var messageSound: String?
    // Optional - the notifications subtitle.
    var messageSubtitle: String?
    // Optional - the notifications title.
    var messageTitle: String?
    // Arguments for the task object.
    struct TaskObject: Codable {
        // The tasks executable.
        var taskPath: String?
        // Arguments to pass to the task executable.
        var taskArguments: [String]?
    }
    // Initialize MessageContent.
    init(messageAction: [TaskObject]? = nil, messageBody: String? = nil, messageButton: String? = nil,
         messageButton2: String? = nil, messageButton2Action: [TaskObject]? = nil,
         messageButtonAction: [TaskObject]? = nil, messageDismissAction: [TaskObject]? = nil,
         messageSound: String? = nil, messageSubtitle: String? = nil, messageTitle: String? = nil) {
        self.messageAction = messageAction
        self.messageBody = messageBody
        self.messageButton = messageButton
        // Assign the second message button label.
        self.messageButton2 = messageButton2
        // Assign the second message button action.
        self.messageButton2Action = messageButton2Action
        self.messageButtonAction = messageButtonAction
        // Assign the dismiss action.
        self.messageDismissAction = messageDismissAction
        self.messageSound = messageSound
        self.messageSubtitle = messageSubtitle
        self.messageTitle = messageTitle
    }
}

// Structure of RootElements.
struct RootElements: Codable {
    // Optional - the messages content.
    var messageContent: String?
    // Optional - removes a specific notification or all notifications delivered.
    var removeOption: String?
    // Optional - enables verbose logging.
    var verboseMode: String?
    // Initialize MessageContent.
    init(messageContent: String? = nil, removeOption: String? = nil, verboseMode: String? = nil) {
        self.messageContent = messageContent
        self.removeOption = removeOption
        self.verboseMode = verboseMode
    }
}
