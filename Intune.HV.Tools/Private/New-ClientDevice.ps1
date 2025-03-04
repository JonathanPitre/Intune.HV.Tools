function New-ClientDevice {
    [cmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Position = 0, Mandatory = $true)]
        [string]$VMName,

        [parameter(Position = 1, Mandatory = $true)]
        [string]$ClientPath,

        [parameter(Position = 2, Mandatory = $true)]
        [string]$RefVHDX,

        [parameter(Position = 3, Mandatory = $true)]
        [string]$VSwitchName,

        [parameter(Position = 4, Mandatory = $false)]
        [string]$VLanId,

        [parameter(Position = 5, Mandatory = $true)]
        [string]$CPUCount,

        [parameter(Position = 6, Mandatory = $true)]
        [string]$VMMemory,

        [parameter(Position = 7, Mandatory = $false)]
        [switch]$DynamicMemory,

        [parameter(Position = 8, Mandatory = $false)]
        [switch]$skipAutoPilot
    )

    # Display all parameters for debugging
    Write-Verbose 'New-ClientDevice Parameters:'
    Write-Verbose "VMName: $VMName"
    Write-Verbose "ClientPath: $ClientPath"
    Write-Verbose "RefVHDX: $RefVHDX"
    Write-Verbose "VSwitchName: $VSwitchName"
    Write-Verbose "VLanId: $VLanId"
    Write-Verbose "CPUCount: $CPUCount"
    Write-Verbose "VMMemory: $VMMemory"
    Write-Verbose "DynamicMemory: $DynamicMemory"
    Write-Verbose "skipAutoPilot: $skipAutoPilot"

    # Check if Hyper-V is running properly
    Write-Host 'Checking Hyper-V service status...' -ForegroundColor Cyan
    $hvService = Get-Service -Name 'vmms' -ErrorAction SilentlyContinue
    if (-not $hvService -or $hvService.Status -ne 'Running') {
        Write-Error 'Hyper-V Virtual Machine Management Service is not running. Please ensure Hyper-V is properly installed and the service is running.'
        return
    }

    # Check Hyper-V configuration paths
    try {
        Write-Host 'Checking Hyper-V configuration paths...' -ForegroundColor Cyan
        #$hyperVConfig = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization' -ErrorAction SilentlyContinue

        # Get default VM and VHD paths
        $defaultVMPath = (Get-VMHost).VirtualMachinePath
        $defaultVHDPath = (Get-VMHost).VirtualHardDiskPath

        Write-Verbose "Default VM Path: $defaultVMPath" -ForegroundColor Green
        Write-Verbose "Default VHD Path: $defaultVHDPath" -ForegroundColor Green

        # Check if these paths exist
        if (-not (Test-Path -Path $defaultVMPath -PathType Container)) {
            Write-Warning "Default VM path does not exist: $defaultVMPath"
            Write-Host 'Creating default VM path...' -ForegroundColor Cyan
            New-Item -Path $defaultVMPath -ItemType Directory -Force | Out-Null
        }

        if (-not (Test-Path -Path $defaultVHDPath -PathType Container)) {
            Write-Warning "Default VHD path does not exist: $defaultVHDPath"
            Write-Host 'Creating default VHD path...' -ForegroundColor Cyan
            New-Item -Path $defaultVHDPath -ItemType Directory -Force | Out-Null
        }
    } catch {
        Write-Warning "Could not verify Hyper-V configuration paths: $_"
    }

    $VHDXPath = "$ClientPath\$VMName.vhdx"
    # Copy VHDX file
    Write-Host "Copying VHDX from $RefVHDX to $VHDXPath..." -ForegroundColor Cyan
    Copy-Item -Path $RefVHDX -Destination $VHDXPath -Force
    # Publish AutoPilot config if needed
    if (-not $skipAutoPilot) {
        Write-Host 'Publishing AutoPilot configuration...' -ForegroundColor Cyan
        Publish-AutoPilotConfig -vmName $VMName -clientPath $ClientPath
    }

    # Verify virtual switch exists
    if (-not (Get-VMSwitch -Name $VSwitchName -ErrorAction SilentlyContinue)) {
        Write-Error "Virtual switch '$VSwitchName' does not exist. Please create it first."
        return
    }
    # Check if VM already exists and remove it
    $existingVM = Get-VM -Name $VMName -ErrorAction SilentlyContinue
    if ($existingVM) {
        Write-Host "VM '$VMName' already exists. Removing it." -ForegroundColor Yellow
        Remove-VM -Name $VMName -Force
    }

    Write-Verbose "Using memory value: $VMMemory bytes"
    # Create the VM with full path to VHDX
    Write-Host "Creating VM: $VMName with VHDX: $VHDXPath..." -ForegroundColor Cyan

    # Try creating VM with explicit configuration path
    $vmConfigPath = Join-Path -Path $defaultVMPath -ChildPath $VMName
    if (-not (Test-Path -Path $vmConfigPath -PathType Container)) {
        New-Item -Path $vmConfigPath -ItemType Directory -Force | Out-Null
    }

    # Create VM with explicit paths
    $vm = New-VM -Name $VMName -MemoryStartupBytes $VMMemory -VHDPath $VHDXPath -Generation 2 -Path $vmConfigPath -ErrorAction Stop

    # Configure VM settings
    Write-Host 'Configuring VM settings...' -ForegroundColor Cyan
    Get-VMIntegrationService -VMName $VMName | Where-Object Name -Match 'Interface' | Enable-VMIntegrationService
    Set-VM -Name $VMName -CheckpointType Disabled -AutomaticStartAction Nothing -AutomaticStopAction ShutDown -ErrorAction Stop
    Set-VMProcessor -VMName $VMName -Count $CPUCount -ErrorAction Stop

    # Enable Dynamic Memory if specified
    If ($DynamicMemory) {
        Write-Host 'Enabling dynamic memory...' -ForegroundColor Cyan
        # Set dynamic memory parameters according to documented ranges:
        # StartupBytes: Must be multiple of 2MB between 32MB and 65536MB (64GB)
        # MinimumBytes: Must be between 32MB and StartupBytes
        # MaximumBytes: Must be between StartupBytes and 1TB
        # BufferPercent: Must be between 5-2000
        Set-VM -Name $VMName -DynamicMemory -ErrorAction Stop
        Set-VMMemory -VMName $VMName `
            -DynamicMemoryEnabled $true `
            -StartupBytes $VMMemory `
            -MinimumBytes 512MB `
            -MaximumBytes $VMMemory `
            -Buffer 20 `
            -ErrorAction Stop
    }

    # Configure firmware and networking
    Set-VMFirmware -VMName $VMName -EnableSecureBoot On -ErrorAction Stop
    Get-VMNetworkAdapter -VMName $VMName -ErrorAction Stop | Connect-VMNetworkAdapter -SwitchName $VSwitchName -ErrorAction Stop | Set-VMNetworkAdapter -Name $VSwitchName -DeviceNaming On -ErrorAction Stop

    # Configure VLAN if specified
    if ($VLanId) {
        Write-Host "Setting VLAN ID: $VLanId..." -ForegroundColor Cyan
        Set-VMNetworkAdapterVlan -VMName $VMName -Access -VlanId $VLanId -ErrorAction Stop
    }

    # Configure TPM
    $owner = Get-HgsGuardian UntrustedGuardian -ErrorAction SilentlyContinue
    If (-not $owner) {
        # Creating new UntrustedGuardian since it did not exist
        $owner = New-HgsGuardian -Name UntrustedGuardian -GenerateCertificates
    }
    $kp = New-HgsKeyProtector -Owner $owner -AllowUntrustedRoot
    Set-VMKeyProtector -VMName $VMName -KeyProtector $kp.RawData -ErrorAction Stop
    Enable-VMTPM -VMName $VMName -ErrorAction Stop

    # Start the VM
    Write-Host "Starting VM: $VMName..." -ForegroundColor Cyan
    Start-VM -Name $VMName -ErrorAction Stop

    # Set VM Info with Serial number
    $vmSerial = (Get-CimInstance -Namespace root\virtualization\v2 -class Msvm_VirtualSystemSettingData |
            Where-Object { ($_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized') -and ($_.ElementName -eq $VMName) }).BIOSSerialNumber
    if ($vmSerial) {
        Get-VM -Name $VMName | Set-VM -Notes "Serial Number: $vmSerial"
    }

    Write-Host "VM '$VMName' created and started successfully!" -ForegroundColor Green
}
