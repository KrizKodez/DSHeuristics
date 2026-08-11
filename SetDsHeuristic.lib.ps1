<#PSScriptInfo

.TYPE Private Library

.TEMPLATEVERSION 1

.PLATFORM 5.1

.GUID 5FC124F3-0090-464C-AE0B-797608994FBF

.AUTHOR Christoph Rust

.COMPANYNAME KrizKodez

.TAGS
    {TagValue}

.FUNCTIONS
    ConvertToHeuristicObject
    ConvertToHeuristicString
    GetGuiWindow
    GetVersion
    OutDsHeuristFlagsView
    TestHeuristicFlag
    UpdateDataGrid

.EXTERNALMODULEDEPENDENCIES
    {<FunctionName>,<ModuleName>}

.REQUIREDSCRIPTS SetDsHeuristic.ps1

.REQUIREDBINARIES
    {<FunctionName>,<BinaryName>}        

.DESCRIPTION
    This library contains private functions for the script defined in REQUIREDSCRIPTS.

.RELEASENOTES 
    {<YYYY-MM-DD>,<FunctionName>,<AuthorID>,<ChangeDescription>}

#>

# DECLARATIONS AND DEFINITIONS
    # CONSTANTS
    # NA

    # VARIABLES
    # NA

# SCRIPTBLOCKS
# Event handlers for all controls which are controlling dsHeuristics flags.
# Each of this controls has the flag number stored in the Tag property.
$CheckBoxCheckedEventHandler = {
    $CheckBox   = [System.Windows.Controls.CheckBox]$this
    $FlagNumber = $CheckBox.Tag
    $UpdatedHeuristicObject."$FlagNumber" = "1"
    $UpdatedHeuristicObject.UpdateControlFlags()
    UpdateDataGrid    
}

$CheckBoxUnCheckedEventHandler = {
    $CheckBox   = [System.Windows.Controls.CheckBox]$this
    $FlagNumber = $CheckBox.Tag
    $UpdatedHeuristicObject."$FlagNumber" = "0"
    $UpdatedHeuristicObject.UpdateControlFlags()
    UpdateDataGrid
}

$ComboBoxSelectionChangedEventHandler = {
    $ComboBox   = [System.Windows.Controls.ComboBox]$this
    $FlagNumber = $ComboBox.Tag
    $UpdatedHeuristicObject."$FlagNumber" = [convert]::ToString($ComboBox.SelectedIndex,16)
    $UpdatedHeuristicObject.UpdateControlFlags()
    UpdateDataGrid
}

$TextBoxTextChangedEventHandler = {
    $TextBox   = [System.Windows.Controls.TextBox]$this
    $FlagNumber = $TextBox.Tag
    if ($TextBox.Text -notmatch '^[0-9a-f]{1,2}$')
    {
        [System.Windows.MessageBox]::Show("The Value must be a Hex-Byte.","WARNING: Wrong Data",0,48)
        $TextBox.Text = '00'
        return
    }
    
    # Here we have one or two hex-nibbles, but we need two.
    if ($TextBox.Text.Length -eq 1) { $FlagValue = "0$($TextBox.Text)"}
    else                            { $FlagValue = $TextBox.Text }
    
    $UpdatedHeuristicObject."$FlagNumber" = $FlagValue.Substring(0,1)
    $NextFlagNumber = [string]([int]$FlagNumber + 1)
    $UpdatedHeuristicObject."$NextFlagNumber" = $FlagValue.Substring(1,1)
    $UpdatedHeuristicObject.UpdateControlFlags()
    UpdateDataGrid
}

# ScriptMethode for the DsHeuristicObject to update
# the control flags number 10, 20 and 30.
$UpdateControlFlags = {
    # Search the highest (farthest to the right) enabled flag number.
    for($i=31;$i -ge 9;$i--)
    {
        if(($i -eq 30) -or ($i -eq 20) -or ($i -eq 10)) { continue }
        if ($this."$i" -ne "0") { break }
    }

    # Set the control flags according to the result.
    switch ($i)
    {
        {$_ -gt 30}
        {
            $this."30" = "1"
            $this."20" = "1"
            $this."10" = "1"
            break
        }
        {$_ -gt 20}
        { 
            $this."30" = "0"
            $this."20" = "1"
            $this."10" = "1"
            break
        }
        {$_ -gt 10}
        {
            $this."30" = "0"
            $this."20" = "0"
            $this."10" = "1"
            break
        }
        {$_ -lt 10}
        {
            $this."30" = "0"
            $this."20" = "0"
            $this."10" = "0"
        }
    }
}# End of scriptblock UpdateControlFlags.


# FUNCTIONS
function ConvertToHeuristicObject
{
<#
.DESCRIPTION
    The function converts the DsHeuristics string value into an object
    to be used in the WPF DataGrid control.
    
.INPUTS
    System.String
    The dsHeuristics value from the Active Directory.
    [You cannot pipe input to this function.]

.OUTPUTS
    System.Management.Automation.PSCustomObject
    Object which contains all DsHeuristics flags as a property.

.PARAMETER Heuristic
    The dsHeuristics attribute value which is a string.

.PARAMETER Type
    Define if the object contains the CURRENT flags or the UPDATED flags.
#>   
    
# PARAMETERS
[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Heuristic,

    [Parameter(Mandatory)]
    [ValidateSet('CURRENT','UPDATED')]
    [string]$Type
)

# PARAMETER CHECK
# NA

# DECLARATIONS AND DEFINITIONS
    # ARGUMENTS
    # NA

    # VARIABLES
    $Result = [PSCustomObject]@{Flags = $Type;
                                "1"="0";"2"="0";"3"="0";"4"="0";"5"="0";"6"="0";"7"="0"
                                "8"="0";"9"="0";"10"="0";"11"="0";"12"="0";"13"="0";"14"="0";"15"="0";"16"="0"
                                "17"="0";"18"="0";"19"=0;"20"="0";"21"="0";"22"="0";"23"="0";"24"="0";"25"="0"
                                "26"="0";"27"="0";"28"="0";"29"="0";"30"="0";"31"="0"
                                }

# FUNCTION MAIN CODE

# Carry the flag charachters into the object properties.
# For the object which stores the update data we must also check if a flag
# has an incorrect value and then we use the replacement value instead.
for ($i=0;$i -le $Heuristic.Length-1;$i++)
{
    if (($Type -eq 'UPDATED') -and $ReplaceOfFlag.ContainsKey("$($i+1)"))
    { $Result."$($i+1)" = $ReplaceOfFlag."$($i+1)" }
    else
    { $Result."$($i+1)" = $Heuristic.Substring($i,1) }
}

# We also add a methode to update the special control flags number 10,20 and 30.
Add-Member -InputObject $Result -MemberType ScriptMethod -Name 'UpdateControlFlags' -Value $UpdateControlFlags

Write-Output $Result

}# End of function ConvertToHeuristicObject

