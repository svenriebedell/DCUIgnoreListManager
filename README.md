# Dell Command | Update - Ignore List Manager

### Changelog:
- 1.0.1 First public version

## Introduction
This experimental project aims to add Ring Deployment capabilities to Dell Command Update (DCU), by using an Ignore List Manager script.  

In a nutshell this solution scans for available updates and uses the information provided to read out the release date of the updates. Based on the release date and your ring deployment policy settings (Severity level & Days) it will assign the updates to a specific update ring. DCU will only process the updates that match a certain update ring.

**Example:**
Driver A: Release Date 12/21/2022
Ring0 / Severity: Critical 7 days

Result: driver can be installed earliest at the 12/28/2022 

## Description
Dell Command | Update allows you to update your devices automatically. The update can be controlled by filters like category of the driver e.g., audio or chipset, etc. or type of the update like BIOS (Basic Input Output System) or hardware driver. Furthermore, the severity of a filter can be selected, e.g., Recommended or Critical.

However, if you only want to have a certain driver not installed, this is possible by creating your own driver catalog with the **Dell Custom Update Catalog**, where you can select everything as you want it and then use this catalog for the updates. For administrators who do not want to create their own catalogs, the above options remain to filter drivers before the update.

One of the biggest challenges today is to patch hardware and software in a way that does not affect the stability of the device. That is why many customers today try a so-called ring deployment of updates. Due to the considerable number  of different installations and devices, however, this is a problem to control in management.

This experimental project tries to realize this by means of Dell Command | Update.
Dell Command | Update already offers a variety of control options for update filtering, update frequency, BIOS authentication, etc.

What is currently not yet available is to install drivers that are available according to the update catalog for a device only at a certain point in time. You can create groups via different configuration settings to realize a test group, but then everything is always installed in these groups unless it is filtered, or you work with custom catalogs. This project tries to map a concept in the form of rings and severity levels so that all devices have the same update policy but in advance it is determined which drivers should not be installed during an update although an update is available.
This allows to define up to 8 different update rings which in turn have 3 different severity levels, so that you can define different update delays for Critical, Recommended and Optional drivers.

The script uses the features provided by Dell Command | Update out of the box. It uses the update scan to identify missing drivers on a device. Then it uses the device update catalog to see when the driver was released. A policy file is used to determine what the update ring policy is for this device. If the driver is allowed to be installed by policy, nothing happens and the Dell Command | Update will update this driver/firmware when starting the update process. If the policy does not allow an update, then this driver is taken on the Ignore list of the Dell Command | Update and this is ignored during the update.

The function is currently external only via this script i.e. to update the Ignore List for drivers this script must be started at regular intervals at least before each update by gangs with Dell Command | Update so that no unwanted drivers are installed or once blocked drivers that are now allowed by policy to be installed by the next Dell Command | Update process are updated.

**Important:** It must be ensured that this script is always started on the device before a Dell Command | Update. Otherwise, unscheduled updates may be performed on the device. The Dell Update Catalog is currently updated weekly, so the script should also run at least once a week.

## Legal disclaimer:
 **THE INFORMATION IN THIS PUBLICATION IS PROVIDED 'AS-IS.' DELL MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY KIND WITH RESPECT TO THE INFORMATION IN THIS PUBLICATION, AND SPECIFICALLY DISCLAIMS IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.** In no event shall Dell Technologies, its affiliates or suppliers, be liable for any damages whatsoever arising from or related to the information contained herein or actions that you decide to take based thereon, including any direct, indirect, incidental, consequential, loss of business profits or special damages, even if Dell Technologies, its affiliates or suppliers have been advised of the possibility of such damages. 


## Configuration option of script
You can make some adjustments in the script to adapt it to your needs.

### Ring definition
There is a possibility to set up to 8 different update rings (Ring0 to Ring7) for the drivers. Each of these rings can be defined in three severity levels to ensure that urgent updates are handled differently than optional updates.

![image](https://user-images.githubusercontent.com/99394991/209308682-49cd61c4-d91d-4718-a4da-71efd3a920ef.png)

### Block driver based on name
There are cases where it is not possible to filter out certain drivers by Type, Category and Severity alone. However, these should never be installed, e.g., certain applications or certain drivers. Here there is the possibility to filter these via match codes from the open updates so that they are not installed. Please **test/check** the match code carefully in advance, so that it does not affect the required/desired drivers later. 

![image](https://user-images.githubusercontent.com/99394991/209308935-d82b2876-ee4b-4d8f-89e5-168274f2e5d1.png)

### Path of Assignment file
For control we use an Excel sheet which is stored centrally in the cloud or on-premises. This Excel sheet defines which device belongs to which update ring. This sheet must be accessible via VPN (Virtual Private Network), network or Internet from the devices.
You should set the path where the file **DellDeviceConfiguration.xlsx** will be saved. For my environment I use Azure storage for this, but you can also use File Shares or e.g., OneDrive's, etc. here. The only important thing is that the device has access to the file.

![image](https://user-images.githubusercontent.com/99394991/209308621-c661aa19-dcf8-4771-a2f9-963f1c7acde6.png)

### Assignment file
In the file DellDeviceConfiguration.xlsx the assignment of the device name to the update ring is defined. The file must contain the required device names, otherwise the device has no assignment. 

**Note:** in a later version there will be a default setting if the device name is not found.

![image](https://user-images.githubusercontent.com/99394991/209309693-f8ac9d34-3677-4d26-90e7-c071797c68a8.png)
![image](https://user-images.githubusercontent.com/99394991/209318844-6055c0c8-90df-4bf5-9139-5f0ab8c760db.png)


## Execution of script
To ensure that the blocked drivers are also entered on the ignore list, the script must always be run before the update with Dell Command | Update. Otherwise, drivers may be installed on the device before the update policy. 

The script can be started manually, or it is recommended to start it using tools with scheduler or other solutions. 

### How it looks before the script has run

![Snag_bbb928d](https://user-images.githubusercontent.com/99394991/209169501-37c2838f-0234-4f51-8f17-b8fa938fc732.png)

### Running the script to maintain the Ignore List

![Snag_bbb9193](https://user-images.githubusercontent.com/99394991/209169561-4347759d-e476-46e4-b687-f024dd4d749f.png)

### Dell Command | Update scan after the script runs.

![Snag_bbb90c7](https://user-images.githubusercontent.com/99394991/209169591-5c20cc9f-e86e-4e2d-9a32-e412341b31dd.png)




## Logging
The script saves the old and the new blocklist as an event in the Microsoft Event. This makes it easy to check changes or troubleshoot why certain updates did not run on the device.

### Backup of the existing registry value

<img width="716" alt="Screenshot 2022-12-22 151518" src="https://user-images.githubusercontent.com/99394991/209154057-5a4492ee-7282-4f77-88e1-4134ef094980.png">

### New registry value set on machine

<img width="708" alt="Screenshot 2022-12-22 151550" src="https://user-images.githubusercontent.com/99394991/209154066-4e167fa6-5d0d-41ce-8ec5-01531338d35f.png">

### Run success of the script

<img width="721" alt="Screenshot 2022-12-22 151608" src="https://user-images.githubusercontent.com/99394991/209154072-9f18707d-3c6e-40bd-92d9-4eb62e784cab.png">



## Next steps

In the next step I will integrate this information into my Dell Command | Update Dashboard for Log Analytics. You can find this project here.

https://github.com/svenriebedell/LogAnalytics