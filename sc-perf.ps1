<#
  Star Citizen Performance Manager


  Changelog:
  * Sat Jan 25 2019 Dan Kinon <dan.kinon@gmail.com>
  - Initial script with infinite loop and StarCitizen process priority monitoring
#>

Function Set-Priority { 
  <#
  .SYNOPSIS    
   Set the process priority of the current Powershell session 
  .PARAMETER priority 
   The priority as an integer value from -2 to 3.  -2 is the lowest, 0 is the default (normal) and 3 is the highest (which may require Administrator privilege) 
  .PARAMETER processID 
   The process ID that will be change.  Omit to set the current powershell session. 
  .PARAMETER silent 
   Suppress the message at the end 
  .EXAMPLE   
   Set-PSPriority 2  
  #>
 
  param ( 
    [ValidateRange(-2,3)]  
    [Parameter(Mandatory=$true)] 
    [int]$priority, 
    [int]$processID = $pid, 
    [switch]$silent 
  )
 
  $priorityhash = @{-2="Idle";-1="BelowNormal";0="Normal";1="AboveNormal";2="High";3="RealTime"}
  (Get-Process -Id $processID).priorityclass = $priorityhash[$priority] 
 
  if (!$silent) { 
    "Process ID [$processID] is now set to " + (Get-Process -Id $pid).priorityclass 
  }
}


$ScriptName = "Star Citizen Performance Manager"
$ProcessName = "StarCitizen"
$PriorityHash = @{-2="Idle";-1="BelowNormal";0="Normal";1="AboveNormal";2="High";3="RealTime"}
$DesiredPriority = 2
$PollingSeconds = 10

<# System Specs #>
$CpuCores = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
$PhysicalMemory = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory/1MB)
$VirtualMemory = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalVirtualMemory/1MB)

Write-Host "$(Get-Date -Format u): Welcome to $ScriptName"
Write-Host "$(Get-Date -Format u): CPU Cores=$CpuCores, Physical Memory=$($PhysicalMemory)MB, Virtual Memory=$($VirtualMemory)MB"

<# GPU Specs #>
foreach ( $gpu in Get-WmiObject Win32_VideoController) {
    $name = $gpu.Name
    $driverVersion = $gpu.DriverVersion
    $resolution = "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution) @ $($gpu.MaxRefreshRate)Hz"
    Write-Host "$(Get-Date -Format u): $name [$driverVersion] running at $resolution"
}



while( $true ) {
  $ProcessActive = Get-Process $ProcessName -ErrorAction SilentlyContinue
  if( $ProcessActive -eq $null ) {
    Write-host "$(Get-Date -Format u): $ProcessName is not running"
  } else {
    $physicalMemory = [math]::Round($ProcessActive.WS/1MB)
    $virtualMemory = [math]::Round($ProcessActive.VM/1MB)
    Write-host "$(Get-Date -Format u): $ProcessName [$($ProcessActive.Id)] Priority=$($ProcessActive.priorityClass), Physical Memory=$($physicalMemory)MB, Virtual Memory=$($virtualMemory)MB"

    
    Get-WmiObject Win32_PerfRawData_PerfProc_Process |
    Sort PercentProcessorTime -descending | Select -first 5 Name,
    @{Name="PercentProcessorTime";Expression={($_.PercentProcessorTime/100000/100)/60}},
    IDProcess | format-table -autosize


    <# Set Process Priority #>
    if( $ProcessActive.PriorityClass -ne $Priorityhash[$DesiredPriority] ) {
      Write-host "$(Get-Date -Format u): setting process priority to $($Priorityhash[$DesiredPriority])"
      $ProcessActive.PriorityClass = $Priorityhash[$DesiredPriority]
    }
  }

  <# gps | where {$_.priorityclass -eq 'AboveNormal' -OR $_.priorityclass -eq 'High' -OR $_.priorityclass -eq 'RealTime'} | select name, priorityclass #>
  <# $i++
  Write-Host "$(Get-Date -Format u): We have counted up to $i" #>
  sleep $PollingSeconds
}