function ConvertToHeuristicString
{
<#
.DESCRIPTION
    The function converts the DsHeuristics object into a string
    to be used in Active Directory attribute.
    
.INPUTS
    System.String
    The dsHeuristics value from the Active Directory.
    [You cannot pipe input to this function.]

.OUTPUTS
    System.Management.Automation.PSCustomObject
    Object which contains all DsHeuristics flags as a property.

.PARAMETER Heuristic
    The dsHeuristics object to be converted into a string.
#>   
    
# PARAMETERS
[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [pscustomobject]$Heuristic
)

# PARAMETER CHECK
# NA

# DECLARATIONS AND DEFINITIONS
    # ARGUMENTS
    # NA

    # VARIABLES
    $Result = $null

# FUNCTION MAIN CODE
for ($i=1;$i -le 31;$i++) { $Result = $Result + $Heuristic."$i" }

# Truncate a series of 0 flags on the right side.
$Result = $Result -replace '0+$',''

Write-Output $Result

}# End of function ConvertToHeuristicString

function GetGuiWindow
{
<#
.DESCRIPTION
    Get the GUI Window.
    
.INPUTS
    None
    [You cannot pipe input to this function.]

.OUTPUTS
    System.Windows.Window
    The WPF Window of the GUI.
#>   

# PARAMETERS
[CmdletBinding()]
param()

# PARAMETER CHECK
# NA

# DECLARATIONS AND DEFINITIONS
    # VARIABLES
    # NA

# FUNCTION MAIN CODE

$WindowXamlDefinition=
@"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Setup Domain Heuristics" Height="700" Width="590" ResizeMode="NoResize">
    <Canvas x:Name="CanvasMain" HorizontalAlignment="Left" Height="668" VerticalAlignment="Top" Width="580" RenderTransformOrigin="0.5,0.5" Background="#FF202F70">
        <Canvas x:Name="CavasKrizKodez" Height="32" Canvas.Top="631" Width="580" Background="#FF00A2E8" Panel.ZIndex="1">
            <Label x:Name="LableCompany" Content="KrizKodez" Height="30" Width="97" Background="{x:Null}" Foreground="White" FontFamily="Segoe UI Black" FontSize="16" Canvas.Left="-2"/>
            <Label x:Name="LabelCompanyDescription" Content="Tools and Components" Height="20" Canvas.Left="95" Width="133" Canvas.Top="9" Padding="0,0,0,0" Foreground="White"/>
            <Label x:Name="LabelVersion" Content="Version" Canvas.Left="520" Canvas.Top="4" RenderTransformOrigin="1.579,-0.462" Foreground="White" Width="55" HorizontalAlignment="Right"/>
        </Canvas>
        <Canvas x:Name="CanvasWelcome" Height="632" Width="580" Background="White" Panel.ZIndex="1">
            <Label x:Name="LabelWelcome" Content="Welcome to the AD DS Heuristics Tool" Height="21" Canvas.Left="7" Canvas.Top="12" Width="365" FontSize="16" IsEnabled="False" Padding="0" FontFamily="Segoe UI Black" FontWeight="Bold"/>
            <TextBlock x:Name="TextWelcome" Height="96" Canvas.Left="7" TextWrapping="Wrap" Text="Microsoft Active Directory provides the dsHeuristics attribute in the Directory Service configuration object. This attribute is a string consisting of 31 characters where 28 represents specific decision rules which determine the behavior of the Active Directory Domain Services while 3 charachters are used only to indicate to the service that further flags are following." Canvas.Top="43" Width="558" LineStackingStrategy="BlockLineHeight" FontSize="14"/>
            <Button x:Name="ButtonContinue" Content="Continue &gt;&gt;" Height="29" Canvas.Left="482" Canvas.Top="596" Width="83"/>
            <Button x:Name="ButtonCancelStart" Height="29" Canvas.Left="376" Canvas.Top="596" Width="83" IsCancel="True" Content="Cancel" IsDefault="True"/>
            <Canvas x:Name="CanvasWarning" Height="103" Canvas.Left="10" Canvas.Top="271" Width="558" Background="#FFFD1903">
                <Label x:Name="LabelBomb" Content="M" Height="36" Canvas.Left="8" Canvas.Top="30" Width="47" FontFamily="Wingdings" FontSize="36" Foreground="Black" Padding="0" Background="#FFFD0303"/>
                <TextBlock Height="58" Canvas.Left="49" TextWrapping="Wrap" Text="Changes take effect immediately and can have unexpected effects on the directory. It's recommended to test settings thoroughly in a test environment before implementing in production." Canvas.Top="22" Width="485" Foreground="#FFFBF9F9" FontSize="14" FontWeight="Bold"/>
            </Canvas>
            <TextBlock x:Name="TextWelcome2" Height="44" Canvas.Left="7" TextWrapping="Wrap" Text="This tool should help with setting up these flags throuh visualization of the actual and the changed attribute and a bit more detailed description text for each flag." Canvas.Top="144" Width="558" FontSize="14"/>
            <Label x:Name="LabelDisclaimer" Content="Disclaimer:" Canvas.Left="3" Canvas.Top="476" FontSize="16" Width="113" FontFamily="Segoe UI Black" FontWeight="Bold" Foreground="#FF6D6D6D"/>
            <TextBlock x:Name="TextDisclaimer" Canvas.Left="7" TextWrapping="Wrap" Text="The tool is provided under the terms of the GPL V3 license. The author points out that this tool should only be used by administrators who have a deep knowledge of Active Directory and are aware of the consequences when making changes with this tool. He is not responsible for any damage caused by improper use." Canvas.Top="504" Height="79" Width="555" FontSize="14"/>
        </Canvas>
        <Canvas x:Name="CanvasFlagSetup" Height="632" Canvas.Left="0" Canvas.Top="0" Width="580" Background="White">
            <Label x:Name="LabelFlagValues" Content="Flag Values:" Height="26" Canvas.Left="8" Width="77" Canvas.Top="-3"/>
            <DataGrid x:Name="DataGridFlags" Height="89" Canvas.Left="10" Canvas.Top="21" Width="559" FrozenColumnCount="1" HorizontalGridLinesBrush="#FFAEAAAA" IsManipulationEnabled="True" VerticalGridLinesBrush="#FFAEAAAA"/>
            <Border x:Name="BoderFlagList" BorderBrush="Black" BorderThickness="1" Height="451" Canvas.Left="10" Canvas.Top="139" Width="559">
                <ScrollViewer x:Name="ScrollFlagList" Height="449" VerticalAlignment="Top" HorizontalAlignment="Left" Width="556">
                    <Canvas x:Name="CanvasFlagList" Height="1387" Width="538" Background="White" RenderTransformOrigin="0.495,0.598" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="0" ScrollViewer.CanContentScroll="True">
                        <Label x:Name="Label1" Content="1" Height="25" Canvas.Top="4" Width="21" Canvas.Left="4"/>
                        <Label x:Name="Label2" Content="2" Height="25" Canvas.Top="40" Width="21" Canvas.Left="4"/>
                        <Label x:Name="Label3" Content="3" Height="25" Canvas.Top="81" Width="21" Canvas.Left="4"/>
                        <CheckBox x:Name="CheckSupFirstLastANR" Content="SupFirstLastANR" Height="18" Canvas.Left="24" Canvas.Top="9" Width="115" FontWeight="Bold" Tag="1"/>
                        <TextBlock x:Name="TextSupFirstLastANR" Height="35" Canvas.Left="43" TextWrapping="Wrap" Text="Ambiguous Name Resolution will not include search by &quot;Firstname Lastname&quot;." Canvas.Top="23" Width="418" FontFamily="Segoe UI Semilight"/>
                        <CheckBox x:Name="CheckSupLastFirstANR" Height="18" Canvas.Left="24" Canvas.Top="46" Width="115" Content="SupLastFirstANR" FontWeight="Bold" Tag="2"/>
                        <TextBlock x:Name="TextSupLastFirstANR" Height="35" Canvas.Left="43" TextWrapping="Wrap" Text="Ambiguous Name Resolution will not include search by &quot;Lastname Firstname&quot;." Canvas.Top="61" Width="481" FontFamily="Segoe UI Semilight"/>
                        <CheckBox x:Name="CheckDoListObject" Height="18" Canvas.Left="24" Canvas.Top="86" Width="115" Content="DoListObject" FontWeight="Bold" Tag="3"/>
                        <TextBlock x:Name="TextDoListObject" Height="38" Canvas.Left="43" TextWrapping="Wrap" Text="The &quot;List Object&quot; right will be enforced and children will be hidden if the searcher does not have the DS_LIST_OBJECT right on the parent." Canvas.Top="100" Width="486" FontFamily="Segoe UI Semilight"/>
                        <CheckBox x:Name="CheckDoNickRes" Height="18" Canvas.Left="24" Canvas.Top="136" Width="115" Content="DoNickRes" FontWeight="Bold" Tag="4"/>
                        <TextBlock x:Name="TextDoNickRes" Height="34" Canvas.Left="43" TextWrapping="Wrap" Text="Ambiguous Name Resolution request via MAPI will attempt an exact match against the MAPI nickname." Canvas.Top="149" Width="481" FontFamily="Segoe UI Semilight"/>
                        <CheckBox x:Name="CheckLDAPUsePermMod" Height="18" Canvas.Left="24" Canvas.Top="186" Width="129" Content="LDAPUsePermMod" FontWeight="Bold" Tag="5"/>
                        <TextBlock x:Name="TextLDAPUsePermMode" Height="56" Canvas.Left="43" TextWrapping="Wrap" Text="LDAP will use the LDAP_SERVER_PERMISSIVE_MODIFY control (return success even if no modification is performed). Otherwise LDAP will use strict modification behavior and return an error if no modifications are to be performed, like deleting an attribute that is not present." Canvas.Top="201" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="LabelHideDSID" Content="HideDSID (Directory Service ID)" Height="23" Canvas.Left="36" Canvas.Top="246" Width="185" FontWeight="Bold"/>
                        <ComboBox x:Name="ComboHideDSID" Height="22" Canvas.Left="41" Canvas.Top="267" Width="484" Background="White" BorderBrush="White" Tag="6">
                            <ComboBoxItem Content="0 - DSIS will always be returned"/>
                            <ComboBoxItem Content="1 - DSID will only be returned if it does not reveal the identity"/>
                            <ComboBoxItem Content="2 - DSID will not be returned"/>
                        </ComboBox>
                        <CheckBox x:Name="CheckLDAPBlockAnonOps" Height="18" Canvas.Left="24" Canvas.Top="298" Width="129" Content="LDAPBlockAnonOps" FontWeight="Bold" Tag="7"/>
                        <TextBlock x:Name="TextLDAPBlockAnonOps" Height="37" Canvas.Left="43" TextWrapping="Wrap" Text="If enabled unauthenticated users are limited to performing only rootDSE searches and bind, otherwise this users can perform any LDAP opertion if the ACL permits it." Canvas.Top="314" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <CheckBox x:Name="CheckAllowAnonNSPI" Height="18" Canvas.Left="24" Canvas.Top="351" Width="129" Content="AllowAnonNSPI" FontWeight="Bold" Tag="8"/>
                        <TextBlock x:Name="TextAllowAnonNSPI" Height="22" Canvas.Left="43" TextWrapping="Wrap" Text="Allow anonymous calls to the Name Service Provider Interface RPC." Canvas.Top="367" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="LabelUserPwdSupport" Content="UserPwdSupport" Height="25" Canvas.Left="38" Canvas.Top="382" Width="185" FontWeight="Bold"/>
                        <ComboBox x:Name="ComboUserPwdSupport" Height="22" Canvas.Left="41" Canvas.Top="419" Width="484" Background="White" BorderBrush="White" Tag="9">
                            <ComboBoxItem Content="0 - (DS only) Allow access to userPassword attribute if ACL permitting"/>
                            <ComboBoxItem Content="1 - Disable access to userPassword attribute regardless of permissions"/>
                            <ComboBoxItem Content="2 - (DS and LDS) Allow access to userPassword attribute, ACL permitting"/>
                        </ComboBox>
                        <CheckBox x:Name="CheckSpecifyGUIDOnAdd" Height="18" Canvas.Left="24" Canvas.Top="450" Width="141" Content="SpecifyGUIDOnAdd" FontWeight="Bold" Tag="11"/>
                        <TextBlock x:Name="TextSpecifyGUIDOnAdd" Height="22" Canvas.Left="43" TextWrapping="Wrap" Text="The requestor is allowed to specify the GUID while adding an object." Canvas.Top="465" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <CheckBox x:Name="CheckDontStandardizeSDs" Height="18" Canvas.Left="24" Canvas.Top="486" Width="129" Content="DontStandardizeSDs" FontWeight="Bold" Tag="12"/>
                        <TextBlock x:Name="TextDontStandardizeSDs" Height="22" Canvas.Left="43" TextWrapping="Wrap" Text="The order of ACEs supplied by the client is preserved, ordering rules are ignored." Canvas.Top="501" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label12" Content="12" Height="25" Canvas.Top="480" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <Label x:Name="Label11" Content="11" Height="25" Canvas.Top="444" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <Label x:Name="Label9" Content="9" Height="25" Canvas.Top="382" Width="21" Canvas.Left="4"/>
                        <Label x:Name="Label8" Content="8" Height="25" Canvas.Top="344" Width="21" Canvas.Left="4"/>
                        <Label x:Name="Label7" Content="7" Height="25" Canvas.Top="292" Width="21" Canvas.Left="4"/>
                        <Label x:Name="Label6" Content="6" Height="25" Canvas.Top="247" Width="21" Canvas.Left="4"/>
                        <Label x:Name="Label4" Content="4" Height="25" Canvas.Top="131" Width="21" Canvas.Left="4"/>
                        <Label x:Name="Labe5" Content="5" Height="25" Canvas.Top="179" Width="21" Canvas.Left="4"/>
                        <CheckBox x:Name="CheckAllowPasswordOps" Height="18" Canvas.Left="24" Canvas.Top="525" Width="278" Content="AllowPasswordOpsOverNonSecureConnections" FontWeight="Bold" Tag="13"/>
                        <TextBlock x:Name="TextAllowPasswordOps" Height="32" Canvas.Left="43" TextWrapping="Wrap" Text="Allow modifation of unicodePwd attribute over a connection that is neither TLS nor SASL-encrypted. (AD LDS ONLY)" Canvas.Top="539" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label13" Content="13" Height="25" Canvas.Top="520" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <Label x:Name="Label14" Content="14" Height="25" Canvas.Top="570" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <CheckBox x:Name="CheckDontPropagateOnNoChangeUpdate" Height="18" Canvas.Left="24" Canvas.Top="576" Width="278" Content="DontPropagateOnNoChangeUpdate" FontWeight="Bold" Tag="14"/>
                        <TextBlock x:Name="TextDontPropagateOnNoChangeUpdate" Height="32" Canvas.Left="43" TextWrapping="Wrap" Text="The ntSecurityDescriptor is propagated to descendant objects on change, even if the new value is bitwise identical to the old one." Canvas.Top="591" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label15" Content="15" Height="25" Canvas.Top="621" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <CheckBox x:Name="CheckComputeANRStats" Height="18" Canvas.Left="24" Canvas.Top="627" Width="278" Content="ComputeANRStats" FontWeight="Bold" Tag="15"/>
                        <TextBlock x:Name="TextComputeANRStats" Height="19" Canvas.Left="43" TextWrapping="Wrap" Text="ANR searches are optimized using cardianlity estimates from previous searches." Canvas.Top="642" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label16" Content="16" Height="25" Canvas.Top="656" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <Label x:Name="LabelAdminSDExMask" Content="AdminSDExMask" Height="25" Canvas.Left="38" Canvas.Top="656" Width="185" FontWeight="Bold"/>
                        <TextBlock x:Name="TextAdminSDExMask" Height="19" Canvas.Left="43" TextWrapping="Wrap" Text="Excludes operator groups from AdminSDHolder:" Canvas.Top="676" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <ComboBox x:Name="ComboAdminSDExMask" Height="22" Canvas.Left="41" Canvas.Top="693" Width="484" Background="White" BorderBrush="White" Tag="16">
                            <ComboBoxItem Content="0 - No excludes"/>
                            <ComboBoxItem Content="1 - Account Operators"/>
                            <ComboBoxItem Content="2 - Server Operators"/>
                            <ComboBoxItem Content="3 - Account Operators + Server Operators"/>
                            <ComboBoxItem Content="4 - Print Operators"/>
                            <ComboBoxItem Content="5 - Account Operators + Print Operators"/>
                            <ComboBoxItem Content="6 - Server Operators + Print Operators"/>
                            <ComboBoxItem Content="7 - Account Operators + Server Operators + Print Operators"/>
                            <ComboBoxItem Content="8 - Backup Operators"/>
                            <ComboBoxItem Content="9 - Account Operators + Backup Operators"/>
                            <ComboBoxItem Content="a - Server Operators + Backup Operators"/>
                            <ComboBoxItem Content="b - Account Operators + Server Operators + Backup Operators"/>
                            <ComboBoxItem Content="c - Print Operators + Backup Operators"/>
                            <ComboBoxItem Content="d - Account Operators + Print Operators + Backup Operators"/>
                            <ComboBoxItem Content="e - Server Operators + Print Operators + Backup Operators"/>
                            <ComboBoxItem Content="f - Account Operators + Server Operators + Print Operators + Backup Operators"/>
                        </ComboBox>
                        <Label x:Name="Label17" Content="17" Height="25" Canvas.Top="717" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <CheckBox x:Name="CheckKVNOEmuW2K" Height="18" Canvas.Left="24" Canvas.Top="723" Width="278" Content="KVNOEmuW2K" FontWeight="Bold" Tag="17"/>
                        <TextBlock x:Name="TextKVNOEmuW2K" Height="19" Canvas.Left="43" TextWrapping="Wrap" Text="In W2K emulation the msDS-KeyVersionNumber will always equal 1." Canvas.Top="738" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label18" Content="18" Height="25" Canvas.Top="755" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <CheckBox x:Name="CheckLDAPBypassUpperBoundsOnLimits" Height="18" Canvas.Left="24" Canvas.Top="760" Width="278" Content="LDAPBypassUpperBoundsOnLimits" FontWeight="Bold" Tag="18"/>
                        <TextBlock x:Name="TextLDAPBypassUpperBoundsOnLimits" Height="21" Canvas.Left="43" TextWrapping="Wrap" Text="DCs will bypass implementation-dependent limits on LDAP policies." Canvas.Top="775" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label19" Content="19" Height="25" Canvas.Top="791" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <CheckBox x:Name="CheckDisableAutoIndexingOnSchemaUpdate" Height="18" Canvas.Left="24" Canvas.Top="796" Width="278" Content="DisableAutoIndexingOnSchemaUpdate" FontWeight="Bold" Tag="19"/>
                        <TextBlock x:Name="TextDisableAutoIndexingOnSchemaUpdate" Height="69" Canvas.Left="43" TextWrapping="Wrap" Text="If the this heuristic is TRUE, it is a hint to DCs that index creation can be delayed upon detection of index-related changes to the searchFlags attribute until either an administrator issues the schemaUpdateNow rootDSE modify operation, the DC is rebooted, or an implementation-dependent time period has elapsed." Canvas.Top="810" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label21" Content="21" Height="25" Canvas.Top="871" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <ComboBox x:Name="ComboDoNotVerifyUPNAndOrSPNUniqueness" Height="22" Canvas.Left="41" Canvas.Top="907" Width="484" Background="White" BorderBrush="White" Tag="21">
                            <ComboBoxItem Content="0 - Verify for uniquenes"/>
                            <ComboBoxItem Content="1 - UPN"/>
                            <ComboBoxItem Content="2 - SPN"/>
                            <ComboBoxItem Content="3 - UPN + SPN"/>
                            <ComboBoxItem Content="4 - SPN Alias"/>
                            <ComboBoxItem Content="5 - UPN + SPN Alias"/>
                            <ComboBoxItem Content="6 - SPN + SPN Alias"/>
                            <ComboBoxItem Content="7 - UPN + SPN + SPN Alias"/>
                        </ComboBox>
                        <TextBlock x:Name="TextDoNotVerifyUPNAndOrSPNUniqueness" Height="21" Canvas.Left="43" TextWrapping="Wrap" Text="The following names will not be verified for uniquenes on change:" Canvas.Top="890" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label22" Content="22" Height="25" Canvas.Top="931" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <Label x:Name="LabelMinimumGetChangesRequestVersion" Content="MinimumGetChangesRequestVersion:" Height="25" Canvas.Left="38" Canvas.Top="930" Width="223" FontWeight="Bold"/>
                        <TextBlock x:Name="TextMinimumGetChangesRequestVersion" Height="52" Canvas.Left="43" TextWrapping="Wrap" Text="A hexadecimal value, ranging from &quot;00&quot; to &quot;FF&quot;. This value controls the minimum version of the DRS_MSG_GETCHGREQ* structures the DC will send or accept. If the value is not set, the value &quot;00&quot; is used. When the value is &quot;00&quot;, no restriction is enforced." Canvas.Top="953" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <TextBox x:Name="TextBoxMinimumGetChangesRequestVersion" Height="21" Canvas.Left="263" TextWrapping="Wrap" Canvas.Top="933" Width="24" FontSize="14" Tag="22" MaxLength="2"/>
                        <Label x:Name="LabelDoNotVerifyUPNAndOrSPNUniqueness" Content="DoNotVerifyUPNAndOrSPNUniqueness" Height="25" Canvas.Left="38" Canvas.Top="870" Width="235" FontWeight="Bold"/>
                        <Label x:Name="Label24" Content="24" Height="25" Canvas.Top="999" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <Label x:Name="LabelMinimumGetChangesReplyVersion" Content="MinimumGetChangesReplyVersion:" Height="25" Canvas.Left="38" Canvas.Top="998" Width="223" FontWeight="Bold"/>
                        <TextBox x:Name="TextBoxMinimumGetChangesReplyVersion" Height="21" Canvas.Left="263" TextWrapping="Wrap" Canvas.Top="1002" Width="24" FontSize="14" Tag="24" MaxLength="2"/>
                        <TextBlock x:Name="TextMinimumGetChangesReplyVersion" Height="52" Canvas.Left="43" TextWrapping="Wrap" Text="A hexadecimal value, ranging from &quot;00&quot; to &quot;FF&quot;. This value controls the minimum version of the DRS_MSG_GETCHGREPLY* structures the DC will send or accept. If the value is not set, the value &quot;00&quot; is used. When the value is &quot;00&quot;, no restriction is enforced." Canvas.Top="1021" Width="481" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label26" Content="26" Height="25" Canvas.Top="1066" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <CheckBox x:Name="CheckLoadV1AddressBooksOnlySetting" Height="18" Canvas.Left="24" Canvas.Top="1072" Width="278" Content="LoadV1AddressBooksOnlySetting" FontWeight="Bold" Tag="26"/>
                        <TextBlock x:Name="TextLoadV1AddressBooksOnlySetting" Height="36" Canvas.Left="43" TextWrapping="Wrap" Text="MAPI address book is calculated using V1 attributes. Otherwise V2 is used. Only works with Windows Client/Server 1903 and newer." Canvas.Top="1088" Width="482" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label27" Content="27" Height="25" Canvas.Top="1118" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <CheckBox x:Name="CheckTreatTokenGroupsAsLDAPTransitiveAttribute" Height="18" Canvas.Left="24" Canvas.Top="1124" Width="278" Content="TreatTokenGroupsAsLDAPTransitiveAttribute" FontWeight="Bold" Tag="27"/>
                        <TextBlock x:Name="TextTreatTokenGroupsAsLDAPTransitiveAttribute" Height="36" Canvas.Left="43" TextWrapping="Wrap" Text="LDAP Policy MaxValueRangeTransitive is respected for token groups, otherwise MaxValueRange is respected. Only works with Windows Client/Server 1903 and newer." Canvas.Top="1139" Width="481" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label28" Content="28" Height="25" Canvas.Top="1167" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <Label x:Name="LabelAttributeAuthorizationOnLDAPAdd" Content="AttributeAuthorizationOnLDAPAdd" Height="25" Canvas.Left="38" Canvas.Top="1167" Width="223" FontWeight="Bold"/>
                        <TextBlock x:Name="TextAttributeAuthorizationOnLDAPAdd" Height="33" Canvas.Left="43" TextWrapping="Wrap" Text="KB5008383 Additional Authentication verifications for LDAP Add operations. Only works with Windows Server 2008 R2 and newer." Canvas.Top="1188" Width="481" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <ComboBox x:Name="ComboAttributeAuthorizationOnLDAPAdd" Height="22" Canvas.Left="41" Canvas.Top="1220" Width="484" Background="White" BorderBrush="White" Tag="28">
                            <ComboBoxItem Content="0 - KB5008383 Events only beeing logged."/>
                            <ComboBoxItem Content="1 - KB5008383 Enforcement mode enabled"/>
                            <ComboBoxItem Content="2 - KB5008383 Enforcem,ent mode disabled"/>
                        </ComboBox>
                        <TextBlock x:Name="TextUserPwdSupport" Height="22" Canvas.Left="43" TextWrapping="Wrap" Text="Defines how the userPassword attribute is treated:" Canvas.Top="402" Width="486" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <Label x:Name="Label29" Content="29" Height="25" Canvas.Top="1240" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <Label x:Name="LabelBlockOwnerImplicitRights" Content="BlockOwnerImplicitRights" Height="25" Canvas.Left="38" Canvas.Top="1239" Width="223" FontWeight="Bold"/>
                        <TextBlock x:Name="TextlBlockOwnerImplicitRights" Height="33" Canvas.Left="43" TextWrapping="Wrap" Text="KB5008383 Temporary removal of Implicit Owner for LDAP Modify. Only works with Windows Server 2008 R2 and newer." Canvas.Top="1258" Width="481" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                        <ComboBox x:Name="ComboBlockOwnerImplicitRights" Height="22" Canvas.Left="41" Canvas.Top="1290" Width="484" Background="White" BorderBrush="White" Tag="29">
                            <ComboBoxItem Content="0 - KB5008383 Events only beeing logged."/>
                            <ComboBoxItem Content="1 - KB5008383 Enforcement mode enabled"/>
                            <ComboBoxItem Content="2 - KB5008383 Enforcement mode disabled"/>
                        </ComboBox>
                        <Label x:Name="Label31" Content="31" Height="25" Canvas.Top="1309" Width="24" RenderTransformOrigin="0.333,0.64" Canvas.Left="1"/>
                        <Label x:Name="LabelDisableConfidentialAttributeEncryptionRequirements" Content="DisableConfidentialAttributeEncryptionRequirements" Height="25" Canvas.Left="38" Canvas.Top="1310" Width="310" FontWeight="Bold"/>
                        <ComboBox x:Name="ComboDisableConfidentialAttributeEncryptionRequirements" Height="22" Canvas.Left="41" Canvas.Top="1347" Width="484" Background="White" BorderBrush="White" Tag="31">
                            <ComboBoxItem Content="0 - Encrypt search, modify and add operations"/>
                            <ComboBoxItem Content="1 - Disable search encryption"/>
                            <ComboBoxItem Content="2 - Disable modify encryption"/>
                            <ComboBoxItem Content="3 - Disable search and modify encryption"/>
                            <ComboBoxItem Content="4 - Disable add encryption"/>
                            <ComboBoxItem Content="5 - Disable add and search encryption"/>
                            <ComboBoxItem Content="6 - Disable add and modify encryptionators"/>
                            <ComboBoxItem Content="7 - Disable encryption for search, add and modify"/>
                        </ComboBox>
                        <TextBlock x:Name="TextDisableConfidentialAttributeEncryptionRequirements" Height="18" Canvas.Left="43" TextWrapping="Wrap" Text="Confidential Attributes encrypted session requirements:" Canvas.Top="1329" Width="481" FontFamily="Segoe UI Semilight" IsEnabled="False"/>
                    </Canvas>
                </ScrollViewer>
            </Border>
            <Label x:Name="LabelFlags" Content="Flags:" Height="30" Width="49" Canvas.Top="115" Canvas.Left="9" RenderTransformOrigin="9.633,2.094"/>
            <Button x:Name="ButtonCancelEdit" Height="29" Canvas.Left="376" Canvas.Top="596" Width="83" IsCancel="True" Content="Cancel" IsDefault="True"/>
            <Button x:Name="ButtonModify" Height="29" Canvas.Left="482" Canvas.Top="596" Width="83" Content="Modify" IsEnabled="False"/>
            <CheckBox x:Name="CheckUnlockModify" Content="I know what I am doing, let me press the Modify button." Canvas.Left="12" Canvas.Top="605" Width="320"/>
        </Canvas>
    </Canvas>

</Window>
"@

[xml]$Xaml = $WindowXamlDefinition
$Reader    = New-Object -TypeName 'System.Xml.XmlNodeReader' -ArgumentList $Xaml
$Result    = [Windows.Markup.XamlReader]::Load($Reader)

Write-Output $Result

}# End of function GetGuiWindow.

