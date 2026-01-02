<#
.SYNOPSIS
    Comprehensive Windows 11 Pro Development Workstation Setup Script
    
.DESCRIPTION
    Automates the setup of a development workstation on Windows 11 Pro with:
    - WSL 2 (Windows Subsystem for Linux 2)
    - Ubuntu LTS installation and configuration
    - Development tools and utilities
    - System validation and verification
    
.PARAMETER SkipWSL
    Skip WSL 2 installation if already installed
    
.PARAMETER SkipUbuntu
    Skip Ubuntu installation if already installed
    
.PARAMETER Verbose
    Enable verbose output for troubleshooting
    
.NOTES
    Author: Development Team
    Version: 2.0.0
    Last Updated: 2026-01-02
    Requires: Windows 11 Pro, Administrator privileges
#>

[CmdletBinding()]
param(
    [switch]$SkipWSL,
    [switch]$SkipUbuntu,
    [switch]$Verbose
)

# ============================================================================
# CONFIGURATION AND CONSTANTS
# ============================================================================

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"

# Script metadata
$ScriptVersion = "2.0.0"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogPath = Join-Path $ScriptPath "Setup-Logs"
$LogFile = Join-Path $LogPath "setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# WSL and Ubuntu configurations
$WSL2MinimumVersion = "2.0.0"
$UbuntuDistributions = @("Ubuntu", "Ubuntu-22.04", "Ubuntu-24.04")
$PreferredUbuntuVersion = "Ubuntu-24.04"

# System requirements
$MinimumRAM = 4GB
$MinimumDiskSpace = 20GB
$RequiredFeatures = @(
    "VirtualMachinePlatform",
    "WSL"
)

# ============================================================================
# LOGGING AND OUTPUT FUNCTIONS
# ============================================================================

function Initialize-Logging {
    <#
    .SYNOPSIS
        Initialize logging for the setup process
    #>
    param()
    
    if (-not (Test-Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }
    
    "Setup Script Execution Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Add-Content $LogFile
    "Script Version: $ScriptVersion" | Add-Content $LogFile
    "PowerShell Version: $($PSVersionTable.PSVersion)" | Add-Content $LogFile
    "---" | Add-Content $LogFile
}

function Write-Log {
    <#
    .SYNOPSIS
        Write message to console and log file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $logMessage | Add-Content $LogFile
    
    switch ($Level) {
        "Info" {
            Write-Host $logMessage -ForegroundColor Cyan
        }
        "Warning" {
            Write-Host $logMessage -ForegroundColor Yellow
        }
        "Error" {
            Write-Host $logMessage -ForegroundColor Red
        }
        "Success" {
            Write-Host $logMessage -ForegroundColor Green
        }
    }
}

function Write-Section {
    <#
    .SYNOPSIS
        Write a formatted section header
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )
    
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Magenta
    Write-Host $Title -ForegroundColor Magenta
    Write-Host "=" * 80 -ForegroundColor Magenta
    Write-Host ""
    
    "--- $Title ---" | Add-Content $LogFile
}

# ============================================================================
# VALIDATION AND VERIFICATION FUNCTIONS
# ============================================================================

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
        Verify script is running with administrator privileges
    #>
    param()
    
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Log "This script requires Administrator privileges" -Level Error
        throw "Administrator privileges required"
    }
    
    Write-Log "Administrator privileges verified" -Level Success
}

function Test-SystemRequirements {
    <#
    .SYNOPSIS
        Validate system meets minimum requirements
    #>
    param()
    
    Write-Section "System Requirements Validation"
    
    # Check Windows version
    $osVersion = [System.Environment]::OSVersion
    $win11Check = (Get-WmiObject Win32_OperatingSystem).Caption -match "Windows 11"
    
    if (-not $win11Check) {
        Write-Log "Windows 11 Pro is required" -Level Error
        throw "Operating system requirement not met"
    }
    Write-Log "Windows 11 detected" -Level Success
    
    # Check RAM
    $systemRAM = (Get-CimInstance CimClass Win32_ComputerSystem).TotalPhysicalMemory
    if ($systemRAM -lt $MinimumRAM) {
        Write-Log "Insufficient RAM: $([math]::Round($systemRAM/1GB, 2))GB (minimum: $([math]::Round($MinimumRAM/1GB, 2))GB)" -Level Warning
    } else {
        Write-Log "RAM check passed: $([math]::Round($systemRAM/1GB, 2))GB" -Level Success
    }
    
    # Check disk space
    $systemDrive = Get-Volume | Where-Object { $_.DriveLetter -eq "C" }
    $availableSpace = $systemDrive.SizeRemaining
    
    if ($availableSpace -lt $MinimumDiskSpace) {
        Write-Log "Low disk space: $([math]::Round($availableSpace/1GB, 2))GB available (minimum: $([math]::Round($MinimumDiskSpace/1GB, 2))GB)" -Level Warning
    } else {
        Write-Log "Disk space check passed: $([math]::Round($availableSpace/1GB, 2))GB available" -Level Success
    }
    
    # Check for Hyper-V capability
    $hyperVCapable = (Get-WmiObject -Class Win32_Processor).VirtualizationCapabilities
    if ($null -eq $hyperVCapable) {
        Write-Log "Virtualization capability not detected - WSL 2 may not function properly" -Level Warning
    } else {
        Write-Log "Virtualization capable processor detected" -Level Success
    }
}

