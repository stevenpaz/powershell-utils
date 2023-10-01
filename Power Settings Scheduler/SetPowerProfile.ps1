param (
    [ValidateSet('Power saver', 'High performance', 'Balanced', 'Ultimate Performance')]
    [string]$powerProfile
)

# Enable debug messages to be printed to the console
# $DebugPreference = 'Continue'

# Define log level: "Debug", "Info", "Warning", "Error"
$logLevel = "Info"

# Define the path of the log file
$logFile = "C:\Scripts\Power Settings Scheduler\SetPowerProfile.log"

# Function to check if the script is being run by Task Scheduler
function IsScheduledTask {
    $parentProcess = Get-WmiObject Win32_Process -Filter "processid=$($pid)" | Select-Object ParentProcessId
    $parentProcessName = Get-Process -Id $parentProcess.ParentProcessId | Select-Object -ExpandProperty ProcessName

    return ($parentProcessName -eq 'svchost' -or $parentProcessName -eq 'taskeng')
}

# Function to handle logging
function Log {
    param (
        [string]$level = "Info",
        [string]$message
    )
    
    $username = $env:USERNAME

    if (IsScheduledTask) {
        $username = "schtsk_$username"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$level] [$username] $message"

    switch ($level) {
        "Debug" {
            if ($logLevel -eq "Debug") {
                Write-Debug $logMessage
                Add-Content -Path $logFile -Value $logMessage
            }
        }
        "Info" {
            Write-Host $logMessage
            Add-Content -Path $logFile -Value $logMessage
        }
        "Error" {
            Write-Error $logMessage
            Add-Content -Path $logFile -Value $logMessage
        }
        "Warning" {
            Write-Warning $logMessage
            Add-Content -Path $logFile -Value $logMessage
        }
    }
}

function LogDebug { 
    param (
        [string]$message
    )

    Log "Debug" $message
}

function LogInfo { 
    param (
        [string]$message
    )

    Log "Info" $message
}

function LogError { 
    param (
        [string]$message
    )

    Log "Error" $message
}

function LogWarning { 
    param (
        [string]$message
    )

    Log "Warning" $message
}

# Function to get the GUID of the power scheme based on the name
function Get-PowerSchemeGUID {
    param (
        [string]$powerSchemeName
    )

    LogDebug "Getting list of all power schemes"
    $powerSchemes = powercfg /list | Out-String -Stream

    # Print all power schemes for debugging
    LogDebug "All Power Schemes: `n$powerSchemes"

    LogDebug "Searching for the power scheme named: $powerSchemeName"

    foreach ($scheme in ($powerSchemes -split "`n")) {
        if ($scheme -match "Power Scheme GUID: (.*)\s+\((.*)\)") {
            LogDebug "GUID: $($matches[1]) - Name: $($matches[2])"

            if ($matches[2] -eq $powerSchemeName) {
                $result = $matches[1].Trim()
                LogDebug "Match found! GUID: '$($result)'"
                return $result
            }
        } 
        
    }

    LogWarning "Power Scheme Name $powerSchemeName not found."
    return $null
}

# Function to set the power scheme
function Set-PowerScheme {
    param (
        [string]$powerSchemeName
    )

    if ($null -eq $powerSchemeName -or $powerSchemeName -eq "") {
        LogError "Power Scheme Name not provided: null or empty"
        return $null
    }

    $guid = Get-PowerSchemeGUID -powerSchemeName $powerSchemeName
    if ($null -eq $guid -or $guid -eq "") {
        LogError "Failed to retrieve the GUID for $powerSchemeName."
        return $null
    }

    $result = powercfg -setactive $guid 2>&1
    if ($null -ne $result -and $result -ne "") {
        LogError "Failed to set the power profile to $powerSchemeName : $result"
        return $null
    }

    LogInfo "Power profile set to $powerSchemeName ($guid)."
}

# Check if powerProfile parameter is provided
# If it is not, launch a GUID drop-down.
if ($null -eq $powerProfile -or $powerProfile -eq "") {
    # Load the assembly required for Windows Forms
    Add-Type -AssemblyName System.Windows.Forms

    # Create a form
    $form = New-Object System.Windows.Forms.Form 
    $form.Text = "Select a Power Plan"
    $form.Size = New-Object System.Drawing.Size(300,150) 

    # Create a ComboBox to display power plans
    $comboBox = New-Object System.Windows.Forms.ComboBox 
    $comboBox.Location = New-Object System.Drawing.Point(30,30)
    $comboBox.Size = New-Object System.Drawing.Size(200,20) 
    $comboBox.Items.Add('Power saver')
    $comboBox.Items.Add('Balanced')
    $comboBox.Items.Add('High performance')
    $comboBox.Items.Add('Ultimate Performance')
    $form.Controls.Add($comboBox) 

    # Add a button to submit the form
    $button = New-Object System.Windows.Forms.Button 
    $button.Location = New-Object System.Drawing.Point(100,60) 
    $button.Size = New-Object System.Drawing.Size(75,23) 
    $button.Text = "OK"
    $button.Add_Click({
        $form.Tag = $comboBox.Text
        $form.Close()
    })
    $form.Controls.Add($button)

    # Display the form and capture the selected power plan
    LogInfo "Launched GUI."
    $form.ShowDialog() | Out-Null
    $powerProfile = $form.Tag
    LogInfo "User selected: $powerProfile"
}

# Set the selected power plan
Set-PowerScheme -powerSchemeName $powerProfile