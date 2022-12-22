<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0.1
_Dev_Status_ = Test
Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.

No implied support and test in test environment/device before using in any production environment.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#Version Changes

1.0.0   inital version
1.0.1   Clean the registry value before DCU scan starts.
        Blocked drivers are now written as success in the registry value so that the value is not deleted again the next day by dcu. 


Knowing Issues
    - Dell Command | Update make a clean of registy on a regular base. This script need to be run on regluar base as well to cover this otherwise drivers could be deployed which normally are blocked.


#>

<#
.Synopsis
    This PowerShell starting the Dell Command | Update to identify missing Drivers. After collecting missing drivers reading the Release Date of each driver and compare it with the planned days of delayed deployment (UpdateRings). If a driver is to new for deployment based on your policy the driver will blocked for update. Next time you will run an update with Dell Command | Update this drivers will be ignored.
    IMPORTANT: This script does not reboot the system to apply or query system.
    IMPORTANT: Dell Command | Update need to install first on the devices.

.DESCRIPTION
   PowerShell helping to use different Updates Rings with Dell Command | Update. You can configure up to 8 different Rings. This script need to run each time if a new Update Catalog is availible to update the Blocklist as well.
   
#>

################################################################
###  Variables Section                                       ###
################################################################

# Deffintion of your Update Rings based on Severity Level. Numbers are days.
$RingPolicy = @(
    [PSCustomObject]@{Name="Ring0"; Critical=7; Recommended=14; Optional=60}
    [PSCustomObject]@{Name="Ring1"; Critical=14; Recommended=21; Optional=120}
    [PSCustomObject]@{Name="Ring2"; Critical=21; Recommended=28; Optional=120}
    [PSCustomObject]@{Name="Ring3"; Critical=28; Recommended=35; Optional=120}
    [PSCustomObject]@{Name="Ring4"; Critical=35; Recommended=42; Optional=180}
    [PSCustomObject]@{Name="Ring5"; Critical=42; Recommended=49; Optional=180}
    [PSCustomObject]@{Name="Ring6"; Critical=49; Recommended=56; Optional=180}
    [PSCustomObject]@{Name="Ring7"; Critical=56; Recommended=63; Optional=180}
)
# This Variable allows you to block specific drivers by match code, e.g. you have on driver you can not deselect by Category or Type without blocking need drivers as well.
$Blacklist = @(
    [PSCustomObject]@{MatchCode="Dell*Update*"; Listed="15/12/2022"}
    [PSCustomObject]@{MatchCode="Dell*Monitor*"; Listed="19/12/2022"}
)

# You need to define the location of you Excel Sheet where the script could be find the assignments of Device-Name to Update-Ring
$UpdateRing = 'https://dellconfighub.blob.core.windows.net/configmaster/DellDeviceConfiguration.xlsx'

