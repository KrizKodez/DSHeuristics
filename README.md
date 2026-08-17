![MSAD](https://img.shields.io/badge/Active_Directory_Domain_Services-blue) ![PowerShell](https://img.shields.io/badge/Powershell-5391FE?style=flat&logo=powershell&logoColor=white) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-green)](https://www.gnu.org/licenses/gpl-3.0)

# Active Directory DSHeuristics Flags Editor.
This repository contains a PowerShell script which provides a GUI to read/write the dsHeuristics attribute which controls various features of the Domain Service functionality.

## References
Microsoft has described all the dsHeuristic flags in the Open Specifications document **MS-ADTS Active Directory Technical Specification**, you can find the list in the following section [6.1.1.2.4.1.2 dSHeuristics](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/e5899be4-862e-496f-9a38-33950617d2c5).

## Motivation
Editing a string that consists of a maximum of 31 zeros or other values, like 00100000010000000001000000000111, is really confusing and prone to mistakes. On top of that, you usually don’t remember the names of the different flags, their functions and the allowed values by heart, and you also have to make sure that the three control flags are set or not set at the right positions. So, to make the task a bit easier, the author developed this GUI that makes all the flags available with names, descriptions, and allowed values.

## Installation and Use
No installation needed, download both files, the .ps1 and the .lib.ps1 to the same directory and run the SetDsHeuristic.ps1 script. You could use the tool in two different ways. Make the dsHeuristic string available to the tool yourself with the Decode parameter:

````PowerShell
.\SetDsHeuristic.ps1 -Decode '0110000'
````
This approach makes sense if you just want to decode a dsHeuristic value to see which flags are activated or deactivated, but also if you can't or don't want to change the value directly in the Domain Service. The tool returns the old and the new value for comparison or further processing:

````PowerShell
Old dsHeuristic Attribute: 0110000
New dsHeuristic Attribute: 010002000111
````
When starting without parameters, it tries to determine the dsHeuristics attribute directly from the Domain Service, for which a domain account is needed. If the changes should also be written, the account must be a member of the Domain Admins or Enterprise Admins group. In both cases, the tool starts with a welcome panel where a warning notice and a disclaimer can be seen.
<p align="center" width="100%">
<img width="587" height="703" alt="Welcome Screen" src="https://github.com/user-attachments/assets/07101c3c-0f8a-4a44-b110-2059221157c2" />
</p>

By pressing the **Continue** button, you confirm that you have read and understood the warning and switch to the editable section. At the very top is the display of the CURRENT value, which was either passed via the Decode parameter or read from the Domain service, and the UPDATED value, which shows the changes that have been made in the Flags section. In this section you could find all flags with the original name, a short description and the possibility to change it value.
</p>
<p align="center" width="100%">
<img width="580" height="705" alt="Flag Screen" src="https://github.com/user-attachments/assets/177286ff-a40b-4307-a0bc-d037cca39707" />
</p>

The cells of the table are colored depending on whether a value is wrong (red) or if the UPDATED value is different from the CURRENT value.
</p>
<p align="center" width="100%">
<img width="586" height="700" alt="Changes and Errors" src="https://github.com/user-attachments/assets/479a776a-4bed-45b6-9f0f-9c2bb7d52147" />
</p>
To avoid accidental changes to the Domain Service, you need to unlock it with the checkbox "I know what I am doing..." before pressing the Modify button.

## Contributing
All PowerShell developers or Active Directory experts are very welcome to help and make the code better, more readable or contribute new ideas. 

## License
This project is licensed under the terms of the GPL V3 license. Please see the included LICENCE file gor more details.

## Release History

### Version 0.1.0 (2026/08/10)
First release, testing has been done but bugs may still exist.
