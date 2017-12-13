<# 
   .SYNOPSIS 
    Checks if automatic update is disabled for Citrix Receiver, and corrects setting if necessary

   .DESCRIPTION
    Check if registry keys responsible for auto update mechanism are set properly, and corrects them if necessary

   .NOTES
    AUTHOR: Mieszko Ślusarczyk
    EMAIL: mieszkoslusarczyk@gmail.com
    VERSION: 1.0.0.0
    DATE: 13.12.2017
    
    CHANGE LOG: 
    1.0.0.0 : 13.12.2017  : Initial version of script 

#>
If (Test-Path "HKLM:\SOFTWARE\Wow6432Node\Citrix\ICA Client\")
{
    $ICAClientBasePath = "HKLM:\SOFTWARE\Wow6432Node\Citrix\ICA Client\"
}
ElseIf (Test-Path "HKLM:\SOFTWARE\Citrix\ICA Client\")
{
    $ICAClientBasePath = "HKLM:\SOFTWARE\Citrix\ICA Client\"
}
Else
{
    Write-Host "Non-Compliant"
}
If ($ICAClientBasePath)
{
    If (!(Test-Path "$ICAClientBasePath\AutoUpdate\Commandline Policy"))
    {
        If (!(Test-Path "$ICAClientBasePath\AutoUpdate"))
        {
            New-Item -Path "$ICAClientBasePath\" -Name "AutoUpdate"
        }
        New-Item -Path "$ICAClientBasePath\AutoUpdate\" -Name "Commandline Policy"
    }

    If  (((Get-ItemProperty "$ICAClientBasePath\AutoUpdate\Commandline Policy\"|Select-Object -ExpandProperty "Banned") -eq "true")`
        -and`
        ((Get-ItemProperty "$ICAClientBasePath\AutoUpdate\Commandline Policy\"|Select-Object -ExpandProperty "Enable") -eq "false"))
        {
            Write-Host "Compliant"
        }
    Else
    {
        Set-ItemProperty -Path "$ICAClientBasePath\AutoUpdate\Commandline Policy\" -Name "Banned" -Value "true"
        Set-ItemProperty -Path "$ICAClientBasePath\AutoUpdate\Commandline Policy\" -Name "Enable" -Value "false"
    }
}