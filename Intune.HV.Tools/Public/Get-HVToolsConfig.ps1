function Get-HVToolsConfig {
    [CmdletBinding()]
    param ()

    try {
        # Check if config path exists
        $configPath = Get-Content -Path "$env:USERPROFILE\.hvtoolscfgpath" -ErrorAction Stop

        # Load and return config
        $script:hvConfig = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        return $script:hvConfig
    } catch {
        Write-Warning "Couldn't find HVTools configuration file. Please run Initialize-HVTools first to create the configuration file."
    }
}
