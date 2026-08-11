![MSAD](https://img.shields.io/badge/Active_Directory_Domain_Services-blue) ![PowerShell](https://img.shields.io/badge/Powershell-5391FE?style=flat&logo=powershell&logoColor=white) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-green)](https://www.gnu.org/licenses/gpl-3.0)

# Active Directory DSHeuristics Flags Editor.
This repository contains a PowerShell script which provides a GUI to read/write the dsHeuristics attribute which controls various features of the Domain Service functionality.

## References
Microsoft has described all the dsHeuristic flags in the Open Specifications document **MS-ADTS Active Directory Technical Specification**, you can find the list in the following section [6.1.1.2.4.1.2 dSHeuristics](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/e5899be4-862e-496f-9a38-33950617d2c5).



## Motivation
Das editieren einer zeichenkette die aus maximal 31 nullen oder anderen werten besteht wie z.B. 00100000010000000001000000000111 ist doch sehr fehleranfällig, dazu komt das es sehr unübersichtlich ist, man meistens die namen der flags und die erlaubten werte sowieso nicht auswendig weiß und man darauf achten muss das die control flags an den richtigen stellen gesetzt sind. Um also die aufgabe etwas zu erleichtern hat der autor diese GUI erstellt
die alle Flags mit namen, beschreibung und den erlaubten werten anzeigt.

Link zu Microft docu

MS-ADTS Active Directory Technical Specification
Berechtigung haben: Domain Admins, Enterprise Admins

.\SetDsHeuristic.ps1 -Decode '0210000'
Old dsHeuristic Attribute: 0210000
New dsHeuristic Attribute: 001

## Installation and Use
No installation needed, download both .ps1 files to a directory and run the SetDsHeuristic.ps1 script.

## Description


<img style="display: block; margin: 0 auto" width="408" height="482" alt="DynamicGroup_Example" src="https://github.com/user-attachments/assets/75bdef34-27b3-4b79-93eb-9a06d14fcc2c" />




## Contributing
All PowerShell developers or Active Directory experts are very welcome to help and make the code better, more readable or contribute new ideas. 

## License
This project is licensed under the terms of the GPL V3 license. Please see the included LICENCE file gor more details.

## Release History

### Version 0.1.0 (2026/08/10)
First release, testing has been done but bugs may still exist.

