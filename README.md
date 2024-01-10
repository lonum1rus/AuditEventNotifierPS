# PowerShell Event Monitoring and Notification Script

## Overview
This PowerShell script is designed to monitor specific Windows Event IDs and send notifications via Telegram when these events occur. It's particularly useful for system administrators and IT professionals who need to stay informed about certain activities on their Windows systems.

## Features
- Monitors specified Windows Event IDs.
- Sends notifications via Telegram for new events.
- Suppresses duplicate notifications.
- Customizable event ID list and notification messages.
- Logs processed events to prevent duplicate notifications.

## Prerequisites
- PowerShell 5.1 or higher.
- Access to Windows Event Logs.
- A Telegram bot and a chat ID for sending notifications.

## Configuration
1. **Telegram Bot Token and Chat ID**: Replace `your-telegram-bot-token` and `your-telegram-chat-id` with your actual Telegram Bot Token and Chat ID in the script.
   ```powershell
   $TelegramToken = "your-telegram-bot-token"
   $TelegramChatId = "your-telegram-chat-id"

## 1. Event IDs: Modify the $eventIDs array to include the Event IDs you wish to monitor.
$eventIDs = 4728, 4732, 4729, ... # Add or remove Event IDs as needed

## 2. Log File Path: Set the path for the log file used to track processed events.
$logFilePath = "C:\\path\\to\\your\\logfile.p"

## Usage
Run the script in PowerShell with administrative privileges. The script will start monitoring the specified Event IDs and send Telegram notifications for new events.

## Example Notification
Event ID: 4724
Event Name: Attempt to reset password
Status: Failed
By user: username
Target User: target_username

## Limitations
The script needs to run continuously for real-time monitoring.
Event log message formats must match expected patterns for correct parsing.
Administrative privileges are required for accessing certain event logs.

## Disclaimer
This script is a quick scratch implementation and is subject to potential errors. 
It's provided "as is" without warranty of any kind, express or implied. While every effort has been made to provide a reliable script, users are advised to use it cautiously and at their own risk. 
The author(s) or contributors shall not be held liable for any direct, indirect, incidental, special, exemplary, or consequential damages resulting from the use of the software.
