## Sunshine Host Display Switcher for Moonlight Streaming

This script changes your host display mode as soon as the client starts streaming, allowing you to have only your primary display turned on while streaming. The display mode is also configurable using the `config.txt` file.

> [!NOTE]
> This is for users who doesn't want to buy another dummy plug or if you don't have enough slots for it. Otherwise, use [MonitorySwapAutomation](https://github.com/Nonary/MonitorSwapAutomation) by Nonary

![image](https://github.com/rairulyle/Sunshine-AutoDisplaySwitch/assets/12708526/03d3660b-7720-4899-9d0a-340ed5a07afe)

### Requirements

- Host must be Windows.
- Sunshine 0.21.0 or higher

### Caveats:

- If using Windows 11, you'll need to set the default terminal to Windows Console Host as there is currently a bug in Windows Terminal that prevents hidden consoles from working properly.
  - That can be changed at Settings > System > For Developers > Terminal [Let Windows decide] >> (change to) >> Terminal [Windows Console Host]
  - On older versions of Windows 11 it can be found at: Settings > Privacy & security > Security > For developers > Terminal [Let Windows decide] >> (change to) >> Terminal [Windows Console Host]
- The script will stop working if you move the folder, simply reinstall it to resolve that issue.
- Due to Windows API restrictions, this script does not work on cold reboots (hard crashes or shutdowns of your computer).
  - If you're cold booting, simply sign into the computer using the "Desktop" app on Moonlight, then end the stream, then start it again.

<!-- #### GFE Users
- You'll need to use the Geforce Experience version of this script instead.
  - The current release for Geforce Experience users is: https://github.com/Nonary/ResolutionAutomation/releases/tag/2.0.15_gfe -->

### Installation Instructions

1. Store the downloaded folder in a location you intend to keep. If you delete this folder or move it, the automation will stop working.
2. To install, double click the Install.bat file.
3. To uninstall, double click the Uninstall.bat file.

This script will ask for elevated rights because Sunshine configuration is be locked from modifications for non-administrator users.

### How it Works

1. When you start streaming any application in Sunshine, it will start the script.
2. It sets the host display to the mode specified in `do` in the `config` file.
3. The script waits for Sunshine to be suspended for more than 120 seconds or until the user ends the stream.
4. It sets the host display back to the mode specified in `undo` in the `config` file.

### Config File

You may have a mobile device that you wish to stream at a lower resolution to save bandwidth or some devices may perform better when streaming at a lower resolution. If you want your host to change the resolution to something higher than the client, use the `config` file to do this.

#### Default

```
do=internal
undo=extend
```

| Mode     | Description            |
| -------- | ---------------------- |
| internal | Primary Monitor Only   |
| external | Secondary Monitor Only |
| extend   | Extend to all Monitors |
| clone    | Clone Primary Monitor  |

### Credits

- Windows 11 DisplaySwitch fix by [u/gerardfraser](https://www.reddit.com/r/windowsinsiders/comments/uurnqd/comment/ipeoq15)
- Install/Uninstall script by [Nonary](https://github.com/Nonary)
