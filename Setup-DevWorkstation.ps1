<#
.SYNOPSIS
    Developer Workstation Setup Automation Script for Windows 11 Pro
    
.DESCRIPTION
    This script automates the setup of a complete developer workstation on Windows 11 Pro.
    It installs essential development tools, sets up the environment, and configures system settings.
    
.PARAMETER SkipAdmin
    If set to $true, skips the administrator check (not recommended)
    
.PARAMETER LogPath
    Path where setup logs will be stored. Defaults to $env:TEMP\DevSetup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log
    
.EXAMPLE
    .\Setup-DevWorkstation.ps1
    
.EXAMPLE
    .\Setup-DevWorkstation.ps1 -LogPath "C:\Logs\setup.log"
    
.NOTES
    Author: DevOps Team
    Version: 1.0.0
    Created: 2026-01-02
    PowerShell Version: 5.1 or higher required
    Administrator privileges required
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $false)]
    [bool]$SkipAdmin = $false,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "$env:TEMP\DevSetup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# ============================================================================
# Global Configuration
# ============================================================================

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'Continue'

$ScriptVersion = "1.0.0"
$ScriptStartTime = Get-Date
$Global:SetupLog = @()

# ============================================================================
# Logging Functions
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
    Writes log messages to both console and log file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $Global:SetupLog += $logMessage
    
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
    
    Add-Content -Path $LogPath -Value $logMessage -ErrorAction SilentlyContinue
}

function Write-Header {
    <#
    .SYNOPSIS
    Writes a formatted header to the log
    #>
    param([string]$Text)
    
    $separator = "=" * 70
    Write-Log $separator
    Write-Log $Text
    Write-Log $separator
}

# ============================================================================
# Validation Functions
# ============================================================================

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
    Verifies that the script is running with administrator privileges
    #>
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Log "This script requires administrator privileges to run." -Level Error
        if (-not $SkipAdmin) {
            Write-Log "Exiting setup due to insufficient privileges." -Level Error
            exit 1
        }
        Write-Log "Admin check bypassed due to -SkipAdmin flag." -Level Warning
    }
    else {
        Write-Log "Administrator privileges verified." -Level Success
    }
}

function Test-WindowsVersion {
    <#
    .SYNOPSIS
    Validates that the system is running Windows 11
    #>
    $osInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $osVersion = [version]$osInfo.CurrentVersion
    $buildNumber = [int]$osInfo.CurrentBuildNumber
    
    Write-Log "Operating System: $($osInfo.ProductName) (Build: $buildNumber)"
    
    if ($osVersion.Major -lt 10 -or $buildNumber -lt 22000) {
        Write-Log "Windows 11 or higher is required for optimal compatibility." -Level Warning
    }
    else {
        Write-Log "Windows version check passed." -Level Success
    }
}

# ============================================================================
# Package Management Functions
# ============================================================================

function Install-Winget {
    <#
    .SYNOPSIS
    Ensures Windows Package Manager (winget) is installed and up to date
    #>
    Write-Header "Installing/Updating Windows Package Manager (winget)"
    
    try {
        $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetPath) {
            Write-Log "winget is already installed." -Level Success
            return $true
        }
        
        Write-Log "Installing Windows Package Manager from Microsoft Store..."
        
        # Attempt to install via Store
        $appPackage = 'Microsoft.DesktopAppInstaller'
        
        Write-Log "Note: winget may need to be installed from Microsoft Store manually."
        Write-Log "Opening Microsoft Store to install App Installer..."
        
        Start-Process -FilePath "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
        Start-Sleep -Seconds 3
        
        Write-Log "Please complete the installation in Microsoft Store and run this script again if needed." -Level Warning
        return $false
    }
    catch {
        Write-Log "Error installing winget: $_" -Level Error
        return $false
    }
}

