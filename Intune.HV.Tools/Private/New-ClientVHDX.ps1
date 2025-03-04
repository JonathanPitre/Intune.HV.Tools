#requires -Modules "Hyper-ConvertImage"
function New-ClientVHDX {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$VhdxPath,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]$IsoPath,

        [Parameter(Position = 2, Mandatory = $false)]
        [switch]$Unattend
    )

    try {
        $module = Get-Module -ListAvailable -Name 'Hyper-ConvertImage'
        if ($module.count -lt 1) {
            Install-Module -Name 'Hyper-ConvertImage'
            $module = Get-Module -ListAvailable -Name 'Hyper-ConvertImage'
        }
        if ($PSVersionTable.PSVersion.Major -eq 7) {
            Import-Module -Name (Split-Path $module.ModuleBase -Parent) -UseWindowsPowerShell -ErrorAction SilentlyContinue 3>$null
        } else {
            Import-Module -Name 'Hyper-ConvertImage'
        }
        $currVol = Get-Volume
        Mount-DiskImage -ImagePath $IsoPath | Out-Null
        $dl = (Get-Volume | Where-Object { $_.DriveLetter -notin $currVol.DriveLetter }).DriveLetter
        $imageIndex = Get-ImageIndexFromWim -wimPath "$dl`:\sources\install.wim"
        Dismount-DiskImage -ImagePath $IsoPath | Out-Null
        $params = @{
            SourcePath = $IsoPath
            Edition = $imageIndex
            VhdType = 'Dynamic'
            VhdFormat = 'VHDX'
            VhdPath = $VhdxPath
            DiskLayout = 'UEFI'
            SizeBytes = 127gb
        }
        if ($Unattend) {
            $params.UnattendPath = $Unattend
        }
        Write-Host 'Building reference image...' -ForegroundColor Cyan -NoNewline
        Convert-WindowsImage @params
    } catch {
        Write-Warning $_
    } finally {
        if ($PSVersionTable.PSVersion.Major -eq 7) {
            Remove-Module -Name 'Hyper-ConvertImage' -Force
        }
    }
}