## Do not change ##
$DCUProgramName = ".\dcu-cli.exe"
$DCUPath = (Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%Command%Update%'").InstallLocation
$IgnoreListPath = "HKLM:\SOFTWARE\DELL\UpdateService\Service\IgnoreList"
$IgnoreListValue = "InstalledUpdateJson"
$DeviceSKU = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemSKUNumber
$catalogPath = $env:ProgramData+'\Dell\UpdateService\Temp'
$DriverAllMissing = New-Object -TypeName psobject
$DateCurrent = Get-Date
$Device = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Name


################################################################
###  Functions Section                                       ###
################################################################

# Function using DCU to identify missings Updates
Function Get-MissingDriver
    {

        Set-Location -Path $DCUPath
        $DCUScanLog = & $DCUProgramName /scan

        # Spliting text strings in single values in one array
        $TempVariable = $DCUScanLog | Select-String ("--")
        $TempVariable = $TempVariable -split ": "
        $TempVariable = $TempVariable -split " -- "
        $CountLines = $TempVariable.Count
        $IndexCounter = 0

        $CatalogFileName = Get-ChildItem $catalogPath | Where-Object Name -Like "*$DeviceSKU*xml" | Select-Object -ExpandProperty Name
        [XML]$DeviceCatalog = Get-Content $catalogPath\$CatalogFileName


                       
        for ($i = 0; $i -lt $CountLines) 
            {
            
            # Temp Var to get XML Datas from Device Catalog
            $TempXMLCatalog = ($DeviceCatalog.Manifest.SoftwareComponent)| Where-Object {$_.releaseid -like $TempVariable[0+$IndexCounter]}
            $ReleaseDate = $TempXMLCatalog.ReleaseDate
            
            # build a temporary array
            $DriverArrayTemp = New-Object -TypeName psobject
            $DriverArrayTemp | Add-Member -MemberType NoteProperty -Name 'DriverID' -Value $TempVariable[0+$IndexCounter]
            $DriverArrayTemp | Add-Member -MemberType NoteProperty -Name 'Name' -Value $TempVariable[1+$IndexCounter]
            $DriverArrayTemp | Add-Member -MemberType NoteProperty -Name 'Severity' -Value $TempVariable[2+$IndexCounter]
            $DriverArrayTemp | Add-Member -MemberType NoteProperty -Name 'Category' -Value $TempVariable[3+$IndexCounter]
            $DriverArrayTemp | Add-Member -MemberType NoteProperty -Name 'ReleaseDate' -Value $ReleaseDate

            
            $DriverArrayTemp
            
            $IndexCounter += 4

            $i = $i + 4

            }
        
        Set-Location \

    }

# Function checking if DCU is installed on a device
function Get-DCU-Installed 
    {

    If($null -ne $DCUPath)
        {

        $true

        }
    else 
        {
        
        $false

        } 
    
    }

# Select Driver based on DCU Scan where Blacklist Matchcode do not allow an update by DCU in general
function remove-DCU-BlacklistDriver 
    {

        ForEach ($black in $Blacklist)
            {

                $DriverAllMissing | Where-Object Name -like $Black.matchcode

            }
            
    
    }

# Select Driver based on DCU Scan where Timer do not allow an update by DCU
function Get-DCU-TimeFilter 
    {
        param
            (
                [String]$DriverRing
            )

        $DriverTime = $RingPolicy | Where-Object Name -EQ $DriverRing

        Foreach ($Driver in $DriverAllMissing)
            {

                If ($Driver.Severity -eq "Recommended")
                    {
                        [Datetime]$ReleaseDriver = $Driver.ReleaseDate
                        [datetime]$DeployDate = $ReleaseDriver.AddDays($DriverTime.Recommended)
                    }
                elseif ($Driver.Severity -eq "Critical") 
                    {
                        [Datetime]$ReleaseDriver = $Driver.ReleaseDate
                        [datetime]$DeployDate = $ReleaseDriver.AddDays($DriverTime.Critical)
                    }
                else
                    {
                        [Datetime]$ReleaseDriver = $Driver.ReleaseDate
                        [datetime]$DeployDate = $ReleaseDriver.AddDays($DriverTime.Optional)
                    }


                If ($DeployDate -gt $DateCurrent)
                    {
                        $Driver
                    }
                else 
                    {

                    }
            }         

    }

# Collect list of existing Drivers on Driver Ignorelist from the registry
function get-DCU-Ignorelist 
    {

	Get-ItemPropertyValue -Path $IgnoreListPath -Name $IgnoreListValue |ConvertFrom-Json

    }

# Get Update Ring information form the Excel File
function get-UpdateRing 
    {
    param 
        (
            [string]$DeviceName
        )
    
    $ExcelData = New-Object -ComObject Excel.Application
    $ReadFile = $ExcelData.workbooks.open($UpdateRing,0,$true)
    ($ReadFile.ActiveSheet.UsedRange.Rows | Where-Object {$_.Columns["A"].Value2 -eq $DeviceName}).Value2

    }

# Generate final list of all not allowed driver for a DCU Deployment
function Get-FinalBlockingList
    {
    
        param 
        (

        )


    
        foreach ($Black in $BlacklistDriver)
            {
                
                $TimerList

                If($TimerList.DriverID -notcontains $Black.DriverID)
                    {

                        $Black
                        
                    }

            }

    }

# Generate new registry value for Ignorelist
function Get-RegistryValue 
    {
    
        
        
        foreach ($Block in $FinalBlockingList)
            {

                $TempArray = New-Object -TypeName psobject

                $TempArray | Add-Member NoteProperty -Name AttemptsCompleted -Value 1
                $TempArray | Add-Member NoteProperty -Name Id -Value $Block.DriverID
                $TempArray | Add-Member NoteProperty -Name IsSuccessful -Value $true
                $TempArray | Add-Member NoteProperty -Name ReturnCode -Value 0
                $TempArray | Add-Member NoteProperty -Name Timer -Value $DateCurrent

                $TempArray

            }
        


    }

################################################################
###  Program Section                                         ###
################################################################

#### Check if DCU is installed if not the script will end

if (Get-DCU-Installed - eq $true) 
    {
        # Assessment get latest Ignorelist from the registry
        [Array]$IgnoreListCurrent = get-DCU-Ignorelist

        # cleanup registry value before start DCU scan to get all drivers who need updated
        Set-ItemProperty -path $IgnoreListPath -Name $IgnoreListValue -Value "" -Force

        ## Service need to restart to read the new registry value
        restart-Service -Name DellClientManagementService -Force
        
        # Assessment drivers get all missing drivers for this device
        $DriverAllMissing = Get-MissingDriver
        
        # get information of Update-Ring for this device from a central stored excel sheet
        [Array]$RingUpdate = get-UpdateRing -DeviceName $Device

        # get drivers who are match to the Blacklisted driver matchcode in $Blacklist
        [Array]$BlacklistDriver = remove-DCU-BlacklistDriver
        
        # get a list of drivers who are missing on the device but based on update ring the drivers are newer than update policy allows
        [Array]$TimerList = Get-DCU-TimeFilter -DriverRing $RingUpdate[1]
        
        # Merge the lists filter by update timer and blacklist match code to one list.
        [Array]$FinalBlockingList = Get-FinalBlockingList
        
        # prepare JSON value for new and old ignore list
        [Array]$RegValue = Get-RegistryValue
        $RegValueJSON = $RegValue | ConvertTo-Json -Compress
        $IgnoreListCurrentJSON = $IgnoreListCurrent | ConvertTo-Json -Compress

        # Set blocking list to registry
        Set-ItemProperty -path $IgnoreListPath -Name $IgnoreListValue -Value $RegValueJSON -Force

        # Log results of old Registry Value and New Registry Value
        # Generate LogName and Source
        New-EventLog -LogName 'Dell' -Source 'DCUOldList' -ErrorAction Ignore
        New-EventLog -LogName 'Dell' -Source 'DCUBlocklist' -ErrorAction Ignore
        New-EventLog -LogName 'Dell' -Source 'DCUBlocklistScriptResult' -ErrorAction Ignore

        # writting blocklists (Old/New) to Microsoft Event if value not empty
        If($null -ne $IgnoreListCurrentJSON)
            {
                # Save value of old registry entry to Microsoft Event
                Write-EventLog -LogName Dell -Source DCUOldList -EntryType Information -EventId 0 -Message $IgnoreListCurrentJSON -ErrorAction SilentlyContinue
            }
       
        If ($null -ne $RegValueJSON)
            {
                # Save value of new registry entry to Microsoft Event
                Write-EventLog -LogName Dell -Source DCUBlocklist -EntryType Information -EventId 0 -Message $RegValueJSON -ErrorAction SilentlyContinue
            }
        
        # Write success to event log registry is set new
        Write-EventLog -LogName Dell -Source DCUBlocklistScriptResult -EntryType SuccessAudit -EventId 0 -Message "Script was run and set new registry value to this machine" -ErrorAction SilentlyContinue
        
        ## Service need to restart to read the new registry value
        restart-Service -Name DellClientManagementService -Force

        # Close script
        exit 0
        
    }
else 
    {
        # Write failure to event log because DCU is not installed on this machine
        Write-EventLog -LogName Dell -Source DCUBlocklistScriptResult -EntryType Error -EventId 2 -Message "DCU Blocklist Script could not run because no DCU is installed on this machine" -ErrorAction SilentlyContinue
        
        # Close script if no DCU is installed on a machine
        Exit 2

    }