function Install-Chocolatey {
    <#
    .SYNOPSIS
    Installs Chocolatey package manager if not already installed
    #>
    Write-Header "Installing Chocolatey Package Manager"
    
    try {
        $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
        
        if ($chocoPath) {
            Write-Log "Chocolatey is already installed." -Level Success
            return $true
        }
        
        Write-Log "Installing Chocolatey..."
        
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        
        $chocoInstallScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
        Invoke-Expression $chocoInstallScript
        
        Write-Log "Chocolatey installed successfully." -Level Success
        return $true
    }
    catch {
        Write-Log "Error installing Chocolatey: $_" -Level Error
        return $false
    }
}

# ============================================================================
# Development Tools Installation
# ============================================================================

function Install-DevelopmentTools {
    <#
    .SYNOPSIS
    Installs essential development tools
    #>
    Write-Header "Installing Development Tools"
    
    $tools = @(
        @{ Name = "git"; Package = "git"; Type = "Choco" }
        @{ Name = "Visual Studio Code"; Package = "vscode"; Type = "Choco" }
        @{ Name = "PowerShell 7"; Package = "powershell-core"; Type = "Choco" }
        @{ Name = "Node.js"; Package = "nodejs"; Type = "Choco" }
        @{ Name = "Python"; Package = "python"; Type = "Choco" }
        @{ Name = "Docker Desktop"; Package = "docker-desktop"; Type = "Choco" }
        @{ Name = "7-Zip"; Package = "7zip"; Type = "Choco" }
        @{ Name = "Notepad++"; Package = "notepadplusplus"; Type = "Choco" }
    )
    
    foreach ($tool in $tools) {
        try {
            Write-Log "Installing $($tool.Name)..."
            
            if ($tool.Type -eq 'Choco') {
                $installed = choco list --local-only | Select-String -Pattern "^$($tool.Package)\s" -ErrorAction SilentlyContinue
                
                if ($installed) {
                    Write-Log "$($tool.Name) is already installed." -Level Success
                }
                else {
                    choco install $tool.Package -y --no-progress
                    Write-Log "$($tool.Name) installed successfully." -Level Success
                }
            }
        }
        catch {
            Write-Log "Error installing $($tool.Name): $_" -Level Warning
        }
    }
}

function Install-DotNetTools {
    <#
    .SYNOPSIS
    Installs .NET development tools and SDKs
    #>
    Write-Header "Installing .NET Development Tools"
    
    try {
        Write-Log "Checking for .NET SDKs..."
        
        $dotnetInstalled = Get-Command dotnet -ErrorAction SilentlyContinue
        
        if ($dotnetInstalled) {
            Write-Log ".NET is already installed." -Level Success
            & dotnet --version
        }
        else {
            Write-Log "Installing .NET SDK..."
            choco install dotnet-sdk -y --no-progress
            Write-Log ".NET SDK installed successfully." -Level Success
        }
    }
    catch {
        Write-Log "Error with .NET installation: $_" -Level Warning
    }
}

function Install-DatabaseTools {
    <#
    .SYNOPSIS
    Installs database tools and clients
    #>
    Write-Header "Installing Database Tools"
    
    $dbTools = @(
        @{ Name = "SQL Server Management Studio"; Package = "sql-server-management-studio"; Type = "Choco" }
        @{ Name = "MySQL Workbench"; Package = "mysql-workbench"; Type = "Choco" }
        @{ Name = "DBeaver"; Package = "dbeaver"; Type = "Choco" }
    )
    
    foreach ($tool in $dbTools) {
        try {
            Write-Log "Installing $($tool.Name)..."
            choco install $tool.Package -y --no-progress
            Write-Log "$($tool.Name) installed successfully." -Level Success
        }
        catch {
            Write-Log "Error installing $($tool.Name): $_" -Level Warning
        }
    }
}

# ============================================================================
# Environment Configuration Functions
# ============================================================================

function Configure-GitEnvironment {
    <#
    .SYNOPSIS
    Configures Git with default settings
    #>
    Write-Header "Configuring Git Environment"
    
    try {
        $gitInstalled = Get-Command git -ErrorAction SilentlyContinue
        
        if (-not $gitInstalled) {
            Write-Log "Git is not installed. Skipping Git configuration." -Level Warning
            return
        }
        
        Write-Log "Configuring Git with default settings..."
        
        # Configure Git line endings for Windows
        git config --global core.autocrlf true
        git config --global core.safecrlf warn
        
        # Configure editor
        git config --global core.editor "code --wait"
        
        # Enable colored output
        git config --global color.ui true
        
        Write-Log "Git environment configured successfully." -Level Success
    }
    catch {
        Write-Log "Error configuring Git: $_" -Level Warning
    }
}

