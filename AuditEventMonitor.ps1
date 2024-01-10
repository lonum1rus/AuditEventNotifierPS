# Telegram Details
$TelegramToken = "your-telegram-bot-token" # Replace with Telegram Token
$TelegramChatId = "your-telegram-chat-id" # Replace with Telegram Chat ID

# Define the Event IDs to monitor
$eventIDs = 4728, 4732, 4729, 4720, 4722, 4723, 4724, 4725, 4726, 4735, 4740, 4767

# Define the log to monitor, usually 'Security' for these event types
$logName = 'Security'

# Log file path
$logFilePath = "C:\\path\\to\\your\\logfile.p"

# Ensure log file directory exists
if (-not (Test-Path (Split-Path $logFilePath -Parent))) {
    New-Item -ItemType Directory -Path (Split-Path $logFilePath -Parent) -Force
}

# Function to send a message via Telegram
function Send-TelegramMessage($message) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = "https://api.telegram.org/bot$TelegramToken/sendMessage?chat_id=$TelegramChatId&text=$message"
    Invoke-RestMethod -Uri $uri -Method Post -ErrorAction SilentlyContinue | Out-Null
}

# Function to check if an event is already logged
function IsEventLogged($eventId, $eventTime) {
    if (Test-Path $logFilePath) {
        $loggedEvents = Get-Content $logFilePath
        foreach ($loggedEvent in $loggedEvents) {
            if ($loggedEvent -eq "$eventId $eventTime") {
                return $true
            }
        }
    }
    return $false
}

# Function to log an event
function LogEvent($eventId, $eventTime) {
    "$eventId $eventTime" | Out-File -Append -FilePath $logFilePath
}

# Function to create a unique identifier for an event
function CreateEventIdentifier($eventId, $eventTime, $additionalInfo) {
    return "$eventId-$eventTime-$additionalInfo"
}

function ProcessEvent($event) {
    $eventId = $event.Id
    $eventTime = $event.TimeCreated.ToString("o") # ISO 8601 format
    $message = $event.Message
    $formattedMessage = ""
    $eventName = $null

    # For Event ID 4724, extract and validate Target Account Name
    $targetAccountName = ""
    if ($eventId -eq 4724) {
        if ($message -match "Target Account:\s+[^\r\n]+\s+Account Name:\s+([^\r\n]+)") {
            $targetAccountName = $matches[1].Trim()
        }

        # Skip processing if Target Account Name is not properly extracted
        if (-not $targetAccountName -or $targetAccountName -match "Account Domain:") {
            return
        }
    }

    # Define event names based on Event ID
    switch ($eventId) {
        4728 { $eventName = "Added member to global group" }
        4732 { $eventName = "Added member to local group" }
        4729 { $eventName = "Removed member from global group" }
        4720 { $eventName = "User account created" }
        4722 { $eventName = "User account enabled" }
        4723 { $eventName = "Attempt to change password" }
        4724 { $eventName = "Attempt to reset password" }
        4725 { $eventName = "User account disabled" }
        4726 { $eventName = "User account deleted" }
        4735 { $eventName = "Changed local group" }
        4740 { $eventName = "User account locked out" }
        4767 { $eventName = "User account unlocked" }
        default { $eventName = "Unknown Event" }
    }

# Create a unique identifier for the event
    $additionalInfo = ""
    if ($eventId -eq 4724) {
        $additionalInfo = if ($message -match "Target Account:\s+[^\r\n]+\s+Account Name:\s+([^\r\n]+)") { $matches[1].Trim() } else { "" }
    }

    $eventIdentifier = CreateEventIdentifier $eventId $eventTime $additionalInfo

    # Check if the event is already logged
    if (-not (IsEventLogged $eventIdentifier)) {
        LogEvent $eventIdentifier

        # Determine status based on Keywords
        $status = if ($event.KeywordsDisplayNames -contains 'Audit Failure') { "Failed" } else { "Success" }

        # Extract and format message based on event type
switch ($eventId) {
    { $_ -in @(4724, 4767) } { # Events like password reset/unlock
        $byUser = if ($message -match "Account Name:\s+([^\r\n]+)\r\n") { $matches[1].Trim() } else { "" }
        $targetUser = if ($message -match "Target Account:\s+[^\r\n]+\s+Account Name:\s+([^\r\n]+)") { $matches[1].Trim() } else { "" }

        $formattedMessage = "Event ID: $eventId`nEvent Name: $eventName`nStatus: $status`nBy user: $byUser`nTarget User: $targetUser"
    }
    { $_ -in @(4728, 4729, 4732, 4720, 4722, 4723, 4725, 4726, 4735, 4740) } { # Other specified event types
        $byUser = if ($message -match "Account Name:\s+([^\r\n]+)\r\n") { $matches[1].Trim() } else { "" }
        $user = if ($message -match "Account Name:\s+CN=([^,]+)") { $matches[1] } else { "" }
        $ou = if ($message -match "OU=([^,]+),OU=([^,]+)") { $matches[2] } else { "" }
        $groupName = if ($message -match "Group Name:\s+([^\r\n]+)") { $matches[1].Trim() } else { "" }

        $formattedMessage = "Event ID: $eventId`nEvent Name: $eventName`nStatus: $status`nUser: $user`nOU: $ou`nGroup Name: $groupName`nBy: $byUser"
    }
    default {
        # Default message format for unknown or unspecified events
        $formattedMessage = "Event ID: $eventId`nEvent Type: Unknown`nMessage: $message"
    }
}
        # Send the formatted message via Telegram
        Send-TelegramMessage -message $formattedMessage
    }
}

# Start monitoring for new events
Write-Host "Starting live monitoring for new events..."
$lastCheck = Get-Date

# Infinite loop to keep the script running
while ($true) {
    try {
        # Retrieve new events since last check
        $newEvents = Get-WinEvent -FilterHashtable @{LogName=$logName; ID=$eventIDs; StartTime=$lastCheck} -ErrorAction SilentlyContinue

        # Process and notify new events
        if ($newEvents) {
            foreach ($event in $newEvents) {
                ProcessEvent $event
            }
        } else {
            Write-Host "No new events since last check."
        }
    } catch {
        Write-Host "Error retrieving events. Waiting for the next interval."
    }

    # Update last check time
    $lastCheck = Get-Date

    # Wait for a certain time (e.g., 10 seconds) before checking again
    Start-Sleep -Seconds 10
}