function GetVersion
{
<#
.DESCRIPTION
    Get the version of the controller.
    
.INPUTS
    None
    [You cannot pipe input to this function.]

.OUTPUTS
    System.String
    The version of the controller.
#>   

# PARAMETERS
[CmdletBinding()]
param()

# PARAMETER CHECK
# NA

# DECLARATIONS AND DEFINITIONS
    # VARIABLES
    # NA

# FUNCTION MAIN CODE
$ScriptText = Get-Content -Path $MyInvocation.ScriptName
$MatchInfo  = $ScriptText | Select-String -Pattern '\.VERSION (\d\.\d\.\d)'
$Result     = $MatchInfo.Matches.Groups[1].Value

Write-Output $Result

}# End of function GetVersion.

function TestHeuristicFlag
{
<#
.DESCRIPTION
    The function checks if the submitted Heuristic string has
    correct values and if the control flags are setup correctly.
    
.INPUTS
    System.String
    Sequence of dsHeusristic flag values.
    [You cannot pipe input to this function.]

.OUTPUTS
    System.Collections.Hashtable
    Hashtable with replacement values for incorrect flags.

.NOTES
    The function does not return a simple boolean value, instead a hashtable
    with all flag numbers and the replacement values.

.PARAMETER Heuristic
    A dsHeuristic value to be tested.
#>   

# PARAMETERS
[CmdletBinding()]
param([string]$Heuristic)

# PARAMETER CHECK
# NA

# DECLARATIONS AND DEFINITIONS
    # VARIABLES
    $Result                       = @{} # Key = flag number, Value = the replacement value.
    $CheckBoxFlagNumbers          = @(1,2,3,4,5,7,8,11,12,13,14,15,17,18,19,26,27)
    $ControlFlagNumbers           = @(10,20,30)
    $ComboThreeValueFlagNumbers   = @(6,9,28,29)
    $ComboNibbleValueFlagNumbers  = @(21,31)
    $ComboHexValueFlagNumbers     = @(16)
    $TexBoxNibbleValueFlagNumbers = @(22,23,24,25)


# FUNCTION MAIN CODE
$HighestEnabledFlagNumber = 0
for($Position=0;$Position -le $Heuristic.Length-1 ;$Position++)
{
    $FlagNumber = $Position + 1
    $FlagValue  = $Heuristic.Substring($Position,1)
    
    # Find the right pattern to compare.
    switch ($FlagNumber)
    {
        {$CheckBoxFlagNumbers          -contains $_ } { $FlagPattern = '[01]'; break }
        {$ControlFlagNumbers           -contains $_ } { $FlagPattern = '[01]'; break }
        {$ComboThreeValueFlagNumbers   -contains $_ } { $FlagPattern = '[012]'; break }
        {$ComboNibbleValueFlagNumbers  -contains $_ } { $FlagPattern = '[0-7]'; break }
        {$ComboHexValueFlagNumbers     -contains $_ } { $FlagPattern = '[0-9a-f]'; break }
        {$TexBoxNibbleValueFlagNumbers -contains $_ } { $FlagPattern = '[0-7]' }
    }
    
    # Here we check only the allowed values.
    if ($FlagValue -notmatch $FlagPattern) { $Result.Add("$FlagNumber","0") }
    
    # Here we want to detect the highest enabled flag which is not a control flag.
    if (($FlagValue -eq "1") -and ($ControlFlagNumbers -notcontains $FlagNumber))
    { $HighestEnabledFlagNumber = $FlagNumber }
}

# Now we must check if the three control flags are correct.
foreach($ControlFlagNumber in $ControlFlagNumbers)
{
    if ($Heuristic.Length -lt $ControlFlagNumber) { break }
    $ControlFlagValue  = $Heuristic.Substring($ControlFlagNumber - 1,1)
    if ($HighestEnabledFlagNumber -lt $ControlFlagNumber)
    {
       if ($ControlFlagValue -eq "1") { $Result."$ControlFlagNumber" = "0" }
    }
    else
    {
        if ($ControlFlagValue -eq "0") { $Result."$ControlFlagNumber" = "1" }  
    }
}

Write-Output $Result

}# End of function TestHeuristicFlag.

