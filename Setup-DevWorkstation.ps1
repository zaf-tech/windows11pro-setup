#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Comprehensive PowerShell script to set up a Windows 11 Pro development workstation with WSL2 and Ubuntu
.DESCRIPTION
    This script automates the installation and configuration of essential development tools,
    WSL 2 (Windows Subsystem for Linux), and Ubuntu on Windows 11 Pro.
.EXAMPLE
    .\Setup-DevWorkstation.ps1 -Verbose
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$SkipWSL,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipChocolatey,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipNodeJS,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipDocker,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipGit,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipVSCode,
    
    [Parameter(Mandatory = $false)]
    [switch]$AllowPrerelease
)

# ==================== Constants ====================
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Colors for output
$Colors = @{
    Success = "Green"
    Error   = "Red"
    Warning = "Yellow"
    Info    = "Cyan"
}

# ==================== Helper Functions ====================

function Write-ColorOutput {
    <#
    .SYNOPSIS
        Write colored output to console
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info')]
        [string]$Color = 'Info'
    )
    
    $ForegroundColor = $Colors[$Color]
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Test-CommandExists {
    <#
    .SYNOPSIS
        Test if a command exists in the current session
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Invoke-CommandWithLogging {
    <#
    .SYNOPSIS
        Execute a command and log the results
    #>
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $true)]
        [string]$Description
    )
    
    Write-ColorOutput "Executing: $Description" -Color Info
    
    try {
        & $ScriptBlock
        Write-ColorOutput "✓ Success: $Description" -Color Success
        return $true
    }
    catch {
        Write-ColorOutput "✗ Failed: $Description - $($_.Exception.Message)" -Color Error
        return $false
    }
}

# ==================== WSL2 and Ubuntu Setup ====================

function Install-WSL2 {
    <#
    .SYNOPSIS
        Install WSL 2 and Ubuntu on Windows 11 Pro
    .DESCRIPTION
        This function enables WSL2, installs the WSL kernel update, and sets up Ubuntu
    #>
    
    Write-ColorOutput "Starting WSL 2 and Ubuntu Setup..." -Color Info
    
    # Check if WSL is already installed
    $wslStatus = wsl --status 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "WSL 2 is already installed" -Color Success
        return
    }
    
    # Enable WSL feature
    Write-ColorOutput "Enabling Windows Subsystem for Linux feature..." -Color Info
    Invoke-CommandWithLogging {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -WarningAction SilentlyContinue | Out-Null
    } "Enable WSL feature"
    
    # Enable Virtual Machine Platform feature
    Write-ColorOutput "Enabling Virtual Machine Platform feature..." -Color Info
    Invoke-CommandWithLogging {
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -WarningAction SilentlyContinue | Out-Null
    } "Enable Virtual Machine Platform"
    
    # Set WSL 2 as default
    Write-ColorOutput "Setting WSL 2 as default version..." -Color Info
    Invoke-CommandWithLogging {
        wsl --set-default-version 2
    } "Set WSL 2 as default"
    
    # Download and install WSL Kernel update
    Write-ColorOutput "Downloading WSL 2 Kernel update..." -Color Info
    $kernelUri = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $kernelPath = "$env:TEMP\wsl_update_x64.msi"
    
    Invoke-CommandWithLogging {
        Invoke-WebRequest -Uri $kernelUri -OutFile $kernelPath -UseBasicParsing
    } "Download WSL Kernel MSI"
    
    # Install the kernel update
    Write-ColorOutput "Installing WSL 2 Kernel update..." -Color Info
    Invoke-CommandWithLogging {
        msiexec.exe /i $kernelPath /quiet /norestart
        Start-Sleep -Seconds 5
    } "Install WSL Kernel"
    
    # Clean up
    Remove-Item $kernelPath -Force -ErrorAction SilentlyContinue
    
    # Install Ubuntu from Microsoft Store
    Write-ColorOutput "Installing Ubuntu from Microsoft Store..." -Color Info
    Invoke-CommandWithLogging {
        winget install Canonical.Ubuntu --exact --source winget --accept-source-agreements --accept-package-agreements
    } "Install Ubuntu via winget"
    
    Write-ColorOutput "✓ WSL 2 and Ubuntu setup completed. Please restart your computer and run Ubuntu to complete the installation." -Color Success
}

# ==================== Package Manager Setup ====================

function Install-Chocolatey {
    <#
    .SYNOPSIS
        Install Chocolatey package manager if not already installed
    #>
    
    if (Test-CommandExists "choco") {
        Write-ColorOutput "Chocolatey is already installed" -Color Success
        return
    }
    
    Write-ColorOutput "Installing Chocolatey..." -Color Info
    Invoke-CommandWithLogging {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } "Install Chocolatey"
}

# ==================== Development Tools Setup ====================

function Install-Git {
    <#
    .SYNOPSIS
        Install Git version control system
    #>
    
    if (Test-CommandExists "git") {
        Write-ColorOutput "Git is already installed" -Color Success
        return
    }
    
    Write-ColorOutput "Installing Git..." -Color Info
    Invoke-CommandWithLogging {
        choco install git -y --params="/GitOnlyOnPath /WindowsTerminal /NoShellIntegrationFallback"
    } "Install Git via Chocolatey"
}

