#$ErrorActionPreference = "Stop"
#region Functions
function New-ClientVHDX {
    param
    (
        [string]$vhdxPath,
        [Parameter(Mandatory = $false)]
        [string]$unattend = 'none',
        [string]$WinISO
    )
    $convMod = Get-Module -ListAvailable -Name 'Convert-WindowsImage'
    if ($convMod.count -ne 1) {
        Install-Module -Name 'Convert-WindowsImage' -Scope AllUsers
    } else {
        Update-Module -Name 'Convert-WindowsImage'
    }
    Import-Module -Name 'Convert-Windowsimage'
    if ($Unattend -eq 'none') {
        Convert-WindowsImage -SourcePath $WinISO -Edition 3 -VhdType Dynamic -VhdFormat VHDX -VhdPath $vhdxPath -DiskLayout UEFI -SizeBytes 127gb
    } else {
        Convert-WindowsImage -SourcePath $WinISO -Edition 3 -VhdType Dynamic -VhdFormat VHDX -VhdPath $vhdxPath -DiskLayout UEFI -SizeBytes 127gb -UnattendPath $unattend
    }
}
function Write-LogEntry {
    [cmdletBinding()]
    param (
        [ValidateSet('Information', 'Error')]
        $Type = 'Information',
        [parameter(Mandatory = $true)]
        $Message
    )
    switch ($Type) {
        'Error' {
            $severity = 3
            $fgColor = 'Red'
            break
        }
        'Information' {
            $severity = 6
            $fgColour = 'Yellow'
            break
        }
    }
    $dateTime = New-Object -ComObject WbemScripting.SWbemDateTime
    $dateTime.SetVarDate($(Get-Date))
    $utcValue = $dateTime.Value
    $utcOffset = $utcValue.Substring(21, $utcValue.Length - 21)
    $scriptName = (Get-PSCallStack)[1]
    $logLine = `
        "<![LOG[$message]LOG]!>" + `
        "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($utcOffset)`" " + `
        "date=`"$(Get-Date -Format M-d-yyyy)`" " + `
        "component=`"$($scriptName.Command)`" " + `
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + `
        "type=`"$severity`" " + `
        "thread=`"$PID`" " + `
        "file=`"$($scriptName.ScriptName)`">"

    $logLine | Out-File -Append -Encoding utf8 -FilePath $logFile -Force
    #Write-Host $Message -ForegroundColor $fgColor
}
function New-ClientVM {
    [cmdletBinding()]
    param (
        [string]$vmName,
        [string]$clientPath,
        [pscredential]$localAdmin,
        [string]$refApVHDX
    )
    If (-not(Test-Path "$clientPath\$vmName")) { New-Item -ItemType Directory -Path "$clientPath\$vmName" }
    Copy-Item -Path $refApVHDX -Destination "$clientPath\$vmName\$vmName.vhdx"
    $disk = (Mount-VHD -Path "$clientPath\$vmName\$vmName.vhdx" -Passthru | Get-Disk | Get-Partition | Where-Object { $_.type -eq 'Basic' }).DriveLetter
    Copy-Item -Path "$clientPath\AutoPilotProfile\AutopilotConfigurationFile.json" -Destination "$disk`:\Windows\Provisioning\Autopilot\" -Recurse -Filter 'AutopilotConfigurationFile.json'
    Dismount-VHD "$clientPath\$vmName\$vmName.vhdx"
    New-VM -Name $vmName -Path $clientPath\ -MemoryStartupBytes 4Gb -VHDPath "$clientPath\$vmName\$vmName.vhdx" -Generation 2 | Out-Null
    Enable-VMIntegrationService -VMName $vmName -Name 'Guest Service Interface'
    #Disable Checkpoints
    #set-vm -name $vmName -CheckpointType Disabled
    # Enable TPM
    Set-VMKeyProtector -VMName $vmName -NewLocalKeyProtector
    Enable-VMTPM -VMName $vmName
    #Disable AutoCheckpoint
    Set-VM $VMName -AutomaticCheckpointsEnabled $false
    #start-vm -Name $vmName
    Get-VMNetworkAdapter -VMName $vmName | Connect-VMNetworkAdapter -SwitchName 'BSALabNAT' | Set-VMNetworkAdapter -Name 'Internet' -DeviceNaming On
}
#endregion
#region Config
$scriptPath = $PSScriptRoot
$config = Get-Content "$scriptPath\client.json" -Raw | ConvertFrom-Json
$clientDetails = $config.ENVConfig | Where-Object { $_.ClientName -eq $config.Client }
$clientPath = "$($config.ClientVMPath)\$($config.Client)"
if (-not(Test-Path $clientPath)) { New-Item -ItemType Directory -Force -Path $clientPath | Out-Null }
$script:logfile = "$clientPath\Build.log"
$refApVHDX = $config.Win10APVHDX
$clientName = $clientDetails.ClientName
$win10iso = $config.Win101809ISO
$numOfVMs = $clientDetails.NumberofClients
$adminUser = $clientDetails.adminuser
Write-LogEntry -Type Information -Message "Path to AutoPilot Reference VHDX is: $refApVHDX"
Write-LogEntry -Type Information -Message "Client name is: $clientName"
Write-LogEntry -Type Information -Message "Win10 ISO is located: $win10iso"
Write-LogEntry -Type Information -Message "Path to client VMs will be: $clientPath"
Write-LogEntry -Type Information -Message "Number of VMs to create: $numOfVMs"
Write-LogEntry -type Information -Message "Admin user for tenant: $clientName is: $adminUser"
if (-not(Test-Path -Path $refApVHDX -ErrorAction SilentlyContinue)) {
    Write-LogEntry -Type Information -Message 'Creating Workstation AutoPilot VHDX'
    new-ClientVHDX -vhdxpath $refApVHDX -winiso $win10iso
    Write-LogEntry -Type Information -Message 'Workstation AutoPilot VHDX has been created'
}
#endregion
#region getAPPolicy
if (-not(Test-Path -Path "$clientPath\AutoPilotProfile\AutopilotConfigurationFile.json" -ErrorAction SilentlyContinue)) {
    if ((Get-Module -ListAvailable -Name WindowsAutoPilotIntune).count -ne 1) {
        Install-Module -Name WindowsAutoPilotIntune -Scope allusers -Force
    } else {
        Update-Module -Name WindowsAutoPilotIntune
    }
    Import-Module -Name WindowsAutoPilotIntune
    Connect-AutoPilotIntune -user $adminUser
    $appolicies = Get-AutoPilotProfile
    if ($appolicies.count -gt 1) {
        $appol = $appolicies | Out-GridView -PassThru
    } else {
        $appol = $appolicies
    }
    If (-not(Test-Path "$clientPath\AutoPilotProfile\")) { New-Item -ItemType Directory -Path "$clientPath\AutoPilotProfile\" }
    $appol | ConvertTo-AutoPilotConfigurationJSON | Out-File "$clientPath\AutoPilotProfile\AutopilotConfigurationFile.json" -Encoding ascii
}
#endregion
#region New Client VM
$apOut = @()
if (-not(Test-Path -Path $clientPath\$vmName\)) { New-Item -ItemType Directory -Force -Path $clientPath\$vmName\ }
if ($numOfVMs -eq 1) {
    $vmName = "$($clientName)$numOfVMs"
    $AP = new-clientVM -vmName $vmName -clientpath $clientPath\$vmName\ -localAdmin $localAdmin -refAPVHDX $refApVHDX
    $ap | Out-File -FilePath "$clientPath\$numOfVMs.csv"
    $apOut += $ap
} else {
    $vnum = 1
    $existingvms = (Get-VM -Name "$($clientname)*").name -replace "$($clientname)"
    while ($vnum -ne ($numOfVMs + 1 + $existingvms.Count)) {
        if (-not($vnum -in $existingvms)) {
            $vmName = "$($clientName)$vnum"
            $apOut += new-clientVM -vmName $vmName -clientpath $clientPath\$vmName\ -localAdmin $localAdmin -refAPVHDX $refApVHDX
        }
        $vnum++
    }
}
#endregion

#$clientPath\$vmName\$vmName.vhdx
