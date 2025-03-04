@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'Intune.HV.Tools.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0.320'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID = 'f9f59767-cb8d-4532-8710-52ab326241ff'

    # Author of this module
    Author = 'Ben Reader, Jonathan Pitre'

    # Company or vendor of this module
    CompanyName = 'Powers-Hell'

    # Copyright statement for this module
    Copyright = '(c) 2020 Ben Reader. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Rapidly build VMs in Hyper-V with Intune.HV.Tools.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(@{ModuleName = 'WindowsAutoPilotIntune'; ModuleVersion = '5.7'; },
        @{ModuleName = 'Microsoft.Graph.Identity.DirectoryManagement'; ModuleVersion = '2.26.1'; },
        @{ModuleName = 'Hyper-ConvertImage'; ModuleVersion = '10.2'; })

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = 'Add-ImageToConfig', 'Add-NetworkToConfig', 'Add-TenantToConfig',
    'Get-HVToolsConfig', 'Initialize-HVTools', 'New-ClientVM'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = 'Intune', 'Azure', 'Automation', 'Hyper-V', 'Virtualization'

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/tabs-not-spaces/Intune.HV.Tools'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = '### 1.0.0.320

- Fixed VMIntegrationService error on non-English systems [#24](https://github.com/tabs-not-spaces/Intune.HV.Tools/pull/24)
- Fixed authentication error to use MgGraph [#29](https://github.com/tabs-not-spaces/Intune.HV.Tools/issues/29)
- Added error checking when AutopilotConfigurationFile.json is missing
- Added fix when multiple Autopilot profile exists
- Improved code formatting
- Improved comments
- Fixed errors when using custom Virtual Machines Disks and Configs path
- Added dynamic memory support for VM creation
- Improved path handling for ISO and VM locations
- Added support for internal virtual switch configuration
- Improved error handling for ISO path validation

### 1.0.0.312

- Added ISOPath and RefVHDX as required parameters
- Fixed documentation typo on line 37
- Added support for custom VHDX files

### 1.0.0.289

- Added ability to build reference images from Add-ImageToConfig
- Fixed compatibility issues with Server OS
- Added Windows image index selection
- Improved code organization and readability
- Enhanced VM naming consistency
- Updated minimum required module versions
- Improved documentation clarity

### 1.0.0.281

- Added missing HGS Guardian creation check
- Added automatic folder creation and VHDX dismount (thanks [hkystar35](https://github.com/hkystar35))
- Added error handling improvements (thanks [hkystar35](https://github.com/hkystar35))
- Added git release notes to build script
- Improved release notes formatting
- Enhanced release notes clarity (thanks [hkystar35](https://github.com/hkystar35))
- Fixed file encoding issue

### 1.0.0.205

- Fixed various minor issues (@hkystar35)
- Fixed legacy variable reference
- Added cmdlet autocomplete functionality
- Standardized parameter values
- Improved cmdlet naming consistency
- Enhanced cmdlet usability
- Fixed PowerShell 7 module dependencies
- Added required Path parameter to Initialize-HVTools
- Updated module description and notes
- Released initial stable version (#3)
- Added VM serial number to notes (@brucesa85)
- Prepared for initial release
- Updated module dependencies
- Fixed multiple VM naming issues
- Added PowerShell 5 and 7 compatibility
- Added config reset capability
- Added configuration management function
- Removed unnecessary expansion
- Added PowerShell version compatibility
- Added parameter auto-completion

### 1.0.0.203

- Initial release'

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}

