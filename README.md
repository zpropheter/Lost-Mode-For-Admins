# Jamf Lost Mode Viewer

A simple tool to query Jamf Cloud devices and display Lost Mode locations in a browser or WebView. Built as a Bash + Python script leveraging the Jamf API.

---

## Features

- Query Jamf Cloud for **mobile devices**.
- Filter devices with **Lost Mode enabled**.
- View **Lost Mode location** for a selected user in a **WebView window**.
- Supports interactive selection of devices via **dropdown dialogs**.

---

## Dependencies

- **Python 3** (macOS comes with Python 3.x; Linux/Windows requires installation)
- **[PyWebView](https://pywebview.flowrl.com/)**  
  Install with:

```bash
pip3 install pywebview
```

### jq

#### macOS (<15.0)
```
brew install jq
```
#### Linux (Debian/Ubuntu)
```
sudo apt-get install jq
```

### Jamf API credentials with the following permissions:

View Lost Mode Location
Read Mobile Devices


# Setup
- Add the webviewlostmode.sh script to Settings> Scripts in Jamf Pro
- Add parameter labels for 4-6 as Jamf Pro URL, API Client ID, and API Client Secret respectively
- Create a Self Service Policy with the script as a payload
- Enter the parameter values for 4-6

# Usage
- Make sure you have installed pywebview
- Run the policy from Self Service
- Select the email of the device that has lost mode enabled that you want to track
- A webview will open with the location of the device