function OutDsHeuristFlagsView
{
<#
.DESCRIPTION
    The function shows a WPF-GUI with the current dsHeuristics flag values
    and let the user manipulate the flags in an easy way.
    
.INPUTS
    Syste.String
    The current dsHeuristics value.
    [You cannot pipe input to this function.]

.OUTPUTS
    System.String
    The updated dsHeuristics value.

.PARAMETER Heuristic
    The dsHeuristics value that should be displayed and modified.
#>   
    
# PARAMETERS
[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Heuristic
)

# PARAMETER CHECK
# NA

# DECLARATIONS AND DEFINITIONS
    # ARGUMENTS
    # NA

    # VARIABLES
    $CurrentHeuristicObject = $null     # The current dsHeuristisc flags.
    $UpdatedHeuristicObject = $null     # The changed dsHeuristics flags.
    $DataSource             = $null     # The datasource for the DataGrid control.
    $Result                 = $null

# FUNCTION MAIN CODE
$WPFForm = GetGuiWindow

# Assign the WPF controls to PowerShell variables.
$ButtonCancelEdit  = $WPFForm.FindName('ButtonCancelEdit')
$ButtonCancelStart = $WPFForm.FindName('ButtonCancelStart')
$ButtonContinue    = $WPFForm.FindName('ButtonContinue')
$ButtonModify      = $WPFForm.FindName('ButtonModify')
$CanvasWelcome     = $WPFForm.FindName('CanvasWelcome')
$CanvasFlagList    = $WPFForm.FindName('CanvasFlagList')
$CheckUnlockModify = $WPFForm.FindName('CheckUnlockModify')
$DataGrid          = $WPFForm.FindName('DataGridFlags')
$LabelVersion      = $WPFForm.FindName('LabelVersion')

# Show the controller version in the label.
$LabelVersion.Content = $ControllerVersion

# Initialize the DataGrid with the current values.
$CurrentHeuristicObject = ConvertToHeuristicObject -Type 'CURRENT' -Heuristic $Heuristic
$UpdatedHeuristicObject = ConvertToHeuristicObject -Type 'UPDATED' -Heuristic $Heuristic
$DataSource             = @($CurrentHeuristicObject,$UpdatedHeuristicObject)
$DataGrid.ItemsSource   = $DataSource

# Add the event handlers.
$ButtonCancelEdit.Add_Click({ $WPFForm.DialogResult = $false })
$ButtonCancelStart.Add_Click({ $WPFForm.DialogResult = $false })
$ButtonContinue.Add_Click({ $CanvasWelcome.Visibility ='Hidden' })
$ButtonModify.Add_Click({ $WPFForm.DialogResult = $true })
$CheckUnlockModify.Add_Checked({ $ButtonModify.IsEnabled = $true })
$CheckUnlockModify.Add_UnChecked({ $ButtonModify.IsEnabled = $false })
$DataGrid.Add_Loaded({ UpdateDataGrid })

# Initialize values and add the event handler to all controls which controlling a dsHeuristics flag.
# The flag number is stored in the Tag property of the control.
# All Flag controls are stored in the CanvasFlagList control.
foreach ($Control in $CanvasFlagList.Children)
{
    if ($null -eq $Control.Tag) { continue }    # Skip controls without a Tag value.
    $Flag = $Control.Tag

    # These are the Flags controled by a CheckBox.
    if ($Control -is [System.Windows.Controls.CheckBox])
    { if ($UpdatedHeuristicObject."$Flag" -ne "0") { $Control.IsChecked = $true } }
    
    # We have only two TextBoxes controlling the four flags 22,23,24,25.
    if ($Control -is [System.Windows.Controls.TextBox])
    {
        if ($Flag -eq "22") { $Control.Text = "$($UpdatedHeuristicObject.'22')$($UpdatedHeuristicObject.'23')" }
        else                { $Control.Text = "$($UpdatedHeuristicObject.'24')$($UpdatedHeuristicObject.'25')" }
    }
    
    # The ComboBoxes storing hex values.
    if ($Control -is [System.Windows.Controls.ComboBox])
    { $Control.SelectedIndex = [convert]::ToInt16($UpdatedHeuristicObject."$Flag",16) }

}# End of foreach all flag controls initialize value.

foreach ($Control in $CanvasFlagList.Children)
{
    if ($null -eq $Control.Tag) { continue }    # Skip controls without a Tag value.
    $Flag = $Control.Tag

    # These are the Flags controled by a CheckBox.
    if ($Control -is [System.Windows.Controls.CheckBox])
    {
        $Control.Add_Checked($CheckBoxCheckedEventHandler)
        $Control.Add_UnChecked($CheckBoxUnCheckedEventHandler)
    }
    
    # We have only two TextBoxes controlling the four flags 22,23,24,25.
    if ($Control -is [System.Windows.Controls.TextBox])
    { $Control.Add_TextChanged($TextBoxTextChangedEventHandler) }
    
    # The ComboBoxes storing hex values.
    if ($Control -is [System.Windows.Controls.ComboBox])
    { $Control.Add_SelectionChanged($ComboBoxSelectionChangedEventHandler) }

}# End of foreach all flag controls adding event handler.

# Show the WPF-GUI and if the user clicks one of the Cancel buttons...
$DialogResult = $WPFForm.ShowDialog()
# ...we cancel the function with a CANCELLED value.
if (-not $DialogResult)
{
    Write-Output 'CANCELLED'
    return
}

# Convert the object back to a string value.
$Result = ConvertToHeuristicString -Heuristic $UpdatedHeuristicObject

Write-Output $Result

}# End of function OutDsHeuristFlagsView

