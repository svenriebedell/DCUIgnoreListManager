# Dell Command | Update - Ignore List Manager

Lastes Version 1.1.2  (3/24/2023)

### Changelog:
- 1.0.1 First public version
- 1.0.2 updating function get-missingdriver (using now XML for datas)
- 1.1.0 migrating policy assignment form excel sheet to ADMX Policy file
- 1.1.1 correction failure if Registry of IgnoreList is failing
        correction failure if Registry of Policy is not availiable (Path)
- 1.1.2 correction of missing Values in InstalledUpateJSON Registry.

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
There is a possibility to set up to 8 different update rings (Ring0 to Ring7) for the drivers. Each of these rings can be defined in three severity levels to ensure that urgent updates are handled differently than optional updates. The time you will find in this pictures are examples you need to change to your company requirements.

<img width="677" alt="2023-01-03_15-47-18" src="https://user-images.githubusercontent.com/99394991/210381056-6afc5d12-dfe9-4414-acd2-fc217f9fc797.png">


### Block driver based on name
There are cases where it is not possible to filter out certain drivers by Type, Category and Severity alone. However, these should never be installed, e.g., certain applications or certain drivers. Here there is the possibility to filter these via match codes from the open updates so that they are not installed. Please **test/check** the match code carefully in advance, so that it does not affect the required/desired drivers later. 

<img width="603" alt="2023-01-03_15-51-55" src="https://user-images.githubusercontent.com/99394991/210381965-5383f350-8ab5-40e5-8941-289d0a6eb3ef.png">

### Working with the ADMX Policy file
The idea is to solve the management of the update rings via Intune configuration profiles. Since December 2022 Intune supports the import of 3rd party ADMX templates (Preview). Since ADMX is already used for many years for the configuration of devices, we adopt this technology in Intune. This allows us to assign update rings directly from Intune per groups to users or devices.

### Import ADMX
Before you can get started, you need to download the ADMX and then import it into Intune. Then you can use the ADMX to set a configuration profile on the device.
![image](https://user-images.githubusercontent.com/99394991/224032390-26ee31c3-1256-4615-9eb6-853b2860eae9.png)


**ADMX is part of this repository**
![image](https://user-images.githubusercontent.com/99394991/224032155-f8991b15-3b46-4e08-a3ef-eab561ba5e04.png)


### Start with the configuartion Profile
The configuration profile in Intune allows to set or change settings on the device. To be able to do this, a new profile must be created and the option "Imported Administrative Templates" must be selected.


#### select Imported Administrative Templates

![image](https://user-images.githubusercontent.com/99394991/224032508-37397b2b-4615-4245-8c12-9b4d6327e926.png)


#### Prepare the policy

![image](https://user-images.githubusercontent.com/99394991/224032578-a549befb-4fe5-46f5-b170-1bba8fd520f5.png)
![image](https://user-images.githubusercontent.com/99394991/224032625-40d899df-95ec-4358-8af5-ac7829784fe0.png)
![image](https://user-images.githubusercontent.com/99394991/224032663-d997434c-7160-4fc6-b6b0-9b7b79c14f36.png)
![image](https://user-images.githubusercontent.com/99394991/224033108-1f725727-9ffb-44a1-82e6-e19b1127815e.png)



#### Assign Configuration Policy to a AAD Group

![image](https://user-images.githubusercontent.com/99394991/224032785-172e763f-d788-4b21-9695-7e26cbfe7a48.png)


## Execution of script
To ensure that the blocked drivers are also entered on the ignore list, the script must always be run before the update with Dell Command | Update. Otherwise, drivers may be installed on the device before the update policy. 

The script can be started manually, or it is recommended to start it using tools with scheduler or other solutions. 

### How it looks before the script has run

<img width="744" alt="MicrosoftTeams-image" src="https://user-images.githubusercontent.com/99394991/210391817-d0508a2f-d7f9-4b45-90a5-6b1d60e9791b.png">


### Running the script to maintain the Ignore List

<img width="557" alt="MicrosoftTeams-image (1)" src="https://user-images.githubusercontent.com/99394991/210391881-7186ee9e-ed35-4ef8-a870-c32e433714b9.png">


### Dell Command | Update scan after the script runs.

<img width="747" alt="MicrosoftTeams-image (2)" src="https://user-images.githubusercontent.com/99394991/210391911-93feb0db-4645-4645-82f2-eba0098a2630.png">



## Logging
The script saves the old and the new blocklist as an event in the Microsoft Event Viewer. This makes it easy to check changes or troubleshoot why certain updates did not run on the device.

### Backup of the existing registry value

<img width="716" alt="Screenshot 2022-12-22 151518" src="https://user-images.githubusercontent.com/99394991/209154057-5a4492ee-7282-4f77-88e1-4134ef094980.png">

### New registry value set on machine

<img width="708" alt="Screenshot 2022-12-22 151550" src="https://user-images.githubusercontent.com/99394991/209154066-4e167fa6-5d0d-41ce-8ec5-01531338d35f.png">

### Run success of the script

<img width="721" alt="Screenshot 2022-12-22 151608" src="https://user-images.githubusercontent.com/99394991/209154072-9f18707d-3c6e-40bd-92d9-4eb62e784cab.png">



## Next steps

In the next step I will integrate this information into my Dell Command | Update Dashboard for Log Analytics. You can find this project here.

https://github.com/svenriebedell/LogAnalytics
