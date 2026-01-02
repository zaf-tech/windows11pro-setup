<#
.SYNOPSIS
    Setup script for Windows 11 Pro development workstation.
    
.DESCRIPTION
    This script automates the setup of a Windows 11 Pro development workstation.
    It installs essential development tools, configures WSL 2 with Ubuntu, and sets up the development environment.
    
.EXAMPLE
    .\Setup-DevWorkstation.ps1 -Verbose
    
.NOTES
    Requires Administrator privileges.
    Run from an elevated PowerShell prompt.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$UbuntuVersion = "22.04",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("LTS", "Latest")]
    [string]$DistroType = "LTS"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Helper functions
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $output = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "Info" { Write-Host $output -ForegroundColor Green }
        "Warning" { Write-Host $output -ForegroundColor Yellow }
        "Error" { Write-Host $output -ForegroundColor Red }
    }
}

function Test-AdminPrivileges {
    $principal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Enable-WindowsFeature {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureName
    )
    
    Write-Log "Enabling Windows feature: $FeatureName"
    
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -NoRestart -ErrorAction Stop | Out-Null
        Write-Log "Successfully enabled: $FeatureName"
    }
    catch {
        Write-Log "Failed to enable $FeatureName : $_" -Level "Error"
        throw
    }
}

function Install-WSL2 {
    Write-Log "Installing WSL 2..."
    
    try {
        # Enable required Windows features
        Enable-WindowsFeature "Microsoft-Windows-Subsystem-Linux"
        Enable-WindowsFeature "VirtualMachinePlatform"
        
        # Set WSL 2 as default
        Write-Log "Setting WSL 2 as default version"
        wsl --set-default-version 2 | Out-Null
        
        Write-Log "WSL 2 installation completed"
    }
    catch {
        Write-Log "Failed to install WSL 2: $_" -Level "Error"
        throw
    }
}

function Install-Ubuntu {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("LTS", "Latest")]
        [string]$Type
    )
    
    Write-Log "Installing Ubuntu $Version ($Type)..."
    
    try {
        # Use winget to install Ubuntu
        $ubuntuPackage = if ($Type -eq "LTS") {
            "Canonical.Ubuntu"
        }
        else {
            "Canonical.Ubuntu"
        }
        
        Write-Log "Installing Ubuntu distribution via winget"
        winget install --exact --quiet $ubuntuPackage
        
        Write-Log "Ubuntu installation completed"
    }
    catch {
        Write-Log "Failed to install Ubuntu: $_" -Level "Error"
        throw
    }
}

function Install-DeveloperTools {
    Write-Log "Installing developer tools..."
    
    try {
        $tools = @(
            "Git.Git",
            "Microsoft.PowerShell",
            "Microsoft.VisualStudioCode",
            "JetBrains.IntelliJIDEA.Community",
            "OpenJS.NodeJS",
            "Python.Python.3"
        )
        
        foreach ($tool in $tools) {
            Write-Log "Installing $tool"
            winget install --exact --quiet $tool
        }
        
        Write-Log "Developer tools installation completed"
    }
    catch {
        Write-Log "Failed to install developer tools: $_" -Level "Error"
        throw
    }
}

function Configure-Environment {
    Write-Log "Configuring development environment..."
    
    try {
        # Configure Git
        Write-Log "Configuring Git"
        git config --global core.autocrlf true
        
        # Create development directories
        Write-Log "Creating development directories"
        $devPaths = @(
            "$env:USERPROFILE\Development",
            "$env:USERPROFILE\Development\Projects",
            "$env:USERPROFILE\Development\Tools"
        )
        
        foreach ($path in $devPaths) {
            if (-not (Test-Path $path)) {
                New-Item -ItemType Directory -Path $path -Force | Out-Null
                Write-Log "Created directory: $path"
            }
        }
        
        Write-Log "Environment configuration completed"
    }
    catch {
        Write-Log "Failed to configure environment: $_" -Level "Error"
        throw
    }
}

# Main execution
function Main {
    Write-Log "Starting Windows 11 Pro Development Workstation Setup"
    
    # Check for admin privileges
    if (-not (Test-AdminPrivileges)) {
        Write-Log "This script requires Administrator privileges" -Level "Error"
        exit 1
    }
    
    Write-Log "Administrator privileges confirmed"
    
    try {
        # Install WSL 2
        Install-WSL2
        
        # Install Ubuntu
        Install-Ubuntu -Version $UbuntuVersion -Type $DistroType
        
        # Install developer tools
        Install-DeveloperTools
        
        # Configure environment
        Configure-Environment
        
        Write-Log "Setup completed successfully"
        Write-Log "Please restart your computer to complete the installation"
    }
    catch {
        Write-Log "Setup failed: $_" -Level "Error"
        exit 1
    }
}

# Run main function
Main
