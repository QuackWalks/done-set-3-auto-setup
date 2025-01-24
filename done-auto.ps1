## Setup script by Doakyz


## Changelog
## V3 - Rework of code by QuackWalks and *shudders* Microsoft Copilot for use with Done Set 3
## V2 - Complete rework of code, additional user input settings based on feedback from Quack Walks
## V1 - Initial proof of concept, extracts zips into target directory, only works in powershell ISE
##

# Initialize GUI resources
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName presentationframework
Add-Type -AssemblyName microsoft.VisualBasic
[System.Windows.Forms.Application]::EnableVisualStyles()

# Required for use with web SSL sites
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Load necessary modules
Import-Module Microsoft.PowerShell.Management
Import-Module Microsoft.PowerShell.Utility

# Function to display GUI folder selection dialog
function Show-FolderDialog {
    param(
        [string]$initialDirectory
    )
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select a directory"
    $folderDialog.RootFolder = "MyComputer"
    if (-not [string]::IsNullOrWhiteSpace($initialDirectory)) {
        $folderDialog.SelectedPath = $initialDirectory
    }
    $result = $folderDialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderDialog.SelectedPath
    } else {
        return $null
    }
}

# Get the extraction location using the GUI folder selection dialog
Write-Host "Select the extraction path."
$extractionPath = Show-FolderDialog -initialDirectory ([System.Environment]::GetFolderPath('Desktop'))

# Check if the extraction path exists, if not, create it
if (-not (Test-Path -Path $extractionPath)) {
    New-Item -ItemType Directory -Path $extractionPath | Out-Null
}

# Function to prompt for yes or no answers
function Prompt-YesNoQuestion {
    while ($true) {
        Write-Host "Y or N ?"
        $choice = Read-Host

        if ($choice -eq 'y') {
            return $true
        } elseif ($choice -eq 'n') {
            return $false
        } else {
            Write-Host "Invalid choice. Please enter 'y' or 'n'."
        }
    }
}

# Function to prompt for additional zip files based on the storage capacity
function Prompt-AdditionalZipFiles {
    param(
        [string]$extractionPath
    )
    $additionalZipFiles = @()

    # Configs
    Write-Host "Do you want optimizations and overlays? (recommended)"
    if (Prompt-YesNoQuestion) {
        # Prompt for model type
        $validChoice = $false
        while (-not $validChoice) {
            Write-Host "What model do you have?"
            Write-Host "1. Plus Model"
            Write-Host "2. V4 Model"
            $modelChoice = Read-Host
            switch ($modelChoice) {
                1 {
                    $configsZipFile = "Configs for Plus Model.zip"
                    $validChoice = $true
                }
                2 {
                    $configsZipFile = "Configs for V4 Model.zip"
                    $validChoice = $true
                }
                default {
                    Write-Host "Invalid choice. Please enter '1' or '2'."
                }
            }
        }

        if ($configsZipFile -ne $null) {
            $additionalZipFiles += $configsZipFile
        }
    }

    # Sensible Console Arrangement
    Write-Host "Would you like a sensible arrangement of consoles (non-alphabetical)?"
    if (Prompt-YesNoQuestion) {
        $sensibleArrangementZipFile = "Sensible Console Arrangement.zip"
        if ($sensibleArrangementZipFile -ne $null) {
            $additionalZipFiles += $sensibleArrangementZipFile
        }
    }

    # Manuals
    Write-Host "Do you want game manuals?"
    if (Prompt-YesNoQuestion) {
        $manualsZipFile = "Manuals.zip"
        if ($manualsZipFile -ne $null) {
            $additionalZipFiles += $manualsZipFile
        }
    }

    # Cheats
    Write-Host "Do you want cheats?"
    if (Prompt-YesNoQuestion) {
        $cheatsZipFile = "Cheats.zip"
        $additionalZipFiles += $cheatsZipFile

        # Locate and modify the retroarch.cfg file
        $configFilePath = "$extractionPath/RetroArch/.retroarch/retroarch.cfg"
        if (Test-Path $configFilePath) {
            (Get-Content $configFilePath) -replace 'quick_menu_show_cheats = "false"', 'quick_menu_show_cheats = "true"' | Set-Content $configFilePath
            Write-Host "Modified $configFilePath to enable cheats."
        } else {
            Write-Host "Config file not found: $configFilePath"
        }
    }

    # Thumbnails
    $validChoice = $false
    while (-not $validChoice) {
        Write-Host "Select your thumbnail option"
        Write-Host "1. 2D Box and Screenshot"
        Write-Host "2. 2D Box"
        Write-Host "3. Miyoo Mix"
        Write-Host "4. None"
        $pictureChoice = Read-Host
        switch ($pictureChoice) {
            1 { $additionalZipFiles += "Imgs (2D Box and Screenshot).zip"; $validChoice = $true }
            2 { $additionalZipFiles += "Imgs (2D Box).zip"; $validChoice = $true }
            3 { $additionalZipFiles += "Imgs (Miyoo Mix).zip"; $validChoice = $true }
            4 { $validChoice = $true }
            default { Write-Host "Invalid choice. Please enter '1', '2', '3' or '4'." }
        }
    }

    # PS1 Addon for 256GB SD Cards
    Write-Host "Would you like to install the PS1 addon for 256GB SD cards?"
    if (Prompt-YesNoQuestion) {
        $ps1AddonZipFile = "PS1 Addon for 256gb SD Cards.zip"
        if ($ps1AddonZipFile -ne $null) {
            $additionalZipFiles += $ps1AddonZipFile
        }
    }

    return $additionalZipFiles
}