function Configure-PowerShellProfile {
    <#
    .SYNOPSIS
    Creates and configures PowerShell profile for development
    #>
    Write-Header "Configuring PowerShell Profile"
    
    try {
        $psProfilePath = $PROFILE
        $profileDir = Split-Path -Path $psProfilePath -Parent
        
        if (-not (Test-Path -Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
            Write-Log "Created PowerShell profile directory."
        }
        
        if (-not (Test-Path -Path $psProfilePath)) {
            $profileContent = @"
# PowerShell Development Profile
# Generated: $(Get-Date)

# Set location to home directory
Set-Location -Path `$HOME

# Create useful aliases
New-Alias -Name which -Value Get-Command -Force -ErrorAction SilentlyContinue

# Function: Create new directory and enter it
function New-DirectoryAndEnter {
    param([string]`$Path)
    New-Item -ItemType Directory -Path `$Path -Force | Out-Null
    Set-Location -Path `$Path
}
New-Alias -Name mkcd -Value New-DirectoryAndEnter -Force -ErrorAction SilentlyContinue

# Function: Quick git status
function gs { git status }
New-Alias -Name gs -Value gs -Force -ErrorAction SilentlyContinue

# Function: Quick git log
function gl { git log --oneline -10 }
New-Alias -Name gl -Value gl -Force -ErrorAction SilentlyContinue

# Set PSReadLine options for better experience
if (Get-Module -Name PSReadLine -ListAvailable) {
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineOption -PredictionSource History
}

Write-Host "PowerShell Development Profile Loaded" -ForegroundColor Green
"@
            
            Set-Content -Path $psProfilePath -Value $profileContent -Force
            Write-Log "PowerShell profile created and configured." -Level Success
        }
        else {
            Write-Log "PowerShell profile already exists." -Level Success
        }
    }
    catch {
        Write-Log "Error configuring PowerShell profile: $_" -Level Warning
    }
}

function Configure-SystemEnvironment {
    <#
    .SYNOPSIS
    Configures system environment variables
    #>
    Write-Header "Configuring System Environment Variables"
    
    try {
        Write-Log "Configuring environment variables for development..."
        
        # Create dev workspace directory
        $devPath = "$env:USERPROFILE\Development"
        if (-not (Test-Path -Path $devPath)) {
            New-Item -ItemType Directory -Path $devPath -Force | Out-Null
            Write-Log "Created Development workspace directory: $devPath"
        }
        
        # Set environment variable
        [Environment]::SetEnvironmentVariable('DEV_WORKSPACE', $devPath, [EnvironmentVariableTarget]::User)
        Write-Log "Set DEV_WORKSPACE environment variable."
        
        Write-Log "System environment configured successfully." -Level Success
    }
    catch {
        Write-Log "Error configuring system environment: $_" -Level Error
    }
}

# ============================================================================
# System Configuration Functions
# ============================================================================

function Enable-DeveloperFeatures {
    <#
    .SYNOPSIS
    Enables Windows developer features and optional features
    #>
    Write-Header "Enabling Windows Developer Features"
    
    try {
        Write-Log "Enabling Developer Mode..."
        
        # Enable Developer Mode
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -PropertyType DWORD -Value 1 -Force | Out-Null
        
        Write-Log "Developer Mode enabled." -Level Success
        
        Write-Log "Enabling optional Windows features..."
        
        $features = @(
            'VirtualMachinePlatform'
            'Hyper-V'
            'Containers'
            'HypervisorPlatform'
        )
        
        foreach ($feature in $features) {
            try {
                $state = Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue
                
                if ($state.State -ne 'Enabled') {
                    Write-Log "Enabling $feature..."
                    Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction SilentlyContinue
                    Write-Log "$feature enabled." -Level Success
                }
                else {
                    Write-Log "$feature is already enabled." -Level Success
                }
            }
            catch {
                Write-Log "Note: Could not enable $feature - it may require restart or be unavailable." -Level Warning
            }
        }
    }
    catch {
        Write-Log "Error enabling developer features: $_" -Level Warning
    }
}

