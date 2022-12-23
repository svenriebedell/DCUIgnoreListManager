# Dell Command | Update - Ignorelist Manager

### Changelog:
- 1.0.1  First public version

## Description
Dell Command | Update allows you to maintain your device updates automatically. You can define severity levels, time of starting updates and filtering on driver category and driver type.
If you want to exclude specific drivers, you can use the Dell Cloud Repository Manager which allows you to manage your own update catalogs. You can define with approach as whitelisting, only admin approve driver will be deployed by Dell Command | Update. 
This concept is based on an excel sheet to managing update rings (from 1 to 8) and PowerShell script we give you the approach of a Blacklist concept. Every time you run this script it is filtering drivers by Release Date or Driver Name. 

**Important:** This script need to be run each time if Dell update the DCU catalog otherwise it could be not all driver you do not want to deploy are blocked.

### Princip of working
The script starting Dell Command | Update and scan for missing drivers. After the missing drivers are identified it checks the Release Date of each driver. 2nd step it checks based on the Excel sheet the assign Update Ring for each device and get values for different severity levels, e.g., Ring0 Critical=7days; Recommended=14days; Optional=60days. 

Now it adds the Ring Value to the release date. If the result is older than today, the drivers can deploy; if the result is newer, the driver will be blocked for a while. 

##Example:##
Driver A: Release Date 12/21/2022
Ring0 / Severity: Critical 7 days

Result: driver can be installed earliest at the 12/28/2022 

**Legal disclaimer: THE INFORMATION IN THIS PUBLICATION IS PROVIDED 'AS-IS.' DELL MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY KIND WITH RESPECT TO THE INFORMATION IN THIS PUBLICATION, AND SPECIFICALLY DISCLAIMS IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.** In no event shall Dell Technologies, its affiliates or suppliers, be liable for any damages whatsoever arising from or related to the information contained herein or actions that you decide to take based thereon, including any direct, indirect, incidental, consequential, loss of business profits or special damages, even if Dell Technologies, its affiliates or suppliers have been advised of the possibility of such damages. 

## Configuration option of script

### Ring definition
You can choose up to 8 different settings (Ring0 to Ring7). Each fo this update ring allows to have 3 different update times based on severity levels. If you need less update rings you can ignore this in the assignment file or delete the values here.

![image](https://user-images.githubusercontent.com/99394991/209308682-49cd61c4-d91d-4718-a4da-71efd3a920ef.png)

### Block driver based on name
In case you want to exclude some drivers/applications in general you have an option to blacklist these installers. Please choose a match code which only affected the required driver/application, or it could impact other drivers. 

![image](https://user-images.githubusercontent.com/99394991/209308935-d82b2876-ee4b-4d8f-89e5-168274f2e5d1.png)

### Path of Assignment file
The assignment of a device to update ring will be managed by an excle sheet file. In my environment I am using a Azure Blob Storge but it could be as well File-Server, Onedrive, etc. only requirment the file need to be accessable for the script.

![image](https://user-images.githubusercontent.com/99394991/209308621-c661aa19-dcf8-4771-a2f9-963f1c7acde6.png)

### Assignment file
The assignment of a device to update ring will be managed by an excel sheet file. In my environment I am using a Azure Blob Storge but it could be as well Fileserver, OneDrive, etc. only requirement the file need to be accessible for the script. 

![image](https://user-images.githubusercontent.com/99394991/209309693-f8ac9d34-3677-4d26-90e7-c071797c68a8.png)

## Execution of script
The script needs to run before a Dell Command | Update will be run otherwise the list is not maintained. The catalog will be updated in 14 days by dell so 1 time per week or 1 time every two weeks is enough. You can run it daily, but it is not needed. 

The script can be used manually (Administrator rights needed) but an automation is recommended by Time scheduler or Software Management solution 


## Logging
Logging will store the following information's in Microsoft Event 

**Existing Reg-Value**

<img width="716" alt="Screenshot 2022-12-22 151518" src="https://user-images.githubusercontent.com/99394991/209154057-5a4492ee-7282-4f77-88e1-4134ef094980.png">

**Blocked Driver**

<img width="708" alt="Screenshot 2022-12-22 151550" src="https://user-images.githubusercontent.com/99394991/209154066-4e167fa6-5d0d-41ce-8ec5-01531338d35f.png">

**Script runs results**

<img width="721" alt="Screenshot 2022-12-22 151608" src="https://user-images.githubusercontent.com/99394991/209154072-9f18707d-3c6e-40bd-92d9-4eb62e784cab.png">

### Backup of the existing registry value

![Snag_bbb928d](https://user-images.githubusercontent.com/99394991/209169501-37c2838f-0234-4f51-8f17-b8fa938fc732.png)

### New registry value set on machine

![Snag_bbb9193](https://user-images.githubusercontent.com/99394991/209169561-4347759d-e476-46e4-b687-f024dd4d749f.png)

### Run success of the script

![Snag_bbb90c7](https://user-images.githubusercontent.com/99394991/209169591-5c20cc9f-e86e-4e2d-9a32-e412341b31dd.png)


In the next step I will integrate this information into my Dell Command | Update Dashboard for Log Analytics. You can find this project here.

https://github.com/svenriebedell/LogAnalytics