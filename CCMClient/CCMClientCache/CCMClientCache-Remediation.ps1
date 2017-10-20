<# 
   .SYNOPSIS 
    Checks size of ConfigMgr client cache, and updates it if necessary

   .DESCRIPTION
    Checks that the current size of the ConfigMgr client cache is still correct, and updates it if necessary

   .NOTES
    AUTHOR: Mieszko Ślusarczyk
    EMAIL: mieszkoslusarczyk@gmail.com
    VERSION: 1.0.0.0
    DATE: 20.10.2017
    
    CHANGE LOG: 
    1.0.0.0 : 20.10.2017  : Initial version of script 

#> 

#Create COM Object for CCM and get Cache Information
$CCM = New-Object -com UIResource.UIResourceMGR
$CCMCache = $CCM.GetCacheInfo()

#=======================================
# Get the free space on the disk where CCMCache is stored (in MegaBytes)
#=======================================
 Function Get-FreeSystemDiskspace
 {
     # Get the free space from WMI and return as %
     $CCMClientCacheDrive = ($CCMCache.Location).Substring(0,2)
     $SystemDrive = Get-WmiObject Win32_LogicalDisk  -Filter "DeviceID='$CCMClientCacheDrive'"
     [int]$ReturnVal = $Systemdrive.FreeSpace/1048576
     return $ReturnVal
 }

 Function Check-CCMClientCacheSize
 {
     param([int]$CurrentFreeSpace)
     begin
     {
         switch($CurrentFreeSpace)
         {
             {$_ -lt 15360}{$NewCCMClientCacheSize = 5120} #if less than 15GB new cache size should be 5GB
             {$_ -lt 20480 -and $_ -ge 15360}{$NewCCMClientCacheSize = 10240} #if lessthan 20GB but more than 15GB new cache size should be 10GB
             {$_ -lt 51200 -and $_ -ge 20480}{$NewCCMClientCacheSize = 15360} #if lessthan 50GB but more than 20GB new cache should be 15GB
             {$_ -ge 51200}{$NewCCMClientCacheSize = 20480}#if more than 50GB new cache should be 20GB
             default{$NewCCMClientCacheSize = 5120}#default value
         }
     Return $NewCCMClientCacheSize
     }
 }
#==============
# End Functions
#==============

# Get the size available and then return the cache space needed
$FreeSpaceAvailable = Get-FreeSystemDiskspace
$CCMClientCacheSize  = $CCMCache.TotalSize
$NewCCMClientCacheSize = Check-CCMClientCacheSize $FreeSpaceAvailable

# Checking cache size has been set
If( $CCMClientCacheSize -ne $NewCCMClientCacheSize)
{
    $CCMCache.TotalSize = $NewCCMClientCacheSize
}