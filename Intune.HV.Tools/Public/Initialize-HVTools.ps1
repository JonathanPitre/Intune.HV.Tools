function Initialize-HVTools {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $true)]
        [System.IO.FileInfo]$Path,

        [parameter(Position = 1, Mandatory = $false)]
        [switch]$Reset
    )
    try {
        $paths = @(
            "$Path\.hvtools",
            "$Path\.hvtools\tenantVMs"
        )
        Write-Host 'Creating hvtools folder structure...' -ForegroundColor Cyan
        foreach ($p in $paths) {
            if (-not(Test-Path $p -ErrorAction SilentlyContinue)) {
                Write-Host " + Creating $p..." -ForegroundColor Cyan -NoNewline
                New-Item -Path $p -ItemType Directory -Force | Out-Null
                Write-Host $script:tick -ForegroundColor Green
            }
        }
        $cfgPath = "$Path\.hvtools\hvconfig.json"
        Write-Host " + Creating $cfgPath..." -ForegroundColor Cyan -NoNewline
        if ((Test-Path $cfgPath -ErrorAction SilentlyContinue) -and ($Reset -eq $false)) {
            Write-Host "$script:tick (Already created - no need to run this again.)" -ForegroundColor Green
        } else {
            $initCfg = @{
                'hvConfigPath' = $cfgPath
                'images' = @()
                'vmPath' = "$Path\.hvtools\tenantVMs"
                'vSwitchName' = $null
                'vLanId' = $null
                'tenantConfig' = @()
            } | ConvertTo-Json -Depth 20
            $initCfg | Out-File -FilePath $cfgPath -Encoding ascii -Force
            $cfgPath | Out-File -FilePath "$env:USERPROFILE\.hvtoolscfgpath" -Encoding ascii -Force
            Write-Host $script:tick -ForegroundColor Green
            $script:hvConfig = (Get-Content -Path "$(Get-Content "$env:USERPROFILE\.hvtoolscfgpath" -ErrorAction SilentlyContinue)" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json)
        }
    } catch {
        Write-Warning $_
    }
}
