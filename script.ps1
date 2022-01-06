function Enable-DriveTrace {
    [CmdletBinding()]param()
    Write-Host "Creo evento"
    $query = "Select * from __InstanceCreationEvent within 1 where TargetInstance ISA 'Win32_LogicalDisk'"
    $identifier = "DeviceConnected"
    $actionBlock = {
        Write-Host "UBS INSERTADO"
        Write-Host $event
        $e = $event.SourceEventArgs.NewEvent.TargetInstance
        $partition = "ASSOCIATORS OF {Win32_LogicalDisk.DeviceID='$($e.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition"
        $p = Get-WmiObject -Query $partition
        $disk = "ASSOCIATORS OF {Win32_LogicalDisk.DeviceID='$($e.DeviceID)'} WHERE AssocClass = Win32_DiskDriveToDiskPartition"
        $d = Get-WmiObject -Query $disk
        $keypath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($d.PNPDeviceID)\Device Parameters\Partmgr"
        $DiskId = (Get-ItemProperty -Path $keypath).diskid
        $output = @()
        $props = [ordered]@{
            DiskID = $DiskId
            Partitions = $d.partitions
            PartititonIndex = $p.Index
            DriveLetter = $e.DeviceID
            Size = $e.size
            FreeSpace = $e.FreeSpace
            FileSystem = $e.fileSystem
            HostName = $e.systemname
        }
        $outPut = New-Object psobject -Property $props
        Write-Host $output
        $outPutProps = $output | Select-Object HostName, DiskID ,FileSystem, DriveLetter, @{N='FreeSpace';E={"$([math]::Round($(($_.FreeSpace)/1GB),2)) GB"}}

        foreach($pr in $outPutProps.psobject.Properties.name){
            Write-Host -ForegroundColor Green "$($pr)$(" " * $(20-$pr.length)) : $($outPutProps.$pr)"
        }

    } 
    Register-WmiEvent -Query $query -SourceIdentifier $Identifier -Action $actionBlock
}

$identifier = @(Enable-DriveTrace)[-1]

#Unregister-Event -SourceIdentifier $identifier -Force
