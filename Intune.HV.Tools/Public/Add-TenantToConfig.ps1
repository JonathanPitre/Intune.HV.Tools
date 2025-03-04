function Add-TenantToConfig {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $true)]
        [string]$TenantName,

        [parameter(Position = 1, Mandatory = $true)]
        [string]$ImageName,

        [parameter(Position = 2, Mandatory = $true)]
        [string]$AdminUpn
    )
    try {
        Write-Host "Adding tenant '$TenantName' to config..." -ForegroundColor Cyan -NoNewline

        # Validate image exists in config
        if ($null -eq $script:hvConfig.images -or $script:hvConfig.images.Count -eq 0) {
            throw 'No images found in configuration. Add an image first using Add-ImageToConfig.'
        } elseif ($script:hvConfig.images.imageName -notcontains $ImageName) {
            throw "Image '$ImageName' not found in configuration. Add it first using Add-ImageToConfig."
        }

        # Check if tenant already exists
        if ($script:hvConfig.tenantConfig.TenantName -contains $TenantName) {
            throw "Tenant '$TenantName' already exists in configuration."
        }

        # Add new tenant config
        $script:hvConfig.tenantConfig += [PSCustomObject]@{
            TenantName = $TenantName
            ImageName = $ImageName
            AdminUpn = $AdminUpn
        }

        # Save updated config
        $script:hvConfig | ConvertTo-Json -Depth 20 | Out-File -FilePath $script:hvConfig.hvConfigPath -Encoding ascii -Force

        Write-Host $script:tick -ForegroundColor Green
    } catch {
        Write-Warning $_.Exception.Message
    }
}