function Configure-FileExplorer {
    <#
    .SYNOPSIS
    Configures File Explorer settings for development
    #>
    Write-Header "Configuring File Explorer"
    
    try {
        Write-Log "Configuring File Explorer settings..."
        
        # Show hidden files
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -PropertyType DWORD -Value 1 -Force | Out-Null
        
        # Show file extensions
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -PropertyType DWORD -Value 0 -Force | Out-Null
        
        # Show full path in title bar
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "FullPath" -PropertyType DWORD -Value 1 -Force | Out-Null
        
        Write-Log "File Explorer configured." -Level Success
    }
    catch {
        Write-Log "Error configuring File Explorer: $_" -Level Warning
    }
}

function Optimize-SystemPerformance {
    <#
    .SYNOPSIS
    Applies system performance optimizations
    #>
    Write-Header "Optimizing System Performance"
    
    try {
        Write-Log "Applying performance optimizations..."
        
        # Disable unnecessary animations
        New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -PropertyType String -Value "0" -Force | Out-Null
        
        # Disable transparency effects
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -PropertyType DWORD -Value 0 -Force | Out-Null
        
        Write-Log "System performance optimizations applied." -Level Success
    }
    catch {
        Write-Log "Error optimizing system performance: $_" -Level Warning
    }
}

# ============================================================================
# Cleanup and Summary Functions
# ============================================================================

function Get-SetupSummary {
    <#
    .SYNOPSIS
    Generates and displays setup summary
    #>
    Write-Header "Setup Summary"
    
    $elapsedTime = (Get-Date) - $ScriptStartTime
    
    Write-Log "Setup completed!"
    Write-Log "Elapsed Time: $($elapsedTime.Hours)h $($elapsedTime.Minutes)m $($elapsedTime.Seconds)s" -Level Success
    Write-Log "Log file saved to: $LogPath" -Level Success
    
    Write-Log ""
    Write-Log "Next Steps:" -Level Info
    Write-Log "1. Restart your computer to complete all installations and configurations."
    Write-Log "2. Configure your Git credentials: git config --global user.name 'Your Name'"
    Write-Log "3. Configure your Git email: git config --global user.email 'your.email@example.com'"
    Write-Log "4. Review the log file for any warnings or errors."
    Write-Log ""
}

# ============================================================================
# Main Execution
# ============================================================================

function Start-Setup {
    <#
    .SYNOPSIS
    Main setup orchestration function
    #>
    try {
        Clear-Host
        Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║        Developer Workstation Setup - Windows 11 Pro              ║" -ForegroundColor Cyan
        Write-Host "║                    Version $ScriptVersion                          ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Log "Setup script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Log "PowerShell Version: $($PSVersionTable.PSVersion)"
        Write-Log "Script Version: $ScriptVersion"
        
        # Pre-flight checks
        Test-AdminPrivileges
        Test-WindowsVersion
        
        # Package managers
        Install-Winget
        Install-Chocolatey
        
        # Installation phases
        Install-DevelopmentTools
        Install-DotNetTools
        Install-DatabaseTools
        
        # Configuration phases
        Configure-GitEnvironment
        Configure-PowerShellProfile
        Configure-SystemEnvironment
        
        # System optimization
        Enable-DeveloperFeatures
        Configure-FileExplorer
        Optimize-SystemPerformance
        
        # Summary
        Get-SetupSummary
        
        Write-Host ""
        Write-Host "Setup completed successfully!" -ForegroundColor Green
        Write-Host "Please restart your computer to complete the setup process." -ForegroundColor Yellow
    }
    catch {
        Write-Log "Fatal error during setup: $_" -Level Error
        Write-Log "Setup failed. Please review the log file for details." -Level Error
        exit 1
    }
}

# Execute main setup if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Start-Setup
}
