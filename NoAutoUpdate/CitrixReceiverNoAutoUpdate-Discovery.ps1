<# 
   .SYNOPSIS 
    Checks if automatic update is disabled for Citrix Receiver

   .DESCRIPTION
    Check if registry keys responsible for auto update mechanism are set properly

   .NOTES
    AUTHOR: Mieszko Ślusarczyk
    EMAIL: mieszkoslusarczyk@gmail.com
    VERSION: 1.0.0.0
    DATE: 13.12.2017
    
    CHANGE LOG: 
    1.0.0.0 : 13.12.2017  : Initial version of script 

#>
If (Test-Path "HKLM:\SOFTWARE\Wow6432Node\Citrix\ICA Client\AutoUpdate\Commandline Policy")
{
    If  (((Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Citrix\ICA Client\AutoUpdate\Commandline Policy\"|Select-Object -ExpandProperty "Banned") -eq "true")`
        -and`
        ((Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Citrix\ICA Client\AutoUpdate\Commandline Policy\"|Select-Object -ExpandProperty "Enable") -eq "false"))
        {
            Write-Host "Compliant"
        }
    Else
    {
        Write-Host "Non-Compliant"
    }
}
ElseIf (Test-Path "HKLM:\SOFTWARE\Citrix\ICA Client\AutoUpdate\Commandline Policy")
{
    If  (((Get-ItemProperty "HKLM:\SOFTWARE\Citrix\ICA Client\AutoUpdate\Commandline Policy\"|Select-Object -ExpandProperty "Banned") -eq "true")`
        -and`
        ((Get-ItemProperty "HKLM:\SOFTWARE\Citrix\ICA Client\AutoUpdate\Commandline Policy\"|Select-Object -ExpandProperty "Enable") -eq "false"))
        {
            Write-Host "Compliant"
        }
    Else
    {
        Write-Host "Non-Compliant"
    }
}
Else
{
    Write-Host "Non-Compliant"
}