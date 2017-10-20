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
$CCMClientCacheSize  = $CCMCache.TotalSize
$CCMCLientCacheFree = $CCMCache.FreeSize
$CCMCLientCacheLocation = $CCMCache.Location

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
$NewCCMClientCacheSize = Check-CCMClientCacheSize $FreeSpaceAvailable

# Checking cache size has been set
If( $CCMClientCacheSize -ne $NewCCMClientCacheSize)
{
    If ($NewCCMClientCacheSize -lt $CCMClientCacheSize)#If new Client cache size is smaller than current cache size perform additional checks:
    {
        If ($NewCCMClientCacheSize -lt ($CCMClientCacheSize - $CCMCLientCacheFree))#If new Client cache size is smaller than size of items currently in cache, clear the cache
        {
            #Region clear cache items
            $ccmCacheItems = `
            Try
            {
                get-wmiobject -query "SELECT * FROM CacheInfoEx" -namespace "ROOT\ccm\SoftMgmtAgent"
            }
            Catch
            {
                Write-Log "Error: Failed to get ccmcache items"
            }
            
            foreach ($ccmCacheItem in $ccmCacheItems)
            {
                [guid]$ccmCacheItemCacheId = $ccmCacheItem.CacheId
                [string]$ccmCacheItemLocation = $ccmCacheItem.Location
                        Try
                        {
                            [wmi]"ROOT\ccm\SoftMgmtAgent:CacheInfoEx.CacheId=`"$ccmCacheItemCacheId`"" | Remove-WmiObject
                        }
                        Catch
                        {
                            Write-Host "Error: Failed to delete $ccmCacheItemCacheId from $ccmCacheItemLocation" -Source Clean-CMCacheOldItems -Severity 2
                        }
            }#Endregion clear cache items

            #Region clear cache orpaned items
            $UsedFolders = $CacheElements | ForEach-Object { Select-Object -inputobject $_.Location }
            Get-ChildItem($CCMCLientCacheLocation) | Where { $_.PSIsContainer } | Where { $UsedFolders -notcontains $_.FullName } | ForEach-Object { Remove-Item $_.FullName -recurse}
            #Endregion clear cache orpaned items
        }
        $CCMCache.TotalSize = $NewCCMClientCacheSize
    }
    Else
    {
        $CCMCache.TotalSize = $NewCCMClientCacheSize
    }
}