function Test-FeatureEnabled {
    <#
    .SYNOPSIS
        Check if Windows feature is enabled
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureName
    )
    
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName
        return $feature.State -eq "Enabled"
    }
    catch {
        Write-Log "Error checking feature $FeatureName : $_" -Level Warning
        return $false
    }
}

function Enable-RequiredFeatures {
    <#
    .SYNOPSIS
        Enable required Windows features for WSL 2
    #>
    param()
    
    Write-Section "Enabling Required Windows Features"
    
    foreach ($feature in $RequiredFeatures) {
        if (Test-FeatureEnabled -FeatureName $feature) {
            Write-Log "Feature already enabled: $feature" -Level Success
        }
        else {
            Write-Log "Enabling feature: $feature" -Level Info
            try {
                Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction Stop | Out-Null
                Write-Log "Feature enabled successfully: $feature" -Level Success
            }
            catch {
                Write-Log "Failed to enable feature $feature : $_" -Level Error
                throw
            }
        }
    }
}

function Test-WSL2Installed {
    <#
    .SYNOPSIS
        Check if WSL 2 is installed
    #>
    param()
    
    try {
        $wslOutput = wsl --version 2>&1
        return $null -ne $wslOutput -and $wslOutput -notmatch "The Windows Subsystem for Linux has no installed distributions"
    }
    catch {
        return $false
    }
}

function Get-WSL2Version {
    <#
    .SYNOPSIS
        Get installed WSL 2 version
    #>
    param()
    
    try {
        $wslOutput = wsl --version 2>&1
        if ($wslOutput -match "WSL version: ([\d.]+)") {
            return $matches[1]
        }
        return "Unknown"
    }
    catch {
        return $null
    }
}

function Test-UbuntuInstalled {
    <#
    .SYNOPSIS
        Check if Ubuntu is installed in WSL 2
    #>
    param()
    
    try {
        $distributions = wsl --list --verbose 2>&1
        return $distributions -match "Ubuntu"
    }
    catch {
        return $false
    }
}

function Get-InstalledDistributions {
    <#
    .SYNOPSIS
        Get list of installed WSL 2 distributions
    #>
    param()
    
    try {
        $distributions = @()
        $wslOutput = wsl --list --verbose 2>&1
        
        foreach ($line in $wslOutput) {
            if ($line -match "^\s*(\*?)\s+(.+?)\s+(\w+)\s+(\d+)") {
                $distributions += [PSCustomObject]@{
                    IsDefault = $matches[1] -eq "*"
                    Name = $matches[2].Trim()
                    State = $matches[3]
                    Version = $matches[4]
                }
            }
        }
        
        return $distributions
    }
    catch {
        Write-Log "Error retrieving distributions: $_" -Level Warning
        return @()
    }
}

# ============================================================================
# WSL 2 INSTALLATION AND CONFIGURATION
# ============================================================================

function Install-WSL2 {
    <#
    .SYNOPSIS
        Install WSL 2 with all required components
    #>
    param()
    
    Write-Section "WSL 2 Installation"
    
    if ($SkipWSL -and (Test-WSL2Installed)) {
        Write-Log "Skipping WSL 2 installation (already installed)" -Level Info
        return
    }
    
    # Enable required features
    Enable-RequiredFeatures
    
    # Install WSL 2 kernel
    Write-Log "Installing WSL 2 kernel package" -Level Info
    try {
        wsl --install --no-distribution --no-launch 2>&1 | ForEach-Object {
            Write-Log $_ -Level Info
        }
        Write-Log "WSL 2 kernel installed successfully" -Level Success
    }
    catch {
        Write-Log "Error installing WSL 2: $_" -Level Error
        throw
    }
    
    # Verify installation
    Start-Sleep -Seconds 5
    $wslVersion = Get-WSL2Version
    Write-Log "WSL 2 Version: $wslVersion" -Level Success
    
    Write-Log "WSL 2 installation completed - a system restart may be required" -Level Info
}

