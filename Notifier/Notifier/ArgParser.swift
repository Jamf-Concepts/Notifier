//
//  ArgParser.swift.
//  Notifier.
//
//  Copyright © 2020 - 2026 Jamf. All rights reserved.
//

// Imports.
import ArgumentParser
import Foundation

/// Notification action options grouped under their own help section.
struct NotificationActionOptions: ParsableArguments {
    // Action when the message body is clicked - carries the shared format documentation.
    @Option(help: ArgumentHelp(
        "The action to perform when the notification body is clicked.",
        discussion: """
                    \t\t  Each action option applies to a different interaction point on the notification:

                    \t\t  • --messageaction        - The action to be performed when the notification body is \
                    clicked.
                    \t\t  • --messagebuttonaction  - Requires --messagebutton. The action to be performed when \
                    --messagebutton is clicked.
                    \t\t  • --messagebutton2action - Requires --messagebutton2. The action to be performed when \
                    --messagebutton2 is clicked.
                    \t\t  • --dismissaction        - The action to be performed when the user clicks the (X) to \
                    dismiss the notification.

                    \t\t  The following values can be passed to any action option:

                    \t\t  • 'logout'              - Prompts the logged-in user to log out.
                    \t\t  • A single path or URL  - Opened via /usr/bin/open (e.g. https://example.com).
                    \t\t  • A binary path + args  - The first argument must be a full path to a binary.

                    \t\t  For example: "/usr/bin/defaults" will work, "defaults" will not.

                    """
    ))
    // Action when the notification body is clicked.
    var messageaction: String = ""
    // Action when the first message button is clicked.
    @Option(help: """
                  The action to perform when --messagebutton is clicked. \
                  Requires --messagebutton to be passed. See --messageaction for format details.

                  """)
    var messagebuttonaction: String = ""
    // Action when the second message button is clicked.
    @Option(help: """
                  The action to perform when --messagebutton2 is clicked. \
                  Requires --messagebutton2 to be passed. See --messageaction for format details.

                  """)
    var messagebutton2action: String = ""
    // Action when the notification is dismissed.
    @Option(help: """
                  The action to perform when the user clicks the (X) button to explicitly dismiss the notification. \
                  See --messageaction for format details.

                  """)
    var dismissaction: String = ""
}

/// Argument parser for the Notifier CLI.
struct ArgParser: ParsableCommand {
    // Set overview and usage text.
    static let configuration = CommandConfiguration(
        // Set the command name to the full path of the running binary.
        commandName: CommandLine.arguments[0],
        abstract: """
                  Notifier \(String(describing:
                                    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!)): \
                  Posts alert or banner style notifications to the logged-in user.
                  """,
        usage: """
               --type <alert|banner> --message <message> [options]
               --type <alert|banner> --message <message> --messageaction <action>
               --type <alert|banner> --message <message> --messagebutton <label> --messagebuttonaction <action>
               --type <alert|banner> --message <message> --messagebutton <label> --messagebutton2 <label> \
               --messagebutton2action <action>
               --type <alert|banner> --message <message> --dismissaction <action>
               --type <alert|banner> --remove prior --message <message> [options]
               --type <alert|banner> --remove all
               --rebrand <path to image>
               """,
        helpNames: [.long]
    )
    // Required - notification type.
    @Option(help: """
                  The notification style to post. Must be either:

                  • alert  - Persistent notification that remains until the user dismisses or interacts with it.
                  • banner - Temporary notification that auto-dismisses after a short time.

                  The user's Notification Center settings for this application may override the requested style.

                  """)
    var type: String = ""
    // The notification's message body.
    @Option(help: """
                  The main body text of the notification.

                  """)
    var message: String = ""
    // Optional first action button label.
    @Option(help: """
                  Adds an action button to the notification with the given label. \
                  Pass --messagebuttonaction to run a command when the button is clicked.

                  """)
    var messagebutton: String = ""
    // Optional second action button label (requires --messagebutton).
    @Option(help: """
                  Adds a second action button to the notification with the given label. \
                  Requires --messagebutton to also be passed. \
                  Pass --messagebutton2action to run a command when this button is clicked.

                  """)
    var messagebutton2: String = ""
    // Notification action options grouped into their own help section.
    @OptionGroup(title: "Notification Actions")
    var actionOptions: NotificationActionOptions
    // Triggers the rebranding function.
    @Option(help: """
                  Path to a PNG or ICNS image to use as the notification icon, replacing the default app icon.

                  Requires root privileges. The calling process must have either Full Disk Access (macOS 10.15+) \
                  or App Management (macOS 13+) permission, and the notifying applications must be permitted to \
                  post to Notification Center. These permissions can be granted manually or via PPPC profiles \
                  delivered by an MDM.

                  If successful and a user is logged in, Notification Center is restarted to apply the change.

                  """)
    var rebrand: String = ""
    // Option to remove a specific notification or all notifications.
    @Option(help: """
                  Removes previously delivered notifications. Pass either:

                  • prior - Removes the notification matching the current --type, --message, and any other \
                  passed flags. All flags used when originally posting the notification must be passed again.
                  • all   - Removes all notifications delivered by this application.

                  """)
    var remove: String = ""
    // Optional sound to play when the notification is delivered.
    @Option(help: """
                  The sound to play when the notification is delivered. Pass "default" for the standard \
                  macOS notification sound, or the name of a sound file in /Library/Sounds or \
                  /System/Library/Sounds (without the file extension).

                  If the named sound cannot be found, macOS will fall back to the default sound.

                  """)
    var sound: String = ""
    // Optional subtitle.
    @Option(help: """
                  Secondary line of text displayed below the title in the notification.

                  """)
    var subtitle: String = ""
    // Optional title.
    @Option(help: """
                  The bold title line displayed at the top of the notification. \
                  Defaults to the application name if not passed.

                  """)
    var title: String = ""
    // Enables verbose logging.
    @Flag(help: """
                Enables detailed progress logging via NSLog. \
                View output in Console.app by filtering for 'Notifier'.

                """)
    var verbose = false
}
