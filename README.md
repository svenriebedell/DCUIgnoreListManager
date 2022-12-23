# Dell Command | Update - Ignorelist Manager

### Changelog:
- 1.0.1  First public version

## Description
Dell Command | Update allows you to maintaining you device updates automaticlly. You can define severity levels, time of starting updates and filtering on driver category and driver type.
If you want to exclude specifig drivers you can use the Dell Cloud Repository Manager which allows you to managing you own update catalogs. You can define with apporach as whitelisting, only admin approve driver will be deployed by Dell Command | Update.
This concept based on an excel sheet to managing update rings (from 1 to 8) and PowerShell script we give you the approche of a Blacklist concept. Every time if you run this script it filtering drivers by Release Date or Driver Name.
**Important:** This script need to be run each time if Dell update the DCU catalog otherwise it could be not all driver you do not want to deploy are blocked.

### Princip of working
The script starting Dell Command | Update and scan for missing drivers. After the missing drivers are identified it check the Release Date of each driver. 2nd step it check based on the Excel sheet the assign Update Ring for each device and get values for different severity levels, e.g. Ring0 Critical=7days; Recommended=14days; Optional=60days.
Now it add the Ring Value to the release date. If the result is older than today the drivers are allowed to deploy, if the result is newer the driver will be blocked for a while.

##Example:##
Driver A: Release Date 12/21/2022
Ring0 / Severity: Critical 7 days

Result: driver can installed earliest at the 12/28/2022

**Legal disclaimer: THE INFORMATION IN THIS PUBLICATION IS PROVIDED 'AS-IS.' DELL MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY KIND WITH RESPECT TO THE INFORMATION IN THIS PUBLICATION, AND SPECIFICALLY DISCLAIMS IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.** In no event shall Dell Technologies, its affiliates or suppliers, be liable for any damages whatsoever arising from or related to the information contained herein or actions that you decide to take based thereon, including any direct, indirect, incidental, consequential, loss of business profits or special damages, even if Dell Technologies, its affiliates or suppliers have been advised of the possibility of such damages. 

## Configuration option of script

![image](https://user-images.githubusercontent.com/99394991/209308682-49cd61c4-d91d-4718-a4da-71efd3a920ef.png)

![image](https://user-images.githubusercontent.com/99394991/209308935-d82b2876-ee4b-4d8f-89e5-168274f2e5d1.png)


![image](https://user-images.githubusercontent.com/99394991/209308621-c661aa19-dcf8-4771-a2f9-963f1c7acde6.png)

![image](https://user-images.githubusercontent.com/99394991/209309693-f8ac9d34-3677-4d26-90e7-c071797c68a8.png)


## Logging

Logging will store the following informations in Microsoft Event

**Existing Reg-Value**

<img width="716" alt="Screenshot 2022-12-22 151518" src="https://user-images.githubusercontent.com/99394991/209154057-5a4492ee-7282-4f77-88e1-4134ef094980.png">

**Blocked Driver**

<img width="708" alt="Screenshot 2022-12-22 151550" src="https://user-images.githubusercontent.com/99394991/209154066-4e167fa6-5d0d-41ce-8ec5-01531338d35f.png">

**Script runs results**

<img width="721" alt="Screenshot 2022-12-22 151608" src="https://user-images.githubusercontent.com/99394991/209154072-9f18707d-3c6e-40bd-92d9-4eb62e784cab.png">

![Snag_bbb928d](https://user-images.githubusercontent.com/99394991/209169501-37c2838f-0234-4f51-8f17-b8fa938fc732.png)


![Snag_bbb9193](https://user-images.githubusercontent.com/99394991/209169561-4347759d-e476-46e4-b687-f024dd4d749f.png)


![Snag_bbb90c7](https://user-images.githubusercontent.com/99394991/209169591-5c20cc9f-e86e-4e2d-9a32-e412341b31dd.png)

