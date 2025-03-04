function Add-ImageToConfig {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$ImageName,

        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateScript({
                if (-not (Test-Path $_)) {
                    throw 'Path does not exist'
                }
                if (-not $_.EndsWith('.iso')) {
                    throw 'Path must end with .iso extension'
                }
                return $true
            })]
        [string]$IsoPath,

        [Parameter(Position = 2, Mandatory = $false)]
        [ValidateScript({
                if (-not $_.EndsWith('.vhdx')) {
                    throw 'Path must end with .vhdx extension'
                }
                return $true
            })]
        [string]$ReferenceVHDX
    )

    try {
        Write-Host "Adding image '$ImageName' to config... " -ForegroundColor Cyan -NoNewline

        # Set reference VHDX path if not provided
        if (-not $PSBoundParameters.ContainsKey('ReferenceVHDX')) {
            $ReferenceVHDX = Join-Path -Path $script:hvConfig.vmPath -ChildPath "wks$($ImageName)ref.vhdx"
        }

        # Check if image already exists
        if ($script:hvConfig.images.imageName -contains $ImageName) {
            throw "Image '$ImageName' already exists in configuration"
        }

        # Create new image configuration
        $newImage = [PSCustomObject]@{
            imageName = $ImageName
            imagePath = $IsoPath
            refImagePath = $ReferenceVHDX
        }

        # Add to config and save
        $script:hvConfig.images += $newImage
        $script:hvConfig | ConvertTo-Json -Depth 20 | Out-File -FilePath $script:hvConfig.hvConfigPath -Encoding ascii -Force
        Write-Host $script:tick -ForegroundColor Green

        # Create reference image if needed
        if (-not (Test-Path -Path $newImage.refImagePath)) {
            #Write-LogEntry -Type Information -Message "Creating reference VHDX for $ImageName"
            Write-Host 'Creating reference Autopilot VHDX - this may take some time...' -NoNewline -ForegroundColor Cyan
            New-ClientVHDX -VhdxPath $newImage.refImagePath -IsoPath $newImage.imagePath
        }
    } catch {
        Write-Warning $_.Exception.Message
    }
}
