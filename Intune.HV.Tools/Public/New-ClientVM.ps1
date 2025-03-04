function New-ClientVM {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Position = 0, Mandatory = $true)]
        [string]$TenantName,

        [parameter(Position = 1, Mandatory = $false)]
        [string]$OSBuild,

        [parameter(Position = 2, Mandatory = $true)]
        [ValidateRange(1, 999)]
        [int]$NumberOfVMs,

        [parameter(Position = 3, Mandatory = $true)]
        [ValidateRange(1, 999)]
        [int]$CPUsPerVM,

        [parameter(Position = 4, Mandatory = $false)]
        [ValidateRange(2gb, 20gb)]
        [int64]$VMMemory = 4gb,

        [parameter(Position = 5, Mandatory = $false)]
        [switch]$DynamicMemory,

        [parameter(Position = 6, Mandatory = $false)]
        [switch]$SkipAutoPilot
    )
    try {
        #region Config
        # Pre-load Hyper-V module
        Get-Command -Module 'Hyper-V' | Out-Null
        $clientDetails = $script:hvConfig.tenantConfig | Where-Object { $_.TenantName -eq $TenantName }
        if ($OSBuild) {
            $imageDetails = $script:hvConfig.images | Where-Object { $_.imageName -eq $OSBuild }
        } else {
            $imageDetails = $script:hvConfig.images | Where-Object { $_.imageName -eq $clientDetails.imageName }
        }
        $clientPath = "$($script:hvConfig.vmPath)\$($TenantName)"
        if ($imageDetails.refimagePath -like "*wks$($ImageName)ref.vhdx") {
            if (-not (Test-Path $imageDetails.imagePath -ErrorAction SilentlyContinue)) {
                throw "Installation media not found at location: $($imageDetails.imagePath)"
            }
        }
        if (-not (Test-Path -Path $clientPath)) {
            New-Item -ItemType Directory -Force -Path $clientPath | Out-Null
        }

        Write-Verbose "Autopilot Reference VHDX: $($imageDetails.refImagePath)"
        Write-Verbose "Client name: $TenantName"
        Write-Verbose "Windows ISO is located:  $($imageDetails.imagePath)"
        Write-Verbose "Path to client VMs will be: $clientPath"
        Write-Verbose "Number of VMs to create:  $NumberOfVMs"
        Write-Verbose "Admin user for $TenantName is:  $($clientDetails.adminUpn)`n"
        #endregion

        #region Check for ref image - if it's not there, build it
        if (-not (Test-Path -Path $imageDetails.refImagePath -ErrorAction SilentlyContinue)) {
            Write-Host 'Creating reference Autopilot VHDX - this may take some time...' -NoNewline -ForegroundColor Cyan
            New-ClientVHDX -vhdxPath $imageDetails.refImagePath -winIso $imageDetails.imagePath
            Write-Host 'Reference Autopilot VHDX has been created.' -ForegroundColor Green
        }
        #endregion
        #region Get Autopilot policy
        if (-not ($SkipAutoPilot)) {
            Get-AutopilotPolicy -FileDestination "$clientPath"
            if (-not (Test-Path "$clientPath\AutopilotConfigurationFile.json" -ErrorAction SilentlyContinue)) {
                throw 'Autopilot config not found.'
            }
        }
        #endregion
        #region Build the client VMs
        if (-not (Test-Path -Path $clientPath -ErrorAction SilentlyContinue)) {
            New-Item -Path $clientPath -ItemType Directory -Force | Out-Null
        }

        # Ensure all required parameters are properly set and validated
        if (-not $script:hvConfig.vSwitchName) {
            throw 'Virtual switch name is not configured. Please check the hvConfig settings.'
        }

        if (-not $imageDetails.refImagePath) {
            throw 'Reference VHDX path is not configured. Please check the image settings.'
        }

        # Create base parameter hashtable with all mandatory parameters
        $vmParams = @{
            ClientPath = $clientPath
            RefVHDX = $imageDetails.refImagePath
            VSwitchName = $script:hvConfig.vSwitchName
            CPUCount = $CPUsPerVM
            VMMemory = $VMMemory
        }

        # Add optional parameters only if they are specified
        if ($SkipAutoPilot) {
            $vmParams.skipAutoPilot = $true
        }

        if ($DynamicMemory) {
            $vmParams.DynamicMemory = $true
        }

        if ($script:hvConfig.vLanId) {
            $vmParams.VLanId = $script:hvConfig.vLanId
        }

        # Display the parameters being passed to New-ClientDevice for debugging
        Write-Host 'Parameters being passed to New-ClientDevice:' -NoNewline -ForegroundColor Cyan
        $vmParams.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key): $($_.Value)" -NoNewline -ForegroundColor Cyan }

        if ($NumberOfVMs -eq 1) {
            # Calculate the VM name before adding it to the parameters
            $max = 1
            $existingVMs = Get-VM -Name "$TenantName*" -ErrorAction SilentlyContinue
            if ($existingVMs) {
                $max = ($existingVMs.name -replace "$TenantName`_" -replace '\D' |
                        Where-Object { $_ -match '^\d+$' } |
                        Measure-Object -Maximum |
                        Select-Object -ExpandProperty Maximum) + 1
            }

            # Add VMName to parameters - this is a mandatory parameter for New-ClientDevice
            $vmName = "$($TenantName)_$max"
            $vmParams.VMName = $vmName

            Write-Host "Creating VM: $vmName..." -NoNewline -ForegroundColor Cyan
            New-ClientDevice @vmParams
        } else {
            (1..$NumberOfVMs) | ForEach-Object {
                # Calculate the VM name before adding it to the parameters
                $max = 1
                $existingVMs = Get-VM -Name "$TenantName*" -ErrorAction SilentlyContinue
                if ($existingVMs) {
                    $max = ($existingVMs.name -replace "$TenantName`_" -replace '\D' |
                            Where-Object { $_ -match '^\d+$' } |
                            Measure-Object -Maximum |
                            Select-Object -ExpandProperty Maximum) + 1
                    }

                    # Add VMName to parameters - this is a mandatory parameter for New-ClientDevice
                    $vmName = "$($TenantName)_$max"
                    $vmParams.VMName = $vmName

                    Write-Host "Creating VM: $vmName..." -NoNewline -ForegroundColor Cyan
                    New-ClientDevice @vmParams
                }
            }
            #endregion
        } catch {
            $errorMsg = $_.Exception.Message
        } finally {
            if ($errorMsg) {
                Write-Warning $errorMsg
            }
        }
    }