function Install-NodeJS {
    <#
    .SYNOPSIS
        Install Node.js and npm
    #>
    
    if (Test-CommandExists "node") {
        Write-ColorOutput "Node.js is already installed" -Color Success
        return
    }
    
    Write-ColorOutput "Installing Node.js..." -Color Info
    Invoke-CommandWithLogging {
        choco install nodejs -y
    } "Install Node.js via Chocolatey"
}

function Install-Docker {
    <#
    .SYNOPSIS
        Install Docker Desktop
    #>
    
    if (Test-CommandExists "docker") {
        Write-ColorOutput "Docker is already installed" -Color Success
        return
    }
    
    Write-ColorOutput "Installing Docker Desktop..." -Color Info
    Invoke-CommandWithLogging {
        choco install docker-desktop -y
    } "Install Docker Desktop via Chocolatey"
}

function Install-VSCode {
    <#
    .SYNOPSIS
        Install Visual Studio Code
    #>
    
    if (Test-CommandExists "code") {
        Write-ColorOutput "Visual Studio Code is already installed" -Color Success
        return
    }
    
    Write-ColorOutput "Installing Visual Studio Code..." -Color Info
    Invoke-CommandWithLogging {
        choco install vscode -y
    } "Install VS Code via Chocolatey"
}

# ==================== System Configuration ====================

function Update-EnvironmentVariables {
    <#
    .SYNOPSIS
        Refresh environment variables in the current session
    #>
    
    Write-ColorOutput "Updating environment variables..." -Color Info
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Configure-ExecutionPolicy {
    <#
    .SYNOPSIS
        Configure PowerShell execution policy for current user
    #>
    
    Write-ColorOutput "Configuring PowerShell execution policy..." -Color Info
    Invoke-CommandWithLogging {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    } "Set execution policy to RemoteSigned"
}

# ==================== Main Script Execution ====================

function Main {
    Write-ColorOutput "================================================" -Color Info
    Write-ColorOutput "Windows 11 Pro Development Workstation Setup" -Color Info
    Write-ColorOutput "================================================" -Color Info
    Write-ColorOutput "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color Info
    Write-ColorOutput ""
    
    # Display configuration
    Write-ColorOutput "Setup Configuration:" -Color Info
    Write-ColorOutput "  Skip WSL:        $SkipWSL" -Color Info
    Write-ColorOutput "  Skip Chocolatey: $SkipChocolatey" -Color Info
    Write-ColorOutput "  Skip Node.js:    $SkipNodeJS" -Color Info
    Write-ColorOutput "  Skip Docker:     $SkipDocker" -Color Info
    Write-ColorOutput "  Skip Git:        $SkipGit" -Color Info
    Write-ColorOutput "  Skip VS Code:    $SkipVSCode" -Color Info
    Write-ColorOutput "  Allow Prerelease: $AllowPrerelease" -Color Info
    Write-ColorOutput ""
    
    # WSL 2 and Ubuntu setup
    if (-not $SkipWSL) {
        Install-WSL2
        Write-ColorOutput ""
    }
    else {
        Write-ColorOutput "Skipping WSL 2 installation (as requested)" -Color Warning
        Write-ColorOutput ""
    }
    
    # Chocolatey setup
    if (-not $SkipChocolatey) {
        Install-Chocolatey
        Write-ColorOutput ""
    }
    else {
        Write-ColorOutput "Skipping Chocolatey installation (as requested)" -Color Warning
        Write-ColorOutput ""
    }
    
    # Git setup
    if (-not $SkipGit -and -not $SkipChocolatey) {
        Install-Git
        Write-ColorOutput ""
    }
    
    # Node.js setup
    if (-not $SkipNodeJS -and -not $SkipChocolatey) {
        Install-NodeJS
        Write-ColorOutput ""
    }
    
    # Docker setup
    if (-not $SkipDocker -and -not $SkipChocolatey) {
        Install-Docker
        Write-ColorOutput ""
    }
    
    # VS Code setup
    if (-not $SkipVSCode -and -not $SkipChocolatey) {
        Install-VSCode
        Write-ColorOutput ""
    }
    
    # Configure system
    Update-EnvironmentVariables
    Configure-ExecutionPolicy
    
    Write-ColorOutput ""
    Write-ColorOutput "================================================" -Color Info
    Write-ColorOutput "Setup completed successfully!" -Color Success
    Write-ColorOutput "End Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color Info
    Write-ColorOutput "================================================" -Color Info
    Write-ColorOutput ""
    Write-ColorOutput "Recommended next steps:" -Color Info
    Write-ColorOutput "1. Restart your computer to complete WSL 2 and Windows feature installations" -Color Info
    Write-ColorOutput "2. Run Ubuntu from Start Menu and complete the initial setup" -Color Info
    Write-ColorOutput "3. Configure Git globally (git config --global user.name 'Your Name')" -Color Info
    Write-ColorOutput "4. Check installation versions: git --version, node --version, docker --version" -Color Info
}

# Execute main function
Main
