<details>
<summary>Licensed under the Apache License, Version 2.0 </summary>
Copyright 2026 Jamf LTD

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
</details>

# Notifier
<p align="center"><img width="256" alt="Alert" src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/d8d2cca1-250c-4601-a1d5-1fea2330ba14">

Notifier is a Swift app which can post alert or banner notifications on macOS 12.0+ clients.

Notifications are delivered via the [UserNotifications Framework](https://developer.apple.com/documentation/usernotifications)

# Usage
## Basic Usage
```
OVERVIEW: Notifier 3.1: Posts alert or banner notifications.

USAGE: --type <alert/banner> --message <some message> <options>
       --type <alert/banner> --remove prior <some message> <options>
       --type <alert/banner> --remove all
       --rebrand <path to image>

OPTIONS:
  --type <type>           alert or banner - REQUIRED.

  --message <message>     The notifications message.

  --messageaction <messageaction>
                          The action to be performed under the users account
                          when the message is clicked.

                          • Passing 'logout' will prompt the user to logout.
                          • If passed a single item, this will be launched via:
                          /usr/bin/open
                          • More complex commands can be passed, but the 1st
                          argument needs to be a binaries path.

                          For example: "/usr/bin/open" will work, "open" will
                          not.

  --messagebutton <messagebutton>
                          Adds a button to the message, with the label being
                          what is passed.

  --messagebuttonaction <messagebuttonaction>
                          The action to be performed under the users account
                          when the optional message button is clicked.

                          • Passing 'logout' will prompt the user to logout.
                          • If passed a single item, this will be launched via:
                          /usr/bin/open
                          • More complex commands can be passed, but the 1st
                          argument needs to be a binaries path.

                          For example: "/usr/bin/open" will work, "open" will
                          not.

  --rebrand <rebrand>     Requires root privileges and that the calling process
                          needs either Full Disk Access (10.15+) or at a
                          minimum App Management (macOS 13+) permissions, as
                          well as the notifying applications being given
                          permission to post to Notification Center. Any of
                          these permissions can be granted manually, but
                          ideally via PPPCP's delivered via an MDM.

                          If successful and someone is logged in, Notification
                          Center is restarted.

  --remove <remove>       "prior" or "all". If passing "prior", the full
                          message will be required too. Including all passed
                          flags.

  --sound <sound>         The sound to play when notification is delivered.
                          Pass "default" for the default macOS sound, else the
                          name of a sound in /Library/Sounds or
                          /System/Library/Sounds.

                          If the sound cannot be found, macOS will use the
                          "default" sound.

  --subtitle <subtitle>   The notifications subtitle.

  --title <title>         The notifications title.

  --verbose               Enables logging of actions. Check console for
                          'Notifier' messages.

  --help                  Show help information.

```

## Examples
The below aim to give you an idea of what so the various notification options look like, across macOS versions as well as Light and Dark mode.

As you can see, some of the behaviour and appearence is OS dependent.

**Example 1** This example shows a basic banner notification.

macOS 10.15.7 - Light Mode |  macOS 14.3 - Dark mode
:-------------------------:|:-------------------------:
<img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/20af5bb9-1e6e-4158-bbc4-67dbd003d7f8" width="317" height="100">  |  <img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/bf8a477c-3ebc-4c54-b4ef-eaa6df8dc052" width="317" height="100">

```
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type banner --message "message"
```
##
**Example 2** This example shows a basic alert notification.
macOS 10.15.7 - Light Mode |  macOS 14.3 - Dark mode
:-------------------------:|:-------------------------:
<img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/1bca78ef-8865-4762-902b-081ac39b9c80" width="317" height="100">  |   <img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/e3f6e325-d7d0-49e8-8bfc-34c19025d472" width="317" height="100">

```
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message "message" --messagebutton "Logout" --messagebuttonaction "Logout"
```
##
**Example 3** This example shows both alert & banner notifications, (sleep used for the example gif, not needed in use but below for completeness sake).
macOS 10.15.7 - Light Mode |  macOS 14.3 - Dark mode
:-------------------------:|:-------------------------:
<img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/8741ccea-f481-46a0-8f15-b97acde2e0c1" width="317" height="154">  |  <img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/dd1f1775-3392-4d24-84b2-dd55aca6d02d" width="317" height="154">

```
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message "Please Logout" --messagebutton "Logout"  --messagebuttonaction "logout" --title "Logout";
/bin/sleep 2;
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type banner --message "👋" --title "Notification"
```
##
**Example 4** This example shows selective remove of a delivered notificaition via `--remove prior`. Where applicable this would also remove notifications from within Notification Center itself.
macOS 10.15.7 - Light Mode |  macOS 14.3 - Dark mode
:-------------------------:|:-------------------------:
<img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/854440ab-ee52-443b-8d65-ebcad501f194" width="317" height="154">  |  <img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/a0e04d63-0e9f-474d-ba8e-1fa97bdf18be" width="317" height="154">

```
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message 'Look at me!!';
/bin/sleep 2; 
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message "message" --messagebutton "Logout";
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message 'Look at me!!' --remove prior
```
##
**Example 5** This example shows removal of all alert notifications and also the differences of delivery of alert notifications across macOS versions, additionally this removes any prior delivered notificaions from Notification Center. Sleep used for the example gif, not needed in use but below for completeness sake.

macOS 10.15.7 - Light Mode |  macOS 14.3 - Dark mode
:-------------------------:|:-------------------------:
<img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/8f4abba7-7866-4e80-8aad-1bc77dcda50c" width="317" height="374">  |  <img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/11902803-3e4e-4ac8-8dda-5c4f0994896e" width="317" height="374">

```
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message message;
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message message1;
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message message2;
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message message3;
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message message4;
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message message5;
/bin/sleep 5;
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --remove all
```
##
**Example 6** This example shows Notifier 3.0+'s `--rebrand` argument in use, this allows for rebranding of Notifier without having to venture into Xcode etc.
macOS 10.15.7 - Light Mode |  macOS 14.3 - Dark mode
:-------------------------:|:-------------------------:
<img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/ea45ad52-96ec-49a1-8679-4d1461451ea5" width="317" height="154">  |  <img src="https://github.com/Jamf-Concepts/Notifier/assets/2464974/49894a04-17e8-4257-9923-e438418a6785" width="317" height="154">

```
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type alert --message "message";
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type banner --message "message";
/bin/sleep 2;
/usr/bin/sudo /Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --rebrand /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ErasingIcon.icns;
/bin/sleep 2;
/usr/bin/sudo /Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type banner --message "message";
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --rebrand /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFileServerIcon.icns;
/bin/sleep 2;
/usr/bin/sudo /Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type banner --message "message";
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --rebrand /Applications/Utilities/Notifier.app/Contents/Resources/AppIcon.icns;
/bin/sleep 2;
/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier --type banner --message "message"
```

# Deployment

## PPPC
It's recommended that the below profile is recommended to be deployed before Notfier itself, to UAMDM devices.
(https://github.com/Jamf-Concepts/Notifier/blob/master/profile/Allow%20Notifier%20Notifications.mobileconfig)

This will allow Notifier to post Notifications without prompting the user to allow.

Additionally, if you're looking to make use of the `--rebrand` flag the calling process needs either Full Disk Access/SystemPolicyAllFiles (10.15+) or at a
minimum App Management/SystemPolicyAppBundles (macOS 13+) permissions, as well as the notifying applications being given permission to post to Notification Center.

Any of these permissions can be granted manually, but ideally via PPPCP's delivered via an MDM.

## PKG
PKG's will be supplied for every release, & can be found in the [releases](https://github.com/Jamf-Concepts/Notifier/releases) section.

## Flow

The below is the advised deployment flow for Notifier.

1. If rebranding - deploy a PPPC for your management tool of choice, granting either Full Disk Access/SystemPolicyAllFiles (10.15+) or App Management/SystemPolicyAppBundles (macOS 13+).
2. Deploy the [Notications PpPC](https://github.com/Jamf-Concepts/Notifier/blob/master/profile/Allow%20Notifier%20Notifications.mobileconfig) to UAMDM devices
3. Deploy the latest [Notifier PKG](https://github.com/Jamf-Concepts/Notifier/releases)
4. If rebranding - deploy the image to use when rebranding.
5. if rebranding - deploy a script or payload free package etc which rebrands Notifier via your management tool. This needs to be down with admin/root privileges.

# How it works
The main Notifier.app parses arguments passed to it (via [Argument Parser](https://apple.github.io/swift-argument-parser/documentation/argumentparser/), and then posts the parsed argument to the two notifying applications included with the the /Contents/Helpers folder of Notifier.app:

```
/Applications/Utilities/Notifier.app/Contents/Helpers/
                                                      Notifier - Alerts.app
                                                      Notifier - Notifications.app
```
Additionally the Notifier.app also checks tha Notification Center is running, & runs the notifying apps in the user context.

The notifying apps (/Applications/Utilities/Notifier.app/Contents/Helpers/Notifier - Alerts.app and /Applications/Utilities/Notifier.app/Contents/Helpers/Notifier - Notifications.app) both post notifications via the [UserNotifications Framework](https://developer.apple.com/documentation/usernotifications).

# Miscellaneous

## Resetting Notifications Center
The below _should_ reset Notifications Center, but please test & submit a PR with a better method as applicable.

1. `/bin/rm -rf $(getconf DARWIN_USER_DIR)/com.apple.notificationcenter/*`
2. Logout & then log back in, or:
* For macOS 10.15+: `/usr/bin/killall "NotificationCenter"`
3. Test the Notifier once more

# FAQs

**Q1:** Why start at version 2?

**A1:** When dataJAR created this, they already had a v1 "Notifier" app deployed.
##
**Q2:** How can you post both banner & alert notifications?

**A2:** See [How it works](#how-it-works)
##
**Q3:** The users are being prompted to allow.. help!

**A3:** This can be due to a few things:

1. Was the notifications profile installed? If not, install.
1. Is the device under UAMDM? If not, check with your MDM vendor on making the device UAMDM. Then try again & maybe reinstall the profile once under UAMDM.
1. Did you change the Bundle ID of either the Alert or Banner applications? If so you'll need to amend the notifications profile accordingly.
##
**Q4:** Is that logo magen...

**A4:** No, it's a shade of pink...
##
**Q5:** Banner or Notifications?

**A5:** The temporary notifications are referred to as "banner" notifications in Apple's documentation, but it seems that most folks call them "Notifications" with the persistent notifications being referred to as alerts by folks as well as within Apple's documentation.
##
**Q6:** I'm seeing alerts when expecting banner notifications, & vice versa

**A6:** Check the Notification settings within System Preferences/System Settings, it's possible that the incorrect option has been selected or set via a profile.
##
**Q7:** --remove prior, didn't clear my last message.

**A7:** Make sure you pass EXACTLY the same message to be cleared.
##
**Q8:** I've rebranded, but the old icon is being shown..

**A8:** Please reset Notification Center as per the [Resetting Notifications Center](#resetting-notifications-center), then try again.
##
**Q9:** Does rebranding work when no one is logged in?

**A9:** Yep, and no restart of Notification Center is needed.
##
**Q10** Why are notifcations all of a sudden showing a prohibted sign across the icon?

**A10** This is a [macOS issue](https://macmule.com/2021/10/28/notifications-showing-a-prohibitory-symbol-after-upgrading-macos-monterey/) that has goes back some years, to resolve either restart Notification Center or the Mac.
##
**Q11** Why does rebranding no longer work on macOS 26.4?

**A11** This seems to have been an Apple change. Feedback has been filed, but no response as of yet. Once there is a reponse we can look to amend this appropriately.
##
**Q12:** Why the jump to version 4?

**A1:** With version 4, Notifier's bundle id's, notarisation and signing changed to Jamf. This needs new profiles being deployed etc, so a major version bump seemed reasonable.

# Alternatives
The below projects can be used instead of Notifier & were very much instrumental in Notifiers creation

## Alert Notifications
[Yo](https://github.com/sheagcraig/yo)

## Banner Notifications
[Terminal Notifier](https://github.com/julienXX/terminal-notifier)

