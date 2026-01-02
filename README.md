# Windows 11 Pro Setup

A comprehensive setup and configuration toolkit for Windows 11 Pro systems. This repository provides automated scripts, configurations, and utilities to help you quickly set up and optimize your Windows 11 Pro environment.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage Examples](#usage-examples)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

### System Optimization
- Automatic disk cleanup and optimization
- Windows Update configuration
- System performance tuning
- Memory and CPU optimization settings

### Software Installation
- Batch installation of popular applications
- Package manager integration (Chocolatey, winget)
- Automatic driver updates
- Optional application suite installation

### Security Hardening
- Windows Defender configuration
- Firewall optimization
- User account control (UAC) settings
- Security policies implementation

### Development Environment Setup
- Git configuration
- Development tools installation
- IDE and editor setup (VS Code, Visual Studio, etc.)
- Runtime environments (Node.js, Python, .NET, Java)

### Network Configuration
- DNS settings optimization
- Network adapter configuration
- VPN and proxy setup
- Network security policies

### Customization
- Taskbar and Start menu configuration
- Theme and appearance settings
- Keyboard shortcuts customization
- Desktop environment personalization

## Installation

### Prerequisites

- Windows 11 Pro edition (Home edition may have limited features)
- Administrator privileges
- PowerShell 5.1 or higher
- At least 2 GB of free disk space
- Internet connection for downloading components

### System Requirements

- **OS**: Windows 11 Pro (21H2 or later)
- **RAM**: Minimum 4 GB (8 GB recommended)
- **Storage**: 20 GB free space for full setup
- **Processor**: Intel Core i5 / AMD Ryzen 5 or equivalent
- **BIOS**: UEFI firmware with Secure Boot support

### Step-by-Step Installation

1. **Clone the Repository**
   ```powershell
   git clone https://github.com/zaf-tech/windows11pro-setup.git
   cd windows11pro-setup
   ```

2. **Open PowerShell as Administrator**
   - Right-click PowerShell and select "Run as administrator"
   - Or press `Win + X` and select "Terminal (Admin)"

3. **Enable Script Execution**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
   ```

4. **Run the Installation Script**
   ```powershell
   .\setup.ps1
   ```

5. **Follow the Interactive Prompts**
   - Select desired features
   - Choose software packages to install
   - Configure security settings
   - Customize appearance preferences

6. **Restart Your System**
   - Reboot when prompted to apply all changes
   - Most configurations take effect after restart

## Quick Start

### Basic Setup (5-10 minutes)

For a quick basic setup with default configurations:

```powershell
cd windows11pro-setup
.\setup.ps1 -QuickStart
```

This will:
- Install essential system updates
- Configure basic security settings
- Set up Windows Defender
- Apply performance optimizations

### Full Setup (30-45 minutes)

For a comprehensive setup with all features:

```powershell
.\setup.ps1 -Full
```

This includes everything in Quick Start plus:
- Development tools installation
- Software suite installation
- Advanced security hardening
- Network optimization
- Complete customization

### Selective Setup

Run individual setup modules:

```powershell
# Security setup only
.\setup.ps1 -SecurityOnly

# Development environment only
.\setup.ps1 -DevOnly

# Software installation only
.\setup.ps1 -SoftwareOnly
```

## Usage Examples

### Example 1: Development Setup

Set up a complete development environment:

```powershell
.\setup.ps1 -DevOnly -IncludeNodeJS -IncludePython -IncludeDotNet
```

This installs:
- Git and GitHub tools
- Visual Studio Code
- Node.js and npm
- Python 3.x
- .NET SDK
- Docker Desktop
- Postman

### Example 2: Security-Focused Setup

Create a hardened, security-focused system:

```powershell
.\setup.ps1 -SecurityOnly -EnableBitLocker -EnableWindowsDefender -StrictFirewall
```

This configures:
- Windows Defender with enhanced protections
- Strict firewall rules
- BitLocker disk encryption
- Advanced security policies
- UAC to maximum level

### Example 3: Gaming Setup

Optimize for gaming performance:

```powershell
.\setup.ps1 -GamingOptimized -DisableBackgroundApps -MaxPerformance
```

This optimizes:
- GPU driver updates
- Game mode activation
- Background process minimization
- Network optimization for gaming
- Storage defragmentation

### Example 4: Custom Multi-Purpose Setup

```powershell
.\setup.ps1 -Custom `
  -IncludeSoftware "Google Chrome, 7-Zip, VLC" `
  -SecurityLevel High `
  -PerformanceMode Balanced `
  -Theme Dark
```

### Example 5: Unattended Installation

For scripted or batch deployments:

```powershell
.\setup.ps1 -Unattended -ConfigFile .\configs\standard-config.json
```

## Configuration

### Configuration File Structure

Edit `config.json` to customize your setup:

```json
{
  "system": {
    "performanceMode": "Balanced",
    "cleanupDisk": true,
    "enableUpdates": true,
    "updateFrequency": "Weekly"
  },
  "security": {
    "enableBitLocker": false,
    "enableDefender": true,
    "firewallLevel": "Standard",
    "uacLevel": 3
  },
  "software": {
    "packageManager": "winget",
    "applications": [
      "Google.Chrome",
      "7zip.7zip",
      "VideoLAN.VLC"
    ]
  },
  "development": {
    "installGit": true,
    "installVSCode": true,
    "runtimes": ["nodejs", "python", "dotnet"]
  },
  "appearance": {
    "theme": "Dark",
    "accentColor": "Blue",
    "language": "en-US"
  }
}
```

### Environment Variables

Set environment variables for custom configurations:

```powershell
$env:WIN11_SETUP_MODE = "Full"
$env:WIN11_SECURITY_LEVEL = "High"
$env:WIN11_INSTALL_APPS = "true"
```

### Advanced Configuration

For advanced users, modify individual scripts:

```powershell
# Edit individual modules
.\modules\security.ps1
.\modules\software.ps1
.\modules\development.ps1
```

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: "Access Denied" or Permission Errors

**Problem**: Script execution fails with access denied errors.

**Solution**:
```powershell
# Run PowerShell as Administrator
# Right-click PowerShell → Run as administrator

# Or enable execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Issue 2: Script Execution Policy Error

**Problem**: `cannot be loaded because running scripts is disabled`

**Solution**:
```powershell
# Check current policy
Get-ExecutionPolicy

# Set to RemoteSigned
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Verify change
Get-ExecutionPolicy
```

#### Issue 3: Windows Defender Warnings

**Problem**: Real-time protection blocks script execution.

**Solution**:
- Temporarily disable Windows Defender real-time protection
- Add the repository folder to Defender exclusions:
  ```powershell
  Add-MpPreference -ExclusionPath "C:\Path\To\windows11pro-setup"
  ```
- Re-run the setup script
- Re-enable real-time protection after completion

#### Issue 4: Software Installation Failures

**Problem**: Some applications fail to install via package manager.

**Solution**:
```powershell
# Update package managers
choco upgrade chocolatey -y
winget upgrade

# Install with elevated privileges
.\setup.ps1 -RunAsAdmin

# Check internet connection and try again
```

#### Issue 5: System Performance Issues After Setup

**Problem**: System runs slower after applying optimizations.

**Solution**:
```powershell
# Restore default settings
.\restore-defaults.ps1

# Or adjust performance settings
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
.\setup.ps1 -PerformanceMode "Balanced"
```

#### Issue 6: Git Configuration Not Applied

**Problem**: Git settings not persisting after setup.

**Solution**:
```powershell
# Verify Git installation
git --version

# Manually configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Check configuration
git config --list
```

#### Issue 7: Network Issues After Setup

**Problem**: Internet connectivity problems after network optimization.

**Solution**:
```powershell
# Reset network settings
netsh int ip reset resetall
ipconfig /release
ipconfig /renew

# Or restore network configuration
.\restore-network-defaults.ps1
```

### Diagnostic Commands

Use these commands to troubleshoot:

```powershell
# Check system information
systeminfo

# View recent logs
Get-EventLog -LogName System -Newest 10

# Check script execution status
Get-ExecutionPolicy

# Verify Windows version
[System.Environment]::OSVersion

# Check available disk space
Get-Volume

# View installed applications
Get-Package | Select-Object Name, Version

# Test network connectivity
Test-NetConnection -ComputerName google.com
```

### Getting Help

1. **Check the Logs**
   - Logs are stored in `./logs/` directory
   - Review error messages for specific issues

2. **Review Issue Tracker**
   - Visit [GitHub Issues](https://github.com/zaf-tech/windows11pro-setup/issues)
   - Search for similar problems

3. **Run in Debug Mode**
   ```powershell
   .\setup.ps1 -Debug -Verbose
   ```

4. **Contact Support**
   - Open an issue on GitHub with:
     - Windows version and build number
     - Error messages
     - Steps to reproduce
     - System specifications

### Rollback and Recovery

To restore your system to a previous state:

```powershell
# Restore all defaults
.\restore-defaults.ps1

# Restore specific component
.\restore-defaults.ps1 -Component Security
.\restore-defaults.ps1 -Component Network
.\restore-defaults.ps1 -Component Appearance
```

### Performance Monitoring

Monitor system performance after setup:

```powershell
# Open Performance Monitor
perfmon.exe

# Check Task Manager
taskmgr.exe

# Monitor resource usage
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
```

## Contributing

We welcome contributions to improve this setup toolkit!

### How to Contribute

1. **Fork the Repository**
   ```bash
   git clone https://github.com/yourusername/windows11pro-setup.git
   cd windows11pro-setup
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**
   - Follow the existing code style
   - Add comments for complex logic
   - Test thoroughly on Windows 11 Pro

4. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "Add feature: description of changes"
   ```

5. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Submit a Pull Request**
   - Describe your changes clearly
   - Reference any related issues
   - Wait for review and feedback

### Development Guidelines

- Use PowerShell best practices
- Include error handling
- Add validation for user inputs
- Document new features
- Test on multiple Windows 11 builds
- Update README if needed

### Reporting Issues

When reporting bugs:
- Provide Windows version and build number
- Include full error messages
- List steps to reproduce
- Share system specifications
- Check existing issues first

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This toolkit modifies system settings and installs software. Use at your own risk. Always:
- Back up your system before running
- Review scripts before execution
- Test in a virtual machine first
- Keep system restore enabled
- Have recovery media available

## Acknowledgments

- Windows 11 community for feedback and suggestions
- Open-source projects used in this toolkit
- Contributors and testers

## Support

For issues, questions, or suggestions:
- Open an issue on [GitHub Issues](https://github.com/zaf-tech/windows11pro-setup/issues)
- Start a discussion on [GitHub Discussions](https://github.com/zaf-tech/windows11pro-setup/discussions)
- Check [Wiki](https://github.com/zaf-tech/windows11pro-setup/wiki) for detailed guides

---

**Last Updated**: January 2, 2026

**Version**: 1.0.0

For more information and updates, visit the [project repository](https://github.com/zaf-tech/windows11pro-setup).
