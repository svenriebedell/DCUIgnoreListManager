# Dell Command | Update - Ignorelist Manager

### Changelog:
- 1.0.1  First public version

## Description
Dell Command | Update allows you to update your devices automatically. The update can be controlled by filters like category of the driver e.g. audio or chipset, etc. or type of the update like BIOS or hardware driver. Furthermore, the severity of a filter can be selected, e.g. Recommended or Critical. 
However, if you only want to have a certain driver not installed, this is possible by creating your own driver catalog with the Dell Custom Update Catalog, where you can select everything as you want it and then use this catalog for the updates.For administrators who do not want to create their own catalogs, the above options remain to filter drivers before the update. 
This experimental project tries to extend the function of the filter. There is the possibility to use so-called update rings for different update groups. Background is an update ring defines how long a driver must be released to be distributed. So we have here the filtering on driver age.
For control we use an Excel sheet which is stored centrally in the cloud or on-premise. This Excel sheet defines which device belongs to which update ring. This sheet must be accessible via VPN, network or Internet from the devices. We support up to 8 different update rings here.

**Important:** It must be ensured that this script is always started on the device before a Dell Command | Update. Otherwise, unscheduled updates may be performed on the device. The Dell Update Catalog is currently updated weekly, so the script should also run at least once a week.

### Princip of working
The script uses the scan function of the Dell Command | Update to identify missing drivers. The missing drivers are then filtered by update rings and a general block list. The remaining drivers can then be updated on the devices via Dell Command | Update. The others are temporarily stored on an IgnoreList and are ignored in the distribution. To set the correct update ring for the device, the script reads the information in the central Excel sheet and get values for different severity levels, e.g., Ring0 Critical=7days; Recommended=14days; Optional=60days. 


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
In case you want to exclude some drivers/applications in general you have an option to irgnore these installers. Please choose a match code which only affected the required driver/application, or it could impact other drivers. 

![image](https://user-images.githubusercontent.com/99394991/209308935-d82b2876-ee4b-4d8f-89e5-168274f2e5d1.png)

### Path of Assignment file
The assignment of a device to update ring will be managed by an excle sheet file. In my environment I am using a Azure Blob Storge but it could be as well File-Server, Onedrive, etc. only requirment the file need to be accessable for the script.

![image](https://user-images.githubusercontent.com/99394991/209308621-c661aa19-dcf8-4771-a2f9-963f1c7acde6.png)

### Assignment file
The assignment of a device to update ring will be managed by an excel sheet file. In my environment I am using a Azure Blob Storge but it could be as well Fileserver, OneDrive, etc. only requirement the file need to be accessible for the script. 

![image](https://user-images.githubusercontent.com/99394991/209309693-f8ac9d34-3677-4d26-90e7-c071797c68a8.png)
![image](https://user-images.githubusercontent.com/99394991/209318844-6055c0c8-90df-4bf5-9139-5f0ab8c760db.png)


## Execution of script
The script needs to run before a Dell Command | Update will be run otherwise the list is not maintained. The catalog will be updated in 14 days by dell so 1 time per week or 1 time every two weeks is enough. You can run it daily, but it is not needed. 

The script can be used manually (Administrator rights needed) but an automation is recommended by Time scheduler or Software Management solution 

### How it looks before the script has run

![Snag_bbb928d](https://user-images.githubusercontent.com/99394991/209169501-37c2838f-0234-4f51-8f17-b8fa938fc732.png)

### Running the script to maintain the Irgnore List

![Snag_bbb9193](https://user-images.githubusercontent.com/99394991/209169561-4347759d-e476-46e4-b687-f024dd4d749f.png)

### Dell Command | Update scan after the script runs.

![Snag_bbb90c7](https://user-images.githubusercontent.com/99394991/209169591-5c20cc9f-e86e-4e2d-9a32-e412341b31dd.png)




## Logging
Logging will store the following information's in Microsoft Event 

### Backup of the existing registry value

<img width="716" alt="Screenshot 2022-12-22 151518" src="https://user-images.githubusercontent.com/99394991/209154057-5a4492ee-7282-4f77-88e1-4134ef094980.png">

### New registry value set on machine

<img width="708" alt="Screenshot 2022-12-22 151550" src="https://user-images.githubusercontent.com/99394991/209154066-4e167fa6-5d0d-41ce-8ec5-01531338d35f.png">

### Run success of the script

<img width="721" alt="Screenshot 2022-12-22 151608" src="https://user-images.githubusercontent.com/99394991/209154072-9f18707d-3c6e-40bd-92d9-4eb62e784cab.png">



## Next steps

In the next step I will integrate this information into my Dell Command | Update Dashboard for Log Analytics. You can find this project here.

https://github.com/svenriebedell/LogAnalytics
