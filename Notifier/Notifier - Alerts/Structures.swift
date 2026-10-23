//
//  Structures.swift.
//  Notifier - Alerts.
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Structure of MessageContent.
struct MessageContent: Codable {
    // Optional - action to perform when the message is clicked.
    var messageAction: [TaskObject]?
    // The notifications message (required).
    var messageBody: String?
    // Optional - alert only - message button label.
    var messageButton: String?
    // Optional - alert only - action to perform when the message button is clicked.
    var messageButtonAction: [TaskObject]?
    // Optional - alert only - second message button label (requires messageButton to also be set).
    var messageButton2: String?
    // Optional - alert only - action to perform when the second message button is clicked.
    var messageButton2Action: [TaskObject]?
    // Optional - alert only - action to perform when the notification is dismissed.
    var dismissAction: [TaskObject]?
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
         messageButtonAction: [TaskObject]? = nil, dismissAction: [TaskObject]? = nil,
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
        self.dismissAction = dismissAction
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
    // Initialize RootElements.
    init(messageContent: String? = nil, removeOption: String? = nil, verboseMode: String? = nil) {
        self.messageContent = messageContent
        self.removeOption = removeOption
        self.verboseMode = verboseMode
    }
}