function Install-Ubuntu {
    <#
    .SYNOPSIS
        Install Ubuntu LTS distribution in WSL 2
    #>
    param(
        [string]$DistroName = $PreferredUbuntuVersion
    )
    
    Write-Section "Ubuntu Installation"
    
    if ($SkipUbuntu -and (Test-UbuntuInstalled)) {
        Write-Log "Skipping Ubuntu installation (already installed)" -Level Info
        return
    }
    
    Write-Log "Installing $DistroName distribution" -Level Info
    try {
        wsl --install $DistroName --no-launch 2>&1 | ForEach-Object {
            Write-Log $_ -Level Info
        }
        Write-Log "Ubuntu distribution installed successfully" -Level Success
    }
    catch {
        Write-Log "Error installing Ubuntu: $_" -Level Error
        throw
    }
    
    # Set as default distribution
    Write-Log "Setting $DistroName as default distribution" -Level Info
    try {
        wsl --set-default $DistroName
        Write-Log "$DistroName set as default distribution" -Level Success
    }
    catch {
        Write-Log "Warning: Could not set default distribution" -Level Warning
    }
}

function Configure-UbuntuEnvironment {
    <#
    .SYNOPSIS
        Configure Ubuntu environment and install development tools
    #>
    param()
    
    Write-Section "Ubuntu Environment Configuration"
    
    $setupScript = @"
#!/bin/bash
set -e

echo "Updating package manager..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq

echo "Installing development tools..."
sudo apt-get install -y -qq \
    build-essential \
    git \
    curl \
    wget \
    vim \
    nano \
    htop \
    net-tools \
    openssh-client

echo "Installing programming languages..."
sudo apt-get install -y -qq \
    python3 \
    python3-pip \
    nodejs \
    npm

echo "Creating development directories..."
mkdir -p ~/dev
mkdir -p ~/projects

echo "Setting up Git configuration prompt..."
echo "Please configure Git (optional):"
read -p "Enter your name (press Enter to skip): " GIT_NAME
if [ ! -z "\$GIT_NAME" ]; then
    git config --global user.name "\$GIT_NAME"
fi

read -p "Enter your email (press Enter to skip): " GIT_EMAIL
if [ ! -z "\$GIT_EMAIL" ]; then
    git config --global user.email "\$GIT_EMAIL"
fi

echo "Ubuntu environment configuration complete!"
"@
    
    Write-Log "Configuring Ubuntu environment..." -Level Info
    
    # Write setup script to temporary location
    $tempScript = Join-Path $env:TEMP "ubuntu-setup.sh"
    Set-Content -Path $tempScript -Value $setupScript -Encoding UTF8
    
    try {
        # Execute setup script in WSL
        wsl bash -c "cat /tmp/ubuntu-setup.sh | bash" 2>&1 | ForEach-Object {
            Write-Log "Ubuntu: $_" -Level Info
        }
        Write-Log "Ubuntu environment configuration completed" -Level Success
    }
    catch {
        Write-Log "Warning: Some Ubuntu configuration steps may have failed" -Level Warning
    }
    finally {
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    }
}

# ============================================================================
# VERIFICATION FUNCTIONS
# ============================================================================

function Test-WSL2Health {
    <#
    .SYNOPSIS
        Perform comprehensive health check of WSL 2 installation
    #>
    param()
    
    Write-Section "WSL 2 Health Check"
    
    $healthStatus = @{
        WSL2Installed = $false
        UbuntuInstalled = $false
        Version = "Unknown"
        Distributions = @()
        IsHealthy = $false
    }
    
    # Check WSL 2 installation
    if (Test-WSL2Installed) {
        Write-Log "WSL 2 is installed" -Level Success
        $healthStatus.WSL2Installed = $true
        $healthStatus.Version = Get-WSL2Version
    }
    else {
        Write-Log "WSL 2 is not installed" -Level Error
        return $healthStatus
    }
    
    # Check Ubuntu installation
    if (Test-UbuntuInstalled) {
        Write-Log "Ubuntu distribution is installed" -Level Success
        $healthStatus.UbuntuInstalled = $true
    }
    else {
        Write-Log "Ubuntu distribution is not installed" -Level Error
        return $healthStatus
    }
    
    # Get distributions
    $distributions = Get-InstalledDistributions
    $healthStatus.Distributions = $distributions
    
    foreach ($dist in $distributions) {
        $statusColor = if ($dist.State -eq "Running") { "Green" } else { "Yellow" }
        Write-Host "  - $($dist.Name): $($dist.State) (Version $($dist.Version))" -ForegroundColor $statusColor
    }
    
    # Try to execute a simple command in WSL
    Write-Log "Testing WSL 2 connectivity..." -Level Info
    try {
        $wslTest = wsl echo "WSL connectivity test" 2>&1
        if ($wslTest -match "WSL connectivity test") {
            Write-Log "WSL 2 connectivity verified" -Level Success
            $healthStatus.IsHealthy = $true
        }
        else {
            Write-Log "WSL 2 connectivity test failed" -Level Warning
        }
    }
    catch {
        Write-Log "WSL 2 connectivity test error: $_" -Level Warning
    }
    
    return $healthStatus
}