# Function to update progress bar with asterisks
function Update-ProgressBar {
    param (
        [int]$percentage
    )
    $progressBar = "*" * ([math]::Round($percentage / 5))  # Each asterisk represents 5%
    Write-Host -NoNewline -Object "`r[$progressBar] $percentage% complete"
}

# Function to get the current sleep settings
function Get-SleepSettings {
    return @{
        SleepOnAC = (powercfg -query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE).Split()[4]
        SleepOnBattery = (powercfg -query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE).Split()[4]
    }
}

# Function to set the sleep settings
function Set-SleepSettings {
    param (
        [string]$onAC,
        [string]$onBattery
    )
    powercfg -change -standby-timeout-ac $onAC
    powercfg -change -standby-timeout-dc $onBattery
}

# Save the current sleep settings
$currentSleepSettings = Get-SleepSettings

# Disable sleep
Set-SleepSettings -onAC 0 -onBattery 0

# Notify user about sleep setting change
Write-Host "Sleep settings have been disabled to prevent the computer from sleeping during extraction."

# Base zip file to always extract
$baseZipFile = "Done Set 3.zip"

# Get additional zip files to be extracted
$zipFilePaths = Prompt-AdditionalZipFiles -extractionPath $extractionPath

# Prompt the user for confirmation to start the extraction
Write-Host "`n"
Write-Host "Please review your selections before proceeding with the extraction."
Write-Host "`n"
Write-Host "Zip files to be extracted:"
foreach ($zipFilePath in $zipFilePaths) {
    Write-Host "- $zipFilePath"
}
Write-Host "`n"
Write-Host "Base zip file: $baseZipFile"
Write-Host "`n"
Write-Host "Extraction path: $extractionPath"
Write-Host ""

$confirmationPrompt = "Do you want to proceed with the extraction? (yes/no)"
$proceedWithExtraction = $null

while ($proceedWithExtraction -notin "yes", "no") {
    $choice = Read-Host -Prompt $confirmationPrompt

    if ($choice -eq "yes") {
        $proceedWithExtraction = $true
        break  # Exit the loop to start extraction
    } elseif ($choice -eq "no") {
        Write-Host "Extraction aborted by user."
        exit
    } else {
        Write-Host "Invalid choice. Please enter 'yes' or 'no'."
    }
}

# Perform the extraction with the -Force parameter to overwrite existing files
if ($proceedWithExtraction) {
    try {
        # Extract the base zip file
        if (Test-Path $baseZipFile) {
            Expand-Archive -Path $baseZipFile -DestinationPath $extractionPath -Force
            Write-Host "Extracted $baseZipFile to $extractionPath"
        } else {
            Write-Host "File not found: $baseZipFile"
        }

        # Extract additional zip files
        $totalFiles = $zipFilePaths.Count + 1  # Including the base zip file
        $extractedFiles = 1

        foreach ($zipFilePath in $zipFilePaths) {
            if (Test-Path $zipFilePath) {
                Expand-Archive -Path $zipFilePath -DestinationPath $extractionPath -Force
                Write-Host "Extracted $zipFilePath to $extractionPath"
                $extractedFiles++
                $percentage = [math]::Round(($extractedFiles / $totalFiles) * 100)
                Update-ProgressBar -percentage $percentage
            } else {
                Write-Host "File not found: $zipFilePath"
            }
        }

        Write-Host "`nExtraction completed. Files extracted to: $extractionPath"
    } catch {
        Write-Host "An error occurred during extraction: $_"
    }
}

# Restore the original sleep settings
Set-SleepSettings -onAC $currentSleepSettings.SleepOnAC -onBattery $currentSleepSettings.SleepOnBattery

# Notify user about restoring sleep settings
Write-Host "Sleep settings have been restored to their original values."

# Notify user that the process is complete and prompt for manual exit
Write-Host "The extraction process is complete. Please press Enter to exit."
Read-Host
