<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0.2
_Dev_Status_ = Develop
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
1.0.2   reworked function get-missingdrivers move from snipping text to use an temporary xml file.

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

# Defintion of your Update Rings based on Severity Level. Numbers are days.
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
$Matchcodelist = @(
    [PSCustomObject]@{MatchCode="Dell*Update*"; Listed="15/12/2022"}
    [PSCustomObject]@{MatchCode="Dell*Configure*"; Listed="19/12/2022"}
)

# You need to define the location of you Excel Sheet where the script could be find the assignments of Device-Name to Update-Ring
$UpdateRing = 'https:/File//"Your File Location"/DellDeviceConfiguration.xlsx'  # need to be change to your file location

# Temp folder used for some processes all files will be deleted later
$Temp_Folder = "C:\Temp\"

## Do not change ##
$DCUProgramName = ".\dcu-cli.exe"
$DCUPath = (Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%Command%Update%'").InstallLocation
$IgnoreListPath = "HKLM:\SOFTWARE\DELL\UpdateService\Service\IgnoreList"
$IgnoreListValue = "InstalledUpdateJson"
$DriverAllMissing = New-Object -TypeName psobject
$DateCurrent = Get-Date
$Device = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Name



################################################################
###  Functions Section                                       ###
################################################################

# Function using DCU to identify missings Updates
Function Get-MissingDriver
    {

        # Test if Temp Path is existing if not generate this Path
        $check_Temp_Folder = Test-Path -Path $Temp_Folder

        if ($check_Temp_Folder -ne $true) 
            {
                New-Item -Path $Temp_Folder -ItemType Directory
            }

        Set-Location -Path $DCUPath
        # DCU scan only generate a XML report with missing drivers
        Start-Process -FilePath $DCUProgramName -ArgumentList "/scan -report=$Temp_Folder" -Wait -WindowStyle Hidden

        # Get Catalog file name of Scan Report
        $ReportFileName = Get-ChildItem $Temp_Folder | Where-Object Name -Like "DCUApp*Update*xml" | Select-Object -ExpandProperty Name

        # read XML File in a variable
        [XML]$MissingDriver = Get-Content $Temp_Folder$ReportFileName

        $DriverArrayXML = $MissingDriver.updates.update

        foreach ($Driver in $DriverArrayXML) 
            {
                        
            # build a temporary array
            $DriverArrayTemp = New-Object -TypeName psobject
            $DriverArrayTemp | Add-Member -MemberType NoteProperty -Name 'DriverID' -Value $Driver.Release
            $DriverArrayTemp | Add-Member -MemberType NoteProperty -Name 'Name' -Value $Driver.name
            $DriverArrayTemp | Add-Member -MemberType NoteProperty -Name 'Severity' -Value $Driver.urgency
            $DriverArrayTemp | Add-Member -MemberType NoteProperty -Name 'Category' -Value $Driver.Category
            $DriverArrayTemp | Add-Member -MemberType NoteProperty -Name 'ReleaseDate' -Value $Driver.Date
            
            $DriverArrayTemp

            }
       
        #Delete temporary report file of dcu from temp folder
        Remove-Item -Path $Temp_Folder$ReportFileName -Force

        # Set folder to root
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

# Select Driver based on DCU Scan where ignore Matchcode do not allow an update by DCU in general
function remove-DCU-MatchcodelistDriver 
    {

        ForEach ($match in $Matchcodelist)
            {

                $DriverAllMissing | Where-Object Name -like $Match.matchcode

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
                        [Datetime]$DeployDate = $ReleaseDriver.AddDays($DriverTime.Recommended)
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
    
        # Move time blocked driver to final blocking list
        $TimerList

        # add driver blocked by match code to blocking list if they are not incl as well in time blocked list.
        foreach ($Match in $MatchcodelistDriver)
            {
                             
                If($TimerList.DriverID -notcontains $Match.DriverID)
                    {

                        $Match
                        
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

        # get drivers who are match to the match code listed driver in $Matchcodelist
        [Array]$MatchcodelistDriver = remove-DCU-MatchcodelistDriver
        
        # get a list of drivers who are missing on the device but based on update ring the drivers are newer than update policy allows
        [Array]$TimerList = Get-DCU-TimeFilter -DriverRing $RingUpdate[1]
        
        # Merge the lists filter by update timer and matchcodelist match code to one list.
        [Array]$FinalBlockingList = Get-FinalBlockingList
        
        # prepare JSON value for new and old ignore list
        [Array]$RegValue = Get-RegistryValue
        $RegValueJSON = $RegValue | ConvertTo-Json -Compress
        $IgnoreListCurrentJSON = $IgnoreListCurrent | ConvertTo-Json -Compress

        # Set blocking list to registry
        Set-ItemProperty -path $IgnoreListPath -Name $IgnoreListValue -Value $RegValueJSON -Force

        # Log results of old Registry Value and New Registry Value
        # Generate LogName and Source
        New-EventLog -LogName 'Dell' -Source 'DCURegValue' -ErrorAction Ignore
        New-EventLog -LogName 'Dell' -Source 'DCUBlocklist' -ErrorAction Ignore
        New-EventLog -LogName 'Dell' -Source 'DCUBlocklistScriptResult' -ErrorAction Ignore

        # writting blocklists (Old/New) to Microsoft Event if value not empty
        If($null -ne $IgnoreListCurrentJSON)
            {
                # Save value of old registry entry to Microsoft Event
                Write-EventLog -LogName Dell -Source DCURegValue -EntryType Information -EventId 0 -Message $IgnoreListCurrentJSON -ErrorAction SilentlyContinue
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