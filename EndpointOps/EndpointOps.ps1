
param(
    [int]$DiskWarningPercent = 15,
    [switch]$Remediate
)

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$ReportDir = Join-Path $Root "Reports"
$LogDir = Join-Path $Root "Logs"

New-Item -ItemType Directory -Force $ReportDir, $LogDir |
    Out-Null

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = Join-Path $LogDir "EndpointOps-$Timestamp.log"
$ReportFile = Join-Path $ReportDir "Inventory-$Timestamp.csv"

function Write-Log {
    param([string]$Message)

    $Line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
    Add-Content -Path $LogFile -Value $Line
    Write-Host $Line
}

try {
    Write-Log "Starting EndpointOps inventory."

    $OS = Get-CimInstance Win32_OperatingSystem
    $Computer = Get-CimInstance Win32_ComputerSystem
    $BIOS = Get-CimInstance Win32_BIOS

    $Uptime = (Get-Date) - $OS.LastBootUpTime
    $MemoryGB = [math]::Round(
        $Computer.TotalPhysicalMemory / 1GB, 2
    )

    $Disks = Get-CimInstance Win32_LogicalDisk `
        -Filter "DriveType=3"

    $DiskResults = foreach ($Disk in $Disks) {
        $FreePercent = if ($Disk.Size -gt 0) {
            [math]::Round(
                ($Disk.FreeSpace / $Disk.Size) * 100, 2
            )
        } else {
            0
        }

        $Status = if ($FreePercent -lt $DiskWarningPercent) {
            "WARNING"
        } else {
            "OK"
        }

        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Drive        = $Disk.DeviceID
            TotalGB      = [math]::Round($Disk.Size / 1GB, 2)
            FreeGB       = [math]::Round($Disk.FreeSpace / 1GB, 2)
            FreePercent  = $FreePercent
            Status       = $Status
        }
    }

    $DiskResults | Export-Csv `
        -Path $ReportFile -NoTypeInformation

    Write-Log "Inventory report saved to $ReportFile"

    $CriticalServices = @(
        "EventLog",
        "Winmgmt",
        "Spooler"
    )

    $ServiceResults = foreach ($Name in $CriticalServices) {
        $Service = Get-Service -Name $Name `
            -ErrorAction SilentlyContinue

        if ($null -eq $Service) {
            $Status = "NOT_FOUND"
        } else {
            $Status = $Service.Status.ToString()
        }

        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Service      = $Name
            Status       = $Status
        }

        Write-Log "Service $Name status: $Status"

        if ($Remediate -and
            $Name -eq "Spooler" -and
            $Status -eq "Stopped") {

            try {
                Start-Service -Name "Spooler"
                Write-Log "Remediation: started Spooler."
            } catch {
                Write-Log "Remediation failed: $($_.Exception.Message)"
            }
        }
    }

    $ServiceResults | Format-Table -AutoSize

    Write-Host "`n--- DEVICE SUMMARY ---"
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        Manufacturer = $Computer.Manufacturer
        Model        = $Computer.Model
        SerialNumber = $BIOS.SerialNumber
        OS           = $OS.Caption
        OSVersion    = $OS.Version
        MemoryGB     = $MemoryGB
        UptimeHours  = [math]::Round($Uptime.TotalHours, 2)
    } | Format-List

    Write-Host "--- DISK HEALTH ---"
    $DiskResults | Format-Table -AutoSize

    Write-Log "EndpointOps completed successfully."
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