function UpdateDataGrid
{
<#
.DESCRIPTION
    The function updates the data records and changes the colors
    of the cells where the value has been changed.    
    
.INPUTS
    None

.OUTPUTS
    None
#>   

# PARAMETERS
[CmdletBinding()]
param()

# PARAMETER CHECK
# NA

# DECLARATIONS AND DEFINITIONS
    # VARIABLES
    # NA

# FUNCTION MAIN CODE

# Rebind the updated DataSource array.
$DataGrid.ItemsSource = $null
$DataGrid.ItemsSource = $DataSource

# We need the update of the layout otherwise the row UpdatedHeuristicRow could not be found.
$DataGrid.UpdateLayout()
$CurrentHeuristicRow = $DataGrid.ItemContainerGenerator.ContainerFromItem($DataGrid.Items[0])
$UpdatedHeuristicRow = $DataGrid.ItemContainerGenerator.ContainerFromItem($DataGrid.Items[1])

# Check which cells we have to colorize.
for ($i=1;$i -le 31;$i++)
{
    # If cell values of the CURRENT and UPDATED rows are different we colorize in the UPDATED row.
    if ($DataSource[0]."$i" -ne $DataSource[1]."$i")
    {
        $Cell = $DataGrid.Columns[$i].GetCellContent($UpdatedHeuristicRow)
        $Cell.Background = [System.Windows.Media.Brushes]::PeachPuff
    }

    # If the cell contains an incorrect flag value we colorize it in the CURRENT row.
    if ($ReplaceOfFlag.ContainsKey("$i"))
    {
        $Cell = $DataGrid.Columns[$i].GetCellContent($CurrentHeuristicRow)
        $Cell.Background = [System.Windows.Media.Brushes]::Red
    }
}

}# End of function UpdateDataGrid.


