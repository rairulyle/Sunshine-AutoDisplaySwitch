param(
    $install
)
$filePath = $($MyInvocation.MyCommand.Path)
$scriptRoot = Split-Path $filePath -Parent
$scriptPath = "$scriptRoot\DisplaySwitch.ps1"


# This script modifies the global_prep_cmd setting in the Sunshine configuration file
# to add a command that runs DisplaySwitch.ps1

# Check if the current user has administrator privileges
$isAdmin = [bool]([System.Security.Principal.WindowsIdentity]::GetCurrent().groups -match 'S-1-5-32-544')

# If the current user is not an administrator, re-launch the script with elevated privileges
if (-not $isAdmin) {
    Start-Process powershell.exe  -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$filePath`" $install"
    exit
}

function Test-AndRequest-SunshineConfig {
    param(
        [string]$InitialPath
    )

    # Check if the initial path exists
    if (Test-Path $InitialPath) {
        Write-Host "File found at: $InitialPath"
        return $InitialPath
    }
    else {
        # Show error message dialog
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        [System.Windows.Forms.MessageBox]::Show("Sunshine configuration could not be found. Please locate it.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)  | Out-Null

        # Open file dialog
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Title = "Open sunshine.conf"
        $fileDialog.Filter = "Configuration files (*.conf)|*.conf"
        $fileDialog.InitialDirectory = [System.IO.Path]::GetDirectoryName($InitialPath)

        if ($fileDialog.ShowDialog() -eq "OK") {
            $selectedPath = $fileDialog.FileName
            # Check if the selected path is valid
            if (Test-Path $selectedPath) {
                Write-Host "File selected: $selectedPath"
                return $selectedPath
            }
            else {
                Write-Error "Invalid file path selected."
            }

        }
        else {
            Write-Error "Sunshine Configuiration file dialog was canceled or no valid file was selected."
            exit 1
        }
    }
}
        
# Define the path to the Sunshine configuration file
$confPath = Test-AndRequest-SunshineConfig -InitialPath  "C:\Program Files\Sunshine\config\sunshine.conf"
$scriptRoot = Split-Path $scriptPath -Parent



# Get the current value of global_prep_cmd from the configuration file
function Get-GlobalPrepCommand {

    # Read the contents of the configuration file into an array of strings
    $config = Get-Content -Path $confPath

    # Find the line that contains the global_prep_cmd setting
    $globalPrepCmdLine = $config | Where-Object { $_ -match '^global_prep_cmd\s*=' }

    # Extract the current value of global_prep_cmd
    if ($globalPrepCmdLine -match '=\s*(.+)$') {
        return $matches[1]
    }
    else {
        Write-Information "Unable to extract current value of global_prep_cmd, this probably means user has not setup prep commands yet."
        return [object[]]@()
    }
}

# Remove any existing commands that contain DisplaySwitch from the global_prep_cmd value
function Remove-Command{

    # Get the current value of global_prep_cmd as a JSON string
    $globalPrepCmdJson = Get-GlobalPrepCommand -ConfigPath $confPath

    # Convert the JSON string to an array of objects
    $globalPrepCmdArray = $globalPrepCmdJson | ConvertFrom-Json
    $filteredCommands = @()

    # Remove any DisplaySwitch Commands
    for ($i = 0; $i -lt $globalPrepCmdArray.Count; $i++) {
        if (-not ($globalPrepCmdArray[$i].do -like "*DisplaySwitch*")) {
            $filteredCommands += $globalPrepCmdArray[$i]
        }
    }

    return [object[]]$filteredCommands
}

# Set a new value for global_prep_cmd in the configuration file
function Set-GlobalPrepCommand {
    param (

        # The new value for global_prep_cmd as an array of objects
        [object[]]$Value
    )

    if ($null -eq $Value) {
        $Value = [object[]]@()
    }


    # Read the contents of the configuration file into an array of strings
    $config = Get-Content -Path $confPath

    # Get the current value of global_prep_cmd as a JSON string
    $currentValueJson = Get-GlobalPrepCommand -ConfigPath $confPath

    # Convert the new value to a JSON string
    $newValueJson = ConvertTo-Json -InputObject $Value -Compress

    # Replace the current value with the new value in the config array
    try {
        $config = $config -replace [regex]::Escape($currentValueJson), $newValueJson
    }
    catch {
        # If it failed, it probably does not exist yet.
        # In the event the config only has one line, we will cast this to an object array so it appends a new line automatically.

        if ($Value.Length -eq 0) {
            [object[]]$config += "global_prep_cmd = []"
        }
        else {
            [object[]]$config += "global_prep_cmd = $($newValueJson)"
        }
    }



    # Write the modified config array back to the file
    $config | Set-Content -Path $confPath -Force
}

# Add a new command to run DisplaySwitch.ps1 to the global_prep_cmd value
function Add-Command {

    # Remove any existing commands that contain DisplaySwitch from the global_prep_cmd value
    $globalPrepCmdArray = Remove-Command -ConfigPath $confPath

     # Read the values from config.txt
    $configFilePath = "$scriptRoot\config.txt"
    $configContent = Get-Content -Path $configFilePath | ForEach-Object {
        $key, $value = $_ -split '='
        [PSCustomObject]@{ Key = $key.Trim(); Value = $value.Trim() }
    }

    $do = $configContent | Where-Object { $_.Key -eq 'do' } | Select-Object -ExpandProperty Value
    $undo = $configContent | Where-Object { $_.Key -eq 'undo' } | Select-Object -ExpandProperty Value

    # Create a new object with the command to run DisplaySwitch.ps1
    $DisplaySwitchCommand = [PSCustomObject]@{
        do       = "powershell.exe -executionpolicy bypass -WindowStyle Hidden -file `"$($scriptPath)`" $do"
        elevated = "false"
        undo     = "powershell.exe -executionpolicy bypass -WindowStyle Hidden -file `"$($scriptPath)`" $undo"
    }

    # Add the new object to the global_prep_cmd array
    [object[]]$globalPrepCmdArray += $DisplaySwitchCommand

    return [object[]]$globalPrepCmdArray
}

$commands = @()
if ($install -eq "True") {
    $commands = Add-Command
}
else {
    $commands = Remove-Command
}


Set-GlobalPrepCommand $commands

$sunshineService = Get-Service -ErrorAction Ignore | Where-Object { $_.Name -eq 'sunshinesvc' -or $_.Name -eq 'SunshineService' }
# In order for the commands to apply we have to restart the service
$sunshineService | Restart-Service  -WarningAction SilentlyContinue
Write-Host "If you didn't see any errors, that means the script installed without issues! You can close this window."