function Verify-UbuntuSetup {
    <#
    .SYNOPSIS
        Verify Ubuntu installation and development tools
    #>
    param()
    
    Write-Section "Ubuntu Setup Verification"
    
    $verificationResults = @{
        Success = $true
        Components = @()
    }
    
    $components = @(
        @{ Name = "Git"; Command = "git --version" },
        @{ Name = "Python3"; Command = "python3 --version" },
        @{ Name = "Node.js"; Command = "node --version" },
        @{ Name = "npm"; Command = "npm --version" },
        @{ Name = "curl"; Command = "curl --version | head -n 1" },
        @{ Name = "wget"; Command = "wget --version | head -n 1" }
    )
    
    foreach ($component in $components) {
        try {
            $result = wsl bash -c "$($component.Command) 2>&1" -ErrorAction SilentlyContinue
            if ($result) {
                Write-Log "$($component.Name): $($result -split [Environment]::NewLine | Select-Object -First 1)" -Level Success
                $verificationResults.Components += @{
                    Name = $component.Name
                    Status = "Installed"
                }
            }
            else {
                Write-Log "$($component.Name): Not found or verification failed" -Level Warning
                $verificationResults.Components += @{
                    Name = $component.Name
                    Status = "Not Found"
                }
                $verificationResults.Success = $false
            }
        }
        catch {
            Write-Log "$($component.Name): Error - $_" -Level Warning
            $verificationResults.Components += @{
                Name = $component.Name
                Status = "Error"
            }
            $verificationResults.Success = $false
        }
    }
    
    return $verificationResults
}

function Get-SetupSummary {
    <#
    .SYNOPSIS
        Generate comprehensive setup summary
    #>
    param(
        [hashtable]$HealthCheck,
        [hashtable]$Verification
    )
    
    Write-Section "Setup Summary"
    
    Write-Host "WSL 2 Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $($HealthCheck.WSL2Installed)" -ForegroundColor Yellow
    Write-Host "  Version: $($HealthCheck.Version)" -ForegroundColor Yellow
    Write-Host "  Healthy: $($HealthCheck.IsHealthy)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Ubuntu Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $($HealthCheck.UbuntuInstalled)" -ForegroundColor Yellow
    Write-Host "  Distributions: $($HealthCheck.Distributions.Count)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Development Tools:" -ForegroundColor Cyan
    foreach ($component in $Verification.Components) {
        $statusColor = if ($component.Status -eq "Installed") { "Green" } else { "Yellow" }
        Write-Host "  $($component.Name): $($component.Status)" -ForegroundColor $statusColor
    }
    Write-Host ""
    
    Write-Host "Overall Status: " -ForegroundColor Cyan -NoNewline
    if ($HealthCheck.IsHealthy -and $Verification.Success) {
        Write-Host "SUCCESSFUL" -ForegroundColor Green
    }
    else {
        Write-Host "COMPLETED WITH WARNINGS" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Log File: $LogFile" -ForegroundColor Cyan
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    <#
    .SYNOPSIS
        Main execution function
    #>
    param()
    
    try {
        # Initialize
        Initialize-Logging
        Write-Log "Development Workstation Setup Script v$ScriptVersion started" -Level Info
        
        # Validation phase
        Test-AdminPrivileges
        Test-SystemRequirements
        
        # Installation phase
        Install-WSL2
        Install-Ubuntu -DistroName $PreferredUbuntuVersion
        Configure-UbuntuEnvironment
        
        # Verification phase
        $healthCheck = Test-WSL2Health
        $verification = Verify-UbuntuSetup
        
        # Summary
        Get-SetupSummary -HealthCheck $healthCheck -Verification $verification
        
        Write-Log "Development Workstation Setup Script completed successfully" -Level Success
    }
    catch {
        Write-Log "Setup script failed: $_" -Level Error
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level Error
        exit 1
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne ".") {
    Main
}
