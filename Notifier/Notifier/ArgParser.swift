//
//  ArgParser.swift
//  Notifier
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports
import ArgumentParser
import Foundation

// Struct grouping the three notification action options into their own help section
struct NotificationActionOptions: ParsableArguments {
    // Action when the message button is clicked - carries the shared format documentation
    @Option(help: ArgumentHelp(
        discussion: """
                    \t\t Each message action applies to a different element of a notitication, these are detailed below:

                    \t\t • --messageaction        - Applies to the clicking the notification itself, excluding \
                    the below elements.
                    \t\t • --messagebuttonaction  - Requires <messagebutton> to be passed. Applies to clicks on the \
                    --messagebutton generated button.
                    \t\t • --messagebutton2action - Requires <message2button> to be passed. Applies to clicks on the \
                    --message2button generated button.
                    \t\t • --messagedismissaction - Applies when a message is dismissed.

                    \t\t See below for the arguments that can be passed to any message action:

                    \t\t • Passing 'logout' will prompt the user to logout.
                    \t\t • If passed a single item, this will be launched via: /usr/bin/open
                    \t\t • More complex commands can be passed, but the 1st argument needs to be a binaries path.

                    \t\t For example: \"/usr/bin/open\" will work, \"open\" will not.

                    """
    ))
    // Action when the message is clicked
    var messageaction: String = ""
    // Action when the first message button is clicked
    @Option(help: """
                  Requires --messagebutton to be passed. See --messageaction for more information.

                  """)
    var messagebuttonaction: String = ""
    // Action when the second message button is clicked
    @Option(help: """
                  Requires --message2button to be passed. See --messageaction for more information.

                  """)
    var messagebutton2action: String = ""
    // Action when the notification is dismissed
    @Option(help: """
                  See --messageaction for more information.

                  """)
    var messagedismissaction: String = ""
}

// Struct for ArgParser
struct ArgParser: ParsableCommand {
    // Set overview and usage text
    static let configuration = CommandConfiguration(
        // Set the command name to the full path of the running binary
        commandName: CommandLine.arguments[0],
        abstract: """
                  Notifier \(String(describing:
                                    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!)): \
                  Posts alert or banner notifications.
                  """,
        usage: """
               --type <alert/banner> --message <some message> <options>
               --type <alert/banner> --message <some message> --messageaction <action>
               --type <alert/banner> --message <some message> --messagebutton <label> --messagebuttonaction <action>
               --type <alert/banner> --message <some message> --messagebutton <label> --messagebutton2 <label> \
               --messagebutton2action <action>
               --type <alert/banner> --message <some message> --messagedismissaction <action>
               --type <alert/banner> --remove prior <some message> <options>
               --type <alert/banner> --remove all
               --rebrand <path to image>
               """,
        helpNames: [.long]
    )
    // Required - notification type
    @Option(help: """
                  alert or banner - REQUIRED.

                  """)
    var type: String = ""
    // The notifications message
    @Option(help: """
                  The notifications message.

                  """)
    var message: String = ""
    // Optional message button text
    @Option(help: """
                  Adds a button to the message, with the label being what is passed.

                  """)
    var messagebutton: String = ""
    // Optional second message button text (requires --messagebutton to also be passed)
    @Option(help: """
                  Adds a second button to the message, with the label being what is passed. \
                  Requires --messagebutton to also be passed.

                  """)
    var messagebutton2: String = ""
    // Notification action options grouped into their own help section
    @OptionGroup(title: "Notification Actions")
    var actionOptions: NotificationActionOptions
    // Triggers rebrand function
    @Option(help: """
                  Requires root privileges and that the calling process needs either Full Disk Access (10.15+) or at \
                  a minimum App Management (macOS 13+) permissions, as well as the notifying applications being given \
                  permission to post to Notification Center. Any of these permissions can be granted manually, but \
                  ideally via PPPCP's delivered via an MDM.

                  If successful and someone is logged in, Notification Center is restarted.

                  """)
    var rebrand: String = ""
    // Option to remove a specific notification or all notifications delivered
    @Option(help: """
                  \"prior\" or \"all\". If passing \"prior\", the full message will be required too. \
                  Including all passed flags.

                  """)
    var remove: String = ""
    // Optional sound to play when notification is delivered
    @Option(help: """
                  The sound to play when notification is delivered. Pass \"default\" for the default \
                  macOS sound, else the name of a sound in /Library/Sounds or /System/Library/Sounds.

                  If the sound cannot be found, macOS will use the \"default\" sound.

                  """)
    var sound: String = ""
    // Optional subtitle for the notification
    @Option(help: """
                  The notifications subtitle.

                  """)
    var subtitle: String = ""
    // Optional Title for the notification
    @Option(help: """
                  The notifications title.

                  """)
    var title: String = ""
    // Enables verbose logging
    @Flag(help: """
                Enables logging of actions. Check console for 'Notifier' messages.

                """)
    var verbose = false
}
