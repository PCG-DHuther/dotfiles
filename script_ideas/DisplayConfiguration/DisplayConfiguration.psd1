@{
    RootModule        = 'DisplayConfiguration.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = '049734DH'
    CompanyName       = ''
    Copyright         = '(c) 2026. All rights reserved.'
    Description       = 'Export and import Windows display configuration (resolution, scaling, position, primary display, rotation, refresh rate) using the Win32 CCD API.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Export-DisplayConfiguration'
        'Import-DisplayConfiguration'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData        = @{
        PSData = @{
            Tags       = @('Display', 'Monitor', 'Resolution', 'DPI', 'Scaling', 'Configuration')
            ProjectUri = ''
        }
    }
}
