
################################################################
###  Variables                                               ###
################################################################

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

$Blacklist = @(
    [PSCustomObject]@{MatchCode="Dell*Update*"; Listed="15/12/2022"}
    [PSCustomObject]@{MatchCode="Dell*Monitor*"; Listed="19/12/2022"}
)

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
function get-DCU-Ignorelist 
    {

	Get-ItemPropertyValue -Path $IgnoreListPath -Name $IgnoreListValue |ConvertFrom-Json

    }

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

function Get-RegistryValue 
    {
    
        
        
        foreach ($Block in $FinalBlockingList)
            {

                $TempArray = New-Object -TypeName psobject

                $TempArray | Add-Member NoteProperty -Name AttemptsCompleted -Value 1
                $TempArray | Add-Member NoteProperty -Name Id -Value $Block.DriverID
                $TempArray | Add-Member NoteProperty -Name IsSuccessful -Value $false
                $TempArray | Add-Member NoteProperty -Name ReturnCode -Value 1
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
        $DriverAllMissing = Get-MissingDriver
        [Array]$IgnoreListCurrent = get-DCU-Ignorelist
        [Array]$BlacklistDriver = remove-DCU-BlacklistDriver
        [Array]$RingUpdate = get-UpdateRing -DeviceName $Device
        [Array]$TimerList = Get-DCU-TimeFilter -DriverRing $RingUpdate[1]
        [Array]$FinalBlockingList = Get-FinalBlockingList
        [Array]$RegValue = Get-RegistryValue
        $RegValueJSON = $RegValue | ConvertTo-Json -Compress

        # Set blocking list to registry
        Set-ItemProperty -path $IgnoreListPath -Name $IgnoreListValue -Value $RegValueJSON -Force

        ## Service need to restart to read the new registry value
        Restart-Service -Name DellClientManagementService -Force
        
    }
else 
    {
    
        Exit 2

    }