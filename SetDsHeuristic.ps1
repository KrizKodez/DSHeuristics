<#PSScriptInfo

.TYPE Controller

.VERSION 0.1.0

.TEMPLATEVERSION 1

.PLATFORM 5.1

.GUID 76204E42-A4E9-47AC-9A79-B4F52B475536

.AUTHOR Christoph Rust

.COMPANYNAME KrizKodez

.TAGS
    Active Directory
    dsHeuristic
    Heuristic

.EXTERNALMODULEDEPENDENCIES
    ActiveDirectory, Microsoft

.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES

.REQUIREDBINARIES

.DESCRIPTION
    The script provides a GUI to comfortably manipulate all Active Directory dsHeuristics flags.

.RELEASENOTES
    {<YYYY-MM-DD>,<SemVersion>,<AuthorID>,<ChangeDescription>}

#>

<#
.SYNOPSIS
    Set Active Directory dsHeuristics value.

.DESCRIPTION
    The script provides a GUI to comfortably manipulate all Active Directory dsHeuristics flags.

.INPUTS
    None
    [You cannot pipe input to this function.]

.OUTPUTS
    None
    
.NOTES
    With the -Decode parameter a 

.LINK
    https://github.com/activedirectory_dsheuristic_tool

.PARAMETER Decode
    A dsHeuristics flags string to be decoded.
#>

# PARAMETERS
[CmdletBinding()]
param
(
    [ValidateLength(0,31)]    
    [string]$Decode
)

# PREREQUISITES
Add-Type -AssemblyName PresentationFramework -ErrorAction Stop

# INCLUDE LIBRARIES
    # PRIVATE
    . "$PSScriptRoot\SetDsHeuristic.lib.ps1"

    # PUBLIC
    # NA

# PARAMETER CHECK
# NA

# DECLARATIONS AND DEFINITIONS
    # ARGUMENTS
    # NA

    # CONSTANTS
    New-Variable -Name AD_RELPATH_DIRECTORY_SERVICE -Value 'CN=Directory Service,CN=Windows NT,CN=Services' -Option Constant -WhatIf:$false

    # VARIABLES
    $ControllerVersion   = GetVersion
    $ReplaceOfFlag       = $null       # Hashtable of all incorrect flags and their replacement values.
    $CurrentHeuristic    = $null       # The current value of the dsHeuristics attribute.
    $UpdatedHeuristic    = $null       # The modificated value of the dsHeuristics attribute.
    
    
# CONTROLLER MAIN CODE

#We use the manuallly submitted dsHeuristics value or read it from the Domain Service.
if ($Decode) { $CurrentHeuristic = $Decode }
else
{
    Import-Module -Name ActiveDirectory -ErrorAction Stop
    $ConfigurationNC  = (Get-ADRootDSE).configurationNamingContext
    $DirectoryService = Get-ADObject -Identity "$AD_RELPATH_DIRECTORY_SERVICE,$ConfigurationNC" -Properties dsHeuristics
    $CurrentHeuristic = $DirectoryService.dsHeuristics
}

# Find all flags with incorrect values.
$ReplaceOfFlag = TestHeuristicFlag -Heuristic $Decode

# Open the WPF dialog, show the current heuristic flags and do the modifications.
$UpdatedHeuristic = OutDsHeuristFlagsView -Heuristic $CurrentHeuristic

# If we have no return value here the user has canceled the operation.
if ($UpdatedHeuristic -eq 'CANCELLED')
{
    Write-Host "dsHeuristics attribute modification has been canceled." -ForegroundColor Red
    return
}

if ($CurrentHeuristic -eq $UpdatedHeuristic)
{
    Write-Host "No changes in dsHeuristic attribute detected." -ForegroundColor Yellow
    return
}

# Write the new dsHeuristics attribute value to the domain.
if (-not $Decode)
{
    $DirectoryService.dsHeuristics = $UpdatedHeuristic
    Set-ADObject -Instance $DirectoryService -ErrorAction Stop
    Write-Host "AD Attribute dsHeuristic has been changed successfully:" -ForegroundColor Yellow
}

if (-not $CurrentHeuristic) { $CurrentHeuristic = '<not set>'}
if (-not $UpdatedHeuristic) { $UpdatedHeuristic = '<not set>'}
Write-Host "Old dsHeuristic Attribute: $CurrentHeuristic" -ForegroundColor Yellow
Write-Host "New dsHeuristic Attribute: $UpdatedHeuristic" -ForegroundColor Yellow

# END MAIN CODE

# EXCEPTION HANDLING
# NA


