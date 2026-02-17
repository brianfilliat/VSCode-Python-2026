<#
.SYNOPSIS

 Generates GUI to be used as front end for CRG Scripts

.DESCRIPTION

 Uses System.windows.forms and System Drawing to create GUI interface to do the following:

    - Create CRG Report
    - Create Custom Reports
    - Show Version Summary
    - Show Health Assessment Summary

.EXAMPLE

 powershell -executionpolicy bypass .\Menu-CRG.ps1

.EXAMPLE

 powershell -executionpolicy bypass -command "& {$pwd\Menu-CRG.ps1 -configfile $pwd\output\example\config.xml}"

.INPUTS
    $configfile = Config File with Vblock settings.   Used to quickly open a config file.

.NOTES
    Version 5.1.1.0 - Added help section and configfile parameter
                    - Fixed issue where NSX was not auto checking when pressing auto check offline
    Version 5.1.1.1 - Fixed issue with import-lcs not correctly importing lcs on some computers
                    - Added feature to pass certain variables to the report scripts to include version checking
    Version 5.1.1.2 - VMware version will now only check hosts provided in filter
                    - Fixed typos
    Version 5.1.2.0 - Fixed issue where Create-xls in Menu-CRG.ps1 was not working 
                    - Fixed issue where running script as stand alone was not working
    Version 5.1.3.3 - Fixed issue where IPI would not work unless another script was run at the same time
                    - Modified VMAX collection to only require BIN file.   Backup config file was not being used in script
                    - Modified offline tab to use datagrid instead
					- Fixed issue where autocheck online was not checking NSX
	Version 5.1.3.4 - Added VDM to DM interface mapping information in NAS report
    Version 5.1.3.6 - Fixed issue with VMAX CRG report not working
	Version 5.1.3.8 - Integrated VMware Paths data collection info from David Taylor
    Version 5.1.3.9 - Updated VMAX and health Assessment to include VMAX alert status
    Version 5.1.4.0 - Updated at completion of Sprint 14 demo
                    - Increased expirary date to 60 days
    Version 5.1.4.1 - Updated to include IPI version
	Version 5.1.5.4 - Support telnet as an option for switches
	Version 5.1.5.5 - Fix N3K/N5K name changes in assessment
    Version 5.1.5.7 - updated n1k and assessment script
    version 5.1.6.0 - updated rcm version file
    version 5.1.7.0 - updated at end of Sprint
#>

[cmdletbinding()]

param
(
    [parameter()]$SystemConfigFile
)

Add-Type -AssemblyName System.Windows.Forms,System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
[Reflection.Assembly]::LoadFrom((Resolve-Path "$pwd\bin\EPPlus.dll")) | Out-Null

$myver        = "5.1.7.1"
$lastupdated  = "February 10, 2017"
$objformtitle = "VCE Vblock Configuration Reference Guide"

$about = 
@"

    CRG Reporting Tool $myver                    
    
    Contributors:   Robert Auvil                  
                    Kevin Clark                   
                    Walter Beach                  
                    Richard Kirchhofer            
                                                  
    Description:    CRG Reporting Tool              
                    VMware Script                   
                                                  
    Created:        April 27, 2014                   
    Last Updated:   $lastupdated                   

"@

$TIMESTAMP = ""

Set-PSBreakpoint -Variable TIMESTAMP -Mode Read -Action {$script:TIMESTAMP=(Get-Date -Format yyyyMMdd_hhmmtt);$script:TIMESTAMP} | Out-Null

# Set default culture to en-US; others not supported by CRG
$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
if ($culture -ne $null)
{
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $culture
}

$ScriptPath       = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path)
$outputpath       = Join-Path -Path $ScriptPath -ChildPath "Output"
$options          = "$scriptpath\bin\Configs\options.xml"
$helpnodesfile    = "$scriptpath\bin\Configs\help.xml"
$env:Path         += ";.\bin;.\bin\scripts;.\bin\reports"
$checkimage       = New-Object System.Drawing.Bitmap "$ScriptPath\Bin\Icons\check.bmp"
$regions          = @{"Standard" = "VMwar3!!"; "Americas" = "V1rtu@1c3!"; "EMEA" = "VMwar3!!"}
$defaultregion    = "Standard"
$modifyregions    = "Standard","Americas","EMEA"
$modifypanels     = "Components","Credentials","Version","Settings"
$region           = $defaultregion
$password         = $regions.item($region)
$passwordsso      = $regions.item($region)
$CHECK_PREREQS    = "false"
$configfile       = "untitled"
$prefscratchspace = "2.5","50"
$rcm_versions     = "$ScriptPath\bin\rcm versions.xlsx"

$arraypsscripts = 
@([pscustomobject]@{Name="UCSB";Alias="UCS Cluster";Variable="PS_UCSB";Script="UCSB-CRG.ps1";SearchPath='Powershell (UCSB*.ps1)  | UCSB*.ps1';Instance=5},
[pscustomobject]@{Name="UCSC";Alias="C2XX";Variable="PS_UCSC";Script="UCSC-CRG.ps1";SearchPath='Powershell (UCSC*.ps1)  | UCSC*.ps1';Instance=1},
[pscustomobject]@{Name="NX";Alias="Nexus Switch";Variable="PS_NX";Script="NX-CRG.ps1";SearchPath='Powershell (NX*.ps1) | NX*.ps1';Instance=5},
[pscustomobject]@{Name="C35";Alias="C3560";Variable="PS_C35";Script="C35K-CRG.ps1";SearchPath='Powershell (C35K*.ps1) | C35K*.ps1';Instance=1},
[pscustomobject]@{Name="C37";Alias="C3750";Variable="PS_C37";Script="C37K-CRG.ps1";SearchPath='Powershell (C37K*.ps1) | C37K*.ps1';Instance=1},
[pscustomobject]@{Name="N1K";Alias="1000v";Variable="PS_N1k";Script="N1K-CRG.ps1";SearchPath='Powershell (N1K*.ps1) | N1K*.ps1';Instance=1},
[pscustomobject]@{Name="MDS";Alias="MDS";Variable="PS_MDS";Script="MDS-CRG.ps1";SearchPath='Powershell (MDS*.ps1) | MDS*.ps1';Instance=1},
[pscustomobject]@{Name="VNXe";Alias="VNXe";Variable="PS_VNXe";Script="VNXe-CRG.ps1";SearchPath='Powershell (VNXe*.ps1) | VNXe*.ps1';Instance=1},
[pscustomobject]@{Name="VNX";Alias="VNX";Variable="PS_VNX";Script="VNX-CRG.ps1";SearchPath='Powershell (VNX-*.ps1) | VNX-*.ps1';Instance=1},
[pscustomobject]@{Name="NAS";Alias="NAS";Variable="PS_NAS";Script="NAS-CRG.ps1";SearchPath='Powershell (NAS*.ps1) | NAS*.ps1';Instance=1},
[pscustomobject]@{Name="Unity";Alias="Unity";Variable="PS_Unity";Script="Unity-CRG.ps1";SearchPath='Powershell (Unity*.ps1) | Unity*.ps1';Instance=1},
[pscustomobject]@{Name="VMAX";Alias="VMAX";Variable="PS_VMAX";Script="VMAX-CRG.ps1";SearchPath='Powershell (VMAX*.ps1) | VMAX*.ps1';Instance=1},
[pscustomobject]@{Name="VMWr";Alias="vCenter";Variable="PS_VMWr";Script="VMWR-CRG.ps1";SearchPath='Powershell (VMWr*.ps1) | VMwr*.ps1';Instance=5},
[pscustomobject]@{Name="XtremIO";Alias="XtremIO";Variable="PS_XtremIO";Script="XtremIO-CRG.ps1";SearchPath='Powershell (XtremIO*.ps1) | XtremIO*.ps1';Instance=1},
[pscustomobject]@{Name="VPLEX";Alias="VPLEX";Variable="PS_VPLEX";Script="VPLEX-CRG.ps1";SearchPath='Powershell (vplex*.ps1) | vplex*.ps1';Instance=1},
[pscustomobject]@{Name="Isilon";Alias="Isilon";Variable="PS_Isilon";Script="Isilon-CRG.ps1";SearchPath='Powershell (Isilon*.ps1) | Isilon*.ps1';Instance=1},
[pscustomobject]@{Name="NSX";Alias="NSX";Variable="PS_NSX";Script="NSX-CRG.ps1";SearchPath='Powershell (NSX*.ps1) | NSX*.ps1';Instance=1},
[pscustomobject]@{Name="IPI";Alias="IPI";Variable="PS_IPI";Script="IPI-CRG.ps1";SearchPath='Powershell (IPI*.ps1) | IPI*.ps1';Instance=1}
)

ForEach($psscript in $arraypsscripts){IF(!(get-variable $psscript.Variable -ErrorAction SilentlyContinue)){New-Variable $psscript.Variable -Scope Script}}

$arrayrpscripts = 
@([pscustomobject]@{Name="BladeSummary";Alias="Host Summary";Variable="RP_BLDSUM";Script="BladeSummary-Report.ps1";Description='Report summarizing UCS and ESXi blade information'},
[pscustomobject]@{Name="PortMap";Alias="Port Map";Variable="PS_PortMap";Script="PortMap-Report.ps1";Description='Produces PortMap output of networking switches including port configuration'},
[pscustomobject]@{Name="Version";Alias="Version";Variable="PS_Version";Script="Version-Report.ps1";Description='Produces Version output in Excel format using files from output path'},
[pscustomobject]@{Name="XtremIO";Alias="XtremIO";Variable="RP_XtremIO";Script="XtremIO-Report.ps1";Description='Produces XtremIO evaluation report based on VCE best practices'}
[pscustomobject]@{Name="Assessment";Alias="Assessment";Variable="RP_Assessment";Script="Assessment-Report.ps1";Description='Health Assessment Excel Report'}
)

ForEach($rpscript in $arrayrpscripts){IF(!(get-variable $rpscript.Variable -ErrorAction SilentlyContinue)){New-Variable $rpscript.Variable -Scope Script}}

IF(!(Test-Path "$ScriptPath\Output")){new-item "$ScriptPath\Output" -ItemType directory | Out-Null}

Import-Module "$ScriptPath\Bin\Modules\vce-vmware"
Import-Module "$ScriptPath\Bin\Modules\global-functions"
Import-Module "$ScriptPath\Bin\Modules\UCS_XMLAPI.psm1"
Import-Module "$Scriptpath\Bin\Modules\ssh-sessions"
Import-Module "$scriptPath\Bin\Modules\import-lcs"
Import-Module "$ScriptPath\Bin\Modules\crg-versions"
Import-Module "$scriptPath\Bin\Modules\crg-assessments"
Import-Module "$scriptPath\Bin\Modules\format_jsonv2"

$modVersion         = Get-Module -Name vce-vmware       | Select-Object -ExpandProperty Version
$globalVersion      = Get-Module -Name global-functions | Select-Object -ExpandProperty Version
$importlcsversion   = Get-Module -Name import-lcs       | Select-Object -ExpandProperty Version
$crgversionsversion = Get-Module -Name crg-versions     | Select-Object -ExpandProperty Version
$crgassessmentver   = Get-Module -Name crg-assessments  | Select-Object -ExpandProperty Version

# Create Icon Extractor Assembly
$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

namespace System
{
	public class IconExtractor
	{

	 public static Icon Extract(string file, int number, bool largeIcon)
	 {
	  IntPtr large;
	  IntPtr small;
	  ExtractIconEx(file, number, out large, out small, 1);
	  try
	  {
	   return Icon.FromHandle(largeIcon ? large : small);
	  }
	  catch
	  {
	   return null;
	  }

	 }
	 [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
	 private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);

	}
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing

Write-Output $about

#region Functions

Function visible-panel
{

Param([Parameter()]$Panel)

$PanelVersion.visible     = $false
$PanelSettings.visible    = $false
$PanelCredentials.visible = $false
$PanelCRG.visible         = $false
$PanelReport.visible      = $false
$PanelAssessment.visible  = $false
$panel.visible            = $true

} # End Function visible-Panel

Function create-config
{

param
(
   [switch]$defaults
)

IF($defaults)
{
    ForEach($ps_variable in $arraypsscripts)
    {
        Set-Variable -Name $ps_variable.Variable -Scope Script -Value $ps_variable.Script
    }

    ForEach($rp_variable in $arrayrpscripts)
    {
        Set-Variable -Name $rp_variable.Variable -Scope Script -Value $rp_variable.Script
    }

    $script:CHECK_PREREQS  = "true"
    $script:SCRUBDATA      = "false"
    $script:panel          = "Components"
        
    Create-ConfigFile
}

IF(-not($defaults))
{
    For($i=0;$i -lt $tabscriptsdatagrid.RowCount;$i++)
    {
        $psscript = $arraypsscripts | where-object {$_.Name -eq $tabscriptsdatagrid.Rows[$i].Cells[0].Value}
        ($arraypsscripts | where-object {$_.Name -eq $tabscriptsdatagrid.Rows[$i].Cells[0].Value}).Script = $tabscriptsdatagrid.Rows[$i].Cells[1].Value
        Set-Variable -Name $psscript.Variable -Value $tabscriptsdatagrid.Rows[$i].Cells[1].Value -Scope Script
    }

    For($i=0;$i -lt $tabreportsdatagrid.RowCount;$i++)
    {
        $psreport = $arrayrpscripts | where-object {$_.Name -eq $tabreportsdatagrid.Rows[$i].Cells[0].Value}
        ($arrayrpscripts | where-object {$_.Name -eq $tabreportsdatagrid.Rows[$i].Cells[0].Value}).Script = $tabreportsdatagrid.Rows[$i].Cells[1].Value
        Set-Variable -Name $psreport.Variable -Value $tabreportsdatagrid.Rows[$i].Cells[1].Value -Scope Script
    }

    $script:defaultregion = $modifyregiondropdown.SelectedItem.ToString()
    IF($modifyprereqcheckbox.checked -eq $true){$script:CHECK_PREREQS = "true"}ELSE{$script:CHECK_PREREQS = "false"}
    IF($scrubbdatacheckbox.checked -eq $true){$script:scrubdata = "true"}ELSE{$script:scrubdata = "false"}

    $script:panel         = $modifypanelsdropdown.SelectedItem.ToString()

    $script:prefscratchspace[0] = $modifyScratchSizeMinTextBox.Text
    $script:prefscratchspace[1] = $modifyScratchSizeMaxTextBox.Text

    Create-ConfigFile
}

} # End Function create-config

Function Create-ConfigFile
{

$configFile=@"
<?xml version="1.0"?>
<config>
    <scripts />
    <reports />
    <settings>
        <region>$defaultregion</region>
        <prereq>$CHECK_PREREQS</prereq>
        <scrub>false</scrub>
        <panel>$panel</panel>
    </settings>
</config>
"@

$xml=[xml]$configFile

ForEach($psscript in $arraypsscripts)
{
    $psvariablevalue = $psscript.Variable
    $psscriptvalue   = $psscript.Script
    
    [xml]$xmlscriptadd = "<$psvariablevalue>$psscriptvalue</$psvariablevalue>"

    $newnode = $xml.ImportNode($xmlscriptadd.DocumentElement,$true)
    $xml.SelectSingleNode('//config//scripts').AppendChild($newnode) | Out-Null
}

ForEach($psreport in $arrayrpscripts)
{
    $rpvariablevalue = $psreport.Variable
    $rpscriptvalue   = $psreport.Script
    
    [xml]$xmlscriptadd = "<$rpvariablevalue>$rpscriptvalue</$rpvariablevalue>"

    $newnode = $xml.ImportNode($xmlscriptadd.DocumentElement,$true)
    $xml.SelectSingleNode('//config//reports').AppendChild($newnode) | Out-Null
}

    $xml.save($options)

} # End Function create-ConfigFile

Function load-defaultconfig
{
    For($i=0;$i -lt $tabscriptsdatagrid.RowCount;$i++)
    {
        $psscript = ($arraypsscripts | where-object {$_.Name -eq $tabscriptsdatagrid.Rows[$i].Cells[0].Value}).Script
        $tabscriptsdatagrid.Rows[$i].Cells[1].Value = $psscript
    }

    For($i=0;$i -lt $tabreportsdatagrid.RowCount;$i++)
    {
        $psreport = ($arrayrpscripts | where-object {$_.Name -eq $tabreportsdatagrid.Rows[$i].Cells[0].Value}).Script
        $tabreportsdatagrid.Rows[$i].Cells[1].Value = $psreport
    }
    
    $panel                        = "Components"
    $modifypanelsdropdown.SelectedItem = $panel

    $region = "Standard"
    $modifyregiondropdown.SelectedItem = $region

    $modifyprereqcheckbox.checked = $true
    $scrubbdatacheckbox.checked   = $false

} # End Function load-defaultconfig

Function load-configfile
{
    [xml]$configFile = Get-Content $options

    ForEach($ps_variable1 in $arraypsscripts)
    {
        IF($configfile.config.scripts.($ps_variable1.Variable) -ne $null){$ps_variablevalue = $configfile.config.scripts.($ps_variable1.Variable)}ELSE{$ps_variablevalue = $ps_variable1.Script;Create-ConfigFile}
        Set-Variable -Name $ps_variable1.Variable -Scope Script -Value $ps_variablevalue
    }

    ForEach($rp_variable1 in $arrayrpscripts)
    {
        IF($configFile.config.reports.($rp_variable1.Variable) -ne $null){$rp_variablevalue = $configFile.config.reports.($rp_variable1.Variable)}ELSE{$rp_variablevalue = $rp_variable1.Script;Create-ConfigFile}
        Set-Variable -Name $rp_variable1.Variable -Scope Script -Value $rp_variablevalue
    }

    $SCRIPT:region        = $configfile.config.settings.region
    $SCRIPT:defaultregion = $configfile.config.settings.region
    $SCRIPT:CHECK_PREREQS = $configfile.config.settings.prereq
	$script:SCRUBDATA     = $configfile.config.settings.scrub
	$script:panel         = $configfile.config.settings.panel

} # End Function load-ConfigFile

Function set-telnet-config
{

param
(
   [switch]$defaults
)

	IF($defaults) {
		$telnetEnabled=$false
		$pythonPath="c:\python27\python.exe"
		$telnetPort=23
	}
	else {
		$telnetEnabled=$modifyenablecheckbox.checked 
		$telnetPort=$modifyPythonPortTextBox.Text
		$pythonPath=$modifyPythonPathTextBox.Text
	}	
	
	if ($telnetEnabled -eq $true) {	
		try{
			$cmdoutput=cmd /c $pythonPath --version '2>&1'
			$pythonVersion=$cmdoutput.split(" ")[1]
			$vc=$pythonVersion.split(".")
			
			if($vc[0] -ne 2 -or $vc[1] -ne 7 -or $vc[2] -lt 12) {
				write-host "    Python 2.7.12 " -noNewline	
				Write-Host "Not installed" -ForegroundColor Red
				$telnetEnabled=$false
			} ELSE {			
				write-host "    Python $pythonVersion " -noNewline			
				write-host "Installed" -ForegroundColor Green					
			}		
		}
		Catch{
			write-host "    Python 2.7.12 " -noNewline	
			Write-Host "Not installed" -ForegroundColor Red
			$telnetEnabled=$false
		}    
    }
	
	$telnetConfigFile= "$pwd\Bin\configs\telnet.config"
	$telnetConfig=@{enabled=$telnetEnabled;port=$telnetPort;pythonPath=$pythonPath} | ConvertTo-Json
	
	try 
	{
		$telnetConfig | Set-Content -path $telnetConfigFile
			
	} 
	catch {
		write-host "Error updating telnet config"
	}

}


Function modify-config
{

$tabxstart = 10
$tabystart = 10
$tabxsize  = 100
$tabysize  = 20

$modifyConfigForm      = New-Object Windows.Forms.Form
$modifyConfigForm.Size = New-Object Drawing.Size @(470,500)
$modifyConfigForm.Icon = "$ScriptPath\Bin\Icons\VCE.ico"
$modifyConfigForm.Text = "Modify Config Form"

$tabmodifyconfig = New-Object System.Windows.Forms.TabControl
$tabmodifyconfig.Location = New-Object System.Drawing.Size(0,0)
$tabmodifyconfig.Size     = New-Object System.Drawing.Size(($modifyConfigForm.Width-10),($modifyConfigForm.Height-70))
$tabmodifyconfig.Anchor   = "Right,Left,Top,Bottom"
$modifyConfigForm.Controls.Add($tabmodifyconfig)

$tabGeneral = New-Object System.Windows.Forms.TabPage
$tabGeneral.UseVisualStyleBackColor = $True
$tabGeneral.Text = "General"
$tabmodifyconfig.TabPages.Add($tabGeneral)

$tabScripts = New-Object System.Windows.Forms.TabPage
$tabScripts.AutoScroll = $true
$tabScripts.UseVisualStyleBackColor = $True
$tabScripts.Text = "Scripts"
$tabmodifyconfig.TabPages.Add($tabScripts)

$tabReports = New-Object System.Windows.Forms.TabPage
$tabReports.AutoScroll = $true
$tabReports.UseVisualStyleBackColor = $True
$tabReports.Text = "Reports"
$tabmodifyconfig.TabPages.Add($tabReports)

$tabPrefVMware = New-Object System.Windows.Forms.TabPage
$tabPrefVMware.AutoScroll = $true
$tabPrefVMware.UseVisualStyleBackColor = $True
$tabPrefVMware.Text = "VMware"
$tabmodifyconfig.TabPages.Add($tabPrefVMware)

$tabPrefTelnet = New-Object System.Windows.Forms.TabPage
$tabPrefTelnet.AutoScroll = $true
$tabPrefTelnet.UseVisualStyleBackColor = $True
$tabPrefTelnet.Text = "Telnet"
$tabmodifyconfig.TabPages.Add($tabPrefTelnet)

#region General Tab

$modifypanelslabel  = New-Object System.Windows.Forms.Label
$modifypanelslabel.Location = New-Object System.Drawing.Size($tabxstart,($tabystart))
$modifypanelslabel.size = New-Object System.Drawing.Size($tabxsize,$tabysize)
$modifypanelslabel.Text = "Default Panel"
$tabgeneral.Controls.Add($modifypanelslabel)

$modifypanelsdropdown = New-Object System.Windows.Forms.ComboBox
$modifypanelsdropdown.Location = New-Object System.Drawing.Size(130,($tabystart))
$modifypanelsdropdown.Size = New-Object System.Drawing.Size(200,20)
$tabgeneral.Controls.Add($modifypanelsdropdown)
ForEach ($item in $modifypanels){$modifypanelsdropdown.Items.Add($item) | Out-Null }
$modifypanelsdropdown.SelectedItem = $panel

$modifyregionlabel  = New-Object System.Windows.Forms.Label
$modifyregionlabel.Location = New-Object System.Drawing.Size($tabxstart,($tabystart+25))
$modifyregionlabel.size = New-Object System.Drawing.Size($tabxsize,$tabysize)
$modifyregionlabel.Text = "Default Region"
$tabgeneral.Controls.Add($modifyregionlabel)

$modifyregiondropdown = New-Object System.Windows.Forms.ComboBox
$modifyregiondropdown.Location = New-Object System.Drawing.Size(130,($tabystart+25))
$modifyregiondropdown.Size = New-Object System.Drawing.Size(200,20)
$tabgeneral.Controls.Add($modifyregiondropdown)
ForEach ($item in $modifyregions){$modifyregiondropdown.Items.Add($item) | Out-Null }
$modifyregiondropdown.SelectedItem = $defaultregion

$modifyprereqcheckbox = New-Object System.Windows.Forms.CheckBox
$modifyprereqcheckbox.location = New-Object System.Drawing.Size(130,($tabystart+50))
$modifyprereqcheckbox.size = New-Object System.Drawing.Size(200,20)
$modifyprereqcheckbox.text = "Check Prerequisites on Load"
IF($CHECK_PREREQS -eq "true"){$modifyprereqcheckbox.checked = $true}ELSE{$modifyprereqcheckbox.checked = $false}
$tabgeneral.Controls.Add($modifyprereqcheckbox)

$scrubbdatacheckbox = New-Object System.Windows.Forms.CheckBox
$scrubbdatacheckbox.location = New-Object System.Drawing.Size(130,($tabystart+70))
$scrubbdatacheckbox.size = New-Object System.Drawing.Size(200,20)
$scrubbdatacheckbox.text = "Anonymize version report"
IF($SCRUBDATA -eq "true"){$scrubbdatacheckbox.checked = $true}ELSE{$scrubbdatacheckbox.checked = $false}
$tabgeneral.Controls.Add($scrubbdatacheckbox)

#endregion General Tab

#region Tab Scripts

$tabscriptsdatagrid = New-Object System.Windows.Forms.DataGridView
$tabscriptsdatagrid.location = New-Object System.Drawing.Size(2,2)
$tabscriptsdatagrid.Size     = New-Object System.Drawing.Size(($tabScripts.Width - 5),($tabScripts.Height - 5))
$tabscriptsdatagrid.ReadOnly = $True
$tabscriptsdatagrid.AllowUserToAddRows = $false
$tabscriptsdatagrid.AllowUserToDeleteRows = $false
$tabscriptsdatagrid.Anchor = "Right,Left,Top,Bottom"
$tabScripts.Controls.Add($tabscriptsdatagrid)

$tabscriptsdatagrid.ColumnHeadersVisible = $false
$tabscriptsdatagrid.RowHeadersVisible    = $false

$tabscriptdatagridcol1 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$tabscriptdatagridcol2 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$tabscriptdatagridcol3 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$tabscriptdatagridcol4 = New-Object System.Windows.Forms.DataGridViewButtonColumn

$tabscriptdatagridcol1.Width = "130"
$tabscriptdatagridcol2.Width = "150"
$tabscriptdatagridcol3.Width = "67"
$tabscriptdatagridcol4.Width = "80"

$tabScriptsDataGrid.Columns.AddRange($tabscriptdatagridcol1,$tabscriptdatagridcol2,$tabscriptdatagridcol3,$tabscriptdatagridcol4)

ForEach($psscript in $arraypsscripts)
{
    $tabscriptsdatagrid.Rows.Add($psscript.Name,(Get-Variable -Name $psscript.Variable).Value,(& (Get-Variable -Name $psscript.Variable).Value -getversion),"Browse")
}

$tabscriptsdatagrid.add_cellclick(
{
    if($_.ColumnIndex -eq 3)
    {
        $psscriptname       = $tabscriptsdatagrid.Rows[$_.RowIndex].Cells[0].Value
        $psscriptsearchpath = ($arraypsscripts | where-object {$_.Name -eq $psscriptname}).SearchPath

        IF(($temp = Get-FileName -Name -initialdirectory "$ScriptPath\Bin\Scripts" -filetype $psscriptsearchpath) -ne "")
        {
            $tabscriptsdatagrid.Rows[$_.RowIndex].Cells[1].Value = $temp
            $tabscriptsdatagrid.Rows[$_.RowIndex].Cells[2].Value = (& $temp -getversion)
        }
    }
})

#endregion Tab Scripts

#region Tab Reports

$tabreportsdatagrid = New-Object System.Windows.Forms.DataGridView
$tabreportsdatagrid.location = New-Object System.Drawing.Size(2,2)
$tabreportsdatagrid.Size     = New-Object System.Drawing.Size(($tabreports.Width - 5),($tabreports.Height - 5))
$tabreportsdatagrid.ReadOnly = $True
$tabreportsdatagrid.AllowUserToAddRows = $false
$tabreportsdatagrid.AllowUserToDeleteRows = $false
$tabreportsdatagrid.Anchor = "Right,Left,Top,Bottom"
$tabreports.Controls.Add($tabreportsdatagrid)

$tabreportsdatagrid.ColumnHeadersVisible = $false
$tabreportsdatagrid.RowHeadersVisible    = $false

$tabreportsdatagridcol1 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$tabreportsdatagridcol2 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$tabreportsdatagridcol3 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$tabreportsdatagridcol4 = New-Object System.Windows.Forms.DataGridViewButtonColumn

$tabreportsdatagridcol1.Width = "130"
$tabreportsdatagridcol2.Width = "150"
$tabreportsdatagridcol3.Width = "67"
$tabreportsdatagridcol4.Width = "80"

$tabreportsDataGrid.Columns.AddRange($tabreportsdatagridcol1,$tabreportsdatagridcol2,$tabreportsdatagridcol3,$tabreportsdatagridcol4)

ForEach($psreport in $arrayrpscripts)
{
    $tabreportsdatagrid.Rows.Add($psreport.Name,(Get-Variable -Name $psreport.Variable).Value,(& (Get-Variable -Name $psreport.Variable).Value -getversion),"Browse")
}

$tabreportsdatagrid.add_cellclick(
{
    if($_.ColumnIndex -eq 3)
    {
        $psreportname       = $tabreportsdatagrid.Rows[$_.RowIndex].Cells[0].Value

        IF(($temp = Get-FileName -Name -initialdirectory "$ScriptPath\Bin\Reports" -filetype 'Powershell (*.ps1)  | *.ps1') -ne "")
        {
            $tabreportsdatagrid.Rows[$_.RowIndex].Cells[1].Value = $temp
            $tabreportsdatagrid.Rows[$_.RowIndex].Cells[2].Value = (& $temp -getversion)
        }
    }
})

#endregion Tab Reports

#region VMware Preferences

$modifyScratchSizeLabel = New-Object System.Windows.Forms.Label 
$modifyScratchSizeLabel.Location = New-Object System.Drawing.Size($tabxstart,($tabystart)) 
$modifyScratchSizeLabel.Size = New-Object System.Drawing.Size(400,20)
$modifyScratchSizeLabel.Text = "Scratchspace: Only datastores between these sizes will be used"
$tabPrefVMware.Controls.Add($modifyScratchSizeLabel)

$modifyScratchSizeMinLabel = New-Object System.Windows.Forms.Label
$modifyScratchSizeMinLabel.Location = New-Object System.Drawing.Size($tabxstart,($tabystart+24)) 
$modifyScratchSizeMinLabel.Size = New-Object System.Drawing.Size(150,$tabysize) 
$modifyScratchSizeMinLabel.Text = "ScratchSize Minimum (GB)"
$tabPrefVMware.Controls.Add($modifyScratchSizeMinLabel)

$modifyScratchSizeMinTextBox = New-Object System.Windows.Forms.TextBox 
$modifyScratchSizeMinTextBox.Location = New-Object System.Drawing.Size(160,($tabystart+22)) 
$modifyScratchSizeMinTextBox.Size = New-Object System.Drawing.Size(50,20)
$modifyScratchSizeMinTextBox.Text = $prefscratchspace[0]
$tabPrefVMware.Controls.Add($modifyScratchSizeMinTextBox)

$modifyScratchSizeMaxLabel = New-Object System.Windows.Forms.Label
$modifyScratchSizeMaxLabel.Location = New-Object System.Drawing.Size(220,($tabystart+24)) 
$modifyScratchSizeMaxLabel.Size = New-Object System.Drawing.Size(150,$tabysize) 
$modifyScratchSizeMaxLabel.Text = "ScratchSize Maximum (GB)"
$tabPrefVMware.Controls.Add($modifyScratchSizeMaxLabel)

$modifyScratchSizeMaxTextBox = New-Object System.Windows.Forms.TextBox 
$modifyScratchSizeMaxTextBox.Location = New-Object System.Drawing.Size(380,($tabystart+22)) 
$modifyScratchSizeMaxTextBox.Size = New-Object System.Drawing.Size(50,20)
$modifyScratchSizeMaxTextBox.Text = $prefscratchspace[1]
$tabPrefVMware.Controls.Add($modifyScratchSizeMaxTextBox)

#endregion VMware Preferences

#region Telnet Preferences

$telnetEnabled=$false
$pythonPath="c:\python27\python.exe"
$telnetPort=23
Try{
	$telnetConfigFile= "$pwd\Bin\configs\telnet.config"
	IF(Test-Path $telnetConfigFile) {
		$telnet=ConvertFrom-Json (gc $telnetConfigFile -raw)
		IF($telnet.enabled -eq $TRUE) {
			$telnetEnabled=$true
			$pythonPath=$telnet.pythonPath
			$telnetPort=$telnet.port			
		}
    }
}
Catch{}

$modifyenablecheckbox = New-Object System.Windows.Forms.CheckBox
$modifyenablecheckbox.location = New-Object System.Drawing.Size($tabystart,($tabystart+10))
$modifyenablecheckbox.size = New-Object System.Drawing.Size(300,20)
$modifyenablecheckbox.text = "Enable use of telnet where applicable"
$modifyenablecheckbox.checked = $telnetEnabled
$tabPrefTelnet.Controls.Add($modifyenablecheckbox)

$modifyPythonPortLabel = New-Object System.Windows.Forms.Label
$modifyPythonPortLabel.Location = New-Object System.Drawing.Size($tabystart,($tabystart+40)) 
$modifyPythonPortLabel.Size = New-Object System.Drawing.Size(80,20) 
$modifyPythonPortLabel.Text = "Telnet Port:"
$tabPrefTelnet.Controls.Add($modifyPythonPortLabel)

$modifyPythonPortTextBox = New-Object System.Windows.Forms.TextBox 
$modifyPythonPortTextBox.Location = New-Object System.Drawing.Size(90, 45)
$modifyPythonPortTextBox.Size = New-Object System.Drawing.Size(30,60)
$modifyPythonPortTextBox.Text = $telnetPort
$tabPrefTelnet.Controls.Add($modifyPythonPortTextBox)

$modifyPythonPathLabel = New-Object System.Windows.Forms.Label
$modifyPythonPathLabel.Location = New-Object System.Drawing.Size($tabystart,($tabystart+68)) 
$modifyPythonPathLabel.Size = New-Object System.Drawing.Size(300,20) 
$modifyPythonPathLabel.Text = "Path of Python executable:"
$tabPrefTelnet.Controls.Add($modifyPythonPathLabel)

$modifyPythonPathTextBox = New-Object System.Windows.Forms.TextBox 
$modifyPythonPathTextBox.Location = New-Object System.Drawing.Size($tabystart,($tabystart+88)) 
$modifyPythonPathTextBox.Size = New-Object System.Drawing.Size(300,20)
$modifyPythonPathTextBox.Text = $pythonPath
$tabPrefTelnet.Controls.Add($modifyPythonPathTextBox)


#endregion Telnet Preferences

# Button Area

$buttonPanel = New-Object Windows.Forms.Panel
$buttonPanel.Size = New-Object Drawing.Size @(300,30)
$buttonPanel.Dock = "Bottom"
$modifyConfigForm.Controls.Add($buttonPanel)

$cancelButton = New-Object Windows.Forms.Button
$cancelButton.Text = "Close"
$cancelButton.DialogResult = "Cancel"
$cancelButton.Top = $buttonPanel.Height - $cancelButton.Height - 5
$cancelButton.Left = $buttonPanel.Width - $cancelButton.Width - 10
$cancelButton.Anchor = "Right"
$buttonPanel.Controls.Add($cancelButton)

$saveButton = New-Object Windows.Forms.Button
$saveButton.Text = "Save"
$saveButton.Top = $cancelButton.Top
$saveButton.Left = $cancelButton.Left - $saveButton.Width - 5
$saveButton.Anchor = "Right"
$buttonPanel.Controls.Add($saveButton)
$saveButton.Add_Click({ $script:region = $modifyregiondropdown.SelectedItem.ToString()
                        create-config
                        write-host "Configuration Saved"
                        $status.text = "Configuration Saved"				
						set-telnet-config												
                        $modifyconfigform.close()
                      })

$defaultButton = New-Object Windows.Forms.Button
$defaultButton.Text = "Default"
$defaultButton.Top  = $cancelButton.Top
$defaultButton.Left = $cancelButton.Left - $saveButton.Width - $defaultButton.Width - 10
$defaultButton.Anchor = "Right"
$buttonPanel.Controls.Add($defaultButton)
$defaultButton.Add_Click({
							load-defaultconfig
							
							$modifyenablecheckbox.checked =$false
							$modifyPythonPortTextBox.Text=23
							$modifyPythonPathTextBox.Text="c:\python27\python.exe"							
						})

# Load Form

$ModifyConfigForm.CancelButton = $cancelButton
$modifyConfigForm.Add_Shown( { $modifyConfigForm.Activate() } )

$result = $modifyConfigForm.ShowDialog()

} # End Modify-config

Function new-config
{

# Header

IF($CompanyTextBox.text -ne ""){$CompanyTextBox.text = ""}
IF($SystemNameTextBox.text -ne ""){$SystemNameTextBox.text = ""}
IF($SerialNumberTextBox.text -ne ""){$SerialNumberTextBox.text = ""}
IF($OutputTextBox.text -ne $outputpath){$OutputTextBox.Text = $outputpath}

# Compute

$C2XXIP1TextBox.text = ""
$C2XXIP2TextBox.text = ""
$C2XXDefaultCheckBox.Checked = $True

$UCS1IP1TextBox.text = ""
$UCS1DefaultCheckBox.Checked = $True

$UCS2IP1TextBox.text = ""
$UCS2DefaultCheckBox.Checked = $True

$UCS3IP1TextBox.text = ""
$UCS3DefaultCheckBox.Checked = $True

$UCS4IP1TextBox.text = ""
$UCS4DefaultCheckBox.Checked = $True

$UCS5IP1TextBox.text = ""
$UCS5DefaultCheckBox.Checked = $True

# Network

$3560IP1TextBox.text = ""
$3560IP2TextBox.text = ""
$3560DefaultCheckBox.Checked = $True

$3750IP1TextBox.text = ""
$3750DefaultCheckBox.Checked = $True

$3048IP1TextBox.text = ""
$3048IP2TextBox.text = ""
$3048DefaultCheckBox.Checked = $True

$55XXIP1TextBox.text = ""
$55XXIP2TextBox.text = ""
$55XXDefaultCheckBox.Checked = $True

$55XX2IP1TextBox.text = ""
$55XX2IP2TextBox.text = ""
$55XXDefaultCheckBox.Checked = $True

$55XX3IP1TextBox.text = ""
$55XX3IP2TextBox.text = ""
$55XX3DefaultCheckBox.Checked = $True

$1000IP1TextBox.text = ""
$1000DefaultCheckBox.Checked = $True

$MDSIP1TextBox.text = ""
$MDSIP2TextBox.text = ""
$MDSDefaultCheckBox.Checked = $True

$N7KIP1TextBox.text = ""
$N7KIP2TextBox.text = ""
$N7KDefaultCheckBox.Checked = $True

# Storage

$VNXeIP1TextBox.text = ""
$VNXeDefaultCheckBox.Checked = $True

$VNXIP1TextBox.text = ""
$VNXDefaultCheckBox.Checked = $True

$NASIP1TextBox.text = ""
$NASDefaultCheckBox.Checked = $True

$UnityIP1TextBox.text = ""
$UnityDefaultCheckBox.Checked = $True

$XtremIOIP1TextBox.text = ""
$XtremIODefaultCheckBox.Checked = $True

$VPLEXIP1TextBox.text = ""
$VPLEXIP2TextBox.text = ""
$VPLEXDefaultCheckBox.Checked = $True

$IsilonIP1TextBox.text = ""
$IsilonDefaultCheckBox.Checked = $True

# VMware

$vCenter1TextBox.text = ""
$VC1DefaultCheckBox.Checked = $True

$vCenter2TextBox.text = ""
$VC2DefaultCheckBox.Checked = $True

$vCenter3TextBox.text = ""
$VC3DefaultCheckBox.Checked = $True

$vCenter4TextBox.text = ""
$VC4DefaultCheckBox.Checked = $True

$vCenter5TextBox.text = ""
$VC5DefaultCheckBox.Checked = $True

$NSXIPTextBox.text = ""
$NSXDefaultCheckBox.Checked = $True

# Misc

$IPIIP1TextBox.text = ""
$IPIIP2TextBox.text = ""
$IPIDefaultCheckBox.Checked = $True

IF($esxiuserTextBox.Text -ne "root"){$esxiuserTextBox.Text = "root"}
IF($esxiPassTextBox.Text -ne ""){$esxiPassTextBox.Text = ""}

# Offline TextBoxes

For($i=0;$i -lt $tabCRGOfflinedatagrid.RowCount;$i++)
{
    $tabCRGOfflinedatagrid.Rows[$i].Cells[2].Value = ""
}

# Settings

IF($dns1TextBox.text -ne ""){$dns1TextBox.text = ""}
IF($dns2TextBox.text -ne ""){$dns2TextBox.text = ""}
IF($ntp1TextBox.text -ne ""){$ntp1TextBox.text = ""}
IF($ntp2TextBox.text -ne ""){$ntp2TextBox.text = ""}
IF($ntp3TextBox.text -ne ""){$ntp3TextBox.text = ""}
IF($community1TextBox.text -ne ""){$community1TextBox.text = ""}
IF($community2TextBox.text -ne ""){$community2TextBox.text = ""}
IF($community3TextBox.text -ne ""){$community3TextBox.text = ""}
IF($target1TextBox.text -ne ""){$target1TextBox.text = ""}
IF($target2TextBox.text -ne ""){$target2TextBox.text = ""}
IF($target3TextBox.text -ne ""){$target3TextBox.text = ""}
IF($snmpport1TextBox.text -ne ""){$snmpport1TextBox.text = ""}
IF($snmpport2TextBox.text -ne ""){$snmpport2TextBox.text = ""}
IF($snmpport3TextBox.text -ne ""){$snmpport3TextBox.text = ""}
IF($syslog1TextBox.text -ne ""){$syslog1TextBox.text = ""}
IF($syslog2TextBox.text -ne ""){$syslog2TextBox.text = ""}
IF($syslog3TextBox.text -ne ""){$syslog3TextBox.text = ""}
IF($domainTextBox.text -ne ""){$domainTextBox.text = ""}
IF($configfile -ne "untitled"){$configfile = "untitled"; $objform.text = $objformtitle + " - Unsaved"}
IF($status.Text -ne ""){$status.Text = ""}

clear-checkboxes

$dropdownsystype.SelectedItem = "System Type"
$credsGridView.rows.Clear()
$versionGridView1.rows.Clear()
$versionGridView2.rows.Clear()
$versionGridView3.rows.Clear()
$assessmentGridView.rows.Clear()

} # End New Config

Function save-config
{

[cmdletbinding()]

param
(
    [switch]$saveas
)

IF($configfile -eq "untitled"){$saveas = $true}
Else{$Filename = $configfile}

IF($saveas){$Filename = save-FileName -initialdirectory $OutputTextBox.Text -filetype "XML (*.xml) | *.xml" }

IF($Filename -ne "")
{
    [xml]$xml = get-content "$scriptpath\bin\Configs\xmloutput_default.xml"
    $xml.config.Global_Stuff.Company      = $CompanyTextBox.Text
    $xml.config.Global_Stuff.SystemName   = $SystemNameTextBox.text
    $xml.config.Global_Stuff.SystemType   = $dropdownsystype.SelectedItem.ToString()
    $xml.config.Global_Stuff.SystemRCM    = $dropdownrcm.SelectedItem.ToString()
    IF($vercustRadio.Checked){$xml.config.Global_Stuff.RCMtype = "Original"}
    ELSEIF($veraddenradio.Checked){$xml.config.Global_Stuff.RCMtype = "Addendum"}
    $xml.config.Global_Stuff.SerialNumber = $SerialNumberTextBox.text
    $xml.config.Global_Stuff.Output       = ($OutputTextBox.Text).replace($outputpath,"")
    $xml.config.Global_Stuff.Region       = $region

  # Compute

  IF($C2XXIP2TextBox.Text -ne ""){$ipaddresses = $C2XXIP1TextBox.Text + "," + $C2XXIP2TextBox.Text}ELSE{$ipaddresses = $C2XXIP1TextBox.Text}
  IF($C2XXRangeCheckBox.Checked -eq $true){$c2xxrange = "True"}ELSEIF($C2XXRangeCheckbox.checked -eq $false){$c2xxrange = "False"}
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C2XX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "UCSC-1" -type "UCSC" -description "AMP Hosts" -defaultcred $C2XXDefaultCheckBox.Checked -ipaddress $ipaddresses -option $c2xxrange -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 1" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "UCSB-1" -type "UCSB" -description "UCS Domain" -defaultcred $UCS1DefaultCheckBox.Checked -ipaddress $UCS1IP1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 2" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "UCSB-2" -type "UCSB" -description "UCS Domain" -defaultcred $UCS2DefaultCheckBox.Checked -ipaddress $UCS2IP1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 3" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "UCSB-3" -type "UCSB" -description "UCS Domain" -defaultcred $UCS3DefaultCheckBox.Checked -ipaddress $UCS3IP1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 4" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "UCSB-4" -type "UCSB" -description "UCS Domain" -defaultcred $UCS4DefaultCheckBox.Checked -ipaddress $UCS4IP1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 5" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "UCSB-5" -type "UCSB" -description "UCS Domain" -defaultcred $UCS5DefaultCheckBox.Checked -ipaddress $UCS5IP1TextBox.Text -xmloutput $xml -data $offlinefile

  # Networking
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C3560" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  IF($3560IP2TextBox.Text -ne ""){$ipaddresses = $3560IP1TextBox.Text + "," + $3560IP2TextBox.Text}ELSE{$ipaddresses = $3560IP1TextBox.Text}
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "C3560-1" -type "c35" -description "Managemnt" -defaultcred $3560DefaultCheckBox.Checked -ipaddress $ipaddresses -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C3750" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "C3750-1" -type "c37" -description "Managemnt" -defaultcred $3750DefaultCheckBox.Checked -ipaddress $3750IP1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Management" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  IF($3048IP2TextBox.Text -ne ""){$ipaddresses = $3048IP1TextBox.Text + "," + $3048IP2TextBox.Text}ELSE{$ipaddresses = $3048IP1TextBox.Text}
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "NX-1" -type "nx"  -description "Managemnt" -defaultcred $3048DefaultCheckBox.Checked -ipaddress $ipaddresses -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Aggregate" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  IF($55XXIP2TextBox.Text -ne ""){$ipaddresses = $55XXIP1TextBox.Text + "," + $55XXIP2TextBox.Text}ELSE{$ipaddresses = $55XXIP1TextBox.Text}
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "NX-2" -type "nx"  -description "Aggregate" -defaultcred $55XXDefaultCheckBox.Checked -ipaddress $ipaddresses -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus BRS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  IF($55XX2IP2TextBox.Text -ne ""){$ipaddresses = $55XX2IP1TextBox.Text + "," + $55XX2IP2TextBox.Text}ELSE{$ipaddresses = $55XX2IP1TextBox.Text}
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "NX-3" -type "nx"  -description "BRS"       -defaultcred $55XX2DefaultCheckBox.Checked -ipaddress $ipaddresses -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Isilon" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  IF($55XX3IP2TextBox.Text -ne ""){$ipaddresses = $55XX3IP1TextBox.Text + "," + $55XX3IP2TextBox.Text}ELSE{$ipaddresses = $55XX3IP1TextBox.Text}
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "NX-4" -type "nx"  -description "Isilon"    -defaultcred $55XX3DefaultCheckBox.Checked -ipaddress $ipaddresses -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "1000v" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "N1K-1" -type "n1k"   -description ""     -defaultcred $1000DefaultCheckBox.Checked -ipaddress $1000IP1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "MDS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  IF($MDSIP2TextBox.Text -ne ""){$ipaddresses = $MDSIP1TextBox.Text + "," + $MDSIP2TextBox.Text}ELSE{$ipaddresses = $MDSIP1TextBox.Text}
  add-component -name "MDS-1" -type "mds" -description ""       -defaultcred $MDSDefaultCheckBox.Checked -ipaddress $ipaddresses -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Core" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  IF($N7KIP2TextBox.Text  -ne ""){$ipaddresses = $N7KIP1TextBox.Text + "," + $N7KIP2TextBox.Text }ELSE{$ipaddresses = $N7KIP1TextBox.Text}
  add-component -name "NX-5" -type "nx"  -description "Core"      -defaultcred $N7KDefaultCheckBox.Checked -ipaddress $ipaddresses -xmloutput $xml -data $offlinefile

  # Storage

  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VNXe" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "VNXe-1"    -type "vnxe"    -description ""     -defaultcred $VNXeDefaultCheckBox.Checked -ipaddress $VNXeIP1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VNX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "VNX-1"     -type "vnx"     -description ""     -defaultcred $VNXDefaultCheckBox.Checked -ipaddress $VNXIP1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "NAS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "NAS-1"     -type "nas"     -description ""     -defaultcred $NASDefaultCheckBox.Checked -ipaddress $NASIP1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Unity" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "Unity-1"    -type "unity"    -description ""     -defaultcred $UnityDefaultCheckBox.Checked -ipaddress $UnityIP1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "XtremIO" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "XtremIO-1" -type "xtremio" -description ""     -defaultcred $XtremIODefaultCheckBox.Checked -ipaddress $XtremIOIP1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VPLEX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  IF($VPLEXIP2TextBox.Text  -ne ""){$ipaddresses = $VPLEXIP1TextBox.Text + "," + $VPLEXIP2TextBox.Text}ELSE{$ipaddresses = $VPLEXIP1TextBox.Text}
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "VPLEX-1"   -type "vplex"  -description ""     -defaultcred $VPLEXDefaultCheckBox.Checked -ipaddress $ipaddresses -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Isilon" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "Isilon-1"  -type "isilon" -description ""     -defaultcred $IsilonDefaultCheckBox.Checked -ipaddress $IsilonIP1TextBox.Text -xmloutput $xml -data $offlinefile

  # VMware

  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 1" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "vCenter-1" -type "vmware" -description "vCenter 1" -defaultcred $VC1DefaultCheckBox.Checked -ipaddress $vCenter1TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 2" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "vCenter-2" -type "vmware" -description "vCenter 2" -defaultcred $VC2DefaultCheckBox.Checked -ipaddress $vCenter2TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 3" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "vCenter-3" -type "vmware" -description "vCenter 3" -defaultcred $VC3DefaultCheckBox.Checked -ipaddress $vCenter3TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 4" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "vCenter-4" -type "vmware" -description "vCenter 4" -defaultcred $VC4DefaultCheckBox.Checked -ipaddress $vCenter4TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 5" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "vCenter-5" -type "vmware" -description "vCenter 5" -defaultcred $VC5DefaultCheckBox.Checked -ipaddress $vCenter5TextBox.Text -xmloutput $xml -data $offlinefile
  
  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "NSX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "NSX-1"     -type "nsx"    -description "NSX 1"     -defaultcred $NSXDefaultCheckBox.Checked -ipaddress $NSXIPTextBox.Text    -xmloutput $xml -data $offlinefile

  # Misc

  $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "IPI" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
  IF($IPIIP1TextBox.Text -ne ""){$ipaddresses = $IPIIP1TextBox.Text + "," + $IPIIP2TextBox.Text}ELSE{$ipaddresses = $IPIIP1TextBox.Text}
  IF($IPIRangeCheckBox.Checked -eq $true){$ipirange = "True"}ELSEIF($IPIRangeCheckBox.Checked -eq $false){$ipirange = "False"}
  $offlinefile = IF(($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).StartsWith($OutputTextBox.Text)){($tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value).Replace($OutputTextBox.Text,"")}ELSE{""}
  add-component -name "IPI-1"     -type "ipi"    -description "IPI 1"     -defaultcred $IPIDefaultCheckBox.Checked -ipaddress $ipaddresses -option $ipirange -xmloutput $xml -data $offlinefile

  # Settings

  $xml.config.Settings.primarydns=$dns1TextBox.Text
  $xml.config.Settings.secondarydns=$dns2TextBox.Text
  $xml.config.Settings.domainname=$domainTextBox.text
  $xml.config.Settings.ntp1=$ntp1TextBox.Text
  $xml.config.Settings.ntp2=$ntp2TextBox.Text
  $xml.config.Settings.ntp3=$ntp3TextBox.Text
  $xml.config.Settings.syslog1=$syslog1TextBox.Text
  $xml.config.Settings.syslog2=$syslog2TextBox.Text
  $xml.config.Settings.syslog3=$syslog3TextBox.Text
  $xml.config.Settings.community1=$community1TextBox.Text
  $xml.config.Settings.target1=$target1TextBox.Text
  $xml.config.Settings.snmpport1=$snmpport1TextBox.Text
  $xml.config.Settings.community2=$community2TextBox.Text
  $xml.config.Settings.target2=$target2TextBox.Text
  $xml.config.Settings.snmpport2=$snmpport2TextBox.Text
  $xml.config.Settings.community3=$community3TextBox.Text
  $xml.config.Settings.target3=$target3TextBox.Text
  $xml.config.Settings.snmpport3=$snmpport3TextBox.Text

  $xml.save($filename)

  $script:configfile = $Filename
  $objform.text = $objformtitle + " - $Filename"
  $status.text = "Completed Save to $Filename"

} # End IF Statement

Else {$status.Text = "Cancelled Save"}

} # End of Save-Config

Function load-config
{

[cmdletbinding()]

Param(
    $SystemConfigFile
)

IF($SystemConfigFile -eq $null)
{
    $SystemConfigFile = Get-FileName -InitialDirectory $OutputTextBox.Text -filetype "XML (*.xml) | *.xml"
}

IF($SystemConfigFile -ne "")
{

new-config

[xml]$loaddata = Get-Content $SystemConfigFile

If($loaddata.config.Global_Stuff.configversion -eq $null){$configversion = "1.0"}ELSE{$configversion = $loaddata.config.Global_Stuff.configversion}

IF($configversion -ge "2.0")
{

# Global Stuff
    
    $script:region                = $loaddata.config.Global_Stuff.Region
    $regiondropdown.SelectedItem  = $region
    $script:password              = $regions.item($region)
    $script:passwordsso           = $regions.item($region)
    $SerialNumberTextBox.text     = $loaddata.config.Global_Stuff.SerialNumber 
    $CompanyTextBox.Text          = $loaddata.config.Global_Stuff.Company
    $OutputTextBox.Text           = $outputpath + $loaddata.config.Global_Stuff.Output
    $SystemNameTextBox.Text       = $loaddata.config.Global_Stuff.SystemName
    $dropdownsystype.SelectedItem = $loaddata.config.Global_Stuff.SystemType
    $dropdownrcm.SelectedItem     = $loaddata.config.Global_Stuff.SystemRCM

    IF($loaddata.config.Global_Stuff.RCMtype -eq "Original"){$vercustRadio.Checked = $true}
    ELSEIF($loaddata.config.Global_Stuff.RCMtype -eq "Addendum"){$veraddenRadio.Checked = $true}

# Compute
    
    $C2XXIP1TextBox.text  = $loaddata.config.data.components."UCSC-1".primary.ipaddress
    $C2XXIP2TextBox.text  = $loaddata.config.data.components."UCSC-1".secondary.ipaddress
    $C2XXRangeCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."UCSC-1".option))
    $C2XXDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."UCSC-1".defaultcred))
    IF(!$C2XXDefaultCheckBox.Checked){$C2XXpassTextBox.text = ""}
    IF($loaddata.config.data.components."UCSC-1".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."UCSC-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C2XX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."UCSC-1".data
    }
    
    $UCS1IP1TextBox.text  = $loaddata.config.data.components."UCSB-1".primary.ipaddress
    $UCS1DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."UCSB-1".defaultcred))
    IF(!$UCS1DefaultCheckBox.Checked){$UCS1passTextBox.Text = ""}
    IF($loaddata.config.data.components."UCSB-1".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."UCSB-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 1" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."UCSB-1".data
    }

    $UCS2IP1TextBox.text  = $loaddata.config.data.components."UCSB-2".primary.ipaddress
    $UCS2DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."UCSB-2".defaultcred))
    IF(!$UCS2DefaultCheckBox.Checked){$UCS2passTextBox.Text = ""}
    IF($loaddata.config.data.components."UCSB-2".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."UCSB-2".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 2" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."UCSB-2".data
    }
    
    $UCS3IP1TextBox.text  = $loaddata.config.data.components."UCSB-3".primary.ipaddress
    $UCS3DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."UCSB-3".defaultcred))
    IF(!$UCS3DefaultCheckBox.Checked){$UCS3passTextBox.Text = ""}    
    IF($loaddata.config.data.components."UCSB-3".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."UCSB-3".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 3" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."UCSB-3".data
    }

    $UCS4IP1TextBox.text  = $loaddata.config.data.components."UCSB-4".primary.ipaddress
    $UCS4DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."UCSB-4".defaultcred))
    IF(!$UCS4DefaultCheckBox.Checked){$UCS4passTextBox.Text = ""}    
    IF($loaddata.config.data.components."UCSB-4".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."UCSB-4".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 4" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."UCSB-4".data
    }

    $UCS5IP1TextBox.text  = $loaddata.config.data.components."UCSB-5".primary.ipaddress
    $UCS5DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."UCSB-5".defaultcred))
    IF(!$UCS5DefaultCheckBox.Checked){$UCS5passTextBox.Text = ""}
    IF($loaddata.config.data.components."UCSB-5".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."UCSB-5".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 5" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."UCSB-5".data
    }

# Networking

    $3560IP1TextBox.text   = $loaddata.config.data.components."C3560-1".primary.ipaddress
    $3560IP2TextBox.text   = $loaddata.config.data.components."C3560-1".secondary.ipaddress
    $3560DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."C3560-1".defaultcred))
    IF(!$3560DefaultCheckBox.Checked){$3560passTextBox.Text = ""}
    IF($loaddata.config.data.components."C3560-1".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."C3560-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C3560" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."C3560-1".data
    }
    
    $3750IP1TextBox.text   = $loaddata.config.data.components."C3750-1".primary.ipaddress
    $3750DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."C3750-1".defaultcred))
    IF(!$3750DefaultCheckBox.Checked){$3750passTextBox.Text = ""}
    IF($loaddata.config.data.components."C3750-1".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."C3750-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C3750" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."C3750-1".data
    }
        
    $3048IP1TextBox.text   = $loaddata.config.data.components."NX-1".primary.ipaddress
    $3048IP2TextBox.text   = $loaddata.config.data.components."NX-1".secondary.ipaddress
    $3048DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."NX-1".defaultcred))
    IF(!$3048DefaultCheckBox.Checked){$3048passTextBox.Text = ""}
    IF($loaddata.config.data.components."NX-1".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."NX-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Management" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."NX-1".data
    }

    $55XXIP1TextBox.text   = $loaddata.config.data.components."NX-2".primary.ipaddress
    $55XXIP2TextBox.text   = $loaddata.config.data.components."NX-2".secondary.ipaddress
    $55XXDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."NX-2".defaultcred))
    IF(!$55XXDefaultCheckBox.Checked){$55XXpassTextBox.Text = ""}
    IF($loaddata.config.data.components."NX-2".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."NX-2".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Aggregate" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."NX-2".data
    }
    
    $55XX2IP1TextBox.text  = $loaddata.config.data.components."NX-3".primary.ipaddress
    $55XX2IP2TextBox.text  = $loaddata.config.data.components."NX-3".secondary.ipaddress
    $55XX2DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."NX-3".defaultcred))
    IF(!$55XX2DefaultCheckBox.Checked){$55XX2passTextBox.Text = ""}
    IF($loaddata.config.data.components."NX-3".data -ne "")
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus BRS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."NX-3".data
    }

    $55XX3IP1TextBox.text  = $loaddata.config.data.components."NX-4".primary.ipaddress
    $55XX3IP2TextBox.text  = $loaddata.config.data.components."NX-4".secondary.ipaddress
    $55XX3DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."NX-4".defaultcred))
    IF(!$55XX3DefaultCheckBox.Checked){$55XX3passTextBox.Text = ""}
    IF($loaddata.config.data.components."NX-4".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."NX-4".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Isilon" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."NX-4".data
    }
    
    $1000IP1TextBox.text   = $loaddata.config.data.components."N1K-1".primary.ipaddress
    $1000DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."N1K-1".defaultcred))
    IF(!$1000DefaultCheckBox.Checked){$1000passTextBox.Text = ""}
    IF($loaddata.config.data.components."N1K-1".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."N1K-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "1000v" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."N1K-1".data
    }

    $MDSIP1TextBox.text    = $loaddata.config.data.components."MDS-1".primary.ipaddress
    $MDSIP2TextBox.text    = $loaddata.config.data.components."MDS-1".secondary.ipaddress
    $MDSDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."MDS-1".defaultcred))
    IF(!$MDSDefaultCheckBox.Checked){$MDSpassTextBox.Text = ""}
    IF($loaddata.config.data.components."MDS-1".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."MDS-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "MDS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."MDS-1".data
    }
    
    $N7KIP1TextBox.Text    = $loaddata.config.data.components."NX-5".primary.ipaddress
    $N7KIP2TextBox.Text    = $loaddata.config.data.components."NX-5".secondary.ipaddress
    $N7KDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."NX-5".defaultcred))
    IF(!$N7KDefaultCheckBox.Checked){$N7KpassTextBox.Text = ""}
    IF($loaddata.config.data.components."NX-5".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."NX-5".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Core" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."NX-5".data
    }

# Storage

    $VNXeIP1TextBox.Text    = $loaddata.config.data.components."VNXe-1".primary.ipaddress
    $VNXeDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."VNXe-1".defaultcred))
    IF(!$VNXeDefaultCheckBox.Checked){$VNXepassTextBox.Text = ""}
    IF($loaddata.config.data.components."VNXe-1".data -ne "" -and (test-path ($OutputTextBox.Text + $loaddata.config.data.components."VNXe-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VNXe" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."VNXe-1".data
    }

    $VNXIP1TextBox.Text     = $loaddata.config.data.components."VNX-1".primary.ipaddress
    $VNXDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."VNX-1".defaultcred))
    IF(!$VNXDefaultCheckBox.Checked){$VNXpassTextBox.Text = ""}
    IF($loaddata.config.data.components."VNX-1".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."VNX-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VNX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."VNX-1".data
    }
    
    $NASIP1TextBox.Text     = $loaddata.config.data.components."NAS-1".primary.ipaddress
    $NASDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."NAS-1".defaultcred))
    IF(!$NASDefaultCheckBox.Checked){$NASpassTextBox.Text = ""}
    IF($loaddata.config.data.components."NAS-1".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."NAS-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "NAS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."NAS-1".data
    }
	
	$UnityIP1TextBox.Text    = $loaddata.config.data.components."Unity-1".primary.ipaddress
    $UnityDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."Unity-1".defaultcred))
    IF(!$UnityDefaultCheckBox.Checked){$UnitypassTextBox.Text = ""}
    IF($loaddata.config.data.components."Unity-1".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."Unity-1".data)) -and $loaddata.config.data.components."Unity-1".data -ne $null)
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Unity" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."Unity-1".data
    }
    
    $XtremIOIP1TextBox.Text = $loaddata.config.data.components."XtremIO-1".primary.ipaddress
    $XtremIODefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."XtremIO-1".defaultcred))
    IF(!$XtremIODefaultCheckBox.Checked){$XtremIOpassTextBox.Text = ""}
    IF($loaddata.config.data.components."XtremIO-1".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."XtremIO-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "XtremIO" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."XtremIO-1".data
    }
    
    $VPLEXIP1TextBox.Text   = $loaddata.config.data.components."VPLEX-1".primary.ipaddress
    $VPLEXIP2TextBox.Text   = $loaddata.config.data.components."VPLEX-1".secondary.ipaddress
    $VPLEXDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."VPLEX-1".defaultcred))
    IF(!$VPLEXDefaultCheckBox.Checked){$VPLEXpassTextBox.Text = ""}
    IF($loaddata.config.data.components."VPLEX-1".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."VPLEX-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VPLEX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."VPLEX-1".data
    }
    
    $IsilonIP1TextBox.Text  = $loaddata.config.data.components."Isilon-1".primary.ipaddress
    $IsilonDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."Isilon-1".defaultcred))
    IF(!$IsilonDefaultCheckBox.Checked){$IsilonpassTextBox.Text = ""}
    IF($loaddata.config.data.components."Isilon-1".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."Isilon-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Isilon" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."Isilon-1".data
    }

# VMware

    $vCenter1TextBox.text  = $loaddata.config.data.components."vCenter-1".primary.ipaddress
    $VC1DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."vCenter-1".defaultcred))
    IF(!$VC1DefaultCheckBox.Checked){$vc1passwordTextBox.Text = ""}
    IF($loaddata.config.data.components."vCenter-1".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."vCenter-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 1" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."vCenter-1".data
    }
    
    $vCenter2TextBox.text  = $loaddata.config.data.components."vCenter-2".primary.ipaddress
    $VC2DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."vCenter-2".defaultcred))
    IF(!$VC2DefaultCheckBox.Checked){$vc2passwordTextBox.Text = ""}
    IF($loaddata.config.data.components."vCenter-2".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."vCenter-2".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 2" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."vCenter-2".data
    }
    
    $vCenter3TextBox.text  = $loaddata.config.data.components."vCenter-3".primary.ipaddress
    $VC3DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."vCenter-3".defaultcred))
    IF(!$VC3DefaultCheckBox.Checked){$vc3passwordTextBox.Text = ""}
    IF($loaddata.config.data.components."vCenter-3".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."vCenter-3".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 3" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."vCenter-3".data
    }

    $vCenter4TextBox.text  = $loaddata.config.data.components."vCenter-4".primary.ipaddress
    $VC4DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."vCenter-4".defaultcred))
    IF(!$VC4DefaultCheckBox.Checked){$vc4passwordTextBox.Text = ""}
    IF($loaddata.config.data.components."vCenter-4".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."vCenter-4".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 4" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."vCenter-4".data
    }

    $vCenter5TextBox.text  = $loaddata.config.data.components."vCenter-5".primary.ipaddress
    $VC5DefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."vCenter-5".defaultcred))
    IF(!$VC5DefaultCheckBox.Checked){$vc5passwordTextBox.Text = ""}
    IF($loaddata.config.data.components."vCenter-5".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."vCenter-5".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 5" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."vCenter-5".data
    }

    $NSXIPTextBox.text  = $loaddata.config.data.components."NSX-1".primary.ipaddress
    $NSXDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."NSX-1".defaultcred))
    IF(!$NSXDefaultCheckBox.Checked){$NSXpasswordTextBox.Text = ""}
    IF($loaddata.config.data.components."NSX-1".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."NSX-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "NSX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."NSX-1".data
    }

# MISC

    $IPIIP1TextBox.text  = $loaddata.config.data.components."IPI-1".primary.ipaddress
    $IPIIP2TextBox.text  = $loaddata.config.data.components."IPI-1".secondary.ipaddress
    $IPIDefaultCheckBox.Checked = ([System.Convert]::ToBoolean($loaddata.config.data.components."IPI-1".defaultcred))
    IF(!$IPIDefaultCheckBox.Checked){$IPIpasswordTextBox.Text = ""}
    IF($loaddata.config.data.components."IPI-1".data -ne "" -and (Test-Path ($OutputTextBox.Text + $loaddata.config.data.components."IPI-1".data)))
    {
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "IPI" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $loaddata.config.data.components."IPI-1".data
    }

# Settings

    $dns1TextBox.Text         = $loaddata.config.Settings.primarydns
    $dns2TextBox.Text         = $loaddata.config.Settings.secondarydns 
    $domainTextBox.text       = $loaddata.config.Settings.domainname
    $ntp1TextBox.Text         = $loaddata.config.Settings.ntp1 
    $ntp2TextBox.Text         = $loaddata.config.Settings.ntp2
    $ntp3TextBox.Text         = $loaddata.config.Settings.ntp3
    $syslog1TextBox.Text      = $loaddata.config.Settings.syslog1
    $syslog2TextBox.Text      = $loaddata.config.Settings.syslog2
    $syslog3TextBox.Text      = $loaddata.config.Settings.syslog3
    $community1TextBox.Text   = $loaddata.config.Settings.community1
    $target1TextBox.Text      = $loaddata.config.Settings.target1
    $snmpport1TextBox.Text    = $loaddata.config.Settings.snmpport1 
    $community2TextBox.Text   = $loaddata.config.Settings.community2 
    $target2TextBox.Text      = $loaddata.config.Settings.target2
    $snmpport2TextBox.Text    = $loaddata.config.Settings.snmpport2
    $community3TextBox.Text   = $loaddata.config.Settings.community3
    $target3TextBox.Text      = $loaddata.config.Settings.target3 
    $snmpport3TextBox.Text    = $loaddata.config.Settings.snmpport3
}

ELSEIF($configversion -eq "1.0")
{
    $script:region            = $loaddata.config.header.region
    $script:password          = $regions.item($region)
    $script:passwordsso       = $regions.item($region)
    $SerialNumberTextBox.text = $loaddata.config.header.vbserial 
    $CompanyTextBox.Text      = $loaddata.config.header.company
    $OutputTextBox.Text       = $outputpath + $loaddata.config.header.output

    # Compute

    $C2XXuserTextBox.text = $loaddata.config.c2xx.username
    $C2XXIP1TextBox.text  = $loaddata.config.c2xx.ip1
    $C2XXIP2TextBox.text  = $loaddata.config.c2xx.ip2
    IF($loaddata.config.c2xx.range -eq "True"){$C2XXRangeCheckBox.checked = $true}ELSEIF($loaddata.config.c2xx.range -eq "False"){$C2XXRangeCheckBox.checked = $false}
    $UCS1userTextBox.text = $loaddata.config.ucs1.username
    $UCS1IP1TextBox.text  = $loaddata.config.ucs1.ip1
    $UCS2userTextBox.text = $loaddata.config.ucs2.username
    $UCS2IP1TextBox.text  = $loaddata.config.ucs2.ip1
    $UCS3userTextBox.text = $loaddata.config.ucs3.username
    $UCS3IP1TextBox.text  = $loaddata.config.ucs3.ip1
    $UCS4userTextBox.text = $loaddata.config.ucs4.username
    $UCS4IP1TextBox.text  = $loaddata.config.ucs4.ip1
    $UCS5userTextBox.text = $loaddata.config.ucs5.username
    $UCS5IP1TextBox.text  = $loaddata.config.ucs5.ip1

    # Networking

    $3560userTextBox.text  = $loaddata.config.c3560.username
    $3560IP1TextBox.text   = $loaddata.config.c3560.ip1
    $3560IP2TextBox.text   = $loaddata.config.c3560.ip2
    $3750userTextBox.text  = $loaddata.config.c3750.username
    $3750IP1TextBox.text   = $loaddata.config.c3750.ip1
    $3048userTextBox.text  = $loaddata.config.nx3048.username
    $3048IP1TextBox.text   = $loaddata.config.nx3048.ip1
    $3048IP2TextBox.text   = $loaddata.config.nx3048.ip2
    $55XXuserTextBox.text  = $loaddata.config.nx5548.username
    $55XXIP1TextBox.text   = $loaddata.config.nx5548.ip1
    $55XXIP2TextBox.text   = $loaddata.config.nx5548.ip2
    $55XX2userTextBox.text = $loaddata.config.nx5548brs.username
    $55XX2IP1TextBox.text  = $loaddata.config.nx5548brs.ip1
    $55XX2IP2TextBox.text  = $loaddata.config.nx5548brs.ip2
    $1000userTextBox.text  = $loaddata.config.nx1000v.username
    $1000IP1TextBox.text   = $loaddata.config.nx1000v.ip1
    $MDSuserTextBox.text   = $loaddata.config.mds.username
    $MDSIP1TextBox.text    = $loaddata.config.mds.ip1
    $MDSIP2TextBox.text    = $loaddata.config.mds.ip2
    $N7KuserTextBox.Text   = $loaddata.config.nx7k.username
    $N7KIP1TextBox.Text    = $loaddata.config.nx7k.ip1
    $N7KIP2TextBox.Text    = $loaddata.config.nx7k.ip2
    
    # Storage

    $VNXeuserTextBox.Text    = $loaddata.config.vnxe.username
    $VNXeIP1TextBox.Text     = $loaddata.config.vnxe.ip1
    $VNXuserTextBox.Text     = $loaddata.config.vnx.username
    $VNXIP1TextBox.Text      = $loaddata.config.vnx.ip1
    $NASuserTextBox.Text     = $loaddata.config.nas.username
    $NASIP1TextBox.Text      = $loaddata.config.nas.ip1
	$UnityuserTextBox.Text   = $loaddata.config.unity.username
    $UnityIP1TextBox.Text    = $loaddata.config.unity.ip1
    $XtremiouserTextBox.Text = $loaddata.config.xtremio.username
    $XtremIOIP1TextBox.Text  = $loaddata.config.xtremio.ip1
    $VPLEXuserTextBox.Text   = $loaddata.config.vplex.username
    $VPLEXIP1TextBox.Text    = $loaddata.config.vplex.ip1
    $VPLEXIP2TextBox.Text    = $loaddata.config.vplex.ip2
    $IsilonuserTextBox.Text  = $loaddata.config.Isilon.username
    $IsilonIP1TextBox.Text   = $loaddata.config.Isilon.ip1

    # VMware

    $vc1userTextBox.text   = $loaddata.config.vcenter1.username
    $vCenter1TextBox.text  = $loaddata.config.vcenter1.ip1
    $vc2userTextBox.text   = $loaddata.config.vcenter2.username
    $vCenter2TextBox.text  = $loaddata.config.vcenter2.ip1
    $vc3userTextBox.text   = $loaddata.config.vcenter3.username
    $vCenter3TextBox.text  = $loaddata.config.vcenter3.ip1
    $vc4userTextBox.text   = $loaddata.config.vcenter4.username
    $vCenter4TextBox.text  = $loaddata.config.vcenter4.ip1
    $vc5userTextBox.text   = $loaddata.config.vcenter5.username
    $vCenter5TextBox.text  = $loaddata.config.vcenter5.ip1

    # MISC

    $NSXuserTextBox.text = $loaddata.config.vcenter5.username
    $NSXIP1TextBox.text  = $loaddata.config.vcenter5.ip1
    $NSXIP2TextBox.text  = $loaddata.config.vcenter5.ip2


# Settings

    $dns1TextBox.text       = $loaddata.config.settings.dns1
    $dns2TextBox.text       = $loaddata.config.settings.dns2
    $ntp1TextBox.text       = $loaddata.config.settings.ntp1
    $ntp2TextBox.text       = $loaddata.config.settings.ntp2
    $ntp3TextBox.text       = $loaddata.config.settings.ntp3
    $community1TextBox.text = $loaddata.config.settings.community1
    $community2TextBox.text = $loaddata.config.settings.community2
    $community3TextBox.text = $loaddata.config.settings.community3
    $target1TextBox.text    = $loaddata.config.settings.target1
    $target2TextBox.text    = $loaddata.config.settings.target2
    $target3TextBox.text    = $loaddata.config.settings.target3
    $snmpport1TextBox.text  = $loaddata.config.settings.snmpport1
    $snmpport2TextBox.text  = $loaddata.config.settings.snmpport2
    $snmpport3TextBox.text  = $loaddata.config.settings.snmpport3
    $syslog1TextBox.text    = $loaddata.config.settings.syslog1
    $syslog2TextBox.text    = $loaddata.config.settings.syslog2
    $syslog3TextBox.text    = $loaddata.config.settings.syslog3
    $domainTextBox.text     = $loaddata.config.settings.domain
}

$script:configfile   = $SystemConfigFile
$objForm.Text = $objformtitle + " - $SystemConfigFile"
$status.text  = "Completed Opening file $SystemConfigFile"

} # End If Statement

} # End of Load-Config

Function load-passwords
{

param
(
    [string]$region
)
    IF($region -eq "Standard"){$ucspassword = "vBl0ck01!"}ELSE{$ucspassword = $regions.item($region)}

    IF($C2XXDefaultCheckBox.Checked){$C2XXpassTextBox.Text   = $regions.item($region)}
    IF($UCS1DefaultCheckBox.Checked){$UCS1passTextBox.Text   = $ucspassword}
    IF($UCS2DefaultCheckBox.Checked){$UCS2passTextBox.Text   = $ucspassword}
    IF($UCS3DefaultCheckBox.Checked){$UCS3passTextBox.Text   = $ucspassword}
    IF($UCS4DefaultCheckBox.Checked){$UCS4passTextBox.Text   = $ucspassword}
    IF($UCS5DefaultCheckBox.Checked){$UCS5passTextBox.Text   = $ucspassword}
    IF($3560DefaultCheckBox.Checked){$3560passTextBox.Text   = $regions.item($region)}
    IF($3750DefaultCheckBox.Checked){$3750passTextBox.Text   = $regions.item($region)}
    IF($3048DefaultCheckBox.Checked){$3048passTextBox.Text   = $regions.item($region)}
    IF($55XXDefaultCheckBox.Checked){$55XXpassTextBox.Text   = $regions.item($region)}
    IF($55XX2DefaultCheckBox.Checked){$55XX2passTextBox.Text = $regions.item($region)}
    IF($55XX3DefaultCheckBox.Checked){$55XX3passTextBox.Text = $regions.item($region)}
    IF($1000DefaultCheckBox.Checked){$1000passTextBox.Text   = $regions.item($region)}
    IF($MDSDefaultCheckBox.Checked){$MDSpassTextBox.Text     = $regions.item($region)}
    IF($N7KDefaultCheckBox.Checked){$N7KpassTextBox.Text     = $regions.item($region)}
    IF($VNXeDefaultCheckBox.Checked){$VNXepassTextBox.Text   = $regions.item($region)}
	IF($UnityDefaultCheckBox.Checked){$UnitypassTextBox.Text   = $regions.item($region)}
    IF($VC1DefaultCheckBox.Checked){$vc1passwordTextBox.Text = $regions.item($region)}
    IF($VC2DefaultCheckBox.Checked){$vc2passwordTextBox.Text = $regions.item($region)}
    IF($VC3DefaultCheckBox.Checked){$vc3passwordTextBox.Text = $regions.item($region)}
    IF($VC4DefaultCheckBox.Checked){$vc4passwordTextBox.Text = $regions.item($region)}
    IF($VC5DefaultCheckBox.Checked){$vc5passwordTextBox.Text = $regions.item($region)}
    IF($IsilonDefaultCheckBox.Checked){$isilonpassTextbox.text = $regions.item($region)}
    IF($VNXDefaultCheckBox.Checked){$VNXpassTextBox.Text     = "sysadmin"}
    IF($NASDefaultCheckBox.Checked){$NASpassTextBox.Text     = "nasadmin"}
    IF($XtremIODefaultCheckBox.Checked){$XtremiopassTextBox.Text = "X10Tech!"}
    IF($VPLEXDefaultCheckBox.Checked){$VPLEXpassTextBox.Text   = "Mi@Dim7T"}
    IF($NSXDefaultCheckBox.Checked){$NSXpasswordTextBox.Text   = $regions.item($region)}
    IF($IPIDefaultCheckBox.Checked){$IPIpasswordTextBox.Text   = "acadia"}

    $esxiPassTextBox.Text       = $regions.item($region)

} # End of Load-passwords

Function get-filterhosts
{

$filter      = $filterDropDownTextBox.Text

    IF($filterDropDown.SelectedItem.ToString() -eq "All") {Get-VMHost | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name}
   
    ELSEIF($ModifyDropDown.SelectedItem.ToString() -eq "Equals")
    {
        IF ($filterDropDown.SelectedItem.ToString() -eq "Datacenter") { Get-Datacenter | Where-Object {$_.Name -eq  $filter} | Get-VMHost | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSEIF ($filterDropDown.SelectedItem.ToString() -eq "Cluster"){ Get-Cluster | Where-Object {$_.Name -eq  $filter} | Sort-Object Name | Get-VMHost | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSEIF ($filterDropDown.selecteditem.ToString() -eq "VMHost") { Get-VMHost | Where-Object {$_.Name -eq  $filter} | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSE   {write-warning "Select from one of the default Values" }
    }
    ELSEIF($ModifyDropDown.SelectedItem.ToString() -eq "NotEquals")
    {
        IF ($filterDropDown.SelectedItem.ToString() -eq "Datacenter") { Get-Datacenter | Where-Object {$_.Name -ne  $filter} | Get-VMHost | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSEIF ($filterDropDown.SelectedItem.ToString() -eq "Cluster") { Get-Cluster | Where-Object {$_.Name -ne  $filter} | Sort-Object Name | Get-VMHost | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSEIF ($filterDropDown.selecteditem.ToString() -eq "VMHost") { Get-VMHost | Where-Object {$_.Name -ne  $filter} | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSE   {write-warning "Select from one of the default Values" }
    }
    ELSEIF($ModifyDropDown.SelectedItem.ToString() -eq "Like")
    {
        IF ($filterDropDown.SelectedItem.ToString() -eq "Datacenter") { Get-Datacenter | Where-Object {$_.Name -like  "*$filter*"} | Get-VMHost | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSEIF ($filterDropDown.SelectedItem.ToString() -eq "Cluster") { Get-Cluster | Where-Object {$_.Name -like  "*$filter*"} | Sort-Object Name | Get-VMHost | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSEIF ($filterDropDown.selecteditem.ToString() -eq "VMHost") { Get-VMHost | Where-Object {$_.Name -like  "*$filter*"} | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSE   {write-warning "Select from one of the default Values" }
    }
    ELSEIF($ModifyDropDown.SelectedItem.ToString() -eq "NotLike")
    {
        IF ($filterDropDown.SelectedItem.ToString() -eq "Datacenter") { Get-Datacenter | Where-Object {$_.Name -notlike  "*$filter*"} | Get-VMHost | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSEIF ($filterDropDown.SelectedItem.ToString() -eq "Cluster") { Get-Cluster | Where-Object {$_.Name -notlike  "*$filter*"} | Sort-Object Name | Get-VMHost | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSEIF ($filterDropDown.selecteditem.ToString() -eq "VMHost") { Get-VMHost | Where-Object {$_.Name -notlike  "*$filter*"} | Where-Object {$_.ConnectionState -ne "NotResponding"} | Sort-Object Name }
        ELSE   {write-warning "Select from one of the default Values" }
    }
    
} # End of get-filterhosts

Function get-lcsitem
{

param
(
    [Parameter()]$sheet,
    [Parameter()]$hostname,
    [Parameter()]$ipaddress,
    [Parameter()]$searchterm,
    [Parameter()]$searchrow
)

        IF($Range.find($searchterm,$searchrow) -ne $null)
        {
            $search     = $Range.find($searchterm,$searchrow)
            $searchname = ($sheet.cells.item($search.row,$search.column+$hostname).text).trim()
            $searchip   = ($sheet.cells.item($search.row,$search.column+$ipaddress).text).trim()
        }

		if ($searchname -eq $null)
		{
			$searchname=""			
		}
		if ($searchip -eq $null)
		{
			$searchip=""
		}
		
return $searchname,$searchip

} # End Function get-lcsitem

Function import-lcs
{

	write-host "Importing LCS"
	$credsGridView.ColumnCount = 5

	$xlsdoc = Get-FileName -filetype "Excel Macro-Enabled Workbook (*.xlsm) | *.xlsm"	
	
	IF($xlsdoc -eq "")
	{       
		return
	}
	
	#region Global Stuff
	$CompanyProfile = "Company Profile"
	$systeminfo     = "System Information"
	$LCS            = "LCS"
	$VB240          = "Vblock 240 IP Scheme Layout"
	$VblockType     = ""
	$password       = $regions.item($region)

	$Excel = New-Object -ComObject "Excel.Application"
	$Workbook = $Excel.workbooks.open($xlsdoc)

	#Sheets
	$sheet  = $Workbook.worksheets.item($LCS)
	$sheet2 = $Workbook.worksheets.item($CompanyProfile)

	try
	{
		$sheet3 = $Workbook.worksheets.item($systeminfo)
	}
	catch
	{
		$sheet3 = "System Information tab doesn't exist"
	}

	#Ranges
	$Range = $sheet.Range("B1").EntireColumn

	#Find
	$CompanyTextBox.Text = get-globalstuff -sheet $sheet2    

	$Excel.Visible = $false
   
	#endregion Global Stuff

	$a=$sheet.cells.item(1,2).text.split("`n")[0].indexof("Version ")
	$lcsversion=$sheet.cells.item(1,2).text.split("`n")[0].substring($a+8)
	if ($lcsversion -lt "2.0.22")
	{
		$message="LCS Version $lcsversion not supported"
		[Windows.Forms.MessageBox]::Show($message, “”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information) 
		$Workbook.close($false)
		$Excel.quit()
		$status.Text = "LCS Version not supported"
		return
	}

	#Determine Vblock Version
	IF($sheet3 -ne "System Information tab doesn't exist")
	{
		$VblockType = get-vblocktype -sheet $sheet3		

		IF($VblockType -eq "340"){$searchrow1 = $sheet.Range("B301");$searchrow2 = $sheet.Range("B1028");$searchrow3 = $sheet.Range("B946")}
		ELSEIF($VblockType -eq "540"){$searchrow1 = $sheet.Range("B418");$searchrow2 = $sheet.Range("B1028");$searchrow3 = $sheet.Range("B937")}
		ELSEIF($VblockType -eq "SAP HANA"){$searchrow1 = $sheet.Range("B497");$searchrow2 = $sheet.Range("B1065");$searchrow3 = $sheet.Range("B937")}
		
	}
	ELSE
	{
		$VblockType = get-vblocktype -sheet $sheet

		$searchrow1 = $sheet.Range("B1")
		$searchrow2 = $sheet.Range("B1")
		$searchrow3 = $sheet.Range("B1")
	}
	
    IF($VblockType -eq "240")
	{	
		$sheetLCS  = $Workbook.worksheets.item($LCS)	
		$LCSConfig  = $sheetLCS.Range("B1").EntireColumn		
		
		$sheet240  = $Workbook.worksheets.item($VB240)
		$RangeIPs = $sheet240.Range("A1").EntireColumn
		
		$RangeConfig = $sheet3.Range("B1").EntireColumn
		$AMP		= $RangeConfig.find("AMP Model Selection")
		$AMPtype	= ($sheet3.cells.item($AMP.row,$AMP.column+1).text).trim().split(" ")[0]		
		
		IF ($AMPtype -like "AMP-2V*")
		{			
			$Range1=$LCSConfig.find("*AMP2V*")		
		}
		ELSEIF ($AMPtype -like "AMP-2LP*")
		{
			$Range1=$LCSConfig.find("*AMP2LP*")			
		}
		ELSEIF ($AMPtype -like "AMP-2P*")
		{
			$Range1=$LCSConfig.find("*AMP2P*")		
		}
		ELSE
		{
			$message="LCS does not contain a recognizable AMP"
			[Windows.Forms.MessageBox]::Show($message, “”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information) 
			$Workbook.close($false)
			$Excel.quit()
			$status.Text = "LCS does not contain a recognizable AMP"
			return
		}			
		
		$Vision = $Range1.find("*Vision Intelligent Operations Configuration Information*")
			

		$CServers   	= $RangeConfig.find("Number of C220 Servers")
		$CServerCount	= $sheet3.cells.item($CServers.row,$CServers.column+1).text.trim()
		[int]$CServerCount		
		
		# Build CIMC
		$searchcimc    = $Range1.find("CIMC Names")
		$C2XXHostRange = ($sheetLCS.cells.item($searchcimc.row,$searchcimc.column+2).text).trim()		
		$C2XXHostRange = $C2XXHostRange.substring(0,($C2XXHostRange.split("--")[0].trim()).Length-2)
		
		$searchcimcip = $RangeIPs.find("C220-A CIMC")		
		
		# Build ESXi Hosts
		$searchhosts   = $Range1.find("ESXi Server Names")
		$ESXiHostRange = ($sheetLCS.cells.item($searchhosts.row,$searchhosts.column+2).text).trim()
		$ESXiHostRange = $ESXiHostRange.substring(0,($ESXiHostRange.split("--")[0].trim()).Length-2)
		
		$searchesxiip = $RangeIPs.find("C220-A ESX IP")		
		
		# Build CIMC and ESXI Host and IP Arrays
		$SYSID="0102030405060170809101112"
		
	
		for($i=0; $i -lt $CServerCount -and $i -lt 12; $i++)
		{			
			$C220NAME=$C2XXHostRange+$SYSID.substring($i*2,2)
			$C220ID=($sheet240.cells.item($searchcimcip.row+$i,$searchcimcip.column).text).trim()
			$C220IP=($sheet240.cells.item($searchcimcip.row+$i,$searchcimcip.column+1).text).trim()
			$credsGridView.Rows.Add($C220ID,$C220NAME,$C220IP,"admin",$password)
			write-host "   Added component"$C220ID
			
			IF($I -eq 0)
			{
				$C2XXIP1TextBox.text = $C220IP
			}
			ELSEIF($I -eq 1)
			{
				$C2XXIP2TextBox.text = $C220IP
			}
			
			$ESXINAME=$ESXiHostRange+$SYSID.substring($i*2,2)
			$ESXID=($sheet240.cells.item($searchesxiip.row+$i,$searchesxiip.column).text).trim()
			$ESXIIP=($sheet240.cells.item($searchesxiip.row+$i,$searchesxiip.column+1).text).trim()	
			$credsGridView.Rows.Add($ESXID,$ESXINAME,$ESXIIP,"admin",$password)	
			write-host "   Added component"$ESXID
		}
	
		$C2XXRangeCheckBox.checked = $true

		$search3KA = $Range1.find("Management Switch 01")
		$3ka=($sheetLCS.cells.item($search3KA.row,$search3KA.column+2).text).trim()
		$search3KA = $RangeIPs.find("Cisco 3084")	
		$3kaip=($sheet240.cells.item($search3KA.row,$search3KA.column+1).text).trim()
		IF($3ka -ne "" -and $3kaip -ne ""){$credsGridView.Rows.Add("Management Switch-A",$3ka,$3kaip,"admin",$password);$3048IP1TextBox.Text = $3kaip;write-host "   Added component N3K A"}

		$search5548A = $Range1.find("Ethernet Switch A")		
		$5548Asrv = ($sheetLCS.cells.item($search5548A.row,$search5548A.column+2).text).trim()
		$search5548A = $RangeIPs.find("5548-A")
		$5548Aip = ($sheet240.cells.item($search5548A.row,$search5548A.column+5).text).trim()
		IF($5548Asrv -ne "" -and $5548Aip -ne ""){$credsGridView.Rows.Add("5548A",$5548Asrv,$5548Aip,"admin",$password);$55XXIP1TextBox.text = $5548Aip;write-host "   Added component N5K A"}
		
		$search5548B = $Range1.find("Ethernet Switch B")
		$5548Bsrv = ($sheetLCS.cells.item($search5548B.row,$search5548B.column+2).text).trim()
		$search5548B = $RangeIPs.find("5548-A")
		$5548Bip = ($sheet240.cells.item($search5548B.row,$search5548B.column+5).text).trim()		
		IF($5548Bsrv -ne "" -and $5548Bip -ne ""){$credsGridView.Rows.Add("5548B",$5548Bsrv,$5548Bip,"admin",$password);$55XXIP2TextBox.Text = $5548Bip;write-host "   Added component N5K B"}
		
		$search1000vName = $Range1.find("Cisco Nexus 1000v Switch")
		$search1000vIP = $RangeIPs.find("Cisco Nexus 1000v")
		$1000Vsrv = ($sheetLCS.cells.item($search1000vName.row,$search1000vName.column+2).text).trim()
		$1000VIP   = ($sheet240.cells.item($search1000vIP.row,$search1000vIP.column+1).text).trim()		
		IF($1000Vsrv -ne "" -and $1000VIP -ne ""){$credsGridView.Rows.Add("1000V",$1000Vsrv,$1000VIP,"admin",$password);$1000IP1TextBox.Text = $1000VIP;write-host "   Added component 1000V"}
		
		$searchspa  = $Range1.find("VNX Service Processor A")
		$spasrv		= ($sheetLCS.cells.item($searchspa.row,$searchspa.column+2).text).trim()
		$searchspa  = $RangeIPs.find("VNX SPA")
		$spaip     	= ($sheet240.cells.item($searchspa.row,$searchspa.column+1).text).trim()	
		
		$searchspb  = $Range1.find("VNX Service Processor B")
		$spbsrv		= ($sheetLCS.cells.item($searchspb.row,$searchspb.column+2).text).trim()
		$searchspb  = $RangeIPs.find("VNX SPB")
		$spbip     	= ($sheet240.cells.item($searchspb.row,$searchspb.column+1).text).trim()		
		IF($spasrv -ne "" -and $spaip -ne ""){$credsGridView.Rows.Add("Service Processor A",$spasrv,$spaip,"sysadmin","sysadmin");$VNXIP1TextBox.text = $spaip;write-host "   Added component VNX"}
        IF($spbsrv -ne "" -and $spbip -ne ""){$credsGridView.Rows.Add("Service processor B",$spbsrv,$spbip,"sysadmin","sysadmin")}
		
		$searchcs0  = $Range1.find("VNX Control Station 0")
		$cs0srv		= ($sheetLCS.cells.item($searchcs0.row,$searchcs0.column+2).text).trim()
		$searchcs0  = $RangeIPs.find("VNX CS0")
		$cs0ip     	= ($sheet240.cells.item($searchcs0.row,$searchcs0.column+1).text).trim()		
		IF($cs0srv -ne "" -and $cs0ip -ne ""){$credsGridView.Rows.Add("Control Station 0",$cs0srv,$cs0ip,"nasadmin","nasadmin");$NASIP1TextBox.text = $cs0ip;write-host "   Added component CS 0"}		
				
		$searchcs1  = $Range1.find("VNX Control Station 1")
		$cs1srv		= ($sheetLCS.cells.item($searchcs1.row,$searchcs1.column+2).text).trim()
		$searchcs1  = $RangeIPs.find("VNXCS1")
		$cs1ip     	= ($sheet240.cells.item($searchcs1.row,$searchcs1.column+1).text).trim()	
		IF($cs1srv -ne "" -and $cs1ip -ne ""){$credsGridView.Rows.Add("Control Station 1",$cs1srv,$cs1ip,"nasadmin","nasadmin");$NASIP2TextBox.text = $cs0ip;write-host "   Added component CS 1"}
			
		$searchvc   = $Range1.find("vCenter Server")
		$vcsrv 		= ($sheetLCS.cells.item($searchvc.row,$searchvc.column+2).text).trim()
		$searchvc   = $RangeIPs.find("vCenter VM")
		$vcsrvip   = ($sheet240.cells.item($searchvc.row,$searchvc.column+1).text).trim()
		IF($vcsrv -ne "" -and $vcsrvip -ne ""){$credsGridView.rows.add("vCenter Server",$vcsrv,$vcsrvip,"administrator",$password);$vCenter1TextBox.text = $vcsrvip;write-host "   Added component vCenter"}
      
		#sso				
		$searchvcsso = $Range1.find("vCenter & SSO Server")		
		$vcssosrv = ($sheetLCS.cells.item($searchvcsso.row,$searchvcsso.column+2).text).trim()
		$sso = $RangeIPs.find("SSO VM")
		$ssosrvip  = ($sheet240.cells.item($sso.row,$sso.column+1).text).trim()	       
		IF($vcssosrv -ne "" -and $vcsrvip -ne ""){$credsGridView.rows.add("vCenter / SSO",$vcssosrv,$vcsrvip,"administrator",$password);$vCenter1TextBox.text = $vcsrvip;write-host "   Added component vCenter SSO"}
	   	  
	   	$searchsso   = $Range1.find("VMware SS0 Server")
		$ssosrv = ($sheetLCS.cells.item($searchsso.row,$searchsso.column+2).text).trim()
		$sso = $RangeIPs.find("SSO VM")
		$ssosrvip  = ($sheet240.cells.item($sso.row,$sso.column+1).text).trim()	      
		IF($ssosrv -ne "" -and $ssosrvip -ne ""){$credsGridView.Rows.Add("SSO",$ssosrv,$ssosrvip,"administrator",$password);write-host "   Added component VMware SSO Server"}
	   
		# vum		
		$searchvum  = $Range1.find("Update Manager Server")
		$vumsrv 	= ($sheetLCS.cells.item($searchvum.row,$searchvum.column+2).text).trim()
		$vum 		= $RangeIPs.find("VUM VM")
	    $vumip     	= ($sheet240.cells.item($vum.row,$vum.column+1).text).trim()
		IF($vumsrv -ne "" -and $vumip -ne ""){$credsGridView.Rows.Add("VUM",$vumsrv,$vumip,"administrator",$password);write-host "   Added component Update Manager"}
	   
		# vsphere db	
	   	$searchdb   = $Range1.find("vSphere Database")
		$dbsrv 		= ($sheetLCS.cells.item($searchdb.row,$searchdb.column+2).text).trim()
		$db			= $RangeIPs.find("Database VM")
		$dbip      = ($sheet240.cells.item($db.row,$db.column+1).text).trim()
		IF($dbsrv -ne "" -and $dbsrv -ne ""){$credsGridView.Rows.Add("vCenter Database",$dbsrv,$dbip,"administrator",$password);write-host "   Added component vSphere Database"}
	   	   		
		$searchem   = $Range1.find("Element Management Server")
		$emsrv 		= 	($sheetLCS.cells.item($searchem.row,$searchem.column+2).text).trim()
		$em			= $RangeIPs.find("Element Manager")
		$emip     	= ($sheet240.cells.item($em.row,$em.column+1).text).trim()
		IF($emsrv -ne "" -and $emip -ne ""){$credsGridView.Rows.Add("Element Manager",$emsrv,$emip,"administrator",$password);write-host "   Added component Element Manager Server"}
	   		
		$searchesrs  = $Range1.find("ESRS Server #1")
		$esrssrv = ($sheetLCS.cells.item($searchesrs.row,$searchesrs.column+2).text).trim()
		$esrs		= $RangeIPs.find("ESRS 1")
		$esrsip    = ($sheet240.cells.item($esrs.row,$esrs.column+1).text).trim()
		IF($esrssrv -ne "" -and $esrsip -ne ""){$credsGridView.Rows.Add("ESRS 1",$esrssrv,$esrsip,"administrator",$password);write-host "   Added component ESRS Server"}
  
		$searchvio   = $Range1.find("VCE Vision Core Server")
		$viosrv = ($sheetLCS.cells.item($searchvio.row,$searchvio.column+2).text).trim()
		$searchvio   = $Vision.find("VCE Vision Core Server")
		$vioip     = ($sheetLCS.cells.item($searchvio.row,$searchvio.column+1).text).trim()
		IF($viosrv -ne "" -and $vioip -ne ""){$credsGridView.Rows.Add("VCE Vision",$viosrv,$vioip,"root",$password);write-host "   Added component Vision Core Server"} 
		
		$searchdns1      	= $Range1.find("Primary DNS")
		$dns1TextBox.Text   = ($sheetLCS.cells.item($searchdns1.row,$searchdns1.column+1).text).trim()		
		
		$searchdns2      	= $Range1.find("Secondary DNS")
		$dns2TextBox.Text          = ($sheetLCS.cells.item($searchdns2.row,$searchdns2.column+1).text).trim()
		
		$searchntp1      	= $Range1.find("Primary NTP")
		$ntp1TextBox.Text   = ($sheetLCS.cells.item($searchntp1.row,$searchntp1.column+1).text).trim()
		
		$searchntp2      	= $Range1.find("Secondary NTP")
		$ntp2TextBox.Text   = ($sheetLCS.cells.item($searchntp2.row,$searchntp2.column+1).text).trim()
		
		$searchsyslog1   = $Range1.find("Syslog Server")
		$syslog1TextBox.Text       = ($sheetLCS.cells.item($searchsyslog1.row,$searchsyslog1.column+1).text).trim()
		
		$searchcommunity = $Range1.find("SNMP r/o Community String")
		$community1TextBox.Text     = ($sheetLCS.cells.item($searchcommunity.row,$searchcommunity.column+1).text).trim()
		
		$searchtargets   = $Range1.find("Trap Receivers")
		$target1TextBox.Text       = ($sheetLCS.cells.item($searchtargets.row,$searchtargets.column+1).text).trim()
		
		$searchdomain    = $Range1.find("Domain Name:")
		$domainTextBox.Text        = ($sheetLCS.cells.item($searchdomain.row,$searchdomain.column+1).text).trim()
		
		$searchpassword  = $Range1.find("Admin@system-domain")
		$global:passwordsso        = ($sheetLCS.cells.item($searchpassword.row,$searchpassword.column+1).text).trim()
		
    }	
    ELSE
    {
        $searchequip = $Range.find("Equipment",$searchrow1)
		IF(($sheet.cells.item($searchequip.row,$searchequip.column+5).text).trim() -ne "Host Name")
		{
			$message="LCS spreadsheet format not as expected, cannot find equipment host name"
			[Windows.Forms.MessageBox]::Show($message, “”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information) 
			$Workbook.close($false)
			$Excel.quit()
			$status.Text = "LCS Spreadsheet format not as expected"
			return
		}
		$j = 5 
		$k = 5

		# Search for Compute Items
        IF($region -eq "Standard"){$ucspassword = "vBl0ck01!"}ELSE{$ucspassword = $regions.item($region)}
        
        $fia,$fiaip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Fabric Interconnect 01 Cluster IP" -searchrow $searchrow1		
        IF($fia -ne "" -and $fiaip -ne ""){$credsGridView.Rows.Add("UCS Cluster 1",$fia,$fiaip,"admin",$ucspassword);$UCS1IP1TextBox.text = $fiaip;write-host "   Added component UCS Cluster 1"}

        $fib,$fibip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Fabric Interconnect 02 Cluster IP" -searchrow $searchrow1		
        IF($fib -ne "" -and $fibip -ne ""){$credsGridView.Rows.Add("UCS Cluster 2",$fib,$fibip,"admin",$ucspassword);$UCS2IP1TextBox.text = $fibip;write-host "   Added component UCS Cluster 2"}

        $fic,$ficip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Fabric Interconnect 03 Cluster IP" -searchrow $searchrow1	
        IF($fic -ne "" -and $ficip -ne ""){$credsGridView.Rows.Add("UCS Cluster 3",$fic,$ficip,"admin",$ucspassword);$UCS3IP1TextBox.text = $ficip;write-host "   Added component UCS Cluster 3"}
        
        $fid,$fidip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Fabric Interconnect 04 Cluster IP" -searchrow $searchrow1
        IF($fid -ne "" -and $fidip -ne ""){$credsGridView.Rows.Add("UCS Cluster 4",$fid,$fidip,"admin",$ucspassword);$UCS4IP1TextBox.text = $fidip;write-host "   Added component UCS Cluster 4"}
        
        $fie,$fieip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Fabric Interconnect 05 Cluster IP" -searchrow $searchrow1
        IF($fie -ne "" -and $fieip -ne ""){$credsGridView.Rows.Add("UCS Cluster 5",$fie,$fieip,"admin",$ucspassword);$UCS5IP1TextBox.text = $fieip;write-host "   Added component UCS Cluster 5"}

        $cimcasearchterms = "AMP CIMC - AMP","AMP A CIMC - HA AMP","AMP-2 Server 1-CIMC","AMP-2 Server #1-CIMC","C220 CIMC 01"

        foreach($searchterm in $cimcasearchterms)
        {
            $cimca,$cimcaip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm $searchterm -searchrow $searchrow1			
            IF ($cimca -ne "" -and $cimcaip -ne ""){$credsGridView.Rows.Add("CIMC 01",$cimca,$cimcaip,"admin",$password);$C2XXIP1TextBox.text = $cimcaip;write-host "   Added component UCS Cluster CIMC 01"}
        }

        $cimcbsearchterms = "AMP B CIMC - HA AMP","AMP-2 Server 2-CIMC","AMP-2 Server #2-CIMC","C220 CIMC 02"

        foreach($searchterm in $cimcbsearchterms)
        {
            $cimcb,$cimcbip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm $searchterm -searchrow $searchrow1		
            IF($cimcb -ne "" -and $cimcbip -ne ""){$credsGridView.Rows.Add("CIMC 02",$cimcb,$cimcbip,"admin",$password);$C2XXIP2TextBox.Text = $cimcbip;write-host "   Added component UCS Cluster CIMC 02"}
        }

        $cimccsearchterms = "AMP-2 Server #3-CIMC","C220 CIMC 03"

        foreach($searchterm in $cimccsearchterms)
        {
            $cimcc,$cimccip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm $searchterm -searchrow $searchrow1			
            IF($cimcc -ne "" -and $cimccip -ne "")
            {
                $credsGridView.Rows.Add("CIMC 03",$cimcc,$cimccip,"admin",$password)
                write-host "   Added component UCS Cluster CIMC 03"
                $C2XXIP2TextBox.Text = $cimccip
                $C2XXRangeCheckBox.checked = $true    
            }
        }
		
		# Search for Network Items
		$3ka,$3kaip = get-lcsitem -sheet $sheet -hostname $k -ipaddress 1 -searchterm "Management Switch A (Cisco Nexus 3K)" -searchrow $searchrow3		
        IF($3ka -ne "" -and $3kaip -ne ""){$credsGridView.Rows.Add("Management Switch-A",$3ka,$3kaip,"admin",$password);$3048IP1TextBox.Text = $3kaip;write-host "   Added component N3K A"}

        $3kb,$3kbip = get-lcsitem -sheet $sheet -hostname $k -ipaddress 1 -searchterm "Management Switch B (Cisco Nexus 3K)" -searchrow $searchrow3
        IF($3kb -ne "" -and $3kbip -ne ""){$credsGridView.Rows.Add("Management Switch-B",$3kb,$3kbip,"admin",$password);$3048IP2TextBox.Text = $3kbip;write-host "   Added component N3K B"}
		
        $etha,$ethaip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Ethernet Switch A" -searchrow $searchrow1
        IF($etha -ne "" -and $ethaip -ne ""){$credsGridView.Rows.Add("Aggregate Switch A",$etha,$ethaip,"admin",$password);$55XXIP1TextBox.text = $ethaip;write-host "   Added component Nexus Switch A"}
		
        $ethb,$ethbip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Ethernet Switch B" -searchrow $searchrow1
        IF($ethb -ne "" -and $ethbip -ne ""){$credsGridView.Rows.Add("Aggregate Switch B",$ethb,$ethbip,"admin",$password);$55XXIP2TextBox.text = $ethbip;write-host "   Added component Nexus Switch B"}

        $ethc,$ethcip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Ethernet Switch C" -searchrow $searchrow1
        IF($ethc -ne "" -and $ethcip -ne ""){$credsGridView.Rows.Add("BRS Switch A",$ethc,$ethcip,"admin",$password);$55XX2IP1TextBox.text = $ethcip;write-host "   Added component Nexus Switch C"}

        $ethd,$ethdip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Ethernet Switch D" -searchrow $searchrow1
        IF($ethd -ne "" -and $ethdip -ne ""){$credsGridView.Rows.Add("BRS Switch B",$ethd,$ethdip,"admin",$password);$55XX2IP2TextBox.text = $ethdip;write-host "   Added component Nexus Switch D"}

        $ethe,$etheip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Isilon Ethernet Switch A" -searchrow $searchrow1
        IF($ethe -ne "" -and $etheip -ne ""){$credsGridView.Rows.Add("Isilon Switch A",$ethe,$etheip,"admin",$password);$55XX3IP1TextBox.text = $etheip;write-host "   Added component Nexus Isilon A"}

        $ethf,$ethfip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Isilon Ethernet Switch B" -searchrow $searchrow1
        IF($ethf -ne "" -and $ethfip -ne ""){$credsGridView.Rows.Add("Isilon Switch B",$ethf,$ethfip,"admin",$password);$55XX3IP2TextBox.Text = $ethfip;write-host "   Added component Nexus Isilon B"}
		
        $1000v,$1000vip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Cisco Nexus 1000v Switch" -searchrow $searchrow1
        IF($1000v -ne "" -and $1000vIP -ne ""){$credsGridView.Rows.Add("1000v",$1000v,$1000vIP,"admin",$password);$1000IP1TextBox.text = $1000VIP;write-host "   Added component 1000v"}

        $mdsa,$mdsaip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Fiber Channel Switch A" -searchrow $searchrow1
        IF($mdsa -ne "" -and $mdsaip -ne ""){$credsGridView.Rows.Add("MDS A",$mdsa,$mdsaip,"admin",$password);$MDSIP1TextBox.text = $mdsaip;write-host "   Added component MDS A"}

        $mdsb,$mdsbip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "Fiber Channel Switch B" -searchrow $searchrow1
        IF($mdsb -ne "" -and $mdsbip -ne ""){$credsGridView.Rows.Add("MDS B",$mdsb,$mdsbip,"admin",$password);$MDSIP2TextBox.Text = $mdsbip;write-host "   Added component MDS B"}
		
		
		# Search for Storage Items
        $xbricka,$xbrickaip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "X-Brick01 Storage Mgmt. IP 1" -searchrow $searchrow1
        IF($xbricka -ne "" -and $xbrickaip -ne ""){$credsGridView.Rows.Add("X-Brick01 Storage MGMT 1",$xbricka,$xbrickaip,"N/A","N/A");write-host "   Added component X-Brick01 Storage MGMT 1"}
        
        $xbrickb,$xbrickbip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "X-Brick01 Storage Mgmt. IP 2" -searchrow $searchrow1
        IF($xbrickb -ne "" -and $xbrickbip -ne ""){$credsGridView.Rows.Add("X-Brick01 Storage MGMT 2",$xbrickb,$xbrickbip,"N/A","N/A");write-host "   Added component X-Brick01 Storage MGMT 2"}                
        
        $xbrickc,$xbrickcip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "X-Brick02 Storage Mgmt. IP 1" -searchrow $searchrow1
        IF($xbrickc -ne "" -and $xbrickcip -ne ""){$credsGridView.Rows.Add("X-Brick02 Storage MGMT 1",$xbrickc,$xbrickcip,"N/A","N/A");write-host "   Added component X-Brick02 Storage MGMT 1"}              
        
        $xbrickd,$xbrickdip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "X-Brick02 Storage Mgmt. IP 2" -searchrow $searchrow1
        IF($xbrickd -ne "" -and $xbrickdip -ne ""){$credsGridView.Rows.Add("X-Brick02 Storage MGMT 2",$xbrickd,$xbrickdip,"N/A","N/A");write-host "   Added component X-Brick02 Storage MGMT 2"}

        $vnxesearchterms = "EMC VNXe Mgmt. IP Address","EMC VNXe Mgmt IP Address","VNXe Management IP Address","EMC VNXe MGMT Address"

        ForEach($searchterm in $vnxesearchterms)
        {
            $vnxe,$vnxeip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm $searchterm -searchrow $searchrow1
            IF($vnxe -ne "" -and $vnxeip -ne ""){$credsGridView.Rows.Add("VNXe",$vnxe,$vnxeip,"admin",$password);$VNXeIP1TextBox.text = $vnxeip;write-host "   Added component VNXe"}
        }

		$unitysearchterms = "EMC Unity Mgmt. IP Address","EMC Unity Mgmt IP Address","Unity Management IP Address","EMC Unity MGMT Address"

        ForEach($searchterm in $unitysearchterms)
        {
            $unity,$unityip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm $searchterm -searchrow $searchrow1
            IF($unity -ne "" -and $unityip -ne ""){$credsGridView.Rows.Add("Unity",$unity,$unityip,"admin",$password);$UnityIP1TextBox.text = $unityip;write-host "   Added component Unity"}
        }
		
        $vnxasearchterms = "EMC VNX SP A (340)","EMC VNX Service Processor A","EMC VNX /VMAX Service Processor A","EMC VNX SP A/VMAX MMCS-0"
        
        ForEach($searchterm in $vnxasearchterms)
        {
            $spa,$spaip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm $searchterm -searchrow $searchrow1
            IF($spa -ne "" -and $spaip -ne ""){$credsGridView.Rows.Add("Service Processor A",$spa,$spaip,"sysadmin","sysadmin");$VNXIP1TextBox.Text = $spaip;write-host "   Added component SPA"}
        }         

        $vnxbsearchterms = "EMC VNX SP B (340)", "EMC VNX Service Processor B","EMC VNX / VMAX Service Processor B","EMC VNX SP B/VMAX MMCS-1"
        
        ForEach($searchterm in $vnxbsearchterms)
        {
            $spb,$spbip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm $searchterm -searchrow $searchrow1
            IF($spb -ne "" -and $spbip -ne ""){$credsGridView.rows.Add("Service Processor B",$spb,$spbip,"sysadmin","sysadmin");write-host "   Added component SPB"}
        }
        
        $cs0,$cs0ip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "EMC Control Station 0" -searchrow $searchrow1
        IF($cs0 -ne "" -and $cs0ip -ne ""){$credsGridView.Rows.Add("Control Station 0",$cs0,$cs0ip,"nasadmin","nasadmin");$NASIP1TextBox.Text = $cs0ip;write-host "   Added component CS0"}
         
        $cs1,$cs1ip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "EMC Control Station 1" -searchrow $searchrow1
        IF($cs1 -ne "" -and $cs1ip -ne ""){$credsGridView.Rows.Add("Control Station 1",$cs1,$cs1ip,"nasadmin","nasadmin");write-host "   Added component CS1"}        

        $vmax,$vmaxip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm "EMC Symmetrix VMAX Service Processor" -searchrow $searchrow1
        IF($vmax -ne "" -and $vmaxip -ne ""){$credsGridView.Rows.Add("VMAX Service Processor",$vmax,$vmaxip,"smc","smc");write-host "   Added component VMAX Service Processor"}

		# Search for VMWare Items
        $esxiasearchterms = "AMP Server ESX MGMT Address - AMP","XMP Server MGMT Address - ESXi01","AMP A Server ESX MGMT Address - HA AMP","AMP-2 Server #1 ESX MGMT Address"

        foreach($searchterm in $esxiasearchterms)
        {
            $esxia,$esxiaip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm $searchterm -searchrow $searchrow1
            IF($esxia -ne "" -and $esxiaip -ne ""){$credsGridView.Rows.Add("MGMT ESXi 01",$esxia,$esxiaip,"root",$password);write-host "   Added component MGMT ESXi 01"}
        }

        $esxibsearchterms = "XMP Server MGMT Address - ESXi02","AMP B Server ESX MGMT Address - HA AMP","AMP-2 Server #2 ESX MGMT Address"

        foreach($searchterm in $esxibsearchterms)
        {
            $esxib,$esxibip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm $searchterm -searchrow $searchrow1
            IF($esxib -ne "" -and $esxibip -ne ""){$credsGridView.Rows.Add("MGMT ESXi 02",$esxib,$esxibip,"root",$password);write-host "   Added component MGMT ESXi 02"}
        }

        $esxicsearchterms = "XMP Server MGMT Address - ESXi03","AMP-2 Server #3 ESX MGMT Address"

        foreach($searchterm in $esxicsearchterms)
        {
            $esxic,$esxicip = get-lcsitem -sheet $sheet -hostname $j -ipaddress 1 -searchterm $searchterm -searchrow $searchrow1
            IF($esxic -ne "" -and $esxicip -ne ""){$credsGridView.Rows.Add("MGMT ESXi 03",$esxic,$esxicip,"root",$password);write-host "   Added component MGMT ESXi 03"}
        }

		# NSX
		$i = 4
		
		$nsx,$nsxip = get-lcsitem -sheet $sheet -ipaddress 1 -hostname $i -searchterm "NSX Manager VM #1" -searchrow $searchrow3
		IF($nsx -ne "" -and $nsxip -ne ""){$credsGridView.Rows.Add("NSX Manager",$nsx,$nsxip,"admin",$password);$NSXIPTextBox.text = $nsxip;write-host "   Added component NSX 1"}


		# Server Role Section
        $vcsearchterms = "VMware vCenter Server","vCenter / SSO Server","VMware vCenter SSO Server"

        foreach($searchterm in $vcsearchterms)
        {
            $vc,$vcip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm $searchterm -searchrow $searchrow2
            IF($vc -ne "" -and $vcip -ne ""){$credsGridView.Rows.Add($searchterm,$vc,$vcip,"administrator",$password);$vCenter1TextBox.Text = $vcip;write-host "   Added component vCenter 1"} 
        }

        $vca,$vcaip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm "vCenter Server Appliance" -searchrow $searchrow2
        IF($vca -ne "" -and $vcaip -ne ""){$credsGridView.Rows.Add("vCenter Appliance",$vca,$vcaip,"root",$password);$vCenter2TextBox.Text = $vcaip;write-host "   Added component vCenter Appliance"}
                    
        $vcrp,$vcrpip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm "vCenter Replication Appliance" -searchrow $searchrow2                
        IF($vcrp -ne "" -and $vcrpip -ne ""){$credsGridView.Rows.Add("vCenter Replication Appliance",$vcrp,$vcrpip,"root",$password);write-host "   Added component vCenter Replication Appliance"}            
         
        $vumsearchterms = "VMware VUM Server","VMware vCenter Update Manager"

        foreach($searchterm in $vumsearchterms)
        {
            $vum,$vumip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm $searchterm -searchrow $searchrow2
            IF($vum -ne "" -and $vumip -ne ""){$credsGridView.Rows.Add("VMware vCenter Update Manager",$vum,$vumip,"administrator",$password);write-host "   Added component VMware Update Manager"}
        }

        $vcdb,$vcdbip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm "VMware vCenter Database Server" -searchrow $searchrow2
        IF($vcdb -ne "" -and $vcdbip -ne ""){$credsGridView.Rows.Add("VMware vCenter Database Server",$vcdb,$vcdbip,"administrator",$password);write-host "   Added component vCenter Database Server"}

        $esrs1,$esrs1ip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm "ESRS Server #1" -searchrow $searchrow2
        IF($esrs1 -ne "" -and $esrs1ip -ne ""){$credsGridView.Rows.Add("ESRS Server #1",$esrs1,$esrs1ip,"administrator",$password);write-host "   Added component ESRS 1"}

        $esrs2,$esrs2ip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm "ESRS Server #2" -searchrow $searchrow2
        IF($esrs2 -ne "" -and $esrs2ip -ne ""){$credsGridView.Rows.Add("ESRS Server #2",$esrs2,$esrs2ip,"administrator",$password);write-host "   Added component ESRS 2"}

        $esrs3,$esrs3ip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm "ESRS Server #3" -searchrow $searchrow2
        IF($esrs3 -ne "" -and $esrs3ip -ne ""){$credsGridView.Rows.Add("ESRS Server #3",$esrs3,$esrs3ip,"administrator",$password);write-host "   Added component ESRS 3"}

        $emsearchterms = "Array Management Server","Element Manager Server"

        foreach($searchterm in $emsearchterms)
        {
            $em,$emip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm $searchterm -searchrow $searchrow2
            IF($em -ne "" -and $emip -ne ""){$credsGridView.Rows.Add("Element Manager Server",$em,$emip,"administrator",$password);write-host "   Added component Element Manager"}
        }

        $vio,$vioip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm "VCE Vision Intelligent Operations Server" -searchrow $searchrow2
        IF($vio -ne "" -and $vioip -ne ""){$credsGridView.Rows.Add("VCE Vision Intelligent Operations",$vio,$vioip,"root",$password);write-host "   Added component VCE Vision"}

        $pp,$ppip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm "EMC Powerpath vApp" -searchrow $searchrow2
        IF($pp -ne "" -and $ppip -ne ""){$credsGridView.Rows.Add("EMC Powerpath vApp",$pp,$ppip,"root",$password);write-host "   Added component PowerPath vAPP"}

        $dcnm,$dcnmip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm "Cisco DCNM Windows 2008 R2 Server" -searchrow $searchrow2
        IF($dcnm -ne "" -and $dcnmip -ne ""){$credsGridView.Rows.Add("DCNM Server",$dcnm,$dcnmip,"administrator",$password);write-host "   Added component DCNM"}

        $uim,$uimip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm "UIM server name?" -searchrow $searchrow2
        IF($uim -ne "" -and $uimip -ne ""){$credsGridView.Rows.Add("UIM",$uim,$uimip,"sysadmin","sysadmin");write-host "   Added component UIMP"}

        $xms,$xmsip = get-lcsitem -sheet $sheet -hostname $i -ipaddress 1 -searchterm "XIO Management Server" -searchrow $searchrow2
        IF($xms -ne "" -and $xmsip -ne ""){$credsGridView.Rows.Add("XtremIO Management Server",$xms,$xmsip,"xmsadmin","Xtrem10");$XtremIOIP1TextBox.text = $xmsip;write-host "   Added component XtremIO Management Server"}

		# Settings
        $searchdns1        = $range.find("Primary DNS")
        $searchdns2        = $range.find("Secondary DNS")
        $searchcommunities = $range.find("SNMP r/o Community String")
        $searchtargets     = $range.find("Trap Receivers")
        $searchntp         = $range.find("NTP Server")
        $searchsyslog1     = $range.find("Syslog 1 (Optional)")
        $searchsyslog2     = $range.find("Syslog 2 (Optional)")

        $dns1TextBox.Text       = ($sheet.cells.item($searchdns1.row,$searchdns1.column+1).text).trim()
        $dns2TextBox.Text       = ($sheet.cells.item($searchdns2.row,$searchdns2.column+1).text).trim()
        $community1TextBox.Text = ($sheet.cells.item($searchcommunities.row,$searchcommunities.column+1).text).trim()
        $target1TextBox.Text    = ($sheet.cells.item($searchtargets.row,$searchtargets.column+1).text).trim()
        $ntp1TextBox.Text       = ($sheet.cells.item($searchntp.row,$searchntp.column+1).text).trim()
        $ntp2TextBox.Text       = ($sheet.cells.item($searchntp.row,$searchntp.column+2).text).trim()
        $syslog1TextBox.Text    = ($sheet.cells.item($searchsyslog1.row,$searchsyslog1.column+1).text).trim()
        $syslog2TextBox.Text    = ($sheet.cells.item($searchsyslog2.row,$searchsyslog2.column+1).text).trim()

        $searchdomain = $Range.find("Domain Name")
        $domainname = ($sheet.cells.item($searchdomain.row+1,$searchdomain.column+1).text).trim()
        IF($domainname -ne ""){$domainTextBox.Text = $domainname}

        $searchssopassword = $Range.find("Password")
        $global:passwordsso = ($sheet.cells.item($searchssopassword.row,$searchssopassword.column+1).text).trim()
	
		# Misc Items
		$ipi2ip,$ipi1ip = get-lcsitem -sheet $sheet -ipaddress 1 -hostname 2 -searchterm "IPI Power Management IP Addresses" -searchrow $searchrow1
		IF($ipi1ip -ne ""){$credsGridView.Rows.Add("IPI Power Management","IPI 1",$ipi1ip,"admin",$password);$IPIIP1TextBox.Text = $ipi1ip;write-host "   Added component IPI 1"}
		IF($ipi1ip -ne "" -and $ipi1ip -ne ""){$credsGridView.Rows.Add("IPI Power Management","IPI 2",$ipi2ip,"admin",$password);$IPIIP2TextBox.Text = $ipi2ip;write-host "   Added component IPI 2"}
	}
	
    write-host "Import LCS Complete"

    [Windows.Forms.MessageBox]::Show(“Import Complete”, “”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)

#region Closing Tasks

    $Workbook.close($false)
    $Excel.quit()
    $status.Text = "Import Complete"

#endregion Closing Tasks

} # End Function import-lcs

Function create-hostsfile 
{	
	$OutFile       = $outputpath + "\hosts_$TIMESTAMP"
		
	For($i=0;$i -lt $credsGridView.rowcount-1;$i++)
	{
		$hostname=$credsGridView.rows[$i].Cells['Hostname'].Value
		$ip=$credsGridView.rows[$i].Cells['IP Address'].Value
		IF ($hostname -eq "" -or $ip -eq "")
		{
			continue
		}
		
		IF ($domainTextBox.text -ne "")
		{
			$domain=$domainTextBox.text
			$fqdn="$hostname.$domain"
		}
		else 
		{
			$fqdn=$hostname
		}
		
		Add-Content $OutFile "$ip $fqdn"
	}
	
	write-host "Host file $OutFile created"
} # End Function create-hostsfile

Function ping-test 
{
	$credsGridView.ColumnCount = 6
	$credsGridView.columns[5].Name  = "Test Connection"
	$credsGridView.columns[5].Width = 175
	$credsGridView.ColumnHeadersVisible = $true
	
	For($i=0;$i -lt $credsGridView.rowcount-1;$i++)
	{
		$hostname=$credsGridView.rows[$i].Cells['Hostname'].Value
		$ip=$credsGridView.rows[$i].Cells['IP Address'].Value
		IF ($domainTextBox.text -ne "")
		{
			$domain=$domainTextBox.text
			$fqdn="$hostname.$domain"
		}
		else 
		{
			$fqdn=$hostname
		}
		IF ($fqdn -eq "")
		{
			$fqdn=$ip
		}
		IF ($fqdn -eq "")
		{
			continue
		}
		
		write-host "   Testing..."$fqdn
		
		IF ((Test-Connection $fqdn -count 1 -quiet) -eq $false)
		{
			IF ((Test-Connection $ip -count 1 -quiet) -eq $false)
			{
				$credsGridView.rows[$i].Cells[5].Value="Failed"
				$credsGridView.rows[$i].Cells[5].Style.backcolor = 'red'	
			}
			ELSE
			{
				$credsGridView.rows[$i].Cells[5].Value="Successful with IP"
				$credsGridView.rows[$i].Cells[5].Style.backcolor = 'red'
			}
		}
		ELSE
		{			
			$credsGridView.rows[$i].Cells[5].Value="Successful"
			$credsGridView.rows[$i].Cells[5].Style.backcolor = 'green'
		}		
		$credsGridView.rows[$i].Cells[5].Style.forecolor = 'white'		
	}

	write-host "Test Connection complete"
	
} # End Function ping-test

Function set-vmhosts
{

$VBID = $SerialNumberTextBox.text
$VAAI = "false"      

IF($VMvaaiDropDown.SelectedItem.ToString() -eq "Disable"){$VAAI = "false"}
IF($VMvaaiDropDown.SelectedItem.ToString() -eq "Enable"){$VAAI = "true"}

IF($Debug)
{ 
    IF(!(Test-Path "$scriptPath\Logs")){New-Item "$scriptPath\Logs" -ItemType directory | Out-Null}
    $logfile = "$scriptpath\Logs\Config-VMware-$VBID-$TIMESTAMP-log.rtf"
    Start-Transcript $logfile
} 

    Write-Host "Started VMware Config"
    $status.text = "Started VMware Config"
    $connected = connect-vcenter

    IF($connected)
    {
        IF($dropdowntextbox.Text -eq "" -and $DropDown.SelectedItem.ToString() -ne "All"){write-warning "Nothing was typed in the search filter"}
    
        ELSE
        {
            $hosts = get-filterhosts

            IF($hosts -ne $null)
            {
                IF($VMDNSCheckbox.Checked -eq $true)   
                {
                    IF($dns1TextBox.text -ne "" -and $dns2textbox.text -ne ""){[array]$DNSServers = $dns1TextBox.text,$dns2TextBox.text}
                    ELSEIF($dns1TextBox.text -ne ""){$DNSServers = $dns1TextBox.text}
                    ELSEIF($dns2textbox.text -ne ""){$DNSServers = $dns2textbox.text}
            
                    $hosts | set-vmdnsservers -DNS $DNSServers
                }
                IF($VMNTPCheckbox.Checked -eq $true)      
                {
                    $NTPServers = $ntp1TextBox.Text; IF($ntp2TextBox.text -ne ""){$NTPServers += "," + $ntp2TextBox.Text};IF($ntp3textbox.text -ne ""){$NTPServers += "," + $ntp3TextBox.Text}
                    $NTPServers = $NTPServers.Split(",")
                    $hosts | set-vmntp -NTP $NTPServers
                }
                IF($VMSyslogCheckbox.Checked -eq $true)   
                {
                    $syslogArray = $syslog1TextBox.text,$syslog2TextBox.Text,$syslog3TextBox.Text
                    $syslog      = ""

                    ForEach($item in $syslogArray | Where-Object {$_ -ne ""})
                    {
                        $syslog += $item + ","
                    }
            
                    $syslog = $syslog.TrimEnd(",")
                    $hosts | set-vmsyslog -Syslog $syslog
                }
                IF($VMSNMPCheckbox.Checked -eq $true)
                {
                    $snmp = ""

                    IF($community1TextBox.Text -ne "" -and $target1TextBox.Text -ne "" -and $snmpport1TextBox.Text -ne ""){$snmp += $target1TextBox.Text + "@" + $snmpport1TextBox.Text + "/" + $community1TextBox.Text + ","}
                    IF($community2TextBox.Text -ne "" -and $target2TextBox.Text -ne "" -and $snmpport2TextBox.Text -ne ""){$snmp += $target2TextBox.Text + "@" + $snmpport2TextBox.Text + "/" + $community2TextBox.Text + ","}
                    IF($community3TextBox.Text -ne "" -and $target3TextBox.Text -ne "" -and $snmpport3TextBox.Text -ne ""){$snmp += $target3TextBox.Text + "@" + $snmpport3TextBox.Text + "/" + $community3TextBox.Text}

                    $snmp = $snmp.TrimEnd(",")
            
                    IF($snmp -eq ""){write-host "You did not correctly fill out the SNMP section in settings" -foreground Yellow}ELSE{$hosts | set-vmsnmp -snmp $snmp}
                }
                IF($VMAdvancedCheckbox.Checked -eq $true) {$hosts | set-vmadvancedsettings }
                IF($VMScratchSpaceCheckbox.Checked  -eq $true)
                {
                    $i = 0
                    write-host "   Configuring Scratch Space            " -NoNewline
                    ForEach($vmhost in $hosts)
                    {
                        Write-Progress -activity "Configuring Scratch Space" -status $vmhost.Name -PercentComplete (($i++ / $hosts.count)  * 100); ticker

                        $datastore = $vmhost | Get-Datastore | Where-Object {$_.CapacityGB -ge $prefscratchspace[0] -and $_.CapacityGB -le $prefscratchspace[1]}
                        IF($datastore -ne $null)
                        {
                            $hostname = $vmhost.name.split(".")[0].ToUpper()
                            IF($datastore.Name -ne ("$hostname"+"-localstorage")){$datastore | Set-Datastore -Name ("$hostname"+"-localstorage"); $datastore = $vmhost | 
                                Get-Datastore | Where-Object {$_.CapacityGB -ge $prefscratchspace[0] -and $_.CapacityGB -le $prefscratchspace[1]}}
                            $vmhost | set-vmscratchspace -datastore $datastore
                        }
                    }
                        Write-Progress -activity "Configuring Scratch Space" -Completed -Status "Complete"; Write-Host `b"Done!"
                } 
                IF($VMRDMCheckbox.Checked      -eq $true){$hosts | set-vmrdm}
                IF($VMVAAICheckbox.Checked     -eq $true){$hosts | set-vaai -vaai:([System.Convert]::ToBoolean($vaai))}
                IF($VMMOBCheckbox.Checked      -eq $true){$hosts | set-mob -username $esxiuserTextBox.Text -password $esxiPassTextBox.Text}
                IF($VMFirewallCheckbox.Checked -eq $true){$hosts | set-vmfirewall}
                IF($VMVPLEXCheckbox.Checked    -eq $true){$hosts | set-vplex}
                IF($VMCoreDumpCheckbox.Checked -eq $true -and $coredumpTextBox.Text -ne ""){$hosts | set-vmcoredump -server $coredumpTextBox.Text}
                IF($VMXtremIOCheckbox.Checked  -eq $true)
                {
                    IF($VMXtremIODropDown.SelectedItem.ToString() -eq "XtremIO"){$hosts | set-xtremio -StorageArray "XtremIO"}
                    ELSEIF($VMXtremIODropDown.SelectedItem.ToString() -eq "VNX"){$hosts | set-xtremio -StorageArray "VNX"}
                    ELSEIF($VMXtremIODropDown.SelectedItem.ToString() -eq "VMAX"){$hosts | set-xtremio -StorageArray "VMAX"}
                    ELSEIF($VMXtremIODropDown.SelectedItem.ToString() -eq "Multi-Array"){$hosts | set-xtremio -StorageArray "Multi-Array"}
                    ELSEIF($VMXtremIODropDown.SelectedItem.ToString() -eq "VPLEX"){$hosts | set-xtremio -StorageArray "VPLEX"}
                }
                IF($VMDomainCheckbox.Checked -eq $true){$hosts | set-vmdomain -domainname $domainTextBox.Text}
                IF($VMSMARTDCheckbox.Checked -eq $true){$hosts | set-vmsmartd -username $esxiuserTextBox.Text -password $esxiPassTextBox.Text -status $VMSMARTDDropDown.SelectedItem.ToString()}
            }
            ELSE{write-host "Filter produced no hosts" -ForegroundColor Yellow}
     }

        Write-Host "Completed VMware Config"
        $status.text = "Completed VMware Config"
        Disconnect-VIServer * -Force -Confirm:$false

    } # End If Connected

IF($Debug){Stop-Transcript}

} # End Function set-vmhosts

Function check-config
{

$style = @"
<style>

TABLE
{
    border-width:     1px;
    border-style:     solid;
    border-color:     black;
    border-collapse:  collapse;
    margin-left:10px;
}

TH
{
    Font-Family:      Arial;
    Font-Size:        10;
    Font-Weight:      Bold;
    Border:           3px solid Black;
    Padding:          5px 5px 5px 5px;
    Background-color: RGB(160,210,234);
}

TD
{
    Font-Family:      Calibri;
    Font-Size:        11;
    Border:           2px solid Black;
    Padding:          5px 5px 5px 5px;
}

</Style>
"@

$VBID        = $SerialNumberTextBox.text

IF($Debug)
{ 
    IF(!(Test-Path "$scriptPath\Logs")){New-Item "$scriptPath\Logs" -ItemType directory | Out-Null}
    $logfile = "$scriptpath\Logs\Check-VMware-$VBID-$TIMESTAMP-log.rtf"
    Start-Transcript $logfile
} 

    Write-Host "Started VMware Check"
    $status.text = "Started VMware Check"
    $connected = connect-vcenter

    IF ($connected)
    {

    IF ($DropDownTextBox.Text -eq "" -and $DropDown.SelectedItem.ToString() -ne "All") { $status.text = "Warning: Nothing was typed in the search filter" }

    ELSE
    {
        $hosts = get-filterhosts

        IF($hosts -ne $null)
        {
            $count = $hosts.length

            IF($VMDNSCheckbox.Checked -eq $true)          { $output += $hosts | get-vmdnsservers       | ConvertTo-HTML -AS Table -Fragment -PreContent "<H2>DNS Servers for $count Host(s)</h2>"       | out-string }
            IF($VMNTPCheckbox.Checked -eq $true)          { $output += $hosts | get-vmntp              | ConvertTo-HTML -AS Table -Fragment -PreContent "<H2>NTP Servers for $count Host(s)</h2>"       | out-string }
            IF($VMSyslogCheckbox.Checked  -eq $true)      { $output += $hosts | get-vmsyslog           | ConvertTo-HTML -AS Table -Fragment -PreContent "<H2>Syslog Servers for $count Host(s)</h2>"    | out-string }
            IF($VMSNMPCheckbox.Checked  -eq $true)        { $output += $hosts | get-vmsnmp             | ConvertTo-HTML -AS Table -Fragment -PreContent "<H2>SNMP Servers for $count Host(s)</h2>"      | out-string }
            IF($VMAdvancedCheckbox.Checked  -eq $true)    { $output += $hosts | get-vmadvancedsettings | ConvertTo-HTML -AS Table -Fragment -PreContent "<H2>Advanced Settings for $count Host(s)</h2>" | out-string }
            IF($VMScratchSpaceCheckbox.Checked  -eq $true){ $output += $hosts | get-vmscratchspace     | ConvertTo-HTML -AS Table -Fragment -PreContent "<H2>Scratch Space for $count Host(s)</h2>"     | out-string }
            IF($VMVAAICheckbox.Checked  -eq $true)        { $output += $hosts | get-vaai               | ConvertTo-HTML -AS Table -Fragment -PreContent "<H2>VAAI for $count Host(s)</h2>"              | out-string }
            IF($VMFirewallCheckbox.Checked  -eq $true)    { $output += $hosts | get-vmfirewall         | ConvertTo-HTML -as Table -Fragment -PreContent "<H2>Firewall Settings for $count Host(s)</h2>" | Out-String }
            IF($VMNetworkingCheckbox.Checked -eq $true)   { $output += $hosts | get-vmnetworking       | ConvertTo-HTML -as Table -Fragment -PreContent "<H2>Networking for $count Host(s)</h2>"        | Out-String }
            IF($VMCoreDumpCheckbox.Checked -eq $true)     { $output += $hosts | get-vmcoredump         | ConvertTo-HTML -as Table -Fragment -PreContent "<H2>Core Dump $count Host(s)</H2>"             | Out-String }

            IF($VMMOBCheckbox.Checked  -eq $true){$output += $hosts | get-mob -username $esxiuserTextBox.text -password $esxiPassTextBox.Text | ConvertTo-Html -as Table -Fragment -PreContent "<H2>Mob Service</h2>" | Out-String}
            IF($VMVPLEXCheckbox.Checked -eq $true){$output += $hosts | get-vplex | ConvertTo-Html -as Table -Fragment -PreContent "<H2>VPLEX Settings</H2>" | Out-String}
            IF($VMXtremIOCheckbox.Checked -eq $true)
            {
                IF($VMXtremIODropDown.SelectedItem.ToString() -eq "XtremIO")
                {
                    $output += $hosts | get-xtremio -StorageArray "XtremIO" | ConvertTo-Html -as Table -Fragment -PreContent "<H2>XtremIO Settings - Xbrick</H2>" | Out-String
                }
                ELSEIF($VMXtremIODropDown.SelectedItem.ToString() -eq "VNX")
                {
                    $output += $hosts | get-xtremio -StorageArray "VNX"| ConvertTo-Html -as Table -Fragment -PreContent "<H2>XtremIO Settings - VNX</H2>" | Out-String
                }
                ELSEIF($VMXtremIODropDown.SelectedItem.ToString() -eq "VMAX")
                {
                    $output += $hosts | get-xtremio -StorageArray "VMAX" | ConvertTo-Html -as Table -Fragment -PreContent "<H2>XtremIO Settings - VMAX</H2>" | Out-String
                }
                ELSEIF($VMXtremIODropDown.SelectedItem.ToString() -eq "Multi-Array")
                {
                    $output += $hosts | get-xtremio -StorageArray "Multi-Array" | ConvertTo-Html -as Table -Fragment -PreContent "<H2>XtremIO Settings - Multi-Array Configuration</H2>" | Out-String
                }
                ELSEIF($VMXtremIODropDown.SelectedItem.ToString() -eq "VPLEX")
                {
                    $output += $hosts | get-xtremio -StorageArray "VPLEX" | ConvertTo-Html -as Table -Fragment -PreContent "<H2>XtremIO Settings - VPLEX</H2>" | Out-String
                }
            }
            IF($VMDomainCheckbox.Checked -eq $true){$output += $hosts | get-vmdomainname | ConvertTo-Html -as Table -Fragment -PreContent "<H2>DomainName Settings</H2>" | Out-String}
            IF($VMATSLockCheckbox.checked -eq $true)
            {
                IF($selectvCenterDropDown.SelectedItem.ToString() -eq "vCenter 1"){$atsvcenter = $vCenter1TextBox.Text}
                ELSEIF($selectvCenterDropDown.SelectedItem.ToString() -eq "vCenter 2"){$atsvcenter = $vCenter2TextBox.Text}
                ELSEIF($selectvCenterDropDown.SelectedItem.ToString() -eq "vCenter 3"){$atsvcenter = $vCenter3TextBox.Text}
                ELSEIF($selectvCenterDropDown.SelectedItem.ToString() -eq "vCenter 4"){$atsvcenter = $vCenter4TextBox.Text}
                ELSEIF($selectvCenterDropDown.SelectedItem.ToString() -eq "vCenter 5"){$atsvcenter = $vCenter5TextBox.Text}

                $vcversion = (get-view -server $atsvcenter ServiceInstance | Select-Object Content).content.about.version

                IF($vcversion -eq "6.0.0")
                {
                    $output += $hosts | get-atslockmode_v6 | ConvertTo-Html -as Table -Fragment -PreContent "<H2>ATS Locking Check for vCenter $vcversion</H2>" | Out-String
                }
                ELSE
                {
                    $output += $hosts | get-atslockmode -esxiPwd $esxiPassTextBox.text | ConvertTo-Html -as Table -Fragment -PreContent "<H2>ATS Locking Check for vCenter $vcversion</H2>" | Out-String
                }
            }
            IF($VMVersionCheckbox.Checked -eq $true)      
            {
                $esxclicomp = get-view -ViewType HostSystem | Sort-Object Name
                $output += $hosts | get-vmversion -esxclicomp $esxclicomp | ConvertTo-HTML -AS Table -Fragment -PreContent "<H2>Host Version Information for $count Host(s)</h2>" | out-string
            } # End vSphere Version Check
            IF($VMRDMCheckbox.Checked -eq $true)      
            {
                $output += $hosts | get-vmrdm | ConvertTo-Html -as Table -Fragment -PreContent "<H2>Host RDM Settings</H2>" | Out-String
            } # End vSphere Version Check
            IF($VMSMARTDCheckbox.Checked -eq $true)      
            {
                $output += $hosts | get-vmsmartd -username $esxiuserTextBox.text -password $esxiPassTextBox.Text | ConvertTo-Html -as Table -Fragment -PreContent "<H2>Host SMARTD Status</H2>" | Out-String
            } # End vSphere Version Check

        $fileoutputpath = (Join-Path $outputtextbox.text -ChildPath "VMware")
        IF(!(Test-Path $fileoutputpath)){new-item $fileoutputpath -ItemType directory | Out-Null}
        $fileoutputpath = (Join-Path $fileoutputpath -ChildPath $selectvCenterDropDown.SelectedItem.ToString())
        IF(!(Test-Path $fileoutputpath)){new-item $fileoutputpath -ItemType directory | Out-Null}

        $fileoutput = $fileoutputpath + "\vce-lbg-$TIMESTAMP-check.html"

        ConvertTo-HTML -head $style -PostContent "$output <BR><i>report generated: $(Get-Date)</i>" | 
            Out-File $fileoutput

        & $fileoutput

        }
        ELSE{write-host "Filter produced no hosts" -ForegroundColor Yellow}
    }

    Disconnect-VIServer * -Force -Confirm:$false
    Write-Host "Completed VMware Check"
    $status.Text = "Completed VMware Check"

    } # End if Connected

IF($Debug){Stop-Transcript}

} # End Function check-config

Function connect-vcenter
{

IF((get-PsSnapin -registered | ? {$_.Name -eq "VMware.VimAutomation.Core"}) -eq $null){$everythingok = $false; [System.Windows.Forms.MessageBox]::Show("PowerCLI is not installed","Error",0,16)}
ELSEIF((get-pssnapin | ? {$_.Name -eq "VMware.VimAutomation.Core"}) -eq $null){$everythingok = $true; write-host "Adding Vmware PowerCLI Module"; Add-PSSnapin VMware.VimAutomation.Core}
ELSE{$everythingok = $true}

    IF($selectvCenterDropDown.SelectedItem.ToString() -eq "vCenter 1") 
    {
        IF($vCenter1TextBox.Text -eq '' -or $vc1userTextBox.text -eq '' -or ($VC1LogOnCredsCheckBox.Checked -eq $false -and $vc1passwordTextBox.text -eq "")){$status.Text = "Warning: A mandatory field was not specified"}
        ELSE
        {
            IF($VC1LogOnCredsCheckBox.checked -eq $false)
            {
                Write-Host "Connecting to vCenter" $vCenter1TextBox.Text
                Try{$everything_ok = $true; Connect-VIServer $vCenter1TextBox.Text -user $vc1userTextBox.text -Password $vc1passwordTextBox.text -WA SilentlyContinue -ErrorAction Stop} 
                Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter1TextBox.Text "because of Invalid Credentials" -ForegroundColor Red}
                Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException] { $everything_ok = $false; write-host "Failed to Connect to" $vCenter1TextBox.Text "because not a valid vCenter Server" -ForegroundColor Red}
            }
            Else
            {
                Write-Host "Connecting to vCenter" $vCenter1TextBox.Text
                Try{$everything_ok = $true; Connect-VIServer $vCenter1TextBox.Text -WA SilentlyContinue -ErrorAction Stop} 
                Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter1TextBox.Text "because of Invalid Credentials" -ForegroundColor Red}
                Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException] { $everything_ok = $false; write-host "Failed to Connect to" $vCenter1TextBox.Text "because not a valid vCenter Server" -ForegroundColor Red}
            }
        }
    }

    ELSEIF($selectvCenterDropDown.SelectedItem.ToString() -eq "vCenter 2") 
    {
        IF($vCenter2TextBox.Text -eq '' -or $vc2userTextBox.text -eq '' -or ($VC2LogOnCredsCheckBox.Checked -eq $false -and $vc2passwordTextBox.text -eq "")){$status.Text = "Warning: A mandatory field was not specified"}
        ELSE
        {
            IF($VC2LogOnCredsCheckBox.checked -eq $false)
            {
                Write-Host "Connecting to vCenter" $vCenter2TextBox.Text
                Try{$everything_ok = $true; Connect-VIServer $vCenter2TextBox.Text -user $vc2userTextBox.text -Password $vc2passwordTextBox.text -WA SilentlyContinue -ErrorAction Stop} 
                Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter2TextBox.Text "because of Invalid Credentials" -ForegroundColor Red}
                Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException] { $everything_ok = $false; write-host "Failed to Connect to" $vCenter2TextBox.Text "because not a valid vCenter Server" -ForegroundColor Red}
            }
            Else
            {
                Write-Host "Connecting to vCenter" $vCenter2TextBox.Text
                Try{$everything_ok = $true; Connect-VIServer $vCenter2TextBox.Text -WA SilentlyContinue -ErrorAction Stop} 
                Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter2TextBox.Text "because of Invalid Credentials" -ForegroundColor Red}
                Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException] { $everything_ok = $false; write-host "Failed to Connect to" $vCenter2TextBox.Text "because not a valid vCenter Server" -ForegroundColor Red}
            }
        }
    }

    ELSEIF($selectvCenterDropDown.SelectedItem.ToString() -eq "vCenter 3") 
    {
        IF($vCenter3TextBox.Text -eq '' -or $vc3userTextBox.text -eq '' -or ($VC3LogOnCredsCheckBox.Checked -eq $false -and $vc3passwordTextBox.text -eq "")){$status.Text = "Warning: A mandatory field was not specified"}
        ELSE
        {
            IF($VC3LogOnCredsCheckBox.checked -eq $false)
            {
                Write-Host "Connecting to vCenter" $vCenter3TextBox.Text
                Try{$everything_ok = $true; Connect-VIServer $vCenter3TextBox.Text -user $vc3userTextBox.text -Password $vc3passwordTextBox.text -WA SilentlyContinue -ErrorAction Stop} 
                Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter3TextBox.Text "because of Invalid Credentials" -ForegroundColor Red}
                Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException] { $everything_ok = $false; write-host "Failed to Connect to" $vCenter3TextBox.Text "because not a valid vCenter Server" -ForegroundColor Red}
            }
            Else
            {
                Write-Host "Connecting to vCenter" $vCenter3TextBox.Text
                Try{$everything_ok = $true; Connect-VIServer $vCenter3TextBox.Text -WA SilentlyContinue -ErrorAction Stop} 
                Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter3TextBox.Text "because of Invalid Credentials" -ForegroundColor Red}
                Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException] { $everything_ok = $false; write-host "Failed to Connect to" $vCenter3TextBox.Text "because not a valid vCenter Server" -ForegroundColor Red}
            }
        }
    }
    ELSEIF($selectvCenterDropDown.SelectedItem.ToString() -eq "vCenter 4") 
    {
        IF($vCenter4TextBox.Text -eq '' -or $vc4userTextBox.text -eq '' -or ($VC4LogOnCredsCheckBox.Checked -eq $false -and $vc4passwordTextBox.text -eq "")){$status.Text = "Warning: A mandatory field was not specified"}
        ELSE
        {
            IF($VC4LogOnCredsCheckBox.checked -eq $false)
            {
                Write-Host "Connecting to vCenter" $vCenter4TextBox.Text
                Try{$everything_ok = $true; Connect-VIServer $vCenter4TextBox.Text -user $vc4userTextBox.text -Password $vc4passwordTextBox.text -WA SilentlyContinue -ErrorAction Stop} 
                Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter4TextBox.Text "because of Invalid Credentials" -ForegroundColor Red}
                Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter4TextBox.Text "because not a valid vCenter Server" -ForegroundColor Red}
            }
            Else
            {
                Write-Host "Connecting to vCenter" $vCenter4TextBox.Text
                Try{$everything_ok = $true; Connect-VIServer $vCenter4TextBox.Text -WA SilentlyContinue -ErrorAction Stop} 
                Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter4TextBox.Text "because of Invalid Credentials" -ForegroundColor Red}
                Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter4TextBox.Text "because not a valid vCenter Server" -ForegroundColor Red}
            }
        }
    }
    ELSEIF($selectvCenterDropDown.SelectedItem.ToString() -eq "vCenter 5") 
    {
        IF($vCenter5TextBox.Text -eq '' -or $vc5userTextBox.text -eq '' -or ($VC5LogOnCredsCheckBox.Checked -eq $false -and $vc5passwordTextBox.text -eq "")){$status.Text = "Warning: A mandatory field was not specified"}
        ELSE
        {
            IF($VC5LogOnCredsCheckBox.checked -eq $false)
            {
                Write-Host "Connecting to vCenter" $vCenter5TextBox.Text
                Try{$everything_ok = $true; Connect-VIServer $vCenter5TextBox.Text -user $vc5userTextBox.text -Password $vc5passwordTextBox.text -WA SilentlyContinue -ErrorAction Stop} 
                Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter5TextBox.Text "because of Invalid Credentials" -ForegroundColor Red}
                Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter5TextBox.Text "because not a valid vCenter Server" -ForegroundColor Red}
            }
            Else
            {
                Write-Host "Connecting to vCenter" $vCenter5TextBox.Text
                Try{$everything_ok = $true; Connect-VIServer $vCenter5TextBox.Text -WA SilentlyContinue -ErrorAction Stop} 
                Catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter5TextBox.Text "because of Invalid Credentials" -ForegroundColor Red}
                Catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException]{$everything_ok = $false; write-host "Failed to Connect to" $vCenter5TextBox.Text "because not a valid vCenter Server" -ForegroundColor Red}
            }
        }
    }

Return $everything_ok

} # End Function connect-vcenter

Function add-versyscomponent 
{

Param
(
    $data
)
    $excel = New-Object OfficeOpenXml.ExcelPackage $ReportXLSXFile
    $sheet = $excel.Workbook.Worksheets["System Versions"]

    IF($data -ne $null)
    {
        $sheet.InsertRow($row3+1,1,$ro3+1)
        $sheet.cells[$row3,$col].Value     = $data.device
        $sheet.cells[$row3,($col+1)].Value = $data.model
        $sheet.cells[$row3,($col+2)].Value = $data.serial
        $sheet.cells[$row3,($col+3)].Value = $data.version
        $range = $sheet.Cells[$row3,$col,$row3,($col+3)]
        $range.Style.Border.Left.Style   = "Thin"
        $range.Style.Border.Bottom.Style = "Thin"
        $range.Style.Border.Right.Style  = "Thin"
        $range.Style.Border.Top.Style    = "Thin"
    }

    $sheet.Cells[1,2,$sheet.Dimension.rows,5].AutoFitColumns()
    $excel.Save()
  
} # End Function ver-syscomponent

Function collect-xmldata
{
    [cmdletbinding()]

    Param(
        # OutputType defines desired output value
        [parameter()]
        [ValidateSet("online", "offline", "both")]
        $xmlfiles
    )

    # Declare Variables

    $ReportXMLFiles = @{}
    $crgonline  = $false
    $ucsfound   = $false
    $vcfound    = $false
    $otherfound = $false
    foreach($item in $arrayucscheckboxes){IF($item.checked -eq $true){$ucsfound = "true"}}
    foreach($item in $arrayvccheckboxes){IF($item.checked -eq $true){$vcfound = "true"}}
    foreach($item in $arrayothercheckboxes){IF($item.checked -eq $true){$otherfound = "true"}}
    foreach($item in $arrayonlinecheckboxes){IF($item.checked -eq $true){$crgonline = "true"}}

#region Online

    IF($xmlfiles -eq "online" -or $xmlfiles -eq "both")
    {

    $vpnmessage = @"
The Cisco VPN connection was detected and in most cases this will interfere with the CRG Collection process.

Change the Cisco VPN connection to the desired state and press ok
"@

        IF($crgonline -eq "true")
        {
            $vpn = Get-WmiObject win32_networkadapterconfiguration -filter "IPEnabled = 'true'" | Where-Object {$_.Description -like "Cisco AnyConnect Secure Mobility Client*"}
            IF($vpn -ne $null){$result = [System.Windows.Forms.MessageBox]::Show($vpnmessage,"VPN Detected",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)}
        }

        IF($crgonline -eq "false"){Write-Warning "Nothing was checked"}

        IF($ucsfound)
        {
            $i = 1

            do
            {
                $output = (Join-Path $outputtextbox.text -ChildPath "Compute")
                IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

                IF($ucsonlinecheckboxes[$i-1].checked)
                {
                    $output = (Join-Path $output -ChildPath "UCS Cluster $i")
                    IF(!(Test-Path $output)){new-item $output -ItemType directory | out-null}

                    $username = get-variable ("UCS$i" + "userTextBox")
                    $password = get-variable ("UCS$i" + "passTextBox")
                    $devip    = get-variable ("UCS$i" + "IP1TextBox")

                    $ReportXMLFile = & $PS_UCSB -OutputPath $output -username $username.value.text -password $password.value.text -OutputType "xml" -devip ($devip.value.text).trim()
                
                    IF($ReportXMLFile -ne $null)
                    {
                        $ReportXMLFiles.Add("UCS Cluster $i",$ReportXMLFile)
                        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster $i" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
                    }
                }
                $i++
            }while($i -ne 6)
        }

        IF($C2XXCheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Compute")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $devip = @()
        
            if($C2XXRangeCheckBox.Checked)
            {
                $devipa = ($C2XXIP1TextBox.text).trim()
                $devipb = ($C2XXIP2TextBox.text).trim()

                IF($devipb -ne "")
                {
	                [string]$DevIPA_1 = $DevIPA.split(".")[0]
	                [string]$DevIPA_2 = $DevIPA.split(".")[1].trim()
	                [string]$DevIPA_3 = $DevIPA.split(".")[2].trimend()
	                [int]$DevIPA_last = $DevIPA.split(".")[3]
	                [int]$DevIPB_last = [int]$DevIPB.split(".")[3] +1
                
                    for($i= $DevIPA_last ; $i -lt $DevIPB_last ; $i++ )
                    { 
	                    [string]$C2xxIP = $DevIPA_1,".",$DevIPA_2,".",$DevIPA_3,".",$i
	                    $devip += $C2xxIP.replace(" ","")
	                }
                }
            }
            ELSE
            {
                $devip = ($C2XXIP1TextBox.text).trim(),($C2XXIP2TextBox.text).trim(); $devip = $devip | ? {$_}
            }
         
            $ReportXMLFile = & $PS_UCSC -OutputPath $output -username $C2XXuserTextBox.text -password $C2XXpassTextBox.Text -OutputType "xml" -DevIP $devip
            IF($ReportXMLFile -ne $null)
            {
                [xml]$data  = Get-Content $ReportXMLFile
                IF($data.root.ucsc -ne "")
                {
                    $ReportXMLFiles.Add("C2XX",$ReportXMLFile)
                    $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C2XX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                    $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
                }
            }
        }

        IF($3560CheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Network")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            IF($3560CheckBox.Checked)        
            { 
                $devip = ($3560IP1TextBox.text).trim(),($3560IP2TextBox.text).trim(); $devip = $devip | ? {$_}
                $ReportXMLFile = & $PS_C35 -OutputPath $output -username $3560userTextBox.text -password $3560passTextBox.Text -OutputType "xml" -DevIP $devip

                IF($ReportXMLFile -ne $null)
                {
                    $ReportXMLFiles.Add("C3560",$ReportXMLFile)
                    $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C3560" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                    $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
                }
            }
        }

        IF($3750CheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Network")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $ReportXMLFile = & $PS_C37 -OutputPath $output -username $3750userTextBox.Text -password $3750passTextBox.Text -OutputType "xml" -DevIP ($3750IP1TextBox.text).trim()
            
            IF($ReportXMLFile -ne $null)
            {
                $ReportXMLFiles.Add("C3750",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C3750" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($1000CheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Network")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $ReportXMLFile = & $PS_N1k -OutputPath $output -username $1000userTextBox.text -password $1000passTextBox.Text -OutputType "xml" -DevIP ($1000IP1TextBox.text).trim()
            
            IF($ReportXMLFile -ne $null)
            {
                $ReportXMLFiles.Add("1000v",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "1000v" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($3048CheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Network")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
            $output = (Join-Path $output -ChildPath "Nexus Management")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $devip = ($3048IP1TextBox.Text).trim(),($3048IP2TextBox.Text).trim(); $devip = $devip | ? {$_}
            $ReportXMLFile = & $PS_NX -OutputPath $output -username $3048userTextBox.text -password $3048passTextBox.Text -OutputType "xml" -DevIP $devip
            $ReportXMLFile = $ReportXMLFile | ? {$_}

            IF($ReportXMLFile -ne $null)
            {
                $ReportXMLFiles.Add("Nexus Management",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Management" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($55XXCheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Network")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
            $output = (Join-Path $output -ChildPath "Nexus Aggregate")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $devip = ($55XXIP1TextBox.Text).trim(),($55XXIP2TextBox.Text).trim(); $devip = $devip | ? {$_}
            $ReportXMLFile = & $PS_NX -OutputPath $output -username $55XXuserTextBox.text -password $55XXpassTextBox.Text -OutputType "xml" -DevIP $devip
            $ReportXMLFile = $ReportXMLFile | ? {$_}

            IF($ReportXMLFile -ne $null)
            {
                $ReportXMLFiles.Add("Nexus Aggregate",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Aggregate" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($55XX2CheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Network")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
            $output = (Join-Path $output -ChildPath "Nexus BRS")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $devip = ($55XX2IP1TextBox.Text).trim(),($55XX2IP2TextBox.Text).trim(); $devip = $devip | ? {$_}
            $ReportXMLFile = & $PS_NX -OutputPath $output -username $55XX2userTextBox.text -password $55XX2passTextBox.Text -OutputType "xml" -DevIP $devip
            $ReportXMLFile = $ReportXMLFile | ? {$_}

            IF($ReportXMLFile -ne $null)
            {
                $ReportXMLFiles.Add("Nexus BRS",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus BRS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($55XX3CheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Network")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
            $output = (Join-Path $output -ChildPath "Nexus Isilon")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $devip = ($55XX3IP1TextBox.Text).trim(),($55XX3IP2TextBox.Text).trim(); $devip = $devip | ? {$_}
            $ReportXMLFile = & $PS_NX -OutputPath $output -username $55XX3userTextBox.text -password $55XX3passTextBox.Text -OutputType "xml" -DevIP $devip
            $ReportXMLFile = $ReportXMLFile | ? {$_}

            IF($ReportXMLFile -ne $null)
            {
                $ReportXMLFiles.Add("Nexus Isilon",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Isilon" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($N7KCheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Network")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
            $output = (Join-Path $output -ChildPath "Nexus Core")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $devip = ($N7KIP1TextBox.Text).trim(),($N7KIP2TextBox.Text).trim(); $devip = $devip | ? {$_}
            $ReportXMLFile = & $PS_NX -OutputPath $output -username $N7KuserTextBox.text -password $N7KpassTextBox.Text -OutputType "xml" -DevIP $devip
            $ReportXMLFile = $ReportXMLFile | ? {$_}

            IF($ReportXMLFile -ne $null)
            {
                $ReportXMLFiles.Add("Nexus Core",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Core" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($MDSCheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Network")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            IF($MDSCheckBox.Checked)        
            { 
                $devip = ($MDSIP1TextBox.Text).trim(),($MDSIP2TextBox.Text).trim(); $devip = $devip | ? {$_}
                $ReportXMLFile = & $PS_MDS -OutputPath $output -username $MDSuserTextBox.text -password $MDSpassTextBox.Text -OutputType "xml" -DevIP $devip

                IF($ReportXMLFile -ne $null)
                { 
                    $ReportXMLFiles.Add("MDS",$ReportXMLFile)
                    $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "MDS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                    $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
                }
            }
        }

        IF($vcfound)
        {
            $i = 1

            do
            {
                IF($vconlinecheckboxes[$i-1].checked)
                {
                    $output = (Join-Path $outputtextbox.text -ChildPath "VMware")
                    IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
                    $output = (Join-Path $output -ChildPath "vCenter $i")
                    IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

                    $username = get-variable ("vc$i" + "userTextBox")
                    $password = get-variable ("vc$i" + "passwordTextBox")
                    $devip    = get-variable ("vCenter$i" + "TextBox")

                    $ReportXMLFile = & $PS_VMWr -OutputPath $output -username $username.value.text -password $password.value.text -OutputType "xml" -devip ($devip.value.text).trim() -ReportXLSXFile $ReportXLSXFile `
                        -loggedoncreds:([System.Convert]::ToBoolean($VC5LogOnCredsCheckBox.checked))

                    IF($ReportXMLFile -ne $null)
                    {                
                        $ReportXMLFiles.Add("vCenter $i",$ReportXMLFile)
                        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter $i" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                        $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
                    }
                }
            $i++
            }while($i -ne 6)
        }

        IF($VNXeCheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Storage")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
    
            $ReportXMLFile = & $PS_VNXe -OutputPath $output -username $VNXeuserTextBox.Text -password $VNXepassTextBox.Text -OutputType "xml" -DevIP ($VNXeIP1TextBox.Text).trim()
            IF($ReportXMLFile -ne $null)
            {            
                $ReportXMLFiles.Add("VNXe",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VNXe" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }
		
		IF($UnityCheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Storage")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
    
            $ReportXMLFile = & $PS_Unity -OutputPath $output -username $UnityuserTextBox.Text -password $UnitypassTextBox.Text -OutputType "xml" -DevIP ($UnityIP1TextBox.Text).trim()
            IF($ReportXMLFile -ne $null)
            {            
                $ReportXMLFiles.Add("Unity",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Unity" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }
		
        IF($VNXCheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Storage")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
    
            $ReportXMLFile = & $PS_VNX -OutputPath $Output -username $VNXuserTextBox.Text -password $VNXpassTextBox.Text -OutputType "xml" -devip ($VNXIP1TextBox.Text).trim()
            IF($ReportXMLFile -ne $null)
            {            
                $ReportXMLFiles.Add("VNX",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VNX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($NASCheckBox.Checked)
        {
            $output = (Join-Path $outputtextbox.text -ChildPath "Storage")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $ReportXMLFile = & $PS_NAS -OutputPath $output -username $NASuserTextBox.Text -password $NASpassTextBox.Text -OutputType "xml" -devip ($NASIP1TextBox.text).trim()
            IF($ReportXMLFile -ne $null)
            {            
                $ReportXMLFiles.Add("NAS",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "NAS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($XtremIOCheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Storage")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $ReportXMLFile = & $PS_XtremIO -OutputPath $output -username $XtremIOuserTextBox.Text -password $XtremIOpassTextBox.Text -OutputType "xml" -DevIP ($XtremIOIP1TextBox.Text).trim()
            IF($ReportXMLFile -ne $null)
            {            
                $ReportXMLFiles.Add("XtremIO",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "XtremIO" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($VPLEXCheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "Storage")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $devip = ($VPLEXIP1TextBox.Text).trim(),($VPLEXIP2TextBox.Text).trim(); $devip = $devip | ? {$_}
            $ReportXMLFile = & $PS_VPLEX -OutputPath $output -username $VPLEXUserTextBox.Text -Password $VPLEXpassTextBox.Text -OutputType "xml" -DevIP $devip
            IF($ReportXMLFile -ne $null)
            {            
                $ReportXMLFiles.Add("VPLEX",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VPLEX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }  

        IF($IsilonCheckBox.Checked)
        {
            $output = (Join-Path $outputtextbox.text -ChildPath "Storage")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $ReportXMLFile = & $PS_Isilon -OutputPath $output -username $IsilonuserTextBox.Text -Password $IsilonpassTextBox.Text -OutputType "xml" -DevIP ($IsilonIP1TextBox.Text).trim()
            IF($ReportXMLFile -ne $null)
            {            
                $ReportXMLFiles.Add("Isilon",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Isilon" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($NSXCheckBox.Checked)
        {
            $output = (Join-Path $outputtextbox.text -ChildPath "VMware")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

            $ReportXMLFile = & $PS_NSX -OutputPath $output -username $NSXuserTextBox.Text -Password $NSXpasswordTextBox.Text -OutputType "xml" -DevIP ($NSXIPTextBox.Text).trim()
            IF($ReportXMLFile -ne $null)
            {            
                $ReportXMLFiles.Add("NSX",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "NSX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }

        IF($IPICheckBox.Checked)
        { 
            $output = (Join-Path $outputtextbox.text -ChildPath "MISC")
            IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
            
            $devip = @()
        
            if($IPIRangeCheckBox.Checked)
            {
                $devipa = ($IPIIP1TextBox.text).trim()
                $devipb = ($IPIIP2TextBox.text).trim()

                IF($devipb -ne "")
                {
	                [string]$DevIPA_1 = $DevIPA.split(".")[0]
	                [string]$DevIPA_2 = $DevIPA.split(".")[1].trim()
	                [string]$DevIPA_3 = $DevIPA.split(".")[2].trimend()
	                [int]$DevIPA_last = $DevIPA.split(".")[3]
	                [int]$DevIPB_last = [int]$DevIPB.split(".")[3] +1
                
                    for($i= $DevIPA_last ; $i -lt $DevIPB_last ; $i++ )
                    { 
	                    [string]$IPIIP = $DevIPA_1,".",$DevIPA_2,".",$DevIPA_3,".",$i
	                    $devip += $IPIIP.replace(" ","")
	                }
                }
            }
            ELSE
            {
                $devip = ($ipiIP1TextBox.text).trim(),($ipiIP2TextBox.text).trim(); $devip = $devip | ? {$_}
            }
         
            $ReportXMLFile = & $PS_IPI -OutputPath $output -username $IPIuserTextBox.text -password $IPIpasswordTextBox.Text -OutputType "xml" -DevIP $devip
            
            IF($ReportXMLFile -ne $null)
            {
                $ReportXMLFiles.Add("IPI",$ReportXMLFile)
                $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "IPI" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
                $tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $ReportXMLFile
            }
        }
    }

#endregion Online

#region Offline

    IF($xmlfiles -eq "offline" -or $xmlfiles -eq "both")
    {
        For($i=0;$i -lt $tabCRGOfflinedatagrid.RowCount;$i++)
        {
            IF(($tabCRGOfflinedatagrid.Rows[$i].Cells[2].Value -ne "") -and ($tabCRGOfflinedatagrid.Rows[$i].Cells[0].Value -eq $true))
            {
                IF(Test-Path $tabCRGOfflinedatagrid.Rows[$i].Cells[2].Value)
                {
                    $ReportXMLFiles.Add($tabCRGOfflinedatagrid.Rows[$i].Cells[1].Value,$tabCRGOfflinedatagrid.Rows[$i].Cells[2].Value)
                }
            }
        }
    }

#endregion Offline

    write-host "CRG Data Collection Complete"
    $status.Text = "CRG Data Collection Complete"
		
    return $ReportXMLFiles

} # End Function collect-xmldata

Function create-crgreport
{

[cmdletbinding()]

Param
(
    $ReportXMLFiles = @{}
)

# Declare Variables

    $output         = $outputtextbox.text
    $systemserial   = $SerialNumberTextBox.text
    $ReportXLSXFile = "$output\VCE`_$systemserial`_$TIMESTAMP`_CRG.xlsx"
    IF($dropdownsystype.SelectedItem.ToString() -ne "System Type"){$systemmodel = $dropdownsystype.SelectedItem.ToString()}ELSE{$systemmodel = $null}
    IF($dropdownrcm.SelectedItem.ToString() -ne "RCM Version"){$systemrcm = $dropdownrcm.SelectedItem.ToString()}ELSE{$systemrcm = $null}

    IF($Debug)
    { 
        IF(!(Test-Path "$scriptPath\Logs")){New-Item "$scriptPath\Logs" -ItemType directory | Out-Null}
        $crgreportlog = "$scriptpath\Logs\CRG_CreateXLS_$systemserial`_$TIMESTAMP`_log.rtf"
        Start-Transcript $crgreportlog
    }

    write-host "CRG Report Creation Started"
    $status.Text = "CRG Report Creation Started"

    $crgonline  = $false
    $ucsfound   = $false
    $vcfound    = $false
    $otherfound = $false

    IF(($ReportXMLFiles.keys | Where-Object {$_ -like "UCS Cluster*"}) -ne $null){$ucsfound = "true"}
    IF(($ReportXMLFiles.keys | Where-Object {$_ -like "vCenter*"}) -ne $null){$vcfound = "true"}
    IF(($ReportXMLFiles.keys | Where-Object {$_ -notlike "vCenter*"} | where-object {$_ -notlike "UCS Cluster*"}) -ne $null){$otherfound = "true"}

    $row1       = 0
    $row2       = 0
    $row3       = 0
    $row4       = 0

# There is no prompt for overwrite with Excel and it will fail if file exists.  As a result we are going to delete a file with the same name before creating new one  

    IF(Test-Path $ReportXLSXFile){Remove-Item $ReportXLSXFile}

#region build header

    $excel = New-Object OfficeOpenXml.ExcelPackage $ReportXLSXFile
    $sheet = $excel.Workbook.Worksheets.Add("Introduction")

    IF($sheet.Workbook.Styles.NamedStyles.name -notcontains "Good")
    {
        $good    = $excel.Workbook.Styles.CreateNamedStyle("good")
        $good.Style.Font.Color.SetColor((convert-RGB 0 97 0))
        $good.Style.Fill.PatternType = "Solid"
        $good.Style.Fill.BackgroundColor.SetColor((convert-RGB 198 239 206))
        $good.Style.HorizontalAlignment = "Center"

        $neutral = $excel.Workbook.Styles.CreateNamedStyle("neutral")
        $neutral.Style.Font.Color.SetColor((convert-RGB 156 101 0))
        $neutral.Style.Fill.PatternType = "Solid"
        $neutral.Style.Fill.BackgroundColor.SetColor((convert-RGB 255 235 156))
        $neutral.Style.HorizontalAlignment = "Center"

        $input   = $excel.Workbook.Styles.CreateNamedStyle("input")
        $input.Style.Font.Color.SetColor((convert-RGB 63 63 118))
        $input.Style.Fill.PatternType = "Solid"
        $input.Style.Fill.BackgroundColor.SetColor((convert-RGB 255 204 153))
        $input.Style.HorizontalAlignment = "Center"

        $bad     = $excel.Workbook.Styles.CreateNamedStyle("bad")
        $bad.Style.Font.Color.SetColor((convert-RGB 156 0 6))
        $bad.Style.Fill.PatternType = "Solid"
        $bad.Style.Fill.BackgroundColor.SetColor((convert-RGB 255 199 206))
        $bad.Style.HorizontalAlignment = "Center"
    }

    $sheet.view.showgridlines = $false

    $image = [system.drawing.image]::FromFile("$pwd\Bin\Icons\logo.jpg")

    $logo = $sheet.Drawings.AddPicture("Logo", $image)
    $logo.SetPosition(80,193)

    $range = $sheet.cells[5,7,7,13]
    $range.Merge = $true
    $range.Style.HorizontalAlignment = "Left"
    $range.style.VerticalAlignment = "center"
    $range.Style.Font.Size = "48"

    $range.Value = "CRG Report"

    $sheet.Cells[8,7].value = "ver. $myver"
    $sheet.Cells[8,7].Style.Font.Size = "18"

    $date = [datetime]::ParseExact($TIMESTAMP, "yyyyMMdd_hhmmtt", $null)

    $sheet.Cells[8,9].value = "Created: " + "{0:MMMM %d, yyyy}" -f [datetime]$date
    $sheet.Cells[8,9].Style.Font.Size = "18"

    $disclaimer = ""

    $range = $sheet.Cells[10,7,12,13]
    $range.Style.WrapText = $true
    $range.Merge = $true
    $range.Style.HorizontalAlignment = "Left"
    $range.style.VerticalAlignment = "top"
    $range.Value = $disclaimer

    $sheet.Cells[14,4,14,6].Merge = $true
    $sheet.Cells[14,4].Value = "Company Name"
    $sheet.Cells[15,4,15,6].Merge = $true
    $sheet.Cells[15,4].Value = "System Name"
    $sheet.Cells[16,4,16,6].Merge = $true
    $sheet.Cells[16,4].Value = "System Serial"
    $sheet.Cells[17,4,17,6].Merge = $true
    $sheet.Cells[17,4].Value = "System Type"
    $sheet.Cells[18,4,18,6].Merge = $true
    $sheet.Cells[18,4].Value = "RCM Version"
    $sheet.Cells[19,4,19,6].Merge = $true
    $sheet.Cells[19,4].Value = "Original or Addendum"

    $sheet.Cells[14,7,14,12].Merge = $true
    $sheet.Cells[14,7].Value = $CompanyTextBox.Text
    $sheet.Cells[15,7,15,12].Merge = $true
    $sheet.Cells[15,7].Value = $SystemNameTextBox.text
    $sheet.Cells[16,7,16,12].Merge = $true
    $sheet.Cells[16,7].Value = $SerialNumberTextBox.text
    $sheet.Cells[17,7,17,12].Merge = $true
    $sheet.Cells[17,7].Value = $dropdownsystype.SelectedItem.ToString()
    $sheet.Cells[18,7,18,12].Merge = $true
    $sheet.Cells[18,7].Value = $dropdownrcm.SelectedItem.ToString()
    $sheet.Cells[19,7,19,12].Merge = $true
    
    IF($vercustRadio.Checked){$sheet.Cells[19,7].Value = $VersionType =  "Original"}
    ELSEIF($veraddenradio.Checked){$sheet.Cells[19,7].Value = $VersionType = "Addendum"}

    $range = $sheet.Cells[14,4,19,12]
    $range.Style.Border.Left.Style   = "Thin"
    $range.Style.Border.Bottom.Style = "Thin"
    $range.Style.Border.Right.Style  = "Thin"
    $range.Style.Border.Top.Style    = "Thin"

    IF($credentialscheckbox.checked -and (Test-Path("$output\" + "Credentials*CRG.xlsx")))
    {
        $temp = Get-ChildItem("$output\" + "Credentials*CRG.xlsx") | Sort-Object Name
        IF($temp.Count -gt 1){$credsxls = $temp[-1].FullName}
        ELSE{$credsxls = $temp.FullName}

        $excelcred = New-Object OfficeOpenXml.ExcelPackage $credsxls
        $excel.Workbook.Worksheets.Add($excelcred.Workbook.Worksheets["System Credentials"],$excelcred.Workbook.Worksheets["System Credentials"])
        $excelcred.dispose()
    }

    $excel.save()

#endregion build header

    IF($ucsfound)
    {
        $i = 1

        do
        {
            IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "UCS Cluster $i"}) -ne $null)
            {
                $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "UCS Cluster $i"})]
                IF($SystemModel -ne $null -and $SystemRCM -ne $null)
                {
                    & $PS_UCSB -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
                }
                ELSE
                {
                    & $PS_UCSB -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
                }
            }
            $i++
        }while($i -ne 6)
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "C2XX"}) -ne $null)
    { 
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "C2XX"})]

        IF($ReportXMLFile.root.ucsc -ne "")
        {
            IF($SystemModel -ne $null -and $SystemRCM -ne $null)
            {
                & $PS_UCSC -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
            }
            ELSE
            {
                & $PS_UCSC -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
            }
        }
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "C3560"}) -ne $null)
    {
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "C3560"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_C35 -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_C35 -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        }
        IF($portmapcheckbox.checked){& $PS_PortMap -OutputPath $output -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile}
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "C3750"}) -ne $null)
    {
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "C3750"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_C37 -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_C37 -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        }
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "1000v"}) -ne $null)
    {
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "1000v"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_N1k -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_N1k -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        }
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -like "Nexus*"}) -ne $null)
    {

$switchnames = @(
    [pscustomobject]@{Name="Nexus Management";Tab_Name="MGMT-ETH";Switch="Nexus Management"},
    [pscustomobject]@{Name="Nexus Aggregate";Tab_Name="Aggregate-Eth";Switch="Nexus Aggregate"},
    [pscustomobject]@{Name="Nexus BRS";Tab_Name="BRS-Eth";Switch="Nexus BRS"},
    [pscustomobject]@{Name="Nexus Isilon";Tab_Name="Isilon-Eth";Switch="Nexus Isilon"},
    [pscustomobject]@{Name="Nexus Core";Tab_Name="Core-Eth";Switch="Core-Eth"}
)
        ForEach($item in $switchnames.name)
        {
            IF(($ReportXMLFiles.keys | Where-Object {$_ -eq $item}) -ne $null)
            {
                $ReportXMLFile = $ReportXMLFiles[$item]
                $tab_name      = ($switchnames | where-object -property Name -eq $item).Tab_Name
                $switch        = ($switchnames | where-object -property Name -eq $item).Switch

                IF($SystemModel -ne $null -and $SystemRCM -ne $null)
                {
                    & $PS_NX -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -Tab_Name $tab_name -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
                }
                ELSE
                {
                    & $PS_NX -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -Tab_Name $tab_name
                }
                IF($portmapcheckbox.checked){& $PS_PortMap -OutputPath $output -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile}
            }
        }
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "MDS"}) -ne $null)
    {
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "MDS"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_MDS -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_MDS -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        }
        IF($portmapcheckbox.checked){& $PS_PortMap -OutputPath $output -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile}
    }
    IF($vcfound)
    {
        $i = 1

        do
        {
            IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "vCenter $i"}) -ne $null)
            {
                $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "vCenter $i"})]
                IF($SystemModel -ne $null -and $SystemRCM -ne $null)
                {
                    & $PS_VMWr -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
                }
                ELSE
                {
                    & $PS_VMWr -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
                } 
            }
        $i++
        }while($i -ne 6)
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "VNXe"}) -ne $null)
    { 
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "VNXe"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_VNXe -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_VNXe -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        }   
    }
	IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "Unity"}) -ne $null)
    { 
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "Unity"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_Unity -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_Unity -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        }    
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "VNX"}) -ne $null)
    { 
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "VNX"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_VNX -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_VNX -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        }
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "NAS"}) -ne $null)
    { 
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "NAS"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_NAS -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_NAS -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        }
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "XtremIO"}) -ne $null)
    { 
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "XtremIO"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_XtremIO -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_XtremIO -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        } 
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "VMAX"}) -ne $null)
    { 
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "VMAX"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_VMAX -OutputPath $output -OutputType "offline" -SYMAPIDB $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_VMAX -OutputPath $output -OutputType "offline" -SYMAPIDB $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        }
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "VPLEX"}) -ne $null)
    { 
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "VPLEX"})]        
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_VPLEX -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_VPLEX -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        } 
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "Isilon"}) -ne $null)
    {
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "Isilon"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_Isilon -OutputPath $Output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_Isilon -OutputPath $Output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        }
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "NSX"}) -ne $null)
    {
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "NSX"})]
        IF($SystemModel -ne $null -and $SystemRCM -ne $null)
        {
            & $PS_NSX -OutputPath $Output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile -SystemModel $Systemmodel -SystemRCM $SystemRCM -rcm_versions $rcm_versions -versiontype $VersionType
        }
        ELSE
        {
            & $PS_NSX -OutputPath $Output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
        }
    }
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "IPI"}) -ne $null)
    {
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "IPI"})]
        & $PS_IPI -OutputPath $output -OutputType "offline" -ReportXMLFile $ReportXMLFile -ReportXLSXFile $ReportXLSXFile
    }

#region Post Collection tasks

    IF($ReportXMLFiles.count -ne "0")
    {
        IF($vercustRadio.Checked){$VersionType =  "Original"}
        ELSEIF($veraddenradio.Checked){$VersionType = "Addendum"}

        IF($dropdownsystype.SelectedItem.ToString() -ne "System Type"){$systemmodel = $dropdownsystype.SelectedItem.ToString()}ELSE{$systemmodel = $null}
        IF($dropdownrcm.SelectedItem.ToString() -ne "RCM Version"){$systemrcm = $dropdownrcm.SelectedItem.ToString()}ELSE{$systemrcm = $null}
    
        & $PS_Version -ReportXmlFiles $ReportXMLFiles -OutputPath $OutputTextBox.Text -outputtype "Excel" -VBID $SerialNumberTextBox.Text -scrubbed:([System.Convert]::ToBoolean($SCRUBDATA)) `
                      -ReportXLSXFile $ReportXLSXFile `
                      -SystemModel $systemmodel `
                      -SystemRCM $systemrcm `
                      -VersionType $VersionType
    }
    IF($Assessmentcheckbox.checked){& $RP_Assessment -ReportXMLFiles $ReportXMLFiles -ReportXLSXFile $ReportXLSXFile -OutputType "Excel"}

#endregion Post Collection tasks

# Move Sheets

    $excel  = New-Object OfficeOpenXml.ExcelPackage $ReportXLSXFile
    $sheets = $excel.Workbook.Worksheets.Name   
    
    IF($sheets -contains "System Credentials"){$excel.Workbook.Worksheets.MoveToEnd("System Credentials")}
    IF($sheets -contains "System Versions"){$excel.Workbook.Worksheets.MoveToEnd("System Versions")}
    IF($sheets -contains "Health Assessment"){$excel.Workbook.Worksheets.MoveToEnd("Health Assessment")}

    IF($excel.workbook.worksheets.count -gt "1")
    {
        $excel.save()
        write-host "Merged Excel file saved to $ReportXLSXFile"
        $status.text = "Merged Excel file saved to $ReportXLSXFile"
        $showexcel = [System.Windows.Forms.MessageBox]::Show("Display Excel Output? (Requires Excel)" , "Display Output" , 4)
        IF($showexcel -eq "YES"){& $ReportXLSXFile}
    }
    Else
    {
        write-host "Generate CRG Report produced a blank document, so it was not saved"
        IF($Assessmentcheckbox.Checked){Remove-Item $ReportXLSXFile}
        $excel.Dispose()
    }

    IF($Debug){Stop-Transcript}

} # End Function create-crgreport

Function clear-checkboxes
{

$arrayonlinecheckboxes  = $C2XXCheckBox,$UCS1CheckBox,$UCS2CheckBox,$UCS3CheckBox,$UCS4CheckBox,$UCS5CheckBox,
                          $3560CheckBox,$3750CheckBox,$3048CheckBox,$55XXCheckBox,$55XX2CheckBox,$55XX3CheckBox,$1000CheckBox,$MDSCheckBox,$N7KCheckBox,
                          $VNXeCheckBox,$UnityCheckBox,$VNXCheckBox,$NASCheckBox,$XtremIOCheckBox,$VPLEXCheckBox,$IsilonCheckBox,
                          $vCenter1CheckBox,$vCenter2CheckBox,$vCenter3CheckBox,$NSXCheckBox,
                          $IPICheckbox
                         
    foreach($item in $arrayonlinecheckboxes) {IF ($item.checked -eq $true){$item.checked = $false}}
    For($i=0;$i -lt $tabCRGOfflinedatagrid.rowcount-1;$i++){$tabCRGOfflinedatagrid.rows[$i].Cells[0].Value = $false}

} # End Clear-Checkboxes

Function auto-Checkboxes
{

Param(
    # OutputType defines desired output value
    [parameter()]
    [ValidateSet("Online", "Offline", "Both")]
    $checkwhat
)

    IF($checkwhat -eq "Online" -or $checkwhat -eq "Both")
    {
        IF($C2XXIP1TextBox.Text -ne ""){$C2XXCheckBox.Checked = $true}
        IF($UCS1IP1TextBox.Text -ne ""){$UCS1CheckBox.Checked = $true}
        IF($UCS2IP1TextBox.Text -ne ""){$UCS2CheckBox.Checked = $true}
        IF($UCS3IP1TextBox.Text -ne ""){$UCS3CheckBox.Checked = $true}
        IF($UCS4IP1TextBox.Text -ne ""){$UCS4CheckBox.Checked = $true}
        IF($UCS5IP1TextBox.Text -ne ""){$UCS5CheckBox.Checked = $true}
        IF($3560IP1TextBox.Text -ne ""){$3560CheckBox.Checked = $true}
        IF($3750IP1TextBox.Text -ne ""){$3750CheckBox.Checked = $true}
        IF($3048IP1TextBox.Text -ne ""){$3048CheckBox.Checked = $true}
        IF($55XXIP1TextBox.Text -ne ""){$55XXCheckBox.Checked = $true}
        IF($55XX2IP1TextBox.Text -ne ""){$55XX2CheckBox.Checked = $true}
        IF($55XX3IP1TextBox.Text -ne ""){$55XX3CheckBox.Checked = $true}
        IF($N7KIP1TextBox.text -ne ""){$N7KCheckBox.Checked = $true}
        IF($1000IP1TextBox.Text -ne ""){$1000CheckBox.Checked = $true}
        IF($MDSIP1TextBox.Text -ne ""){$MDSCheckBox.Checked = $true}
        IF($VNXeIP1TextBox.Text -ne ""){$VNXeCheckbox.Checked = $true}
		IF($UnityIP1TextBox.Text -ne ""){$UnityCheckbox.Checked = $true}
        IF($VNXIP1TextBox.Text -ne ""){$VNXCheckBox.Checked = $true}
        IF($NASIP1TextBox.Text -ne ""){$NASCheckBox.Checked = $true}
        IF($XtremIOIP1TextBox.Text -ne ""){$XtremIOCheckBox.Checked = $true}
        IF($VPLEXIP1TextBox.Text -ne ""){$VPLEXCheckBox.Checked = $true}
        IF($vCenter1TextBox.Text -ne ""){$vCenter1Checkbox.Checked = $true}
        IF($vCenter2TextBox.Text -ne ""){$vcenter2Checkbox.Checked = $true}
        IF($vCenter3TextBox.Text -ne ""){$vcenter3Checkbox.Checked = $true}
        IF($IsilonIp1TextBox.Text -ne ""){$IsilonCheckbox.checked = $true}
        IF($NSXIPTextBox.Text -ne ""){$NSXCheckBox.checked = $true}
        IF($IPIIP1TextBox.Text -ne ""){$IPICheckbox.checked = $true}
    }

    IF($checkwhat -eq "Offline" -or $checkwhat -eq "Both")
    {
        For($i=0;$i -lt $tabCRGOfflinedatagrid.rowcount-1;$i++)
        {
            IF($tabCRGOfflinedatagrid.rows[$i].Cells[2].Value -ne ""){$tabCRGOfflinedatagrid.rows[$i].Cells[0].Value = $true}
        }
    }

} # End auto-Checkboxes

Function auto-crgoffline
{
    IF(Test-Path ($OutputTextBox.Text + "\Compute\UCS-C*.xml"))
    {
        $myUcsCFiles = Get-ChildItem ($OutputTextBox.Text + "\Compute\UCS-C*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C2XX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myUcsCFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text +  "\Compute\" + $myUcsCFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Compute\" + $myUcsCFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True
    }
    IF(Test-Path ($OutputTextBox.Text + "\Compute\UCS Cluster 1\UCS-B*.xml")) 
    {
        $myUcsBFiles = Get-ChildItem ($OutputTextBox.Text + "\Compute\UCS Cluster 1\UCS-B*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 1" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myUcsBFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Compute\UCS Cluster 1\" + $myUcsBFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Compute\UCS Cluster 1\" + $myUcsBFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True
    }
    IF(Test-Path ($OutputTextBox.Text + "\Compute\UCS Cluster 2\UCS-B*.xml")) 
    {
        $myUcsBFiles = Get-ChildItem ($OutputTextBox.Text + "\Compute\UCS Cluster 2\UCS-B*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 2" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myUcsBFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Compute\UCS Cluster 2\" + $myUcsBFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Compute\UCS Cluster 2\" + $myUcsBFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Compute\UCS Cluster 3\UCS-B*.xml")) 
    {
        $myUcsBFiles = Get-ChildItem ($OutputTextBox.Text + "\Compute\UCS Cluster 3\UCS-B*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 3" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myUcsBFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Compute\UCS Cluster 3\" + $myUcsBFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Compute\UCS Cluster 3\" + $myUcsBFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True
    }
    IF(Test-Path ($OutputTextBox.Text + "\Compute\UCS Cluster 4\UCS-B*.xml")) 
    {
        $myUcsBFiles = Get-ChildItem ($OutputTextBox.Text + "\Compute\UCS Cluster 4\UCS-B*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 4" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myUcsBFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Compute\UCS Cluster 4\" + $myUcsBFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Compute\UCS Cluster 4\" + $myUcsBFiles.Name} 
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True
    }
    IF(Test-Path ($OutputTextBox.Text + "\Compute\UCS Cluster 5\UCS-B*.xml")) 
    {
        $myUcsBFiles = Get-ChildItem ($OutputTextBox.Text + "\Compute\UCS Cluster 5\UCS-B*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "UCS Cluster 5" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myUcsBFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Compute\UCS Cluster 5\" + $myUcsBFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Compute\UCS Cluster 5\" + $myUcsBFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Network\C35K*.xml")) 
    {
        $myC35KFiles = Get-ChildItem ($OutputTextBox.Text + "\Network\C35K*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C3560" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myC35KFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\" + $myC35KFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\" + $myC35KFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Network\C37k*.xml")) 
    {
        $myC37KFiles = Get-ChildItem ($OutputTextBox.Text + "\Network\C37k*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "C3750" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myC37KFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\" + $myC37KFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\" + $myC37KFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Network\Nexus Management\N3k*.xml")) 
    {
        $myN3kFiles = Get-ChildItem ($OutputTextBox.Text + "\Network\Nexus Management\N3k*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Management" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myN3kFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\Nexus Management\" + $myN3kFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\Nexus Management\" + $myN3kFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Network\Nexus Aggregate\N?k*.xml")) 
    {
        $myN5kFiles = Get-ChildItem ($OutputTextBox.Text + "\Network\Nexus Aggregate\N?k*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Aggregate" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myN5kFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\Nexus Aggregate\" + $myN5kFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\Nexus Aggregate\" + $myN5kFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True
    }
    IF(Test-Path ($OutputTextBox.Text + "\Network\Nexus BRS\N?k*.xml")) 
    {
        $myN5kFiles = Get-ChildItem ($OutputTextBox.Text + "\Network\Nexus BRS\N?k*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus BRS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myN5kFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\Nexus BRS\" + $myN5kFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\Nexus BRS\" + $myN5kFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Network\Nexus Isilon\N?k*.xml")) 
    {
        $myN5kFiles = Get-ChildItem ($OutputTextBox.Text + "\Network\Nexus Isilon\N?k*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Isilon" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myN5kFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\Nexus Isilon\" + $myN5kFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\Nexus Isilon\" + $myN5kFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Network\Nexus Core\N?k*.xml")) 
    {
        $myN7kFiles = Get-ChildItem ($OutputTextBox.Text + "\Network\Nexus Core\N?k*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Nexus Core" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myN7kFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\Nexus Core\" + $myN7kFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\Nexus Core\" + $myN7kFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF (Test-Path ($OutputTextBox.Text + "\Network\N1K*.xml")) 
    {
        $myN1KFiles = Get-ChildItem ($OutputTextBox.Text + "\Network\N1K*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "1000v" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myN1KFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\" + $myN1KFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\" + $myN1KFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF (Test-Path ($OutputTextBox.Text + "\Network\MDS*.xml")) 
    {
        $myMDSFiles = Get-ChildItem ($OutputTextBox.Text + "\Network\MDS*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "MDS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myMDSFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\" + $myMDSFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Network\" + $myMDSFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True
    }
    IF(Test-Path ($OutputTextBox.Text + "\Storage\VNXe*.xml")) 
    {
        $myVNXeFiles = Get-ChildItem ($OutputTextBox.Text + "\Storage\VNXe*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VNXe" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myVNXeFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myVNXeFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myVNXeFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
	IF(Test-Path ($OutputTextBox.Text + "\Storage\Unity*.xml")) 
    {
        $myUnityFiles = Get-ChildItem ($OutputTextBox.Text + "\Storage\Unity*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Unity" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myUnityFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myUnityFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myUnityFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Storage\VNX-Block*.xml")) 
    {
        $myVNXFiles = Get-ChildItem ($OutputTextBox.Text + "\Storage\VNX-Block*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VNX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myVNXFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myVNXFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myVNXFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Storage\NAS*.xml")) 
    {
        $myNASFiles = Get-ChildItem ($OutputTextBox.Text + "\Storage\NAS*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "NAS" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myNASFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myNASFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myNASFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Storage\XtremIO*.xml")) 
    {
        $myXtremIOFiles = Get-ChildItem ($OutputTextBox.Text + "\Storage\XtremIO*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "XtremIO" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myXtremIOFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myXtremIOFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myXtremIOFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Storage\VPLEX*.xml")) 
    {
        $myVPLEXFiles = Get-ChildItem ($OutputTextBox.Text + "\Storage\VPLEX*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VPLEX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myVPLEXFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myVPLEXFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myVPLEXFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF(Test-Path ($OutputTextBox.Text + "\Storage\Isilon*.xml")) 
    {
        $myIsilonFiles = Get-ChildItem ($OutputTextBox.Text + "\Storage\Isilon*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "Isilon" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myIsilonFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myIsilonFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\Storage\" + $myIsilonFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF((Get-ChildItem -Recurse -include "*.bin" -Path $OutputTextBox.text | measure).count -ge 1)
    {
        $VMAXfile1 = Get-ChildItem -Recurse -include "*.bin" -Path $OutputTextBox.text | Select-Object -ExpandProperty FullName
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "VMAX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($Vmaxfile1.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $VMAXfile1[-1]}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $VMAXfile1}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True
    }
    IF (Test-Path ($OutputTextBox.Text + "\VMware\vCenter 1\vCenter*.xml")) 
    {
        $myvCenterFiles = Get-ChildItem ($OutputTextBox.Text + "\VMware\vCenter 1\vCenter*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 1" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myvCenterFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\vCenter 1\" + $myvCenterFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\vCenter 1\" + $myvCenterFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True
    }
    IF (Test-Path ($OutputTextBox.Text + "\VMware\vCenter 2\vCenter*.xml")) 
    {
        $myvCenterFiles = Get-ChildItem ($OutputTextBox.Text + "\VMware\vCenter 2\vCenter*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 2" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myvCenterFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\vCenter 2\" + $myvCenterFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\vCenter 2\" + $myvCenterFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True
    }
    IF (Test-Path ($OutputTextBox.Text + "\VMware\vCenter 3\vCenter*.xml")) 
    {
        $myvCenterFiles = Get-ChildItem ($OutputTextBox.Text + "\VMware\vCenter 3\vCenter*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 3" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myvCenterFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\vCenter 3\" + $myvCenterFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\vCenter 3\" + $myvCenterFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True
    }
    IF (Test-Path ($OutputTextBox.Text + "\VMware\vCenter 4\vCenter*.xml")) 
    {
        $myvCenterFiles = Get-ChildItem ($OutputTextBox.Text + "\VMware\vCenter 4\vCenter*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 4" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myvCenterFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\vCenter 4\" + $myvCenterFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\vCenter 4\" + $myvCenterFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True
    }
    IF (Test-Path ($OutputTextBox.Text + "\VMware\vCenter 5\vCenter*.xml")) 
    {
        $myvCenterFiles = Get-ChildItem ($OutputTextBox.Text + "\VMware\vCenter 5\vCenter*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "vCenter 5" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF ($myvCenterFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\vCenter 5\" + $myvCenterFiles[-1].Name}
        ELSE {$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\vCenter 5\" + $myvCenterFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF (Test-Path ($OutputTextBox.Text + "\VMware\NSX*.xml")) 
    {
        $myNSXFiles = Get-ChildItem ($OutputTextBox.Text + "\VMware\NSX*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "NSX" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF($myNSXFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\" + $myNSXFiles[-1].Name}
        ELSE{$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + "\VMware\" + $myNSXFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }
    IF (Test-Path ($OutputTextBox.Text + "\IPI*.xml")) 
    {
        $myIPIFiles = Get-ChildItem ($OutputTextBox.Text + "\IPI*.xml") | Sort-Object Name
        $rowindex    = $tabcrgofflinedatagrid.Rows.Cells | Where-Object {$_.value -eq "IPI" -and $_.ColumnIndex -eq "1"} | Select-Object -ExpandProperty RowIndex
        IF ($myIPIFiles.Count -gt 1){$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $myIPIFiles[-1].Name}
        ELSE {$tabcrgofflinedatagrid.rows[$rowindex].Cells[2].Value = $OutputTextBox.Text + $myIPIFiles.Name}
        $tabcrgofflinedatagrid.rows[$rowindex].Cells[0].Value = $True 
    }

} # End Auto-crgoffline

Function export-credentials
{

$output = @()

For($i=0;$i -lt $credsGridView.rowcount-1;$i++)
{
    $object = New-Object PSobject
    $object | Add-Member NoteProperty "Device"   $credsGridView.rows[$i].Cells['Device Name'].Value
    $object | Add-Member NoteProperty "Hostname" $credsGridView.rows[$i].Cells['Hostname'].Value
    $object | Add-Member NoteProperty "IP"       $credsGridView.rows[$i].Cells['IP Address'].Value
    $object | Add-Member NoteProperty "Username" $credsGridView.rows[$i].Cells['Username'].Value
    $object | Add-Member NoteProperty "Password" $credsGridView.rows[$i].Cells['Password'].Value

    $output += $object
}

$output

} # End Function export-credentials

Function create-credentials
{
    $data = export-credentials
    $dcnm = ""
    $OutFile       = $OutputTextBox.text + "\Credentials`_$TIMESTAMP`_CRG.xlsx"

    write-host "Creating Credentials"
    $status.Text = "Creating Credentials"

    $excel = New-Object OfficeOpenXml.ExcelPackage $OutFile

    $credentials = $excel.Workbook.Worksheets.Add("System Credentials")

    [int]$row = 2
    [int]$col = 2
    $startrow = $row
    $startcol = $col

    $sectiontitle = "VCE Vblock " + $dropdownsystype.SelectedItem.tostring() + " User Credentials (All Components)"
    $colheaders = @("Device","Hostname","IP","Username","Password")
    
    $row, $col, $newcol, $range, $offset = drawHeader $credentials $colheaders $sectiontitle $row $col
    $row += 1

    ForEach($item in $data)
    {
        $credentials.cells[$row,$col].Value     = $item.device
        $credentials.cells[$row,($col+1)].Value = $item.hostname
        $credentials.cells[$row,($col+2)].Value = $item.IP
        $credentials.cells[$row,($col+3)].Value = $item.username
        $credentials.cells[$row,($col+4)].Value = $item.password

        IF($item.device -eq "vCenter Server")
        {
            $row++
            $credentials.cells[$row,$col].Value = "vCenter Web Client"

            $MergeCells = $credentials.Cells[("C${Row}:D$row")]
            $MergeCells.Merge = $true

            $credentials.cells[$row,($col+1)].Value = "https://" + $item.hostname + "." + $domainTextBox.text + ":9443/vsphere-client"
            $credentials.cells[$row,($col+3)].Value = "admin@system-domain"
            $credentials.cells[$row,($col+4)].Value = $passwordsso
        }

        IF($item.device -like "vCenter*SSO*")
        {
            $row++
            $credentials.cells[$row,$col].Value = "vCenter Web Client"

            $MergeCells = $credentials.Cells["C${Row}:D$row"]
            $MergeCells.Merge = $true

            $credentials.cells[$row,($col+1)].Value = "https://" + $item.hostname + "." + $domainTextBox.text + ":9443/vsphere-client"
            $credentials.cells[$row,($col+3)].Value = "administrator@vsphere.local"
            $credentials.cells[$row,($col+4)].Value = $passwordsso
        }

        IF($item.device -eq "vCenter Appliance")
        {
            $row++
            $credentials.cells[$row,$col].Value = "vCenter Web Client"

            $MergeCells = $credentials.Cells["C${Row}:D$row"].Value
            $MergeCells.Merge = $true

            $credentials.cells[$row,($col+1)].Value = "https://" + $item.hostname + "." + $domainTextBox.text + ":9443/vsphere-client"
            $credentials.cells[$row,($col+3)].Value = "administrator@vsphere.local"
            $credentials.cells[$row,($col+4)].Value = $passwordsso
        }

        IF($item.device -like "*Vision")
        {
            $row++
            $credentials.cells[$row,$col].Value = " - VCE Vision XML"

            $MergeCells = $credentials.Cells["C${Row}:D$row"]
            $MergeCells.Merge = $true
    
            $credentials.cells[$row,($col+1)].Value = "https://" + $item.hostname + "." + $domainTextBox.text + ":8443/fm/vblocks"
            $credentials.cells[$row,($col+3)].Value = "admin"
            $credentials.cells[$row,($col+4)].Value = "7j@m4Qd+1L"

            $row++
            $credentials.cells[$row,$col].Value = " - Config Collector"

            $MergeCells = $credentials.Cells["C${Row}:D$row"]
            $MergeCells.Merge = $true

            $credentials.cells[$row,($col+1)].Value = "https://" + $item.hostname + "." + $domainTextBox.text + ":8443/fm/configcollector"
            $credentials.cells[$row,($col+3)].Value = "admin"
            $credentials.cells[$row,($col+4)].Value = "7j@m4Qd+1L"

            $row++
            $credentials.cells[$row,$col].Value = " - Export Logs"

            $MergeCells = $credentials.Cells["C${Row}:D$row"]
            $MergeCells.Merge = $true

            $credentials.cells[$row,($col+1)].Value = "https://" + $item.hostname + "." + $domainTextBox.text + ":8443/fm/exportlogs"
            $credentials.cells[$row,($col+3)].Value = "admin"
            $credentials.cells[$row,($col+4)].Value = "7j@m4Qd+1L"
        }

        IF($item.device -eq "VNXe")
        {
            $row++
            $credentials.cells[$row,$col].Value = " - service account"

            $row2 = $row-1

            $MergeCells1 = $credentials.Cells["C${row2}:C$row"]
            $MergeCells1.Merge = $true
            $MergeCells1.Style.VerticalAlignment = "Center"

            $MergeCells2 = $credentials.Cells["D${row2}:D$row"]
            $MergeCells2.Merge = $true
            $MergeCells2.Style.VerticalAlignment = "Center"
    
            $credentials.cells[$row,($col+3)].Value = "service"
            $credentials.cells[$row,($col+4)].Value = $password
        }
		
		IF($item.device -eq "Unity")
        {
            $row++
            $credentials.cells[$row,$col].Value = " - service account"

            $row2 = $row-1

            $MergeCells1 = $credentials.Cells["C${row2}:C$row"]
            $MergeCells1.Merge = $true
            $MergeCells1.Style.VerticalAlignment = "Center"

            $MergeCells2 = $credentials.Cells["D${row2}:D$row"]
            $MergeCells2.Merge = $true
            $MergeCells2.Style.VerticalAlignment = "Center"
    
            $credentials.cells[$row,($col+3)].Value = "service"
            $credentials.cells[$row,($col+4)].Value = $password
        }

        IF($item.device -eq "UIM")
        {
            $row++
            $credentials.cells[$row,$col].Value = " - root account"

            $row2 = $row-1
                
            $MergeCells1 = $credentials.Cells["C${row2}:C$row"]
            $MergeCells1.Merge = $true
            $MergeCells1.Style.VerticalAlignment = "Center"
    
            $MergeCells2 = $credentials.Cells["D${row2}:D$row"]
            $MergeCells2.Merge = $true
            $MergeCells2.Style.VerticalAlignment = "Center"

            $credentials.cells[$row,($col+3)].Value = "root"
            $credentials.cells[$row,($col+4)].Value = $password
        }

        IF($item.device -like "MDS*"){$dcnm = $data | Where-Object {$_.Device -like "Element Manager*"} | select-object -ExpandProperty Hostname}
        IF($item.device -like "DCNM*")
        {
            $row++

            $MergeCells = $credentials.Cells["C${Row}:D$row"]
            $MergeCells.Merge = $true

            $credentials.cells[$row,$col].Value = " - Web Portal"
            $credentials.cells[$row,($col+1)].Value = "http://" + $item.hostname + "." + $domainTextBox.text + ":8080"
            $credentials.cells[$row,($col+3)].Value = "admin"
            $credentials.cells[$row,($col+4)].Value = "password1"
        }
        $row++
    }

    $row -= 1

    drawBox $credentials $range $startrow $startcol $newcol $offset $row $col

    $credentials.Column(3).width = 30
    $credentials.Column(4).width = 30

    $excel.save()

    write-host "Creating Credentials Complete"
    $status.Text = "Creating Credentials Complete"

} # End Function create-credentials

Function import-vision
{

$visionForm = New-Object Windows.Forms.Form
$visionForm.Size = New-Object Drawing.Size @(420,150)
$visionForm.Icon = "$ScriptPath\Bin\Icons\VCE.ico"
$visionForm.Text = "VB Serial Import Script"

$importvisionLabel = New-Object System.Windows.Forms.Label
$importvisionLabel.Location = New-Object System.Drawing.Size(10,7) 
$importvisionLabel.Size = New-Object System.Drawing.Size(100,20) 
$importvisionLabel.Text = "Vision IP Address"
$visionForm.Controls.Add($importvisionLabel)

$importvisionTextBox = New-Object System.Windows.Forms.TextBox 
$importvisionTextBox.Location = New-Object System.Drawing.Size(120,5) 
$importvisionTextBox.Size = New-Object System.Drawing.Size(270,20) 
$visionForm.Controls.Add($importvisionTextBox)

$importviouserLabel = New-Object System.Windows.Forms.Label
$importviouserLabel.Location = New-Object System.Drawing.Size(10,32) 
$importviouserLabel.Size = New-Object System.Drawing.Size(60,20) 
$importviouserLabel.Text = "Username"
$visionForm.Controls.Add($importviouserLabel)

$importviouserTextBox = New-Object System.Windows.Forms.TextBox 
$importviouserTextBox.Location = New-Object System.Drawing.Size(120,30) 
$importviouserTextBox.Size = New-Object System.Drawing.Size(270,20) 
$importviouserTextBox.text = "root"
$visionForm.Controls.Add($importviouserTextBox)

$importviopassLabel = New-Object System.Windows.Forms.Label
$importviopassLabel.Location = New-Object System.Drawing.Size(10,57) 
$importviopassLabel.Size = New-Object System.Drawing.Size(60,20) 
$importviopassLabel.Text = "Password"
$visionForm.Controls.Add($importviopassLabel)

$importviopassTextBox = New-Object System.Windows.Forms.TextBox 
$importviopassTextBox.Location = New-Object System.Drawing.Size(120,55) 
$importviopassTextBox.Size = New-Object System.Drawing.Size(270,20)
$importviopassTextBox.Text = $regions.item($region)
$importviopassTextBox.UseSystemPasswordChar = $True
$visionForm.Controls.Add($importviopassTextBox)

# Button Area

$buttonPanel = New-Object Windows.Forms.Panel
$buttonPanel.Size = New-Object Drawing.Size @(300,100)
$buttonPanel.Dock = "Bottom"
$visionForm.Controls.Add($buttonPanel)

$cancelButton = New-Object Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.DialogResult = "Cancel"
$cancelButton.Top = $buttonPanel.Height - $cancelButton.Height - 5
$cancelButton.Left = $buttonPanel.Width - $cancelButton.Width - 10
$cancelButton.Anchor = "right"
$buttonPanel.Controls.Add($cancelButton)

$okButton = New-Object Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Top = $cancelButton.Top
$okButton.Left = $buttonPanel.Width - $okButton.Width - $cancelButton.Width - 15
$okButton.Anchor = "right"
$buttonPanel.Controls.Add($okButton)
$okButton.Add_Click(
{
   New-SshSession -ComputerName $importvisiontextbox.Text -Username $importviouserTextBox.Text -Password $importviopassTextBox.Text

	    $command = "xmllint --format /opt/vce/fm/conf/vblock.xml | grep -i serial -m 1"
	    [xml]$temp = Invoke-SshCommand -ComputerName $importvisiontextbox.Text -Command $command -quiet
        $VBSerialTextBox.text = $temp.serialnumber

    Remove-SshSession -ComputerName $devipa

$visionForm.Close()

})

$visionForm.CancelButton = $cancelButton
$visionForm.Add_Shown( { $visionForm.Activate() } )

$result = $visionForm.ShowDialog()

} # End Function import-vision

Function import-version
{
    write-host "`nStarting Version Check"

    $Reportxmlfiles = (collect-xmldata -xmlfiles offline)

    $i = 1

    do
    {
        IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "UCS Cluster $i"}) -ne $null) 
        {
            $ucs,$blades = get-verucs -ReportXMLFile $Reportxmlfiles["UCS Cluster $i"] -Domain $i
    
            Foreach($item in $ucs)
            {
                $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
            }

            write-host "   Adding UCS Blades"

            foreach($item in $blades)
            {
                $versionGridView2.Rows.Add(
                        $item.Domain,
                        $item.Chassis,
                        $item.Model,
                        $item.Serial,
                        $item.CIMC,
                        $item.BIOS,
                        $item.AdapterID,
                        $item.AdapterSN,
                        $item.Processor,
                        $item.ServiceProfile)
            }
        }
    $i++
    }while($i -ne 6)

    $i = 1

    do
    {
        IF($Reportxmlfiles["vCenter $i"] -ne $null) 
        {
            $vcoutput,$blades = get-vervcenter -Reportxmlfile $Reportxmlfiles["vCenter $i"] -vcenter $i
    
            Foreach($item in $vcoutput){$versionGridView1.Rows.Add($item.device,$item.hostname,$item.model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)}

            write-host "   Adding ESXi Hosts"

            foreach($item in $blades)
            {
                $versionGridView3.Rows.Add(
                    $item.vCenter,
                    $item.ESXname,
                    $item.version,
                    $item.enic,
                    $item.fnic,
                    $item.ppve,
                    $item.vem)
            }
        }
    $i++
    }while($i -ne 8)

    IF($Reportxmlfiles["C2XX"] -ne $null){$data = get-verc2xx -ReportXMLFile $Reportxmlfiles["C2XX"]}ELSE{$data = $null}
   
    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF(($ReportXMLFiles.keys | Where-Object {$_ -like "Nexus*"}) -ne $null)
    {
        ForEach($item in ($ReportXMLFiles.keys | Where-Object {$_ -like "Nexus*"}))
        {
            $data = get-vernexus -ReportXMLFile $ReportXMLFiles[$item]

            IF($data -ne $null)
            {
                Foreach($item in $data)
                {
                    $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
                }
            }
        }
    }

    IF($Reportxmlfiles["MDS"] -ne $null){$data = get-vermds -ReportXMLFile $Reportxmlfiles["MDS"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["C3560"] -ne $null){$data = get-verc3560 -ReportXMLFile $Reportxmlfiles["C3560"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["C3750"] -ne $null){$data = get-verc3750 -ReportXMLFile $Reportxmlfiles["C3750"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["1000v"] -ne $null){$data = get-vern1k -ReportXMLFile $Reportxmlfiles["1000v"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["VNXe"] -ne $null){$data = get-vervnxe -ReportXMLFile $Reportxmlfiles["VNXe"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["VNX"] -ne $null){$data = get-vervnxblock -ReportXMLFile $Reportxmlfiles["VNX"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["NAS"] -ne $null){$data = get-vervnxfile -ReportXMLFile $Reportxmlfiles["NAS"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["Unity"] -ne $null){$data = get-verunity -ReportXMLFile $Reportxmlfiles["Unity"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["XtremIO"] -ne $null){$data = get-verxtremio -ReportXMLFile $Reportxmlfiles["XtremIO"]}ELSE{$data = $null}

    IF($data -ne $null)
    {

        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["VPLEX"] -ne $null){$data = get-vervplex -ReportXMLFile $Reportxmlfiles["VPLEX"]}ELSE{$data = $null}

    IF($data -ne $null)
    {

        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["VMAX"] -ne $null){$data = get-vervmax -ReportXMLFile $Reportxmlfiles["VMAX"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["Isilon"] -ne $null){$data = get-verisilon -ReportXMLFile $Reportxmlfiles["Isilon"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["NSX"] -ne $null){$data = get-vernsx -ReportXMLFile $Reportxmlfiles["NSX"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

    IF($Reportxmlfiles["IPI"] -ne $null){$data = get-veripi -ReportXMLFile $Reportxmlfiles["IPI"]}ELSE{$data = $null}

    IF($data -ne $null)
    {
        Foreach($item in $data)
        {
            $versionGridView1.Rows.Add($item.device,$item.hostname,$item.Model,$item.serial,$item.version); write-host ("   Adding " + $item.Device)
        }
    }

write-host "Version Check Complete";  $status.text = "Version Check Complete"

} # End Function import-version

Function run-portmap
{

$ischecked = $false

$Reportxmlfiles = (collect-xmldata -xmlfiles offline)

$NothingChecked = @"
No Offline Items were checked.

To use the port map script.   Add the files in the offline tab and check the boxes next to the network devices you want to create Port Maps for.
"@

IF(($Reportxmlfiles.keys | Where-Object {$_ -eq "C3560" -or $_ -like "Nexus*" -or $_ -eq "MDS"}) -ne $null){$ischecked = $true}

IF(!($ischecked)){[System.Windows.Forms.MessageBox]::Show($NothingChecked,"Nothing Checked",0,48)}

    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "C3560"}) -ne $null)
    {
        $output = (Join-Path $outputtextbox.text -ChildPath "Network")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
        write-host "`nProcessing Catalyst 3560 Port Map Script"        
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "C3560"})]
        & $PS_PortMap -OutputPath $output -ReportXMLFile $ReportXMLFile
    }

    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "Nexus Management"}) -ne $null)
    {
        $output = (Join-Path $outputtextbox.text -ChildPath "Network")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
        $output = (Join-Path $output -ChildPath "Nexus Management")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
        write-host "`nProcessing Nexus 3K Port Map Script"     
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "Nexus Management"})]
        & $PS_PortMap -OutputPath $output -ReportXMLFile $ReportXMLFile
    }

    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "Nexus Aggregate"}) -ne $null)
    {
        $output = (Join-Path $outputtextbox.text -ChildPath "Network")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
        $output = (Join-Path $output -ChildPath "Nexus Aggregate")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
        write-host "`nProcessing Nexus Aggregate Port Map Script"    
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "Nexus Aggregate"})]
        & $PS_PortMap -OutputPath $output -ReportXMLFile $ReportXMLFile
    }
    
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "Nexus BRS"}) -ne $null)
    {
        $output = (Join-Path $outputtextbox.text -ChildPath "Network")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
        $output = (Join-Path $output -ChildPath "Nexus BRS")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
        write-host "`nProcessing Nexus BRS Port Map Script"    
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "Nexus BRS"})]
        & $PS_PortMap -OutputPath $output -ReportXMLFile $ReportXMLFile
    }
    
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "Nexus Isilon"}) -ne $null)
    {
        $output = (Join-Path $outputtextbox.text -ChildPath "Network")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
        $output = (Join-Path $output -ChildPath "Nexus Isilon")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
        write-host "`nProcessing Nexus Isilon Port Map Script"    
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "Nexus Isilon"})]
        & $PS_PortMap -OutputPath $output -ReportXMLFile $ReportXMLFile
    }
    
    IF(($ReportXMLFiles.keys | Where-Object {$_ -eq "MDS"}) -ne $null)
    {
        $output = (Join-Path $outputtextbox.text -ChildPath "Network")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}
        write-host "`nProcessing MDS Port Map Script"    
        $ReportXMLFile = $ReportXMLFiles[($ReportXMLFiles.keys | Where-Object {$_ -eq "MDS"})]
        & $PS_PortMap -OutputPath $output -ReportXMLFile $ReportXMLFile
    }      

} # End Function run-portmap

Function run-techsupport
{

$ischecked = $false
$NetworkDevicesArray = $3560CheckBox,$3750CheckBox,$3048CheckBox,$55XXCheckBox,$55XX2CheckBox,$55XX3CheckBox,$MDSCheckBox,$1000CheckBox

$NothingChecked = @"
No Network Devices were checked.

To use the tech-support script enter at least one IP address for the device and check the box.
"@

ForEach($item in $NetworkDevicesArray){IF($item.checked -eq $true){$ischecked = $true}}

IF(!($ischecked)){[System.Windows.Forms.MessageBox]::Show($NothingChecked,"Nothing Checked",0,48)}

ELSE
{
    $output = (Join-Path $outputtextbox.text -ChildPath "Network")
    IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

    IF($3560CheckBox.Checked)
    {
        $output = (Join-Path $outputtextbox.text -ChildPath "Network")
        write-host "`nProcessing Catalyst 3560 TechSupport Script"
        $devip = ($3560IP1TextBox.text).trim(),($3560IP2TextBox.text).trim(); $devip = $devip | ? {$_}
        
        $username = $3560userTextBox.Text
        $password = $3560passTextBox.Text
        
        ForEach($ip in $devip)
        {
            get-techsupport -devip $ip -username $username -password $password -output $output -catalyst 
        }
        write-host "Processing Catalyst 3560 TechSupport Script Complete"
    }

    IF($3750CheckBox.Checked)
    {
        $output = (Join-Path $outputtextbox.text -ChildPath "Network")
        write-host "`nProcessing Catalyst 3750 TechSupport Script"
        $devip = ($3750IP1TextBox.text).trim()

        $username = $3750userTextBox.Text
        $password = $3750passTextBox.Text
        
        get-techsupport -devip $ip -username $username -password $password -output $output -catalyst

        write-host "Processing Catalyst 3750 TechSupport Script Complete"
    }
    
    IF($3048CheckBox.Checked)
    {
        $output = (Join-Path $outputtextbox.text -ChildPath "Network\Nexus Management")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

        write-host "`nProcessing Nexus 3K TechSupport Script"
        $devip = ($3048IP1TextBox.text).trim(),($3048IP2TextBox.text).trim(); $devip = $devip | ? {$_}
        
        $username = $3048userTextBox.Text
        $password = $3048passTextBox.Text

        ForEach($ip in $devip)
        {
            get-techsupport -devip $ip -username $username -password $password -output $output 
        }
        write-host "Processing Nexus 3K TechSupport Script Complete"
    }

    IF($55XXCheckBox.Checked)
    { 
        $output = (Join-Path $outputtextbox.text -ChildPath "Network\Nexus Aggregate")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

        write-host "`nProcessing Nexus Aggregate TechSupport Script"
        $devip = ($55XXIP1TextBox.text).trim(),($55XXIP2TextBox.text).trim(); $devip = $devip | ? {$_}
        
        $username = $55XXuserTextBox.Text
        $password = $55XXpassTextBox.Text
        
        ForEach($ip in $devip)
        {
            get-techsupport -devip $ip -username $username -password $password -output $output
        }
        write-host "Processing Nexus Aggregate TechSupport Script Complete"
    }

    IF($55XX2CheckBox.Checked)
    { 
        $output = (Join-Path $outputtextbox.text -ChildPath "Network\Nexus BRS")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

        write-host "`nProcessing Nexus Aggregate TechSupport Script"
        $devip = ($55XX2IP1TextBox.text).trim(),($55XX2IP2TextBox.text).trim(); $devip = $devip | ? {$_}
        
        $username = $55XX2userTextBox.Text
        $password = $55XX2passTextBox.Text
        
        ForEach($ip in $devip)
        {
            get-techsupport -devip $ip -username $username -password $password -output $output
        }
        write-host "Processing Nexus Aggregate TechSupport Script Complete"
    }

    IF($55XX3CheckBox.Checked)
    { 
        $output = (Join-Path $outputtextbox.text -ChildPath "Network\Nexus Isilon")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

        write-host "`nProcessing Nexus Aggregate TechSupport Script"
        $devip = ($55XX3IP1TextBox.text).trim(),($55XX3IP2TextBox.text).trim(); $devip = $devip | ? {$_}
        
        $username = $55XX3userTextBox.Text
        $password = $55XX3passTextBox.Text
        
        ForEach($ip in $devip)
        {
            get-techsupport -devip $ip -username $username -password $password -output $output
        }
        write-host "Processing Nexus Aggregate TechSupport Script Complete"
    }

    IF($MDSCheckBox.checked)
    { 
        $output = (Join-Path $outputtextbox.text -ChildPath "Network")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

        write-host "`nProcessing MDS TechSupport Script"
        $devip = ($MDSIP1TextBox.text).trim(),($MDSIP2TextBox.text).trim(); $devip = $devip | ? {$_}
        
        $username = $MDSuserTextBox.Text
        $password = $MDSpassTextBox.Text

        ForEach($ip in $devip)
        {
            get-techsupport -devip $ip -username $username -password $password -output $output
        }
        write-host "Processing MDS TechSupport Script Complete"
    }

    IF($1000CheckBox.checked)
    { 
        $output = (Join-Path $outputtextbox.text -ChildPath "Network")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

        write-host "`nProcessing 1000v TechSupport Script"
        $devip = ($1000IP1TextBox.text).trim()
        
        $username = $1000userTextBox.Text
        $password = $1000passTextBox.Text

        get-techsupport -devip $devip -username $username -password $password -output $output
  
        write-host "Processing 1000v TechSupport Script Complete"
    }
    
    IF($N7KCheckBox.Checked)
    { 
        $output = (Join-Path $outputtextbox.text -ChildPath "Network\Nexus Core")
        IF(!(Test-Path $output)){new-item $output -ItemType directory | Out-Null}

        write-host "`nProcessing Nexus Core TechSupport Script"
        $devip = ($N7KIP1TextBox.text).trim(),($N7KIP2TextBox.text).trim(); $devip = $devip | ? {$_}
        
        $username = $N7KuserTextBox.Text
        $password = $N7KpassTextBox.Text
        
        ForEach($ip in $devip)
        {
            get-techsupport -devip $ip -username $username -password $password -output $output
        }
        write-host "Processing Nexus Core TechSupport Script Complete"
    }

}

} # End Function run-techsupport

Function get-techsupport
{
    [cmdletbinding()]
  
    Param
    (
        [parameter(Mandatory=$true)]$devip,
        [parameter(Mandatory=$true)]$username,
        [parameter(Mandatory=$true)]$password,
        [parameter(Mandatory=$true)]$output,
        [switch]$catalyst
    )

    Begin
    {
        IF($catalyst)
        {
            $cmdhostname    = "show version"
            $cmdtechsupport = "show tech-support"
        }
        ELSE
        {
            $cmdhostname    = 'show version | i "Device name"'
            $cmdtechsupport = "show tech-support details"
        }
    }
    Process
    {
        Try
        {
            write-host "    Connecting to switch"
            
            $SshClient  = New-SshSession -server $DevIP -user $username -pass $password -ErrorAction Stop
            $failedtocollect = "false"

            IF($catalyst)
            {
                write-host "    Getting hostname information"
        
                $SshCommand = New-SshCommand -SshClient $SshClient -Command $cmdhostname

                $hostname = ($SshCommand.result.split("`n") | Where-Object {$_ -like "*uptime*"}).split(" ")[0]
                $filename = "$Output\TechSupport`_$hostname`_$TIMESTAMP`.txt"
        
                $sshcommand.Dispose()

                $SshClient  = New-SshSession -server $DevIP -user $username -pass $password -ErrorAction Stop
                    
                write-host "    Collecting TechSupport Details for $hostname - Be patient"

                $SshCommand2 = New-SshCommand -SshClient $SshClient -Command $cmdtechsupport
                $SshCommand2.result.split("`n") | out-file $filename
                $SshCommand2.Dispose()
            }
            ELSE
            {
                write-host "    Getting hostname information"
                
                $SshCommand = New-SshCommand -SshClient $SshClient -Command $cmdhostname

                $hostname = ($SshCommand.result.trim().split(" "))[2]
                $filename = "$Output\TechSupport`_$hostname`_$TIMESTAMP`.txt"

                $sshcommand.Dispose()

                write-host "    Collecting TechSupport Details for $hostname - Be patient"

                $SshCommand2 = New-SshCommand -SshClient $SshClient -Command $cmdtechsupport
                $SshCommand2.result.split("`n") | out-file $filename
                $SshCommand2.Dispose()

                # Dispose of artifacts

                $SshClient.Disconnect()
                $SshClient.Dispose()
            }
        }
        Catch
        {
            Write-Host "`tFailed to Collect" -BackgroundColor red -ForegroundColor yellow
            $failedtocollect = "true"
        }
    }
    End
    {
        IF($failedtocollect -ne "true")
        {
            write-host "    Collecting TechSupport for $hostname Complete"
        }
    }
} # End Function get-techsupport

Function check-versions
{

[cmdletbinding()]

    $excel      = New-Object OfficeOpenXml.ExcelPackage $rcm_versions
    $workbook   = $excel.workbook

    IF($dropdownrcm.SelectedItem.ToString() -ne "RCM Version")
    {
        $worksheetmain = $workbook.Worksheets[$dropdownsystype.SelectedItem.ToString()]
        $worksheetmisc = $workbook.Worksheets["Misc"]

        $intcolmax = $workbook.Worksheets["Misc"].Dimension.columns
        
        $rownumber = "1"

        $hashnamemain = $hashnames
        $hashnamemisc = @{}

        For($intcol = 2; $intcol -le $intcolmax; $intcol++)
        {
            $name = $worksheetmisc.cells[$rownumber,$intcol].value
            
            IF($name -ne "Addendum")
            {
                IF($worksheetmisc.cells[$rownumber,$intcol].value -ne $null)
                {
                    $hashnamemisc.Add($name,$intcol)
                }
            }
        }

        $terms = @{
            "UCS"          = "Cisco UCS"
            "FI"           = "Fabric Interconnect"
            "C3560"        = "Cisco Catalyst 3560X-24T-L"
            "C3750"        = "Cisco Catalyst 3750"
            "N3K"          = "Cisco Nexus 3K"
            "N3172TQ"      = "Cisco Nexus 3172TQ"
            "N3064TQ"      = "Cisco Nexus 3064TQ"
            "N3048TP"      = "Cisco Nexus 3048"
            "N5K"          = "Cisco Nexus 55xx"
            "N9K"          = "Cisco Nexus 9396"
            "MDS"          = "Cisco MDS*"
            "1000v"        = "Cisco Nexus 1000v VEM and VSM"
            "vCenter"      = "Vmware vCenter Server"
            "VNXe"         = "EMC VNXe31xx OE"
			"Unity"        = "EMC Unity OE"
            "VMAX"         = "EMC Symmetrix VMAX"
            "VNX Block"    = "EMC VNX OE for Block"
            "VNX File"     = "EMC VNX OE for File"
            "NSX"          = "VMware NSX for vSphere"
        }
        $termsmisc = @{
            "VPLEX"     = "EMC VPLEX GeoSynchrony"
            "XtremIO"   = "EMC XtremIO Storage Array"
            "Isilon"    = "EMC Isilon OneFS Operating System"
        }
        $termsesxi = @{
            "ESXi"      = "esxi_version"
            "ENIC"      = "Vmware ESXi enic Driver for Cisco UCS"
            "FNIC"      = "Vmware ESXi fnic Driver for Cisco UCS"
            "PowerPath" = "EMC PowerPath/VE"
        }

#region Devices tab

        $i = 0
        
        For($i=0;$i -lt $versionGridView1.RowCount;$i++)
        {
            $ver = $null
            
            $versionGridView1.Rows[$i].Cells['RCM Version'].Value = ""
            $versionGridView1.Rows[$i].DefaultCellStyle.BackColor = "White"
            $versionGridView1.Rows[$i].DefaultCellStyle.ForeColor = "Black"

            $searchterm = ($versionGridView1.Rows[$i].Cells['Device'].Value).trim()
            
            IF($searchterm -ne "VNX Block" -and $searchterm -ne "VNX File")
            {
                $searchterm = (($versionGridView1.Rows[$i].Cells['Device'].Value).trim()).split(" ")[0].split("-")[0]
            }
            
            IF(($terms.keys -like $searchterm) -and ($versionGridView1.Rows[$i].Cells['Version'].Value -ne "N/A"))
            {
                $worksheet = $worksheetmain
                $hashnames = $hashnamemain
                $ver = ($worksheet.Cells["A:A"] | Where-Object {$_.text -like $terms[$searchterm]}).address
            }
            ELSEIF($versionGridView1.Rows[$i].Cells['Model'].Value -like "UCS C2?0*")
            {
                IF($versionGridView1.Rows[$i].Cells['Model'].Value -like "*C200*")
                {
                    $worksheet = $worksheetmain
                    $hashnames = $hashnamemain
                    $ver = ($worksheet.Cells["A:A"] | Where-Object {$_.text -eq "Cisco C200 M2"}).address
                }
                ELSE
                {
                    $worksheet = $worksheetmain
                    $hashnames = $hashnamemain
                    $ver = ($worksheet.Cells["A:A"] | Where-Object {$_.text -like "Cisco C2?0*"} | where-object {$_.text -notlike "Cisco C200*"}).address
                }
            }
            ELSEIF(($termsmisc.keys -like $searchterm) -and ($versionGridView1.Rows[$i].Cells['Version'].Value -ne "N/A"))
            {
                $worksheet = $worksheetmisc
                $hashnames = $hashnamemisc
                $ver = ($worksheet.Cells["A:A"] | Where-Object {$_.text -eq $termsmisc[$searchterm]}).address
            }
            
            IF($ver -ne $null)
            {
                IF($vercustRadio.Checked)
                {
                    $rcmversion = $versionGridView1.Rows[$i].Cells['RCM Version'].Value = $worksheet.Cells[($ver.Substring(1,$ver.Length-1)),($hashnames[$dropdownrcm.SelectedItem.ToString()])].value
                }
                ELSEIF($veraddenRadio.checked)
                {
                    IF($worksheet.Cells[($ver.Substring(1,$ver.Length-1)),(($hashnames[$dropdownrcm.SelectedItem.ToString()])+1)].value -ne $null)
                    {
                        $rcmversion = $versionGridView1.Rows[$i].Cells['RCM Version'].Value = $worksheet.Cells[($ver.Substring(1,$ver.Length-1)),(($hashnames[$dropdownrcm.SelectedItem.ToString()])+1)].value    
                    }
                    ELSE
                    {
                        $rcmversion = $versionGridView1.Rows[$i].Cells['RCM Version'].Value = $worksheet.Cells[($ver.Substring(1,$ver.Length-1)),($hashnames[$dropdownrcm.SelectedItem.ToString()])].value
                    }
                }
                $version = $versionGridView1.Rows[$i].Cells['Version'].Value
                
                IF($version -eq $rcmversion)
                {
                    $versionGridView1.Rows[$i].DefaultCellStyle.BackColor = "Green"
                    $versionGridView1.Rows[$i].DefaultCellStyle.ForeColor = "White"
                }
                ELSEIF($rcmversion -eq $null)
                {
                    $versionGridView1.Rows[$i].DefaultCellStyle.BackColor = "White"
                    $versionGridView1.Rows[$i].DefaultCellStyle.ForeColor = "Black"
                }
                ELSE
                {
                    $versionGridView1.Rows[$i].DefaultCellStyle.BackColor = "Red"
                    $versionGridView1.Rows[$i].DefaultCellStyle.ForeColor = "White"
                }
            }
        }

#endregion Devices tab

#region ESXi tab

        $esxiver = ($worksheetmain.Cells["A:A"] | Where-Object {$_.text -eq $termsesxi["ESXi"]}).address
                
        IF((($worksheetmain.Cells["A:A"] | Where-Object {$_.text -eq $termsesxi["ENIC"]}).address) -ne $null)
        {
            $enicver = ($worksheetmain.Cells["A:A"] | Where-Object {$_.text -eq $termsesxi["ENIC"]}).address    
        }
        ELSE{$enicver = "N/A"}

        IF((($worksheetmain.Cells["A:A"] | Where-Object {$_.text -eq $termsesxi["FNIC"]}).address) -ne $null)
        {
            $fnicver = ($worksheetmain.Cells["A:A"] | Where-Object {$_.text -eq $termsesxi["FNIC"]}).address
        }
        ELSE{$fnicver = "N/A"}

        IF((($worksheetmain.Cells["A:A"] | Where-Object {$_.text -eq $termsesxi["PowerPath"]}).address) -ne $null)
        {
            $ppvever = ($worksheetmain.Cells["A:A"] | Where-Object {$_.text -eq $termsesxi["PowerPath"]}).address
        }
        ELSE{$ppvever = "N/A"}

        IF($vercustRadio.Checked)
        {
            $esxiversion = $worksheetmain.Cells[($esxiver.Substring(1,$esxiver.Length-1)),($hashnamemain[$dropdownrcm.SelectedItem.ToString()])].value
        
            IF($enicver -ne "N/A")
            {
                $enicversion = $worksheetmain.Cells[($enicver.Substring(1,$enicver.Length-1)),($hashnamemain[$dropdownrcm.SelectedItem.ToString()])].value
            }
            IF($fnicver -ne "N/A")
            {
                $fnicversion = $worksheetmain.Cells[($fnicver.Substring(1,$fnicver.Length-1)),($hashnamemain[$dropdownrcm.SelectedItem.ToString()])].value
            }
            IF($ppvever -ne "N/A")
            {
                $ppveversion = $worksheetmain.Cells[($ppvever.Substring(1,$ppvever.Length-1)),($hashnamemain[$dropdownrcm.SelectedItem.ToString()])].value 
            }       
        }
        ELSEIF($veraddenRadio.checked)
        {
            IF($worksheetmain.Cells[($esxiver.Substring(1,$esxiver.Length-1)),(($hashnamemain[$dropdownrcm.SelectedItem.ToString()])+1)].value -ne $null)
            {
                $esxiversion = $worksheetmain.Cells[($esxiver.Substring(1,$esxiver.Length-1)),(($hashnamemain[$dropdownrcm.SelectedItem.ToString()])+1)].value
            }
            ELSE
            {
                $esxiversion = $worksheetmain.Cells[($esxiver.Substring(1,$esxiver.Length-1)),($hashnamemain[$dropdownrcm.SelectedItem.ToString()])].value
            }
            IF($enicver -ne "N/A")
            {
                IF($worksheetmain.Cells[($enicver.Substring(1,$enicver.Length-1)),(($hashnamemain[$dropdownrcm.SelectedItem.ToString()])+1)].value -ne $null)
                {
                    $enicversion = $worksheetmain.Cells[($enicver.Substring(1,$enicver.Length-1)),(($hashnamemain[$dropdownrcm.SelectedItem.ToString()])+1)].value
                }
                ELSE
                {
                    $enicversion = $worksheetmain.Cells[($enicver.Substring(1,$enicver.Length-1)),($hashnamemain[$dropdownrcm.SelectedItem.ToString()])].value
                }
            }
            IF($fnicver -ne "N/A")
            {
                IF($worksheetmain.Cells[($fnicver.Substring(1,$fnicver.Length-1)),(($hashnamemain[$dropdownrcm.SelectedItem.ToString()])+1)].value -ne $null)
                {
                    $fnicversion = $worksheetmain.Cells[($fnicver.Substring(1,$fnicver.Length-1)),(($hashnamemain[$dropdownrcm.SelectedItem.ToString()])+1)].value
                }
                ELSE
                {
                    $fnicversion = $worksheetmain.Cells[($fnicver.Substring(1,$fnicver.Length-1)),($hashnamemain[$dropdownrcm.SelectedItem.ToString()])].value
                }
            }
            IF($ppvever -ne "N/A")
            {
                IF($worksheetmain.Cells[($ppvever.Substring(1,$ppvever.Length-1)),(($hashnamemain[$dropdownrcm.SelectedItem.ToString()])+1)].value -ne $null)
                {
                    $ppveversion = $worksheetmain.Cells[($ppvever.Substring(1,$ppvever.Length-1)),(($hashnamemain[$dropdownrcm.SelectedItem.ToString()])+1)].value
                }
                ELSE
                {
                    $ppveversion = $worksheetmain.Cells[($ppvever.Substring(1,$ppvever.Length-1)),($hashnamemain[$dropdownrcm.SelectedItem.ToString()])].value
                }
            }  
        }
        
        $esxiname = $versionGridView3.Columns[2].Name = "ESXi = $esxiversion" 
        $enicname = $versionGridView3.Columns[3].Name = "ENIC = $enicversion"
        $fnicname = $versionGridView3.Columns[4].Name = "FNIC = $fnicversion"
        $ppvename = $versionGridView3.Columns[5].Name = "PPVE = $ppveversion"

        For($i=0;$i -lt $versionGridView3.RowCount;$i++)
        {
            $vermatch = "False"

            IF($enicver -eq "N/A" -and $fnicver -eq "N/A" -and $ppvever -eq "N/A")
            {
                IF(($versionGridView3.Rows[$i].Cells[$esxiname].value).trim() -eq $esxiversion){$vermatch = "True"}
            }
            ELSE
            {
                $arrayesxiver = @()
                                
                IF(($versionGridView3.Rows[$i].Cells[$esxiname].value).trim() -eq $esxiversion){$esxiverhash += "True"}ELSE{$arrayesxiver += "False"}
                
                IF((($versionGridView3.Rows[$i].Cells[$enicname].value).trim() -eq $enicversion) -or (($versionGridView3.Rows[$i].Cells[$enicname].value).trim() -eq "N/A"))
                {
                    $arrayesxiver += "True"
                }
                ELSE{$arrayesxiver += "False"}
                
                IF((($versionGridView3.Rows[$i].Cells[$fnicname].value).trim() -eq $fnicversion) -or (($versionGridView3.Rows[$i].Cells[$fnicname].value).trim() -eq "N/A"))
                {
                    $esxiverhash += "True"
                }
                ELSE{$arrayesxiver += "False"}

                IF((($versionGridView3.Rows[$i].Cells[$ppvename].value).trim() -like "$ppveversion*") -or (($versionGridView3.Rows[$i].Cells[$ppvename].value).trim() -eq "N/A"))
                {
                    $esxiverhash += "True"
                }
                ELSE{$arrayesxiver += "False"}
                
                IF($arrayesxiver -notcontains "False"){$vermatch = "True"}ELSE{$vermatch = "False"}
            }

            IF($vermatch -eq "True")
            {
                $versionGridView3.Rows[$i].DefaultCellStyle.BackColor = "Green"
                $versionGridView3.Rows[$i].DefaultCellStyle.ForeColor = "White"
            }
            ELSE
            {
                $versionGridView3.Rows[$i].DefaultCellStyle.BackColor = "Red"
                $versionGridView3.Rows[$i].DefaultCellStyle.ForeColor = "White"
            }
        }
    
#endregion ESXi tab

    }

    ELSE
    {
        For($i=0;$i -lt $versionGridView1.RowCount;$i++)
        { 
            $versionGridView1.Rows[$i].Cells['RCM Version'].Value = ""
            $versionGridView1.Rows[$i].DefaultCellStyle.BackColor = "White"
            $versionGridView1.Rows[$i].DefaultCellStyle.ForeColor = "Black"
        }
        
        $versionGridView3.Columns[2].Name = "ESXi"
        $versionGridView3.Columns[3].Name = "ENIC"
        $versionGridView3.Columns[4].Name = "FNIC"
        $versionGridView3.Columns[5].Name = "PPVE"
        $versionGridView3.Columns[6].Name = "VEM"
        
        For($i=0;$i -lt $versionGridView3.RowCount;$i++)
        { 
            $versionGridView3.Rows[$i].DefaultCellStyle.BackColor = "White"
            $versionGridView3.Rows[$i].DefaultCellStyle.ForeColor = "Black"
        }
    }

    $excel.dispose()

} # End Function check-versions

Function add-HelpNode
{
    param(
	    $selectedNode,
		$name,
		$tag
    )
	
    $newNode = new-object System.Windows.Forms.TreeNode 
	$newNode.Name = $name
	$newNode.Text = $name
	$newNode.Tag  = $tag
	$selectedNode.Nodes.Add($newNode) | Out-Null
	return $newNode
} # End Function add-HelpNode

Function open-help
{

[xml]$helpnodes = Get-Content $helpnodesfile

$objFormHelp = New-Object System.Windows.Forms.Form
$objFormHelp.Icon = "$ScriptPath\Bin\Icons\VCE.ico"
$objFormHelp.AutoScroll = $True
$objFormHelp.ClientSize = New-Object System.Drawing.Size(780,515)
$objFormHelp.Name = "objformHelp"
$objFormHelp.StartPosition = 1
$objFormHelp.Text = "CRG Help"
$objFormHelp.DataBindings.DefaultDataSourceUpdateMode = 0

$treeViewhelp           = New-Object System.Windows.Forms.TreeView
$treeViewhelp.Location  = New-Object System.Drawing.Point(0,0)
$treeViewhelp.Size      = New-Object System.Drawing.Size("200",($objFormHelp.Height -38))
$treeViewhelp.Name      = "treeView1"
$objFormHelp.Controls.Add($treeViewhelp)
$treeViewhelp.DataBindings.DefaultDataSourceUpdateMode = 0

$labelhelpdesc          = New-Object System.Windows.Forms.Label
$labelhelpdesc.Size     = New-Object System.Drawing.Size(100,20)
$labelhelpdesc.Location = New-Object System.Drawing.Point(210,5)
$labelhelpdesc.Text     = "Description"
$labelhelpdesc.Name     = "labelhelpdesc"
$labelhelpdesc.DataBindings.DefaultDataSourceUpdateMode = 0
$objFormHelp.Controls.Add($labelhelpdesc)

$richtexthelpdetails           = New-Object System.Windows.Forms.RichTextBox
$richtexthelpdetails.Size      = New-Object System.Drawing.Size(562,480)
$richtexthelpdetails.Location  = New-Object System.Drawing.Point(210,25)
$richtexthelpdetails.Text      = ""
$richtexthelpdetails.Name      = "richtexthelpdetails"
$richtexthelpdetails.ReadOnly  = $True
$richtexthelpdetails.DataBindings.DefaultDataSourceUpdateMode = 0
$objFormHelp.Controls.Add($richtexthelpdetails)

$objFormHelp.add_Load(
{
	IF ($script:cmdletNodes) 
    { 
      	$treeViewhelp.Nodes.remove($script:cmdletNodes)
        $objFormHelp.Refresh()
    }
	
    $script:cmdletNodes = New-Object System.Windows.Forms.TreeNode
	$script:cmdletNodes.text = "PowerShell Help"
	$script:cmdletNodes.Name = "PowerShell Help"
	$script:cmdletNodes.Tag = "root"
	$treeViewhelp.Nodes.Add($script:cmdletNodes) | Out-Null
	
	$treeViewhelp.add_AfterSelect(
    {
	    IF(($this.SelectedNode.Tag)[0] -eq "Cmdlet")
        {
		    IF($this.SelectedNode.Tag[1] -eq "Module")
            {
                $helpText = Get-Help ($this.SelectedNode.Tag)[2]
			    $richtexthelpdetails.Text = $helpText | Out-String
			    $objFormHelp.refresh()
            }
            ELSEIF($this.SelectedNode.Tag[1] -eq "String")
            {
			    $richtexthelpdetails.Text = $this.SelectedNode.Tag[2]
			    $objFormHelp.refresh()
            }
		} 
        ELSE
        {
			$richtexthelpdetails.Text = ""
		}
	})
	
    ForEach($module in ($helpnodes.crg_help.GetEnumerator() | Select-Object -ExpandProperty Name))
    {
        $parentNode = Add-HelpNode $cmdletNodes $module "Module"
		$moduleCmdlets = $helpnodes.crg_help.$module.GetEnumerator() | Select-Object -ExpandProperty Name
		
        ForEach($command in $moduleCmdlets)
        {
           $tag1 = "Cmdlet"
           $tag2 = $helpnodes.crg_help.$module.$command.source
           $tag3 = $helpnodes.crg_help.$module.$command.value
           $childnodetag = $tag1,$tag2,$tag3
           $childNode = Add-HelpNode $parentNode $command $childnodetag
        }
    }
	$script:cmdletNodes.Expand()
})
$objFormHelp.ShowDialog() | Out-Null

} # End Function open-help

Function about-config 
{

$about += "  Module Versions:

  vce-vmware:       $modVersion
  global-functions: $globalVersion
  import-lcs:       $importlcsversion
  crg-versions:     $crgversionsversion
  crg-assessments:  $crgassessmentver
"
    #Add objects for About
    $formAbout = New-Object System.Windows.Forms.Form
    $richTextBoxAbout = New-Object System.Windows.Forms.RichTextBox
    
    #About Form
    $formAbout.Icon = "$ScriptPath\Bin\Icons\VCE.ico"
    $formAbout.AutoScroll = $True
    $formAbout.ClientSize = New-Object System.Drawing.Size(464,500)
    $formAbout.DataBindings.DefaultDataSourceUpdateMode = 0
    $formAbout.Name = "formAbout"
    $formAbout.StartPosition = 1
    $formAbout.Text = "About Message Center"
    
    $richTextBoxAbout.Anchor = 15
    $richTextBoxAbout.BackColor = [System.Drawing.Color]::FromArgb(255,240,240,240)
    $richTextBoxAbout.BorderStyle = 0
    $richTextBoxAbout.Font = "lucida console"
    $richTextBoxAbout.DataBindings.DefaultDataSourceUpdateMode = 0
    $richTextBoxAbout.Location = New-Object System.Drawing.Point(13,13)
    $richTextBoxAbout.Name = "richTextBoxAbout"
    $richTextBoxAbout.ReadOnly = $True
    $richTextBoxAbout.Size = New-Object System.Drawing.Size(440,500)
    $richTextBoxAbout.Text = $about
        
    $formAbout.Controls.Add($richTextBoxAbout)

    $formAbout.Show() | Out-Null

} # End About Config

Function check-prerequisites
{

IF($CHECK_PREREQS -eq "false")
{
    Write-Host "`n**Started checking for 3rd party tools.**"

    $installed = @{}

    IF($psversiontable.psversion.major -ge 3)
    {
        $installed.Add("PowerShell 3","Installed")
    }
    ELSE
    {
        $installed.Add("PowerShell 3","Not Installed")
    }

    Try{
        start-process -erroraction STOP uemcli.exe -WindowStyle Hidden
        $installed.Add("uemcli","Installed")
    }
    Catch{
        $installed.Add("uemcli","Not Installed")
    }
    Try{
        start-process -erroraction STOP naviseccli.exe -WindowStyle Hidden
        $installed.Add("naviseccli","Installed")
    }
    Catch{
        $installed.Add("naviseccli","Not Installed")
    }
    Try{
        start-process -erroraction STOP symcli.exe -WindowStyle Hidden
        $installed.Add("symcli","Installed")
    }
    Catch{
        $installed.Add("symcli","Not Installed")
    }
    IF((get-PsSnapin -registered | ? {$_.Name -eq "VMware.VimAutomation.Core"}) -ne $null)
    {
        $installed.Add("PowerCLI","Installed")
    }
    ELSE
    {
        $installed.Add("PowerCLI","Not Installed")
    }
    Try{
        $net4installed = Get-ItemProperty -path "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -ErrorAction STOP | Select-Object -ExpandProperty Install
        IF($net4installed -eq 1)
        {
            $installed.Add(".net v4","Installed")
        }
        ELSE{$installed.Add(".net v4","Not Installed")}
    }
    Catch{
        $installed.Add(".net v4","Not Installed")
    }   
	
	Try{
       $telnetConfigFile= "$pwd\Bin\configs\telnet.config"
	   IF(Test-Path $telnetConfigFile) {
			$telnet=ConvertFrom-Json (gc $telnetConfigFile -raw)
			IF($telnet.enabled -eq $TRUE) {
				$python=$telnet.pythonPath

				$cmdoutput=cmd /c $python --version '2>&1'
				$pythonVersion=$cmdoutput.split(" ")[1]
				$vc=$pythonVersion.split(".")
				if($vc[0] -ne 2 -or $vc[1] -ne 7 -or $vc[2] -lt 12) {
					$installed.Add("Python 2.7.12","Not Installed")
				} ELSE {
					$installed.Add("Python $pythonVersion","Installed")
				}
			}
		}
    }
    Catch{
        $installed.Add("Python 2.7","Not Installed")
    }    

    ForEach($item in $installed.keys)
    {
        IF($ITEM.length -gt 12) {
			write-host "   $item " -NoNewline
		} ELSE {
			write-host "   $item`t " -NoNewline
		}

        IF($installed[$item] -eq "installed")
        {
            write-host $installed[$item] -ForegroundColor Green}ELSE{Write-Host $installed[$item] -ForegroundColor Red
        }
    }

    Write-Host "**Finished checking for 3rd party tools.**"
}

$prereqFormSize = ($arraypsscripts.count * 22.5) + 4

$prereqForm = New-Object System.Windows.Forms.Form
$prereqForm.Icon = "$ScriptPath\Bin\Icons\VCE.ico"
$prereqForm.AutoScroll = $True
$prereqForm.ClientSize = New-Object System.Drawing.Size(590,$prereqFormSize)
$prereqForm.Name = "prereqform"
$prereqForm.StartPosition = 1
$prereqForm.Text = "Prerequisite Checker"

$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.location = New-Object System.Drawing.Size(5,5)
$dataGridView.Size=New-Object System.Drawing.Size(580,($prereqFormSize - 10))

$dataGridView.AllowUserToAddRows    = $false
$datagridview.AllowUserToDeleteRows = $false
$dataGridView.RowHeadersVisible     = $false

$prereqForm.Controls.Add($dataGridView)

$dataGridView.ColumnCount = 4
$dataGridView.ColumnHeadersVisible = $true
$dataGridView.Columns[0].Name = "Component"
$dataGridView.Columns[0].width = 100
$dataGridView.Columns[1].Name = "Product"
$dataGridView.Columns[1].width = 120
$dataGridView.Columns[2].Name = "Version"
$datagridview.Columns[2].width = 80
$datagridview.Columns[3].Name = "Notes"
$datagridview.Columns[3].width = 255

$i = 0

IF($psversiontable.psversion.major -ge 3)
{
    $Psversion = "Powershell 3.0+ found"
    $dataGridView.Rows.Add("Powershell",$Psversion,$psversiontable.psversion.major,"")
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $Psversion = "Powershell " + $psversiontable.psversion.major + " found"
    $dataGridView.Rows.Add("Powershell",$Psversion,$psversiontable.psversion.major,"Powershell 3 or above required")
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "pink"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
}

IF($installed[".net v4"] -eq "Installed"){$net4presence = ".net 4 or above found"}ELSE{$net4presence = ".net 4 or above NOT found"}

$dataGridView.Rows.Add(".net v4+",$net4presence,"","")

IF($installed[".net v4"] -eq "Installed")
{
    $dataGridView.Rows[$i].Cells[2].Value = Get-ItemProperty -path "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" | Select-Object -ExpandProperty Version
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE{$dataGridView.Rows[$i++].Cells[1].Style.BackColor = "pink"}

$dataGridView.Rows.Add("UCS-B",$Psversion,$psversiontable.psversion.major,"")

IF($Psversion -eq "Powershell 3.0+ found")
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[3].Value = "Powershell 3 or above required"
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "pink"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
}

$dataGridView.Rows.Add("UCS-C",$Psversion,$psversiontable.psversion.major,"")

IF($Psversion -eq "Powershell 3.0+ found")
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[3].Value = "Powershell 3 or above required"
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "pink"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
}

$dataGridView.Rows.Add("Catalyst Switch",$Psversion,$psversiontable.psversion.major,"")

IF($Psversion -eq "Powershell 3.0+ found")
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[3].Value = "Powershell 3 or above required"
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "pink"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
}

$dataGridView.Rows.Add("Nexus Switch",$Psversion,$psversiontable.psversion.major,"")

IF($Psversion -eq "Powershell 3.0+ found")
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[3].Value = "Powershell 3 or above required"
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "pink"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
}

$dataGridView.Rows.Add("MDS Switch",$Psversion,$psversiontable.psversion.major,"")

IF($Psversion -eq "Powershell 3.0+ found")
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[3].Value = "Powershell 3 or above required"
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "pink"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
}

IF($installed["uemcli"] -eq "installed")
{
    $VNXeFound   = "uemcli found"
    $VNXeVersion = ((& uemcli.exe -v)[0].TrimStart("Version:  ")).trimend(".UEM_BUILD_NUM") 
    $dataGridView.Rows.Add("VNXe",$VNXeFound,$VNXeVersion,"")
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $VNXeFound  = "uemcli NOT found"
    $dataGridView.Rows.Add("VNXe",$VNXeFound,"","")    
    $dataGridView.Rows[$i++].Cells[1].Style.BackColor = "pink"
}

IF($installed["uemcli"] -eq "installed")
{
    $UnityFound   = "uemcli found"
    $UnityVersion = ((& uemcli.exe -v)[0].TrimStart("Version:  ")).trimend(".UEM_BUILD_NUM") 
    $dataGridView.Rows.Add("Unity",$UnityFound,$UnityVersion,"")
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $UnityFound  = "uemcli NOT found"
    $dataGridView.Rows.Add("Unity",$UnityFound,"","")    
    $dataGridView.Rows[$i++].Cells[1].Style.BackColor = "pink"
}
IF($installed["naviseccli"] -eq "installed")
{
    $VNXFound   = "naviseccli found"
    
    IF((Get-WmiObject Win32_operatingsystem).osarchitecture -eq "64-Bit")
    {
        IF((Get-Itemproperty "hklm:\SOFTWARE\Wow6432Node\EMC\Navisphere CLI" | select -ExpandProperty ReleaseVersion) -ne $null)
        {
            $VNXVersion = Get-Itemproperty "hklm:\SOFTWARE\Wow6432Node\EMC\Navisphere CLI" | select -ExpandProperty ReleaseVersion
        }
        ELSE{$VNXVersion = Get-Itemproperty "hklm:\SOFTWARE\EMC\Navisphere CLI" | select -ExpandProperty ReleaseVersion}
    }
    ELSE
    {
        $VNXVersion = Get-Itemproperty "hklm:\SOFTWARE\EMC\Navisphere CLI" | select -ExpandProperty ReleaseVersion
    }  

    $dataGridView.Rows.Add("VNX",$VNXFound,$VNXVersion,"")

    IF((naviseccli security -certificate -getlevel) -ne "low") 
    { 
        $dataGridView.Rows[$i].Cells[3].Value = "Security level is not LOW."
        $dataGridView.Rows[$i].Cells[3].Style.BackColor = "yellow"
	}
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
    
}
ELSE
{
    $VNXFound  = "naviseccli NOT found"
    $VNXVersion = ""
    $dataGridView.Rows.Add("VNX",$VNXFound,$VNXVersion,"")    
    $dataGridView.Rows[$i++].Cells[1].Style.BackColor = "pink"
}

IF($installed["symcli"] -eq "installed")
{
    $VMAXFound = "symcli found"
    $VMAXVersion = Get-Itemproperty "hklm:\software\EMC\EMC Solutions Enabler" | select -ExpandProperty BuildNumber
    $dataGridView.Rows.Add("VMAX",$VMAXFound,$VMAXVersion,"")
        
    IF($VMAXVersion.TrimStart("V") -le "7.5")
    {
        $VMAXNote = "Req: VMAX >= 7.6, VMAX3 >= 8"
        $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
        $dataGridView.Rows[$i].Cells[2].Style.BackColor = "pink"
        $dataGridView.Rows[$i++].Cells[3].Value = $VMAXNote
    }
    ELSEIF($VMAXVersion.TrimStart("V") -ge "7.6" -and $VMAXVersion.TrimStart("V") -le 8)
    {
        $VMAXNote = "VMAX3 needs ver 8.0"
        $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
        $dataGridView.Rows[$i].Cells[2].Style.BackColor = "pink"
        $dataGridView.Rows[$i++].Cells[3].Value = $VMAXNote
    }
    ELSEIF($VMAXVersion.TrimStart("V") -ge "8")
    {
        $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
        $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
    }
} 
ELSE
{ 
    $VMAXFound = "symcli NOT found"
    $VMAXNote  = "Req: VMAX >= 7.6, VMAX3 >= 8"
    $dataGridView.Rows.Add("VMAX",$VMAXFound,$VMAXVersion,$VMAXNote)
    $dataGridView.Rows[$i++].Cells[1].Style.BackColor = "pink"
}

$dataGridView.Rows.Add("XtremIO",$Psversion,$psversiontable.psversion.major,"")

IF($Psversion -eq "Powershell 3.0+ found")
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[3].Value = "Powershell 3 or above required"
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "pink"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
}

$dataGridView.Rows.Add("VPLEX",$Psversion,$psversiontable.psversion.major,"")

IF($Psversion -eq "Powershell 3.0+ found")
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[3].Value = "Powershell 3 or above required"
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "pink"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
}

IF($installed["PowerCLI"] -eq "installed")
{
    $PCLIFound = "PowerCLI found"
    IF((Get-WmiObject Win32_operatingsystem).osarchitecture -eq "64-Bit")
    {
        $PCLIversion = Get-Itemproperty "hklm:\SOFTWARE\Wow6432Node\Microsoft\PowerShell\1\PowerShellSnapIns\VMware.VimAutomation.Core" | select -ExpandProperty Version
    }
    ELSE
    {
        $PCLIversion = Get-Itemproperty "hklm:\SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\VMware.VimAutomation.Core" | select -ExpandProperty Version
    }
    IF($PCLIversion -ge "5.1.0")
    {
        $dataGridView.Rows.Add("VMware",$PCLIFound,$PCLIversion,"")
        $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
        $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
    }
    ELSEIF($PCLIversion -eq "5.0.0")
    {
        $PCLINote = "Req. 5.1 some features won't work"
        
        $dataGridView.Rows.Add("VMware",$PCLIFound,$PCLIversion,$PCLINote)
        $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
        $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "yellow"
    }
    ELSEIF($PCLIversion -lt "5.0.0")
    {
        $PCLINote = "Requires 5.1 or above"
        
        $dataGridView.Rows.Add("VMware",$PCLIFound,$PCLIversion,$PCLINote)
        $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
        $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
    }
} 
ELSE
{
    $PCLIFound = "PowerCLI NOT found"
    $PCLINote  = "Requires 5.1 or above"
    $dataGridView.Rows.Add("VMware",$PCLIFound,$PCLIversion,$PCLINote)
    $dataGridView.Rows[$i++].Cells[1].Style.BackColor = "pink"
}

$dataGridView.Rows.Add("Isilon",$Psversion,$psversiontable.psversion.major,"")

IF($Psversion -eq "Powershell 3.0+ found")
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[3].Value = "Powershell 3 or above required"
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "pink"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
}

$dataGridView.Rows.Add("NSX",$Psversion,$psversiontable.psversion.major,"")

IF($Psversion -eq "Powershell 3.0+ found")
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[3].Value = "Powershell 3 or above required"
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "pink"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
}

$dataGridView.Rows.Add("IPI",$Psversion,$psversiontable.psversion.major,"")

IF($Psversion -eq "Powershell 3.0+ found")
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "lime"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "lime"
}
ELSE
{
    $dataGridView.Rows[$i].Cells[2].Value = $psversiontable.psversion.major
    $dataGridView.Rows[$i].Cells[3].Value = "Powershell 3 or above required"
    $dataGridView.Rows[$i].Cells[1].Style.BackColor = "pink"
    $dataGridView.Rows[$i++].Cells[2].Style.BackColor = "pink"
}

$prereqForm.Show() | Out-Null

} # End check-prerequisites

Function run-bladesummary
{

$tabxstart = 10
$tabystart = 10
$tabxsize  = 100
$tabysize  = 20

$bladesummaryformxsize = 70 

(($arraypsscripts | ? {$_.Name -eq "UCSC" -or $_.Name -eq "UCSB" -or $_.Name -eq "VMWR"}) | % {$bladesummaryformxsize += ($_.instance * 22.5)})

$bladesummaryForm      = New-Object Windows.Forms.Form
$bladesummaryForm.Size = New-Object Drawing.Size @(1024,$bladesummaryformxsize)
$bladesummaryForm.Icon = "$ScriptPath\Bin\Icons\VCE.ico"
$bladesummaryForm.Text = "Blade Summary Report"

#region Tab Scripts

$bladesummarydatagrid = New-Object System.Windows.Forms.DataGridView
$bladesummarydatagrid.location = New-Object System.Drawing.Size(2,2)
$bladesummarydatagrid.Size     = New-Object System.Drawing.Size(($bladesummaryForm.Width - 0),($bladesummaryForm.Height - 72))
$bladesummarydatagrid.ReadOnly = $True
$bladesummarydatagrid.AllowUserToAddRows = $false
$bladesummarydatagrid.AllowUserToDeleteRows = $false
$bladesummarydatagrid.Anchor = "Right,Left,Top,Bottom"
$bladesummaryForm.Controls.Add($bladesummarydatagrid)

$bladesummarydatagrid.ColumnHeadersVisible = $false
$bladesummarydatagrid.RowHeadersVisible    = $false

$bladesummarydatagridcol1 = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$bladesummarydatagridcol2 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$bladesummarydatagridcol3 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$bladesummarydatagridcol4 = New-Object System.Windows.Forms.DataGridViewButtonColumn

$bladesummarydatagridcol1.Width = "50"
$bladesummarydatagridcol2.Width = "80"
$bladesummarydatagridcol3.Width = "810"
$bladesummarydatagridcol4.Width = "60"

$bladesummarydatagrid.Columns.AddRange($bladesummarydatagridcol1,$bladesummarydatagridcol2,$bladesummarydatagridcol3,$bladesummarydatagridcol4)

ForEach($psscript in $arraypsscripts)
{
    IF($psscript.Name -eq "UCSC" -or $psscript.Name -eq "UCSB" -or $psscript.Name -eq "VMWR")
    {
        $i = 1
        do
        {
            IF($psscript.Instance -eq 1)
            {
                $bladesummarydatagrid.Rows.Add($false,$psscript.alias,"","Browse")
            }
            ELSE
            {
                $bladesummarydatagrid.Rows.Add($false,($psscript.alias + " $i"),"","Browse")
            }            
            $i++
        }while($i -le $psscript.Instance)
    }
}

$bladesummarydatagrid.add_cellclick({

    IF($_.ColumnIndex -eq 0)
    {
        IF($bladesummarydatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $false){$bladesummarydatagrid.Rows[$_.RowIndex].Cells[0].Value = $true}
        ELSEIF($bladesummarydatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $true){$bladesummarydatagrid.Rows[$_.RowIndex].Cells[0].Value = $false}
    }

    if($_.ColumnIndex -eq 3)
    {
        $xmlfile       = $bladesummarydatagrid.Rows[$_.RowIndex].Cells[1].Value

        IF(($temp = Get-FileName -initialdirectory $OutputTextBox.Text -filetype 'XML (*.xml) | *.xml') -ne "")
        {
            $bladesummarydatagrid.Rows[$_.RowIndex].Cells[2].Value = $temp
            $bladesummarydatagrid.Rows[$_.RowIndex].Cells[0].Value = $true
        }
    }
})

#endregion Tab Scripts

# Button Area

$buttonPanel = New-Object Windows.Forms.Panel
$buttonPanel.Size = New-Object Drawing.Size @(300,30)
$buttonPanel.Dock = "Bottom"
$bladesummaryForm.Controls.Add($buttonPanel)

$cancelButton = New-Object Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.DialogResult = "Cancel"
$cancelButton.Top = $buttonPanel.Height - $cancelButton.Height - 5
$cancelButton.Left = $buttonPanel.Width - $cancelButton.Width - 10
$cancelButton.Anchor = "Right"
$buttonPanel.Controls.Add($cancelButton)

$runButton = New-Object Windows.Forms.Button
$runButton.Text = "Run"
$runButton.Top = $cancelButton.Top
$runButton.Left = $cancelButton.Left - $runButton.Width - 5
$runButton.Anchor = "Right"
$buttonPanel.Controls.Add($runButton)
$runButton.Add_Click({

        $ReportXMLFiles = @{}

        For($i=0;$i -lt $bladesummarydatagrid.RowCount;$i++)
        {
            IF(($bladesummarydatagrid.Rows[$i].Cells[2].Value -ne "") -and ($bladesummarydatagrid.Rows[$i].Cells[0].Value -eq $true))
            {
                $ReportXMLFiles.Add($bladesummarydatagrid.Rows[$i].Cells[1].Value,$bladesummarydatagrid.Rows[$i].Cells[2].Value)
            }
        }

        & BladeSummary-Report.ps1 -ReportXMLFiles $ReportXMLFiles -OutputPath $outputtextbox.text

        $bladesummaryForm.close()
})

# Load Form

$bladesummaryForm.CancelButton = $cancelButton
$bladesummaryForm.Add_Shown({$bladesummaryForm.Activate()})

$result = $bladesummaryForm.ShowDialog()

} # End run-bladesummary

Function run-portmapreport
{

$tabxstart = 10
$tabystart = 10
$tabxsize  = 100
$tabysize  = 20

$portformxsize = 70 

(($arraypsscripts | ? {$_.Name -eq "C35" -or $_.Name -eq "C37" -or $_.Name -eq "MDS" -or $_.Name -eq "NX"}) | % {$portformxsize += ($_.instance * 22.5)})

$portmapForm      = New-Object Windows.Forms.Form
$portmapForm.Size = New-Object Drawing.Size @(1024,$portformxsize)
$portmapForm.Icon = "$ScriptPath\Bin\Icons\VCE.ico"
$portmapForm.Text = "PortMap Report"

#region Tab Scripts

$portmapdatagrid = New-Object System.Windows.Forms.DataGridView
$portmapdatagrid.location = New-Object System.Drawing.Size(2,2)
$portmapdatagrid.Size     = New-Object System.Drawing.Size(($portmapForm.Width - 0),($portmapForm.Height - 72))
$portmapdatagrid.ReadOnly = $True
$portmapdatagrid.AllowUserToAddRows = $false
$portmapdatagrid.AllowUserToDeleteRows = $false
$portmapdatagrid.Anchor = "Right,Left,Top,Bottom"
$portmapForm.Controls.Add($portmapdatagrid)

$portmapdatagrid.ColumnHeadersVisible = $false
$portmapdatagrid.RowHeadersVisible    = $false

$portmapdatagridcol1 = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$portmapdatagridcol2 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$portmapdatagridcol3 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$portmapdatagridcol4 = New-Object System.Windows.Forms.DataGridViewButtonColumn

$portmapdatagridcol1.Width = "50"
$portmapdatagridcol2.Width = "87"
$portmapdatagridcol3.Width = "805"
$portmapdatagridcol4.Width = "60"

$portmapdatagrid.Columns.AddRange($portmapdatagridcol1,$portmapdatagridcol2,$portmapdatagridcol3,$portmapdatagridcol4)

ForEach($psscript in $arraypsscripts)
{
    IF($psscript.Name -eq "C35" -or $psscript.Name -eq "C37" -or $psscript.Name -eq "MDS" -or $psscript.Name -eq "NX")
    {
        $i = 1
        do
        {
            IF($psscript.Instance -eq 1)
            {
                $portmapdatagrid.Rows.Add($false,$psscript.alias,"","Browse")
            }
            ELSE
            {
                $portmapdatagrid.Rows.Add($false,($psscript.alias + " $i"),"","Browse")
            }            
            $i++
        }while($i -le $psscript.Instance)
    }
}

$portmapdatagrid.add_cellclick({

    IF($_.ColumnIndex -eq 0)
    {
        IF($portmapdatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $false){$portmapdatagrid.Rows[$_.RowIndex].Cells[0].Value = $true}
        ELSEIF($portmapdatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $true){$portmapdatagrid.Rows[$_.RowIndex].Cells[0].Value = $false}
    }

    if($_.ColumnIndex -eq 3)
    {
        $xmlfile       = $portmapdatagrid.Rows[$_.RowIndex].Cells[1].Value

        IF(($temp = Get-FileName -initialdirectory $OutputTextBox.Text -filetype 'XML (*.xml) | *.xml') -ne "")
        {
            $portmapdatagrid.Rows[$_.RowIndex].Cells[2].Value = $temp
            $portmapdatagrid.Rows[$_.RowIndex].Cells[0].Value = $true
        }
    }
})

#endregion Tab Scripts

# Button Area

$buttonPanel = New-Object Windows.Forms.Panel
$buttonPanel.Size = New-Object Drawing.Size @(300,30)
$buttonPanel.Dock = "Bottom"
$portmapForm.Controls.Add($buttonPanel)

$cancelButton = New-Object Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.DialogResult = "Cancel"
$cancelButton.Top = $buttonPanel.Height - $cancelButton.Height - 5
$cancelButton.Left = $buttonPanel.Width - $cancelButton.Width - 10
$cancelButton.Anchor = "Right"
$buttonPanel.Controls.Add($cancelButton)

$runButton = New-Object Windows.Forms.Button
$runButton.Text = "Run"
$runButton.Top = $cancelButton.Top
$runButton.Left = $cancelButton.Left - $runButton.Width - 5
$runButton.Anchor = "Right"
$buttonPanel.Controls.Add($runButton)
$runButton.Add_Click({

        $ReportXMLFiles = @{}
        $outputpath = $OutputTextBox.Text
        $ReportXLSXFile = "$outputpath\Portmap_$TIMESTAMP`_report.xlsx" 

        For($i=0;$i -lt $portmapdatagrid.RowCount;$i++)
        {
            IF(($portmapdatagrid.Rows[$i].Cells[2].Value -ne "") -and ($portmapdatagrid.Rows[$i].Cells[0].Value -eq $true))
            {
                & $PS_PortMap -ReportXMLFile $portmapdatagrid.Rows[$i].Cells[2].Value -ReportXLSXFile $ReportXLSXFile 
            }
        }
    
        $portmapForm.close()
})

# Load Form

$portmapForm.CancelButton = $cancelButton
$portmapForm.Add_Shown({$portmapForm.Activate()})

$result = $portmapForm.ShowDialog()

} # End run-portmapreport

Function run-versionreport
{

$tabxstart = 10
$tabystart = 10
$tabxsize  = 100
$tabysize  = 20

$versionformxsize = 70 

(($arraypsscripts | ? {$_.Name -ne "ipi"}) | % {$versionformxsize += ($_.instance * 22.5)})

$versionreportForm      = New-Object Windows.Forms.Form
$versionreportForm.Size = New-Object Drawing.Size @(1024,$versionformxsize)
$versionreportForm.Icon = "$ScriptPath\Bin\Icons\VCE.ico"
$versionreportForm.Text = "Version Report"

#region Tab Scripts

$versionreportdatagrid = New-Object System.Windows.Forms.DataGridView
$versionreportdatagrid.location = New-Object System.Drawing.Size(2,2)
$versionreportdatagrid.Size     = New-Object System.Drawing.Size(($versionreportForm.Width - 0),($versionreportForm.Height - 80))
$versionreportdatagrid.ReadOnly = $True
$versionreportdatagrid.AllowUserToAddRows = $false
$versionreportdatagrid.AllowUserToDeleteRows = $false
$versionreportdatagrid.Anchor = "Right,Left,Top,Bottom"
$versionreportForm.Controls.Add($versionreportdatagrid)

$versionreportdatagrid.ColumnHeadersVisible = $false
$versionreportdatagrid.RowHeadersVisible    = $false

$versionreportdatagridcol1 = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$versionreportdatagridcol2 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$versionreportdatagridcol3 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$versionreportdatagridcol4 = New-Object System.Windows.Forms.DataGridViewButtonColumn

$versionreportdatagridcol1.Width = "50"
$versionreportdatagridcol2.Width = "87"
$versionreportdatagridcol3.Width = "805"
$versionreportdatagridcol4.Width = "60"

$versionreportdatagrid.Columns.AddRange($versionreportdatagridcol1,$versionreportdatagridcol2,$versionreportdatagridcol3,$versionreportdatagridcol4)

ForEach($psscript in $arraypsscripts)
{
    $i = 1
    do
    {
        IF($psscript.Instance -eq 1)
        {
            $versionreportdatagrid.Rows.Add($false,$psscript.alias,"","Browse")
        }
        ELSE
        {
            $versionreportdatagrid.Rows.Add($false,($psscript.alias + " $i"),"","Browse")
        }            
        $i++
    }while($i -le $psscript.Instance)
}

$versionreportdatagrid.add_cellclick({

    IF($_.ColumnIndex -eq 0)
    {
        IF($versionreportdatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $false){$versionreportdatagrid.Rows[$_.RowIndex].Cells[0].Value = $true}
        ELSEIF($versionreportdatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $true){$versionreportdatagrid.Rows[$_.RowIndex].Cells[0].Value = $false}
    }

    if($_.ColumnIndex -eq 3)
    {
        $xmlfile       = $versionreportdatagrid.Rows[$_.RowIndex].Cells[1].Value

        IF(($temp = Get-FileName -initialdirectory $OutputTextBox.Text -filetype 'XML (*.xml) | *.xml') -ne "")
        {
            $versionreportdatagrid.Rows[$_.RowIndex].Cells[2].Value = $temp
            $versionreportdatagrid.Rows[$_.RowIndex].Cells[0].Value = $true
        }
    }
})

#endregion Tab Scripts

# Button Area

$buttonPanel = New-Object Windows.Forms.Panel
$buttonPanel.Size = New-Object Drawing.Size @(300,30)
$buttonPanel.Dock = "Bottom"
$versionreportForm.Controls.Add($buttonPanel)

$cancelButton = New-Object Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.DialogResult = "Cancel"
$cancelButton.Top = $buttonPanel.Height - $cancelButton.Height - 5
$cancelButton.Left = $buttonPanel.Width - $cancelButton.Width - 10
$cancelButton.Anchor = "Right"
$buttonPanel.Controls.Add($cancelButton)

$runButton = New-Object Windows.Forms.Button
$runButton.Text = "Run"
$runButton.Top = $cancelButton.Top
$runButton.Left = $cancelButton.Left - $runButton.Width - 5
$runButton.Anchor = "Right"
$buttonPanel.Controls.Add($runButton)
$runButton.Add_Click({

        $ReportXMLFiles = @{}

        For($i=0;$i -lt $versionreportdatagrid.RowCount;$i++)
        {
            IF(($versionreportdatagrid.Rows[$i].Cells[2].Value -ne "") -and ($versionreportdatagrid.Rows[$i].Cells[0].Value -eq $true))
            {
                $ReportXMLFiles.Add($versionreportdatagrid.Rows[$i].Cells[1].Value,$versionreportdatagrid.Rows[$i].Cells[2].Value)
            }
        }

        IF($vercustRadio.Checked){$VersionType =  "Original"}
        ELSEIF($veraddenradio.Checked){$VersionType = "Addendum"}

        IF($dropdownsystype.SelectedItem.ToString() -ne "System Type"){$systemmodel = $dropdownsystype.SelectedItem.ToString()}ELSE{$systemmodel = $null}
        IF($dropdownrcm.SelectedItem.ToString() -ne "RCM Version"){$systemrcm = $dropdownrcm.SelectedItem.ToString()}ELSE{$systemrcm = $null}
    
        & $PS_Version -ReportXmlFiles $ReportXMLFiles -OutputPath $OutputTextBox.Text -outputtype "Excel" -VBID $SerialNumberTextBox.Text -scrubbed:([System.Convert]::ToBoolean($SCRUBDATA)) `
                      -SystemModel $systemmodel `
                      -SystemRCM $systemrcm `
                      -VersionType $VersionType

        $versionreportForm.close()
})

# Load Form

$versionreportForm.CancelButton = $cancelButton
$versionreportForm.Add_Shown({$versionreportForm.Activate()})

$result = $versionreportForm.ShowDialog()

} # End run-versionreport

Function run-xtremioreport
{

$tabxstart = 10
$tabystart = 10
$tabxsize  = 100
$tabysize  = 20

$xtremioformxsize = 70 

(($arraypsscripts | ? {$_.Name -eq "VMwr" -or $_.Name -eq "XtremIO" -or $_.Name -eq "UCSB"}) | % {$xtremioformxsize += ($_.instance * 23)})

$xtremioreportForm      = New-Object Windows.Forms.Form
$xtremioreportForm.Size = New-Object Drawing.Size @(1024,$xtremioformxsize)
$xtremioreportForm.Icon = "$ScriptPath\Bin\Icons\VCE.ico"
$xtremioreportForm.Text = "XtremIO Summary Report"

#region Tab Scripts

$xtremioreportdatagrid = New-Object System.Windows.Forms.DataGridView
$xtremioreportdatagrid.location = New-Object System.Drawing.Size(2,2)
$xtremioreportdatagrid.Size     = New-Object System.Drawing.Size(($xtremioreportForm.Width - 0),($xtremioreportForm.Height - 80))
$xtremioreportdatagrid.ReadOnly = $True
$xtremioreportdatagrid.AllowUserToAddRows = $false
$xtremioreportdatagrid.AllowUserToDeleteRows = $false
$xtremioreportdatagrid.Anchor = "Right,Left,Top,Bottom"
$xtremioreportForm.Controls.Add($xtremioreportdatagrid)

$xtremioreportdatagrid.ColumnHeadersVisible = $false
$xtremioreportdatagrid.RowHeadersVisible    = $false

$xtremioreportdatagridcol1 = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$xtremioreportdatagridcol2 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$xtremioreportdatagridcol3 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$xtremioreportdatagridcol4 = New-Object System.Windows.Forms.DataGridViewButtonColumn

$xtremioreportdatagridcol1.Width = "50"
$xtremioreportdatagridcol2.Width = "87"
$xtremioreportdatagridcol3.Width = "805"
$xtremioreportdatagridcol4.Width = "60"

$xtremioreportdatagrid.Columns.AddRange($xtremioreportdatagridcol1,$xtremioreportdatagridcol2,$xtremioreportdatagridcol3,$xtremioreportdatagridcol4)

ForEach($psscript in $arraypsscripts)
{
    IF($psscript.Name -eq "VMWr" -or $psscript.Name -eq "XtremIO" -or $psscript.Name -eq "UCSB")
    {
        $i = 1
        do
        {
            IF($psscript.Instance -eq 1)
            {
                $xtremioreportdatagrid.Rows.Add($false,$psscript.alias,"","Browse")
            }
            ELSE
            {
                $xtremioreportdatagrid.Rows.Add($false,($psscript.alias + " $i"),"","Browse")
            }            
            $i++
        }while($i -le $psscript.Instance)
    }
}

$xtremioreportdatagrid.add_cellclick({

    IF($_.ColumnIndex -eq 0)
    {
        IF($xtremioreportdatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $false){$xtremioreportdatagrid.Rows[$_.RowIndex].Cells[0].Value = $true}
        ELSEIF($xtremioreportdatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $true){$xtremioreportdatagrid.Rows[$_.RowIndex].Cells[0].Value = $false}
    }

    if($_.ColumnIndex -eq 3)
    {
        $xmlfile  = $xtremioreportdatagrid.Rows[$_.RowIndex].Cells[1].Value

        IF(($temp = Get-FileName -initialdirectory $OutputTextBox.Text -filetype 'XML (*.xml) | *.xml') -ne "")
        {
            $xtremioreportdatagrid.Rows[$_.RowIndex].Cells[2].Value = $temp
            $xtremioreportdatagrid.Rows[$_.RowIndex].Cells[0].Value = $true
        }
    }
})

#endregion Tab Scripts

# Button Area

$buttonPanel = New-Object Windows.Forms.Panel
$buttonPanel.Size = New-Object Drawing.Size @(300,30)
$buttonPanel.Dock = "Bottom"
$xtremioreportForm.Controls.Add($buttonPanel)

$cancelButton = New-Object Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.DialogResult = "Cancel"
$cancelButton.Top = $buttonPanel.Height - $cancelButton.Height - 5
$cancelButton.Left = $buttonPanel.Width - $cancelButton.Width - 10
$cancelButton.Anchor = "Right"
$buttonPanel.Controls.Add($cancelButton)

$runButton = New-Object Windows.Forms.Button
$runButton.Text = "Run"
$runButton.Top  = $cancelButton.Top
$runButton.Left = $cancelButton.Left - $runButton.Width - 5
$runButton.Anchor = "Right"
$buttonPanel.Controls.Add($runButton)
$runButton.Add_Click({

        $ReportXMLFiles = @{}

        For($i=0;$i -lt $xtremioreportdatagrid.RowCount;$i++)
        {
            IF(($xtremioreportdatagrid.Rows[$i].Cells[2].Value -ne "") -and ($xtremioreportdatagrid.Rows[$i].Cells[0].Value -eq $true))
            {
                $ReportXMLFiles.Add($xtremioreportdatagrid.Rows[$i].Cells[1].Value,$xtremioreportdatagrid.Rows[$i].Cells[2].Value)
            }
        }

        & $RP_XtremIO -ReportXMLFiles $ReportXMLFiles -OutputPath $OutputTextBox.Text -StorageArray $dropdownstoragetype.SelectedItem.tostring()

        $xtremioreportForm.close()
})

$dropdownstoragetypes = "XtremIO","Multi-Array","VNX","VMAX","VPLEX"

$dropdownstoragetype = New-Object Windows.forms.combobox
$dropdownstoragetype.Top  = $cancelButton.Top
$dropdownstoragetype.Left = $runbutton.Left - $dropdownstoragetype.Width - 10
$dropdownstoragetype.Anchor = "Right"
$buttonPanel.Controls.add($dropdownstoragetype)

ForEach($item in $dropdownstoragetypes){$dropdownstoragetype.Items.Add($item) | Out-Null}
$dropdownstoragetype.SelectedItem = "XtremIO"

# Load Form

$xtremioreportForm.CancelButton = $cancelButton
$xtremioreportForm.Add_Shown({$xtremioreportForm.Activate()})

$result = $xtremioreportForm.ShowDialog()

} # End run-xtremioreport

Function run-assessmentreport
{

$tabxstart = 10
$tabystart = 10
$tabxsize  = 100
$tabysize  = 20

$assessmentformxsize = 70 

$arraypsscripts | % {$assessmentformxsize += ($_.instance * 22.5)}

$assessmentreportForm      = New-Object Windows.Forms.Form
$assessmentreportForm.Size = New-Object Drawing.Size @(1024,$assessmentformxsize)
$assessmentreportForm.Icon = "$ScriptPath\Bin\Icons\VCE.ico"
$assessmentreportForm.Text = "Health Assessment Report"

#region Tab Scripts

$assessmentreportdatagrid = New-Object System.Windows.Forms.DataGridView
$assessmentreportdatagrid.location = New-Object System.Drawing.Size(2,2)
$assessmentreportdatagrid.Size     = New-Object System.Drawing.Size(($assessmentreportForm.Width - 0),($assessmentreportForm.Height - 80))
$assessmentreportdatagrid.ReadOnly = $True
$assessmentreportdatagrid.AllowUserToAddRows = $false
$assessmentreportdatagrid.AllowUserToDeleteRows = $false
$assessmentreportdatagrid.Anchor = "Right,Left,Top,Bottom"
$assessmentreportForm.Controls.Add($assessmentreportdatagrid)

$assessmentreportdatagrid.ColumnHeadersVisible = $false
$assessmentreportdatagrid.RowHeadersVisible    = $false

$assessmentreportdatagridcol1 = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$assessmentreportdatagridcol2 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$assessmentreportdatagridcol3 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$assessmentreportdatagridcol4 = New-Object System.Windows.Forms.DataGridViewButtonColumn

$assessmentreportdatagridcol1.Width = "50"
$assessmentreportdatagridcol2.Width = "87"
$assessmentreportdatagridcol3.Width = "805"
$assessmentreportdatagridcol4.Width = "60"

$assessmentreportdatagrid.Columns.AddRange($assessmentreportdatagridcol1,$assessmentreportdatagridcol2,$assessmentreportdatagridcol3,$assessmentreportdatagridcol4)

ForEach($psscript in $arraypsscripts)
{
    $i = 1
    do
    {
        IF($psscript.Instance -eq 1)
        {
            $assessmentreportdatagrid.Rows.Add($false,$psscript.alias,"","Browse")
        }
        ELSE
        {
            $assessmentreportdatagrid.Rows.Add($false,($psscript.alias + " $i"),"","Browse")
        }            
        $i++
    }while($i -le $psscript.Instance)
}

$assessmentreportdatagrid.add_cellclick({

    IF($_.ColumnIndex -eq 0)
    {
        IF($assessmentreportdatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $false){$assessmentreportdatagrid.Rows[$_.RowIndex].Cells[0].Value = $true}
        ELSEIF($assessmentreportdatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $true){$assessmentreportdatagrid.Rows[$_.RowIndex].Cells[0].Value = $false}
    }

    if($_.ColumnIndex -eq 3)
    {
        $xmlfile  = $assessmentreportdatagrid.Rows[$_.RowIndex].Cells[1].Value

        IF(($temp = Get-FileName -initialdirectory $OutputTextBox.Text -filetype 'XML (*.xml) | *.xml') -ne "")
        {
            $assessmentreportdatagrid.Rows[$_.RowIndex].Cells[2].Value = $temp
            $assessmentreportdatagrid.Rows[$_.RowIndex].Cells[0].Value = $true
        }
    }
})

#endregion Tab Scripts

# Button Area

$buttonPanel = New-Object Windows.Forms.Panel
$buttonPanel.Size = New-Object Drawing.Size @(300,30)
$buttonPanel.Dock = "Bottom"
$assessmentreportForm.Controls.Add($buttonPanel)

$cancelButton = New-Object Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.DialogResult = "Cancel"
$cancelButton.Top = $buttonPanel.Height - $cancelButton.Height - 5
$cancelButton.Left = $buttonPanel.Width - $cancelButton.Width - 10
$cancelButton.Anchor = "Right"
$buttonPanel.Controls.Add($cancelButton)

$runButton = New-Object Windows.Forms.Button
$runButton.Text = "Run"
$runButton.Top  = $cancelButton.Top
$runButton.Left = $cancelButton.Left - $runButton.Width - 5
$runButton.Anchor = "Right"
$buttonPanel.Controls.Add($runButton)
$runButton.Add_Click({

        $ReportXMLFiles = @{}

        For($i=0;$i -lt $assessmentreportdatagrid.RowCount;$i++)
        {
            IF(($assessmentreportdatagrid.Rows[$i].Cells[2].Value -ne "") -and ($assessmentreportdatagrid.Rows[$i].Cells[0].Value -eq $true))
            {
                $ReportXMLFiles.Add($assessmentreportdatagrid.Rows[$i].Cells[1].Value,$assessmentreportdatagrid.Rows[$i].Cells[2].Value)
            }
        }

        & $RP_Assessment -ReportXMLFiles $ReportXMLFiles -OutputPath $OutputTextBox.Text -OutputType "Excel"

        $assessmentreportForm.close()
})

# Load Form

$assessmentreportForm.CancelButton = $cancelButton
$assessmentreportForm.Add_Shown({$assessmentreportForm.Activate()})

$result = $assessmentreportForm.ShowDialog()

} # End run-assessmentreport

#endregion Functions

IF(!(Test-Path $options)){create-config -defaults}

load-configfile

#region MenuStrip

$MS_Main                   = New-Object System.Windows.Forms.MenuStrip
$fileMenu                  = New-Object System.Windows.Forms.ToolStripMenuItem
   $newMenu                = New-Object System.Windows.Forms.ToolStripMenuItem
   $openMenu               = New-Object System.Windows.Forms.ToolStripMenuItem
   $saveMenu               = New-Object System.Windows.Forms.ToolStripMenuItem
   $saveasMenu             = New-Object System.Windows.Forms.ToolStripMenuItem
   $importMenu             = New-Object System.Windows.Forms.ToolStripMenuItem
       $lcsMenu            = New-Object System.Windows.Forms.ToolStripMenuItem
       $visionMenu         = New-Object System.Windows.Forms.ToolStripMenuItem
   $exitMenu               = New-Object System.Windows.Forms.ToolStripMenuItem
$editMenu                  = New-Object System.Windows.Forms.ToolStripMenuItem
   $preferencesMenu        = New-Object System.Windows.Forms.ToolStripMenuItem
$toolsMenu                 = New-Object System.Windows.Forms.ToolStripMenuItem
    $clearcheckMenu        = New-Object System.Windows.Forms.ToolStripMenuItem
    $autoCheckMenu         = New-Object System.Windows.Forms.ToolStripMenuItem
    $autoOfflineMenu       = New-Object System.Windows.Forms.ToolStripMenuItem
    $zipMenu               = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenu                  = New-Object System.Windows.Forms.ToolStripMenuItem
   $DebugMenu              = New-Object System.Windows.Forms.ToolStripMenuItem
   $viewhelpMenu           = New-Object System.Windows.Forms.ToolStripMenuItem
   $prereqMenu             = New-Object System.Windows.Forms.ToolStripMenuItem
   $aboutMenu              = New-Object System.Windows.Forms.ToolStripMenuItem

# MS_Main

$MS_Main.Items.AddRange(@(
$fileMenu,$editMenu,$toolsMenu,$helpMenu))
$MS_Main.Location = new-object System.Drawing.Point(0, 0)
$MS_Main.Name = "MS_Main"
$MS_Main.Text = "menuStrip1"

# fileToolStripMenuItem

$fileMenu.DropDownItems.AddRange(@(
$newMenu,$openMenu,$saveMenu,$saveasMenu,$importMenu,$exitMenu))

$fileMenu.Name = "fileMenu"
$fileMenu.Text = "&File"

$newMenu.Name = "newMenu"
$newMenu.ShortcutKeys = "Control, N"
$newMenu.Text = "&New"
$newMenu.Add_Click({new-config})

$openMenu.Name = "openMenu"
$openMenu.ShortcutKeys = "Control, O"
$openMenu.Text = "&Open"
$openMenu.Add_Click({load-config})

$saveMenu.Name = "saveMenu"
$saveMenu.ShortcutKeys = "Control, S"
$saveMenu.Text = "&Save"
$saveMenu.Add_Click({save-config})

$saveasMenu.Name = "saveasMenu"
$saveasMenu.ShortcutKeys = "Control, A"
$saveasMenu.Text = "Save &As"
$saveasMenu.Add_Click({save-config -saveas})

$importMenu.DropDownItems.AddRange(@(
$lcsMenu,$visionMenu))

$importMenu.Name = "importMenu"
$importMenu.Text = "&Import"

$lcsMenu.Name = "lcsMenu"
$lcsMenu.Text = "Import LCS"
$lcsMenu.Add_Click({import-lcs})

$visionMenu.Name = "visionMenu"
$visionMenu.Text = "Import S/N from Vision"
$visionMenu.Add_Click({import-vision})

$exitMenu.Name = "exitMenu"
$exitMenu.Text = "&Exit"
$exitMenu.Add_Click({$objForm.Close()})

$editMenu.DropDownItems.AddRange(@(
$preferencesMenu))

$editMenu.Name = "editMenu"
$editMenu.Text = "&Edit"

$preferencesMenu.Name = "preferencesMenu"
$preferencesMenu.text = "Preferences"
$preferencesMenu.Add_Click({modify-config})

$toolsMenu.DropDownItems.AddRange(@(
$clearcheckMenu,$autoCheckMenu,$autoOfflineMenu,$zipMenu))

$toolsMenu.Name = "ToolsMenu"
$toolsMenu.Text = "&Tools"

$clearcheckMenu.Name = "clearcheckMenu"
$clearcheckMenu.Text = "Clear Check Boxes"
$clearcheckMenu.Add_Click({clear-checkboxes})

$autoCheckMenu.Name = "autocheckMenu"
$autoCheckMenu.Text = "Auto Check Boxes"
$autoCheckMenu.Add_Click({auto-Checkboxes})

$autoOfflineMenu.Name = "autoOfflineMenu"
$autoOfflineMenu.Text = "Auto Add Offline Files"
$autoOfflineMenu.Add_Click({auto-crgoffline})

$zipMenu.Name = "zipMenu"
$zipMenu.Text = "Zip Files"
$zipMenu.Add_Click( 
         { 
            # no go make a consolidated CRG file.
            Write-Host "******Starting CRG ZIP ******" 
            if (test-path $OutputTextBox.Text) { 
            Write-Host ("   Directory named " + $OutputTextBox.Text + " found")

            IF((Test-Path ("$OutputTextBox.text" + "\crgfiles.zip")) -eq $false)
            {
                Remove-Item ($OutputTextBox.text + "\crgfiles.zip")
            }

            SEND-ZIP ($OutputTextBox.Text + "\crgfiles.zip") $OutputTextBox.Text
            } else {Write-Host ("can not Zip, Directory named " + $OutputTextBox.Text + " was not found")}
            Write-Host "******Finished CRG ZIP ******" 
          } 
)

$helpMenu.DropDownItems.AddRange(@(
$DebugMenu,$viewhelpMenu,$prereqMenu,$aboutMenu))

$helpMenu.Name  = "helpMenu"
$helpMenu.Text  = "&Help"

$DebugMenu.Name = "DebugMenu"
$DebugMenu.text = "Debug"
$DebugMenu.Add_Click({ IF($DebugMenu.Image -eq $null) {
                                $DebugMenu.Image = $checkimage
                                $Script:Debug = $True
                               } 
                              ELSE {
                                $DebugMenu.Image = $null;
                                $Script:Debug = $false
                              } 
})
$DebugMenu.Image = $null
$Debug = $false

$viewhelpMenu.Name  = "helpMenu"
$viewhelpMenu.Text  = "View Help"
$viewhelpMenu.Add_Click({open-help})

$prereqMenu.Name = "prereqMenu"
$prereqMenu.Text = "Check PreRequisites"
$prereqMenu.Add_Click({check-prerequisites})

$aboutMenu.Name = "aboutMenu"
$aboutMenu.Text = "&About"
$aboutMenu.Add_Click({about-config})

#endregion MenuStrip

#region objForm

$objForm = New-Object System.Windows.Forms.Form
$objForm.Icon = "$ScriptPath\Bin\Icons\VCE.ico"
$objForm.Text = $objformtitle + " - Unsaved"
$objForm.Size = New-Object System.Drawing.Size(1200,768) 
$objForm.StartPosition = "CenterScreen"
$objForm.MainMenuStrip = $MS_Main
$objForm.Controls.Add($MS_Main)

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

#endregion objForm

#region Ribbon

$buttonHelp           = New-Object System.Windows.Forms.Button
$buttonHelp.Name      = "About"
$buttonHelp.location  = New-Object System.Drawing.Point(($objform.Width-40),25)
$buttonHelp.Anchor    = "Top","Right"
$buttonHelp.Size      = New-Object System.Drawing.Point(20,20)
$buttonHelp.Image     = [System.IconExtractor]::Extract("shell32.dll", 23, $false)
$buttonHelp.add_click({open-help})
$objForm.Controls.add($buttonHelp)

$tabRibbon = New-Object System.Windows.Forms.TabControl
$tabRibbon.Location = New-Object System.Drawing.Size(0,25)
$tabRibbon.Size     = New-Object System.Drawing.Size($objform.Width,80)
$tabRibbon.Anchor   = "Left,Right,Top"
$objForm.Controls.Add($tabRibbon)

#region Tab Ribbon Home

$tabRibbonHome = New-Object System.Windows.Forms.TabPage
$tabRibbonHome.UseVisualStyleBackColor = $True
$tabRibbonHome.Text = "HOME"
$tabRibbon.TabPages.Add($tabRibbonHome)

$CompanyLabel = New-Object System.Windows.Forms.Label
$CompanyLabel.Location = New-Object System.Drawing.Size(5,7) 
$CompanyLabel.Size = New-Object System.Drawing.Size(60,20) 
$CompanyLabel.Text = "Company:"
$tabRibbonHome.Controls.Add($CompanyLabel)

$CompanyTextBox = New-Object System.Windows.Forms.TextBox 
$CompanyTextBox.Location = New-Object System.Drawing.Size(85,5) 
$CompanyTextBox.Size = New-Object System.Drawing.Size(270,20) 
$tabRibbonHome.Controls.Add($CompanyTextBox)

$SystemNameLabel = New-Object System.Windows.Forms.Label
$SystemNameLabel.Location = New-Object System.Drawing.Size(360,7) 
$SystemNameLabel.Size = New-Object System.Drawing.Size(85,20) 
$SystemNameLabel.Text = "System Name:"
$tabRibbonHome.Controls.Add($SystemNameLabel)

$SystemNameTextBox = New-Object System.Windows.Forms.TextBox 
$SystemNameTextBox.Location = New-Object System.Drawing.Size(445,5) 
$SystemNameTextBox.Size = New-Object System.Drawing.Size(120,20) 
$tabRibbonHome.Controls.Add($SystemNameTextBox)

$SerialNumberLabel = New-Object System.Windows.Forms.Label
$SerialNumberLabel.Location = New-Object System.Drawing.Size(570,7) 
$SerialNumberLabel.Size = New-Object System.Drawing.Size(80,20) 
$SerialNumberLabel.Text = "System Serial:"
$tabRibbonHome.Controls.Add($SerialNumberLabel)

$SerialNumberTextBox = New-Object System.Windows.Forms.TextBox 
$SerialNumberTextBox.Location = New-Object System.Drawing.Size(650,5) 
$SerialNumberTextBox.Size = New-Object System.Drawing.Size(85,20) 
$tabRibbonHome.Controls.Add($SerialNumberTextBox)

$OutputLabel = New-Object System.Windows.Forms.Label
$OutputLabel.Location = New-Object System.Drawing.Size(5,32) 
$OutputLabel.Size = New-Object System.Drawing.Size(80,20) 
$OutputLabel.Text = "Output Folder:"
$tabRibbonHome.Controls.Add($OutputLabel)

$OutputTextBox = New-Object System.Windows.Forms.TextBox 
$OutputTextBox.Location = New-Object System.Drawing.Size(85,30) 
$OutputTextBox.Size = New-Object System.Drawing.Size(480,20)
$OutputTextBox.ReadOnly = $true
$OutputTextBox.Text = $outputpath
$tabRibbonHome.Controls.Add($OutputTextBox)

$OpenOutputButton           = New-Object System.Windows.Forms.Button
$OpenOutputButton.Name      = "OpenOutputFolder"
$OpenOutputButton.location  = New-Object System.Drawing.Point(567,30)
$OpenOutputButton.Size      = New-Object System.Drawing.Point(20,20)
$OpenOutputButton.Image     = [System.IconExtractor]::Extract("shell32.dll", 4, $true)
$OpenOutputButton.add_click({invoke-item $OutputTextBox.text})
$tabRibbonHome.Controls.add($OpenOutputButton)

$Outputbutton           = New-Object System.Windows.Forms.Button
$Outputbutton.Name      = "OutputButton"
$Outputbutton.location  = New-Object System.Drawing.Point(606,30)
$Outputbutton.size      = New-Object System.Drawing.Point(130,20)
$Outputbutton.text      = "Select Output Folder"
$Outputbutton.add_click({$outputtemp = select-folder -Directory $outputpath; IF($outputtemp -ne $null){$OutputTextBox.Text = $outputtemp}})
$tabRibbonHome.Controls.Add($Outputbutton)

$dropdownsystype = New-Object System.Windows.Forms.ComboBox
$dropdownsystype.Location = New-Object System.Drawing.Size(740,5)
$dropdownsystype.Size = New-Object System.Drawing.Size(150,22)
$tabRibbonHome.Controls.Add($dropdownsystype)
$dropdownsystype.Items.Add("System Type") | Out-Null

$excel      = New-Object OfficeOpenXml.ExcelPackage $rcm_versions
$workbook   = $excel.workbook
$worksheets = $workbook.Worksheets | Select-Object -ExpandProperty Name

ForEach($item in $worksheets | Where-Object {$_ -like "V*"}){$dropdownsystype.Items.Add($item) | Out-Null}
$dropdownsystype.SelectedIndex = 0

$excel.dispose()

$dropdownrcm = New-Object System.Windows.Forms.ComboBox
$dropdownrcm.Location = New-Object System.Drawing.Size(740,30)
$dropdownrcm.Size = New-Object System.Drawing.Size(150,22)
$tabRibbonHome.Controls.Add($dropdownrcm)
$dropdownrcm.Items.Add("RCM Version") | Out-Null
$dropdownrcm.SelectedIndex = 0

$dropdownsystype.Add_SelectedIndexChanged(
{
    $excel      = New-Object OfficeOpenXml.ExcelPackage $rcm_versions
    $workbook   = $excel.workbook 
    
    IF($dropdownsystype.SelectedItem.ToString() -ne "System Type")
    {
        IF($dropdownrcm.Items -notcontains "RCM Version"){$dropdownrcm.items.Add("RCM Version") | Out-Null}
        ForEach($item in $dropdownrcm.Items | Where-Object {$_ -ne "RCM Version"}){$dropdownrcm.Items.Remove($item)}
        $dropdownrcm.SelectedIndex = 0
        
        $worksheet = $workbook.Worksheets[$dropdownsystype.SelectedItem.ToString()]
        $intcolmax = $workbook.Worksheets[$dropdownsystype.SelectedItem.ToString()].Dimension.columns
        
        $rownumber = "1"

        $script:hashnames = @{}

        For($intcol = 2; $intcol -le $intcolmax; $intcol++)
        {
            $lookupA1 = (Convert-NumberToA1 -number $intcol) + $rownumber
            $name = $worksheet.cells[$lookupA1].value
            
            IF($name -ne "Addendum" -and $name -ne $null)
            {
                $script:hashnames.Add($name,$intcol)
                $dropdownrcm.Items.Add($name) | Out-Null
            }
        }
    }
    ELSE
    {
        $dropdownrcm.SelectedIndex = 0
    }

    $excel.dispose()
})

$dropdownrcm.Add_SelectedIndexChanged({check-versions})

$vercustRadio = New-Object System.Windows.Forms.RadioButton
$vercustRadio.Location = New-Object System.Drawing.Size(900,7) 
$vercustRadio.Size = New-Object System.Drawing.Size(80,20)
$vercustRadio.Text = "Original"
$vercustRadio.Checked = $true
$tabRibbonHome.Controls.Add($vercustRadio)

$veraddenRadio = New-Object System.Windows.Forms.RadioButton
$veraddenRadio.Location = New-Object System.Drawing.Size(900,32) 
$veraddenRadio.Size = New-Object System.Drawing.Size(80,20)
$veraddenRadio.Text = "Addendum"
$tabRibbonHome.Controls.Add($veraddenRadio)

$vercustRadio.Add_Click({IF($dropdownrcm.SelectedItem.ToString() -ne "RCM Version"){check-versions}})
$veraddenRadio.Add_Click({IF($dropdownrcm.SelectedItem.ToString() -ne "RCM Version"){check-versions}})

#endregion Tab Ribbon Home

#region Tab Ribbon CRG

$tabRibbonCRG = New-Object System.Windows.Forms.TabPage
$tabRibbonCRG.UseVisualStyleBackColor = $True
$tabRibbonCRG.Text = "CRG"
$tabRibbon.TabPages.Add($tabRibbonCRG)

$DiscoverButton           = New-Object System.Windows.Forms.Button
$DiscoverButton.Name      = "Discover"
$DiscoverButton.location  = New-Object System.Drawing.Point(2,2)
$DiscoverButton.size      = New-Object System.Drawing.Size(60,50)
$DiscoverButton.text      = "Collect XML Data"
$DiscoverButton.Font      = New-Object System.Drawing.Font("Arial",8)
$DiscoverButton.add_click(
{
    $systemserial   = $SerialNumberTextBox.text
    
    IF($Debug)
    { 
        IF(!(Test-Path "$scriptPath\Logs")){New-Item "$scriptPath\Logs" -ItemType directory | Out-Null}
        $xmldatalog = "$scriptpath\Logs\CRG_Collect_$systemserial`_$TIMESTAMP`_log.rtf"
        Start-Transcript $xmldatalog
    }

    collect-xmldata -xmlfiles both

    IF($Debug){Stop-Transcript}
})
$tabRibbonCRG.Controls.Add($DiscoverButton)

$ReportButton           = New-Object System.Windows.Forms.Button
$ReportButton.Name      = "Report"
$ReportButton.location  = New-Object System.Drawing.Point(65,2)
$ReportButton.size      = New-Object System.Drawing.Size(60,50)
$ReportButton.text      = "Generate CRG Report"
$ReportButton.Font      = New-Object System.Drawing.Font("Arial",8)
$ReportButton.add_click(
{
    $systemserial   = $SerialNumberTextBox.text
    
    IF($Debug)
    { 
        IF(!(Test-Path "$scriptPath\Logs")){New-Item "$scriptPath\Logs" -ItemType directory | Out-Null}
        $xmldatalog = "$scriptpath\Logs\CRG_Collect_$systemserial`_$TIMESTAMP`_log.rtf"
        Start-Transcript $xmldatalog
    }

    $ReportXMLFiles = collect-xmldata -xmlfiles both

    IF($Debug){Stop-Transcript}

    IF($ReportXMLFiles.count -gt 0)
    {
        create-crgreport -ReportXMLFiles $ReportXMLFiles
    }
    ELSE{write-host "Either no XML files were generated or you did not include any offline files.  Excel report not created" -ForegroundColor Yellow}
})
$tabRibbonCRG.Controls.Add($ReportButton)

$credentialscheckbox          = New-Object System.Windows.Forms.CheckBox
$credentialscheckbox.Name     = "credentialscheckbox"
$credentialscheckbox.location = New-Object System.Drawing.Size(130,0)
$credentialscheckbox.size     = New-Object System.Drawing.Size(120,20)
$credentialscheckbox.text     = "Include Credentials"
$tabRibbonCRG.Controls.Add($credentialscheckbox)

$portmapcheckbox          = New-Object System.Windows.Forms.CheckBox
$portmapcheckbox.Name     = "portmapcheckbox"
$portmapcheckbox.location = New-Object System.Drawing.Size(130,18)
$portmapcheckbox.size     = New-Object System.Drawing.Size(120,20)
$portmapcheckbox.text     = "Include PortMaps"
$tabRibbonCRG.Controls.Add($portmapcheckbox)

$Assessmentcheckbox          = New-Object System.Windows.Forms.CheckBox
$Assessmentcheckbox.Name     = "Assessmentcheckbox"
$Assessmentcheckbox.location = New-Object System.Drawing.Size(130,36)
$Assessmentcheckbox.size     = New-Object System.Drawing.Size(124,20)
$Assessmentcheckbox.text     = "Include Assessment"
$tabRibbonCRG.Controls.Add($Assessmentcheckbox)

$regionlabel  = New-Object System.Windows.Forms.Label
$regionlabel.Location = New-Object System.Drawing.Size(255,5)
$regionlabel.size = New-Object System.Drawing.Size(80,20)
$regionlabel.Text = "Password List:"
$tabRibbonCRG.Controls.Add($regionlabel)

$regiondropdown = New-Object System.Windows.Forms.ComboBox
$regiondropdown.Location = New-Object System.Drawing.Size(255,27)
$regiondropdown.Size = New-Object System.Drawing.Size(80,20)
$tabRibbonCRG.Controls.Add($regiondropdown)
ForEach ($item in $modifyregions){$regiondropdown.Items.Add($item) | Out-Null }
$regiondropdown.SelectedItem = $region
$regiondropdown.Add_SelectedIndexChanged({$script:region = $regiondropdown.SelectedItem.ToString();load-passwords -region $region})

$AutoOnlineCheckButton           = New-Object System.Windows.Forms.Button
$AutoOnlineCheckButton.Name      = "AutoCheck"
$AutoOnlineCheckButton.location  = New-Object System.Drawing.Point(345,2)
$AutoOnlineCheckButton.size      = New-Object System.Drawing.Size(120,16)
$AutoOnlineCheckButton.text      = "Auto Check Online"
$AutoOnlineCheckButton.Font      = New-Object System.Drawing.Font("Arial",8)
$AutoOnlineCheckButton.add_click({auto-Checkboxes -checkwhat "Online"})
$tabRibbonCRG.Controls.Add($AutoOnlineCheckButton)

$AutoOfflineCheckButton           = New-Object System.Windows.Forms.Button
$AutoOfflineCheckButton.Name      = "AutoCheck"
$AutoOfflineCheckButton.location  = New-Object System.Drawing.Point(345,19)
$AutoOfflineCheckButton.size      = New-Object System.Drawing.Size(120,16)
$AutoOfflineCheckButton.text      = "Auto Check Offline"
$AutoOfflineCheckButton.Font      = New-Object System.Drawing.Font("Arial",8)
$AutoOfflineCheckButton.add_click({auto-Checkboxes -checkwhat "Offline"})
$tabRibbonCRG.Controls.Add($AutoOfflineCheckButton)

$AutoBothCheckButton           = New-Object System.Windows.Forms.Button
$AutoBothCheckButton.Name      = "AutoCheck"
$AutoBothCheckButton.location  = New-Object System.Drawing.Point(345,36)
$AutoBothCheckButton.size      = New-Object System.Drawing.Size(120,16)
$AutoBothCheckButton.text      = "Auto Check Both"
$AutoBothCheckButton.Font      = New-Object System.Drawing.Font("Arial",8)
$AutoBothCheckButton.add_click({auto-Checkboxes -checkwhat "Both"})
$tabRibbonCRG.Controls.Add($AutoBothCheckButton)

$ClearCheckButton           = New-Object System.Windows.Forms.Button
$ClearCheckButton.Name      = "ClearCheck"
$ClearCheckButton.location  = New-Object System.Drawing.Point(469,2)
$ClearCheckButton.size      = New-Object System.Drawing.Size(60,50)
$ClearCheckButton.text      = "Clear Check Boxes"
$ClearCheckButton.Font      = New-Object System.Drawing.Font("Arial",8)
$ClearCheckButton.add_click({clear-checkboxes})
$tabRibbonCRG.Controls.Add($ClearCheckButton)

$AutoAddOfflineButton           = New-Object System.Windows.Forms.Button
$AutoAddOfflineButton.Name      = "AutoAddOffline"
$AutoAddOfflineButton.location  = New-Object System.Drawing.Point(531,2)
$AutoAddOfflineButton.size      = New-Object System.Drawing.Size(60,50)
$AutoAddOfflineButton.text      = "Auto Add Offline Files"
$AutoAddOfflineButton.Font      = New-Object System.Drawing.Font("Arial",8)
$AutoAddOfflineButton.add_click({auto-crgoffline})
$tabRibbonCRG.Controls.Add($AutoAddOfflineButton)

$ZipFilesButton           = New-Object System.Windows.Forms.Button
$ZipFilesButton.Name      = "ZipFiles"
$ZipFilesButton.location  = New-Object System.Drawing.Point(593,2)
$ZipFilesButton.size      = New-Object System.Drawing.Size(60,50)
$ZipFilesButton.text      = "Zip CRG Files"
$ZipFilesButton.Font      = New-Object System.Drawing.Font("Arial",8)
$ZipFilesButton.add_click( 
         { 
            # no go make a consolidated CRG file.
            Write-Host "******Starting CRG ZIP ******" 
            if (test-path $OutputTextBox.Text) { 
            Write-Host ("   Directory named " + $OutputTextBox.Text + " found")

            IF((Test-Path ("$OutputTextBox.text" + "\crgfiles.zip")) -eq $false)
            {
                Remove-Item ($OutputTextBox.text + "\crgfiles.zip")
            }

            SEND-ZIP ($OutputTextBox.Text + "\crgfiles.zip") $OutputTextBox.Text
            } else {Write-Host ("can not Zip, Directory named " + $OutputTextBox.Text + " was not found")}
            Write-Host "******Finished CRG ZIP ******" 
          } 
)
$tabRibbonCRG.Controls.Add($ZipFilesButton)

#endregion Tab Ribbon CRG

#region Tab Ribbon VMware

$tabRibbonVMware = New-Object System.Windows.Forms.TabPage
$tabRibbonVMware.UseVisualStyleBackColor = $True
$tabRibbonVMware.Text = "VMWARE"
$tabRibbon.TabPages.Add($tabRibbonVMware)

$filterDropDownArray   = "All","Datacenter","Cluster","VMHost"
$modifierDropDownArray = "Equals","NotEquals","Like","NotLike"
$vcenterDropDownArray  = "vCenter 1","vCenter 2","vCenter 3","vCenter 4","vCenter 5"

$selectvCenterDropDown = New-Object System.Windows.Forms.ComboBox
$selectvCenterDropDown.Location = New-Object System.Drawing.Point(2,5)
$selectvCenterDropDown.Size     = New-Object System.Drawing.Size(77,20)
$tabRibbonVMware.Controls.Add($selectvCenterDropDown)
ForEach($item in $vcenterDropDownArray){$selectvCenterDropDown.items.Add($item) | Out-Null}
$selectvCenterDropDown.SelectedIndex = 0

$esxiuserLabel = New-Object System.Windows.Forms.Label
$esxiuserLabel.Location = New-Object System.Drawing.Size(81,8) 
$esxiuserLabel.Size     = New-Object System.Drawing.Size(80,20) 
$esxiuserLabel.Text     = "ESXi Creds"
$esxiuserLabel.Font     = New-Object System.Drawing.Font("Arial",8)
$tabRibbonVMware.Controls.Add($esxiuserLabel)

$esxiuserTextBox = New-Object System.Windows.Forms.TextBox 
$esxiuserTextBox.Location = New-Object System.Drawing.Size(162,5) 
$esxiuserTextBox.Size     = New-Object System.Drawing.Size(90,20)
$esxiuserTextBox.Text     = "root"
$esxiuserTextBox.Font     = New-Object System.Drawing.Font("Arial",8)
$tabRibbonVMware.Controls.Add($esxiuserTextBox)

$esxiPassTextBox = New-Object System.Windows.Forms.TextBox 
$esxiPassTextBox.Location = New-Object System.Drawing.Size(254,5) 
$esxiPassTextBox.Size     = New-Object System.Drawing.Size(104,20)
$esxiPassTextBox.UseSystemPasswordChar = $True
$esxiPassTextBox.Text     = $regions.item($region)
$esxiPassTextBox.Font     = New-Object System.Drawing.Font("Arial",8)
$tabRibbonVMware.Controls.Add($esxiPassTextBox)

$filterDropDown = New-Object System.Windows.Forms.ComboBox
$filterDropDown.Location = New-Object System.Drawing.Size(2,30)
$filterDropDown.Size     = New-Object System.Drawing.Size(77,20)
$tabRibbonVMware.Controls.Add($filterDropDown)
ForEach($item in $filterDropDownArray){$filterDropDown.Items.Add($item) | Out-Null}
$filterDropDown.SelectedIndex = 0

$ModifyDropDown = New-Object System.Windows.Forms.ComboBox
$ModifyDropDown.Location = New-Object System.Drawing.Size(80,30)
$ModifyDropDown.Size = New-Object System.Drawing.Size(80,20)
$tabRibbonVMware.Controls.Add($ModifyDropDown)
ForEach ($item in $modifierDropDownArray){ $ModifyDropDown.Items.Add($item) | Out-Null}
$ModifyDropDown.SelectedIndex = 0

$filterDropDownTextBox = New-Object System.Windows.Forms.TextBox
$filterDropDownTextBox.Location = New-Object System.Drawing.Point(162,31)
$filterDropDownTextBox.Size = New-Object System.Drawing.Point(195,20)
$tabRibbonVMware.controls.Add($filterDropDownTextBox)

$VMDNSCheckbox = New-Object System.Windows.Forms.CheckBox
$VMDNSCheckbox.Location = New-Object System.Drawing.Point(364,0)
$VMDNSCheckbox.Size     = New-Object System.Drawing.Size(50,20)
$VMDNSCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMDNSCheckbox.Text     = "DNS"
$tabRibbonVMware.Controls.Add($VMDNSCheckbox)

$VMNTPCheckbox = New-Object System.Windows.Forms.CheckBox
$VMNTPCheckbox.Location = New-Object System.Drawing.Point(364,17)
$VMNTPCheckbox.Size     = New-Object System.Drawing.Size(50,20)
$VMNTPCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMNTPCheckbox.Text     = "NTP"
$tabRibbonVMware.Controls.Add($VMNTPCheckbox)

$VMSNMPCheckbox = New-Object System.Windows.Forms.CheckBox
$VMSNMPCheckbox.Location = New-Object System.Drawing.Point(364,34)
$VMSNMPCheckbox.Size     = New-Object System.Drawing.Size(56,20)
$VMSNMPCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMSNMPCheckbox.Text     = "SNMP"
$tabRibbonVMware.Controls.Add($VMSNMPCheckbox)

$VMSyslogCheckbox = New-Object System.Windows.Forms.CheckBox
$VMSyslogCheckbox.Location = New-Object System.Drawing.Point(422,0)
$VMSyslogCheckbox.Size     = New-Object System.Drawing.Size(72,20)
$VMSyslogCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMSyslogCheckbox.Text     = "Syslog"
$tabRibbonVMware.Controls.Add($VMSyslogCheckbox)

$VMFirewallCheckbox = New-Object System.Windows.Forms.CheckBox
$VMFirewallCheckbox.Location = New-Object System.Drawing.Point(422,17)
$VMFirewallCheckbox.Size     = New-Object System.Drawing.Size(72,20)
$VMFirewallCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMFirewallCheckbox.Text     = "Firewall"
$tabRibbonVMware.Controls.Add($VMFirewallCheckbox)

$VMAdvancedCheckbox = New-Object System.Windows.Forms.CheckBox
$VMAdvancedCheckbox.Location = New-Object System.Drawing.Point(422,34)
$VMAdvancedCheckbox.Size     = New-Object System.Drawing.Size(72,20)
$VMAdvancedCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMAdvancedCheckbox.Text     = "Advanced"
$tabRibbonVMware.Controls.Add($VMAdvancedCheckbox)

$VMDomainCheckbox = New-Object System.Windows.Forms.CheckBox
$VMDomainCheckbox.Location = New-Object System.Drawing.Point(497,0)
$VMDomainCheckbox.Size     = New-Object System.Drawing.Size(62,20)
$VMDomainCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMDomainCheckbox.Text     = "Domain"
$tabRibbonVMware.Controls.Add($VMDomainCheckbox)

$VMMOBCheckbox = New-Object System.Windows.Forms.CheckBox
$VMMOBCheckbox.Location = New-Object System.Drawing.Point(497,17)
$VMMOBCheckbox.Size     = New-Object System.Drawing.Size(62,20)
$VMMOBCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMMOBCheckbox.Text     = "MOB"
$tabRibbonVMware.Controls.Add($VMMOBCheckbox)

$VMVPLEXCheckbox = New-Object System.Windows.Forms.CheckBox
$VMVPLEXCheckbox.Location = New-Object System.Drawing.Point(497,34)
$VMVPLEXCheckbox.Size     = New-Object System.Drawing.Size(62,20)
$VMVPLEXCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMVPLEXCheckbox.Text     = "VPLEX"
$tabRibbonVMware.Controls.Add($VMVPLEXCheckbox)

$VMCoreDumpCheckbox = New-Object System.Windows.Forms.CheckBox
$VMCoreDumpCheckbox.Location = New-Object System.Drawing.Point(562,0)
$VMCoreDumpCheckbox.Size     = New-Object System.Drawing.Size(82,20)
$VMCoreDumpCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMCoreDumpCheckbox.Text     = "Core Dump"
$tabRibbonVMware.Controls.Add($VMCoreDumpCheckbox)

$VMNetworkingCheckbox = New-Object System.Windows.Forms.CheckBox
$VMNetworkingCheckbox.Location = New-Object System.Drawing.Point(562,17)
$VMNetworkingCheckbox.Size     = New-Object System.Drawing.Size(82,20)
$VMNetworkingCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMNetworkingCheckbox.Text     = "Networking"
$tabRibbonVMware.Controls.Add($VMNetworkingCheckbox)

$VMScratchSpaceCheckbox = New-Object System.Windows.Forms.CheckBox
$VMScratchSpaceCheckbox.Location = New-Object System.Drawing.Point(562,36)
$VMScratchSpaceCheckbox.Size     = New-Object System.Drawing.Size(94,18)
$VMScratchSpaceCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMScratchSpaceCheckbox.Text     = "Scratch Space"
$tabRibbonVMware.Controls.Add($VMScratchSpaceCheckbox)

$VMATSLockCheckbox = New-Object System.Windows.Forms.CheckBox
$VMATSLockCheckbox.Location = New-Object System.Drawing.Point(662,0)
$VMATSLockCheckbox.Size     = New-Object System.Drawing.Size(80,18)
$VMATSLockCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMATSLockCheckbox.Text     = "ATS Lock"
$tabRibbonVMware.Controls.Add($VMATSLockCheckbox)

$VMVersionCheckbox = New-Object System.Windows.Forms.CheckBox
$VMVersionCheckbox.Location = New-Object System.Drawing.Point(662,17)
$VMVersionCheckbox.Size     = New-Object System.Drawing.Size(80,20)
$VMVersionCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMVersionCheckbox.Text     = "Version"
$tabRibbonVMware.Controls.Add($VMVersionCheckbox)

$VMRDMCheckbox = New-Object System.Windows.Forms.CheckBox
$VMRDMCheckbox.Location = New-Object System.Drawing.Point(662,36)
$VMRDMCheckbox.Size     = New-Object System.Drawing.Size(80,20)
$VMRDMCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMRDMCheckbox.Text     = "RDM"
$tabRibbonVMware.Controls.Add($VMRDMCheckbox)

$VMSMARTDCheckbox = New-Object System.Windows.Forms.CheckBox
$VMSMARTDCheckbox.Location = New-Object System.Drawing.Point(742,7)
$VMSMARTDCheckbox.Size     = New-Object System.Drawing.Size(64,18)
$VMSMARTDCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMSMARTDCheckbox.Text     = "SMARTD"
$tabRibbonVMware.Controls.Add($VMSMARTDCheckbox)

$VMSMARTDDownArray = "Enable","Disable","Restart"

$VMSMARTDDropDown = New-Object System.Windows.Forms.ComboBox
$VMSMARTDDropDown.Location = New-Object System.Drawing.Point(812,5)
$VMSMARTDDropDown.Size     = New-Object System.Drawing.Size(70,6)
$tabRibbonVMware.Controls.Add($VMSMARTDDropDown)
ForEach ($item in $VMSMARTDDownArray){$VMSMARTDDropDown.Items.Add($item) | Out-Null}
$VMSMARTDDropDown.SelectedIndex = 0

$VMXtremIOCheckbox = New-Object System.Windows.Forms.CheckBox
$VMXtremIOCheckbox.Location = New-Object System.Drawing.Point(892,7)
$VMXtremIOCheckbox.Size     = New-Object System.Drawing.Size(64,18)
$VMXtremIOCheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMXtremIOCheckbox.Text     = "XtremIO"
$tabRibbonVMware.Controls.Add($VMXtremIOCheckbox)

$VMXtremIODownArray = "XtremIO","VNX","VMAX","Multi-Array","VPLEX"

$VMXtremIODropDown = New-Object System.Windows.Forms.ComboBox
$VMXtremIODropDown.Location = New-Object System.Drawing.Point(962,5)
$VMXtremIODropDown.Size     = New-Object System.Drawing.Size(70,6)
$tabRibbonVMware.Controls.Add($VMXtremIODropDown)
ForEach ($item in $VMXtremIODownArray){$VMXtremIODropDown.Items.Add($item) | Out-Null}
$VMXtremIODropDown.SelectedIndex = 0

$VMVAAICheckbox = New-Object System.Windows.Forms.CheckBox
$VMVAAICheckbox.Location = New-Object System.Drawing.Point(892,32)
$VMVAAICheckbox.Size     = New-Object System.Drawing.Size(50,20)
$VMVAAICheckbox.Font     = New-Object System.Drawing.Font("Arial",8)
$VMVAAICheckbox.Text     = "VAAI"
$tabRibbonVMware.Controls.Add($VMVAAICheckbox)

$VMvaaiDownArray = "Disable","Enable"

$VMvaaiDropDown = New-Object System.Windows.Forms.ComboBox
$VMvaaiDropDown.Location = New-Object System.Drawing.Point(962,30)
$VMvaaiDropDown.Size     = New-Object System.Drawing.Size(70,6)
$tabRibbonVMware.Controls.Add($VMvaaiDropDown)
ForEach ($item in $VMvaaiDownArray){$VMvaaiDropDown.Items.Add($item) | Out-Null}
$VMvaaiDropDown.SelectedIndex = 0

$VMStartSSHButton = New-Object System.Windows.Forms.Button
$VMStartSSHButton.Location = New-Object System.Drawing.Point(1035,5)
$VMStartSSHButton.Size     = New-Object System.Drawing.Size(62,20)
$VMStartSSHButton.Font     = New-Object System.Drawing.Font("Arial",8)
$VMStartSSHButton.Text     = "Start SSH"
$tabRibbonVMware.Controls.Add($VMStartSSHButton)
$VMStartSSHButton.add_click({$connected = connect-vcenter; IF($connected){get-filterhosts | set-vmssh -start}})

$VMStopSSHButton = New-Object System.Windows.Forms.Button
$VMStopSSHButton.Location = New-Object System.Drawing.Point(1035,30)
$VMStopSSHButton.Size     = New-Object System.Drawing.Size(62,20)
$VMStopSSHButton.Font     = New-Object System.Drawing.Font("Arial",8)
$VMStopSSHButton.Text     = "Stop SSH"
$tabRibbonVMware.Controls.Add($VMStopSSHButton)
$VMStopSSHButton.add_click({$connected = connect-vcenter; IF($connected){get-filterhosts | set-vmssh -stop}})

$VMConfigButton = New-Object System.Windows.Forms.Button
$VMConfigButton.Location = New-Object System.Drawing.Point(1100,5)
$VMConfigButton.Size     = New-Object System.Drawing.Size(50,20)
$VMConfigButton.Font     = New-Object System.Drawing.Font("Arial",8)
$VMConfigButton.Text     = "Config"
$tabRibbonVMware.Controls.Add($VMConfigButton)
$VMConfigButton.Add_Click(
        {
            $configyes = [System.Windows.Forms.MessageBox]::Show("Configure ESXi as per the settings tab and LBG?" , "vSphere Config" , 4)
            IF($configyes -eq "YES"){set-vmhosts}ELSE{write-host "vSphere Config cancelled"}
        })

$VMCheckButton = New-Object System.Windows.Forms.Button
$VMCheckButton.Location = New-Object System.Drawing.Point(1100,30)
$VMCheckButton.Size     = New-Object System.Drawing.Size(50,20)
$VMCheckButton.Font     = New-Object System.Drawing.Font("Arial",8)
$VMCheckButton.Text     = "Check"
$tabRibbonVMware.Controls.Add($VMCheckButton)
$VMCheckButton.Add_Click({check-config})

#endregion Tab Ribbon VMware

#region Tab Ribbon Network

$tabRibbonNetwork = New-Object System.Windows.Forms.TabPage
$tabRibbonNetwork.UseVisualStyleBackColor = $True
$tabRibbonNetwork.Text = "NETWORK"
$tabRibbon.TabPages.Add($tabRibbonNetwork)

$portmapbutton = New-object System.Windows.Forms.Button
$portmapbutton.Name = "Portmap Button"
$portmapbutton.location = New-Object System.Drawing.Point(2,5)
$portmapbutton.size = New-Object System.Drawing.Point(120,20)
$portmapbutton.text = "Create PortMaps"
$portmapbutton.add_click({run-portmap})
$tabribbonNetwork.Controls.Add($portmapbutton)

$techsupportbutton = New-object System.Windows.Forms.Button
$techsupportbutton.Name = "TechSupport Button"
$techsupportbutton.location = New-Object System.Drawing.Point(2,30)
$techsupportbutton.size = New-Object System.Drawing.Point(120,20)
$techsupportbutton.text = "Create Tech-Support"
$techsupportbutton.add_click({run-techsupport})
$tabribbonNetwork.Controls.Add($techsupportbutton)

#endregion Tab Ribbon Network

#endregion Ribbon

#region StatusBar

$statusStrip = new-object System.Windows.Forms.StatusStrip
$statusStrip.SizingGrip = $false

$status = new-object System.Windows.Forms.ToolStripStatusLabel
$Status.Text = ""

[void]$statusStrip.Items.add($status)

$objForm.Controls.Add($statusStrip)

#endregion StatusBar

#region Menu

$MenuPanel = New-Object System.Windows.Forms.Panel
$MenuPanel.Size = New-Object System.Drawing.Size(100,($objForm.Height - $tabribbon.height - 65))
$MenuPanel.BorderStyle = "Fixed3D"
$MenuPanel.Top = $tabRibbon.Height
$MenuPanel.Anchor = "Left,Top,Bottom"
$objForm.Controls.Add($MenuPanel)

$CRGbutton   		    = New-Object System.Windows.Forms.Button
$CRGbutton.Name         = "CRGbutton"
$CRGbutton.text         = "Components"
$CRGbutton.size         = New-Object System.Drawing.Point(95,22)
$CRGButton.Location     = New-Object System.Drawing.Size(0,($MenuPanel.Height - ($CRGButton.Height*6) - 5)) 
$CRGbutton.left         = 2
$CRGbutton.Anchor       = "Left,Bottom"
$CRGbutton.add_click({visible-panel -Panel $PanelCRG})
$MenuPanel.Controls.Add($CRGbutton)

$settingsbutton          = New-Object System.Windows.Forms.Button
$settingsbutton.Name     = "Settingsbutton"
$settingsbutton.Text     = "Settings"
$settingsbutton.size     = New-Object System.Drawing.Point(95,22)
$settingsbutton.Location = New-Object System.Drawing.Size(0,($MenuPanel.Height - ($CRGButton.Height*5) - 5))
$settingsbutton.left     = 2
$settingsbutton.Anchor   = "Left,Bottom"
$settingsbutton.add_click({visible-panel -Panel $PanelSettings})
$MenuPanel.Controls.Add($settingsbutton)

$credentialsbutton          = New-Object System.Windows.Forms.Button
$credentialsbutton.Name     = "credentialsbutton"
$credentialsbutton.Text     = "Credentials"
$credentialsbutton.size     = New-Object System.Drawing.Point(95,22)
$credentialsbutton.Location = New-Object System.Drawing.Size(0,($MenuPanel.Height - ($CRGButton.Height*4) - 5)) 
$credentialsbutton.left     = 2
$credentialsbutton.Anchor   = "Left,Bottom"
$credentialsbutton.add_click({visible-panel -Panel $PanelCredentials})
$MenuPanel.Controls.Add($credentialsbutton)

$versionbutton          = New-Object System.Windows.Forms.Button
$versionbutton.Name     = "versionbutton"
$versionbutton.Text     = "Version"
$versionbutton.size     = New-Object System.Drawing.Point(95,22)
$versionbutton.Location = New-Object System.Drawing.Size(0,($MenuPanel.Height - ($CRGButton.Height*3) - 5)) 
$versionbutton.left     = 2
$versionbutton.Anchor   = "Left,Bottom"
$versionbutton.add_click({visible-panel -Panel $PanelVersion})
$MenuPanel.Controls.Add($versionbutton)

$reportbutton          = New-Object System.Windows.Forms.Button
$reportbutton.Name     = "reportbutton"
$reportbutton.Text     = "Reports"
$reportbutton.size     = New-Object System.Drawing.Point(95,22)
$reportbutton.Location = New-Object System.Drawing.Size(0,($MenuPanel.Height - ($CRGButton.Height*2) - 5))
$reportbutton.left     = 2
$reportbutton.Anchor   = "Left,Bottom"
$reportbutton.add_click({visible-panel -Panel $PanelReport})
$MenuPanel.Controls.Add($reportbutton)

$assessmentbutton          = New-Object System.Windows.Forms.Button
$assessmentbutton.Name     = "assessmentbutton"
$assessmentbutton.Text     = "Assessment"
$assessmentbutton.size     = New-Object System.Drawing.Point(95,22)
$assessmentbutton.Location = New-Object System.Drawing.Size(0,($MenuPanel.Height - ($CRGButton.Height*1) - 5))
$assessmentbutton.left     = 2
$assessmentbutton.Anchor   = "Left,Bottom"
$assessmentbutton.add_click({visible-panel -Panel $Panelassessment})
$MenuPanel.Controls.Add($assessmentbutton)

#endregion Menu

#region Panels

$MainPanelLocation = "100",($tabRibbon.Height + 20)
$MainPanelWidth  = ($objForm.Width - $MenuPanel.Width - 20)
$MainPanelHeight = ($objform.Height - $tabRibbon.Height - $statusStrip.Height - 60)

$MainPanelTabHeight = $MainPanelHeight - 30

$MainPanelSize = $MainPanelWidth,$MainPanelHeight

#region CRG

$PanelCRG = New-Object System.Windows.Forms.Panel
$PanelCRG.Location = New-Object System.Drawing.Point($MainPanelLocation)
$PanelCRG.Size = New-Object System.Drawing.Size($MainPanelSize)
$PanelCRG.Anchor = "Right,Left,Top,Bottom"
$PanelCRG.Visible = $true
$objForm.Controls.Add($PanelCRG)

$tabctrlCRG = New-Object System.Windows.Forms.TabControl
$tabctrlCRG.Location = New-Object System.Drawing.Size(2,30)
$tabctrlCRG.Size     = New-Object System.Drawing.Size($MainPanelWidth,$MainPanelTabHeight)
$tabctrlCRG.Anchor   = "Right,Left,Top,Bottom"
$PanelCRG.Controls.Add($tabctrlCRG)

#region tabCRGCompute

$tabxstart = 125
$tabystart = 10
$tabxsize  = 90
$tabysize  = 20
$labelxSize = 100
$textboxxSize = 160

IF($region -eq "Standard"){$ucspassword = "vBl0ck01!"}ELSE{$ucspassword = $regions.item($region)}

$ReportingLabel = New-Object System.Windows.Forms.Label
$ReportingLabel.Location = New-Object System.Drawing.Size(5,5) 
$ReportingLabel.Size = New-Object System.Drawing.Size(170,20) 
$ReportingLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",12,1,3,1)
$ReportingLabel.Text = "CRG Reporting Tool"
$PanelCRG.Controls.Add($ReportingLabel)

$tabCRGOnlineCompute = New-Object System.Windows.Forms.TabPage
$tabCRGOnlineCompute.UseVisualStyleBackColor = $True
$tabCRGOnlineCompute.Text = "Compute"
$tabctrlCRG.TabPages.Add($tabCRGOnlineCompute)

$tabComputeUserLabel = New-Object System.Windows.Forms.Label
$tabComputeUserLabel.Location = New-Object System.Drawing.Size($tabxstart,$tabystart) 
$tabComputeUserLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabComputeUserLabel.Text = "Username"
$tabCRGOnlineCompute.Controls.Add($tabComputeUserLabel)

$tabComputePassLabel = New-Object System.Windows.Forms.Label
$tabComputePassLabel.Location = New-Object System.Drawing.Size(($tabxstart +145),$tabystart)
$tabComputePassLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabComputePassLabel.Text = "Password"
$tabCRGOnlineCompute.Controls.Add($tabComputePassLabel)

$tabComputeIP1Label = New-Object System.Windows.Forms.Label
$tabComputeIP1Label.Location = New-Object System.Drawing.Size(($tabxstart +290),$tabystart) 
$tabComputeIP1Label.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabComputeIP1Label.Text = "IP Address 1"
$tabCRGOnlineCompute.Controls.Add($tabComputeIP1Label)

$tabComputeIP2Label = New-Object System.Windows.Forms.Label
$tabComputeIP2Label.Location = New-Object System.Drawing.Size(($tabxstart +385),$tabystart)
$tabComputeIP2Label.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabComputeIP2Label.Text = "IP Address 2"
$tabCRGOnlineCompute.Controls.Add($tabComputeIP2Label)

$tabComputeOptionLabel = New-Object System.Windows.Forms.Label
$tabComputeOptionLabel.Location = New-Object System.Drawing.Size(($tabxstart+480),$tabystart) 
$tabComputeOptionLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabComputeOptionLabel.Text = "Option"
$tabCRGOnlineCompute.Controls.Add($tabComputeOptionLabel)

$tabComputeDefaultCredLabel = New-Object System.Windows.Forms.Label
$tabComputeDefaultCredLabel.Location = New-Object System.Drawing.Size(($tabxstart+600),$tabystart) 
$tabComputeDefaultCredLabel.Size = New-Object System.Drawing.Size(($tabxsize+30),$tabysize) 
$tabComputeDefaultCredLabel.Text = "Default Credentials"
$tabCRGOnlineCompute.Controls.Add($tabComputeDefaultCredLabel)

$C2XXCheckBox = New-Object System.Windows.Forms.CheckBox
$C2XXCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +22)) 
$C2XXCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$C2XXCheckBox.Text = "C2XX"
$tabCRGOnlineCompute.Controls.Add($C2XXCheckBox)

$C2XXuserTextBox = New-Object System.Windows.Forms.TextBox 
$C2XXuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +20))
$C2XXuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$C2XXuserTextBox.Text = "admin"
$C2XXuserTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($C2XXuserTextBox)

$C2XXpassTextBox = New-Object System.Windows.Forms.TextBox 
$C2XXpassTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +20)) 
$C2XXpassTextBox.Size = New-Object System.Drawing.Size(140,20)
$C2XXpassTextBox.Text = $regions.item($region)
$C2XXpassTextBox.UseSystemPasswordChar = $True
$C2XXpassTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($C2XXpassTextBox)

$C2XXIP1TextBox = New-Object System.Windows.Forms.TextBox 
$C2XXIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +20))
$C2XXIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineCompute.Controls.Add($C2XXIP1TextBox)

$C2XXIP2TextBox = New-Object System.Windows.Forms.TextBox 
$C2XXIP2TextBox.Location = New-Object System.Drawing.Size(505,($tabystart +20)) 
$C2XXIP2TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineCompute.Controls.Add($C2XXIP2TextBox)

$C2XXRangeCheckBox = New-Object System.Windows.Forms.CheckBox
$C2XXRangeCheckBox.Location = New-Object System.Drawing.Size(605,($tabystart +22))
$C2XXRangeCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$C2XXRangeCheckBox.Text = "Range?"
$tabCRGOnlineCompute.Controls.Add($C2XXRangeCheckBox)

$C2XXDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$C2XXDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +20))
$C2XXDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$C2XXDefaultCheckBox.Checked = $True
$tabCRGOnlineCompute.Controls.Add($C2XXDefaultCheckBox)

$C2XXDefaultCheckBox.Add_CheckStateChanged({
    IF($C2XXDefaultCheckBox.checked)
    {
        $C2XXuserTextBox.Text = "admin"
        $C2XXuserTextBox.ReadOnly = $true
        $C2XXpassTextBox.Text = $regions.item($region)
        $C2XXpassTextBox.ReadOnly = $true
    }
    IF(!$C2XXDefaultCheckBox.checked)
    {
        $C2XXuserTextBox.ReadOnly = $false
        $C2XXpassTextBox.ReadOnly = $false
    }
})

$UCS1CheckBox = New-Object System.Windows.Forms.CheckBox
$UCS1CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +52)) 
$UCS1CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$UCS1CheckBox.Text = "UCS Domain 1"
$tabCRGOnlineCompute.Controls.Add($UCS1CheckBox)

$UCS1userTextBox = New-Object System.Windows.Forms.TextBox 
$UCS1userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +50))
$UCS1userTextBox.Size = New-Object System.Drawing.Size(140,20)
$UCS1userTextBox.Text = "admin"
$UCS1userTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($UCS1userTextBox)

$UCS1passTextBox = New-Object System.Windows.Forms.TextBox 
$UCS1passTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +50)) 
$UCS1passTextBox.Size = New-Object System.Drawing.Size(140,20)
$UCS1passTextBox.Text = $ucspassword
$UCS1passTextBox.UseSystemPasswordChar = $True
$UCS1passTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($UCS1passTextBox)

$UCS1IP1TextBox = New-Object System.Windows.Forms.TextBox 
$UCS1IP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +50))
$UCS1IP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineCompute.Controls.Add($UCS1IP1TextBox)

$UCS1DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$UCS1DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart+50))
$UCS1DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$UCS1DefaultCheckBox.Checked = $True
$tabCRGOnlineCompute.Controls.Add($UCS1DefaultCheckBox)

$UCS1DefaultCheckBox.Add_CheckStateChanged({
    IF($UCS1DefaultCheckBox.checked)
    {
        $UCS1userTextBox.Text = "admin"
        $UCS1userTextBox.ReadOnly = $true
        IF($region -eq "Standard"){$ucspassword = "vBl0ck01!"}ELSE{$ucspassword = $regions.item($region)}
        $UCS1passTextBox.Text = $ucspassword
        $UCS1passTextBox.ReadOnly = $true
    }
    IF(!$UCS1DefaultCheckBox.checked)
    {
        $UCS1userTextBox.ReadOnly = $false
        $UCS1passTextBox.ReadOnly = $false
    }
})

$UCS2CheckBox = New-Object System.Windows.Forms.CheckBox
$UCS2CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +82)) 
$UCS2CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$UCS2CheckBox.Text = "UCS Domain 2"
$tabCRGOnlineCompute.Controls.Add($UCS2CheckBox)

$UCS2userTextBox = New-Object System.Windows.Forms.TextBox 
$UCS2userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +80))
$UCS2userTextBox.Size = New-Object System.Drawing.Size(140,20)
$UCS2userTextBox.Text = "admin"
$UCS2userTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($UCS2userTextBox)

$UCS2passTextBox = New-Object System.Windows.Forms.TextBox 
$UCS2passTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +80)) 
$UCS2passTextBox.Size = New-Object System.Drawing.Size(140,20)
$UCS2passTextBox.Text = $ucspassword
$UCS2passTextBox.UseSystemPasswordChar = $True
$UCS2passTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($UCS2passTextBox)

$UCS2IP1TextBox = New-Object System.Windows.Forms.TextBox 
$UCS2IP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +80))
$UCS2IP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineCompute.Controls.Add($UCS2IP1TextBox)

$UCS2DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$UCS2DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart+80))
$UCS2DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$UCS2DefaultCheckBox.Checked = $True
$tabCRGOnlineCompute.Controls.Add($UCS2DefaultCheckBox)

$UCS2DefaultCheckBox.Add_CheckStateChanged({
    IF($UCS2DefaultCheckBox.checked)
    {
        $UCS2userTextBox.Text = "admin"
        $UCS2userTextBox.ReadOnly = $true
        IF($region -eq "Standard"){$ucspassword = "vBl0ck01!"}ELSE{$ucspassword = $regions.item($region)}
        $UCS2passTextBox.Text = $ucspassword
        $UCS2passTextBox.ReadOnly = $true
    }
    IF(!$UCS2DefaultCheckBox.checked)
    {
        $UCS2userTextBox.ReadOnly = $false
        $UCS2passTextBox.ReadOnly = $false
    }
})

$UCS3CheckBox = New-Object System.Windows.Forms.CheckBox
$UCS3CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +112)) 
$UCS3CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$UCS3CheckBox.Text = "UCS Domain 3"
$tabCRGOnlineCompute.Controls.Add($UCS3CheckBox)

$UCS3userTextBox = New-Object System.Windows.Forms.TextBox 
$UCS3userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +110))
$UCS3userTextBox.Size = New-Object System.Drawing.Size(140,20)
$UCS3userTextBox.Text = "admin"
$UCS3userTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($UCS3userTextBox)

$UCS3passTextBox = New-Object System.Windows.Forms.TextBox 
$UCS3passTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +110)) 
$UCS3passTextBox.Size = New-Object System.Drawing.Size(140,20)
$UCS3passTextBox.Text = $ucspassword
$UCS3passTextBox.UseSystemPasswordChar = $True
$UCS3passTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($UCS3passTextBox)

$UCS3IP1TextBox = New-Object System.Windows.Forms.TextBox 
$UCS3IP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +110))
$UCS3IP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineCompute.Controls.Add($UCS3IP1TextBox)

$UCS3DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$UCS3DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart+110))
$UCS3DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$UCS3DefaultCheckBox.Checked = $True
$tabCRGOnlineCompute.Controls.Add($UCS3DefaultCheckBox)

$UCS3DefaultCheckBox.Add_CheckStateChanged({
    IF($UCS3DefaultCheckBox.checked)
    {
        $UCS3userTextBox.Text = "admin"
        $UCS3userTextBox.ReadOnly = $true
        IF($region -eq "Standard"){$ucspassword = "vBl0ck01!"}ELSE{$ucspassword = $regions.item($region)}
        $UCS3passTextBox.Text = $ucspassword
        $UCS3passTextBox.ReadOnly = $true
    }
    IF(!$UCS3DefaultCheckBox.checked)
    {
        $UCS3userTextBox.ReadOnly = $false
        $UCS3passTextBox.ReadOnly = $false
    }
})

$UCS4CheckBox = New-Object System.Windows.Forms.CheckBox
$UCS4CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +142)) 
$UCS4CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$UCS4CheckBox.Text = "UCS Domain 4"
$tabCRGOnlineCompute.Controls.Add($UCS4CheckBox)

$UCS4userTextBox = New-Object System.Windows.Forms.TextBox 
$UCS4userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +140))
$UCS4userTextBox.Size = New-Object System.Drawing.Size(140,20)
$UCS4userTextBox.Text = "admin"
$UCS4userTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($UCS4userTextBox)

$UCS4passTextBox = New-Object System.Windows.Forms.TextBox 
$UCS4passTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +140)) 
$UCS4passTextBox.Size = New-Object System.Drawing.Size(140,20)
$UCS4passTextBox.Text = $ucspassword
$UCS4passTextBox.UseSystemPasswordChar = $True
$UCS4passTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($UCS4passTextBox)

$UCS4IP1TextBox = New-Object System.Windows.Forms.TextBox 
$UCS4IP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +140))
$UCS4IP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineCompute.Controls.Add($UCS4IP1TextBox)

$UCS4DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$UCS4DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart+140))
$UCS4DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$UCS4DefaultCheckBox.Checked = $True
$tabCRGOnlineCompute.Controls.Add($UCS4DefaultCheckBox)

$UCS4DefaultCheckBox.Add_CheckStateChanged({
    IF($UCS4DefaultCheckBox.checked)
    {
        $UCS4userTextBox.Text = "admin"
        $UCS4userTextBox.ReadOnly = $true
        IF($region -eq "Standard"){$ucspassword = "vBl0ck01!"}ELSE{$ucspassword = $regions.item($region)}
        $UCS4passTextBox.Text = $ucspassword
        $UCS4passTextBox.ReadOnly = $true
    }
    IF(!$UCS4DefaultCheckBox.checked)
    {
        $UCS4userTextBox.ReadOnly = $false
        $UCS4passTextBox.ReadOnly = $false
    }
})

$UCS5CheckBox = New-Object System.Windows.Forms.CheckBox
$UCS5CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +172)) 
$UCS5CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$UCS5CheckBox.Text = "UCS Domain 5"
$tabCRGOnlineCompute.Controls.Add($UCS5CheckBox)

$UCS5userTextBox = New-Object System.Windows.Forms.TextBox 
$UCS5userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +170))
$UCS5userTextBox.Size = New-Object System.Drawing.Size(140,20)
$UCS5userTextBox.Text = "admin"
$UCS5userTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($UCS5userTextBox)

$UCS5passTextBox = New-Object System.Windows.Forms.TextBox 
$UCS5passTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +170)) 
$UCS5passTextBox.Size = New-Object System.Drawing.Size(140,20)
$UCS5passTextBox.Text = $ucspassword
$UCS5passTextBox.UseSystemPasswordChar = $True
$UCS5passTextBox.ReadOnly = $true
$tabCRGOnlineCompute.Controls.Add($UCS5passTextBox)

$UCS5IP1TextBox = New-Object System.Windows.Forms.TextBox 
$UCS5IP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +170))
$UCS5IP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineCompute.Controls.Add($UCS5IP1TextBox)

$UCS5DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$UCS5DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart+170))
$UCS5DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$UCS5DefaultCheckBox.Checked = $True
$tabCRGOnlineCompute.Controls.Add($UCS5DefaultCheckBox)

$UCS5DefaultCheckBox.Add_CheckStateChanged({
    IF($UCS5DefaultCheckBox.checked)
    {
        $UCS5userTextBox.Text = "admin"
        $UCS5userTextBox.ReadOnly = $true
        IF($region -eq "Standard"){$ucspassword = "vBl0ck01!"}ELSE{$ucspassword = $regions.item($region)}
        $UCS5passTextBox.Text = $ucspassword
        $UCS5passTextBox.ReadOnly = $true
    }
    IF(!$UCS5DefaultCheckBox.checked)
    {
        $UCS5userTextBox.ReadOnly = $false
        $UCS5passTextBox.ReadOnly = $false
    }
})

#endregion tabCRGCompute

#region tabCRGNetwork

$tabCRGOnlineNetwork = New-Object System.Windows.Forms.TabPage
$tabCRGOnlineNetwork.UseVisualStyleBackColor = $True
$tabCRGOnlineNetwork.Text = "Network"
$tabctrlCRG.TabPages.Add($tabCRGOnlineNetwork)

$tabNetworkUserLabel = New-Object System.Windows.Forms.Label
$tabNetworkUserLabel.Location = New-Object System.Drawing.Size($tabxstart,$tabystart) 
$tabNetworkUserLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabNetworkUserLabel.Text = "Username"
$tabCRGOnlineNetwork.Controls.Add($tabNetworkUserLabel)

$tabNetworkPassLabel = New-Object System.Windows.Forms.Label
$tabNetworkPassLabel.Location = New-Object System.Drawing.Size(($tabxstart +145),$tabystart)
$tabNetworkPassLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabNetworkPassLabel.Text = "Password"
$tabCRGOnlineNetwork.Controls.Add($tabNetworkPassLabel)

$tabNetworkIP1Label = New-Object System.Windows.Forms.Label
$tabNetworkIP1Label.Location = New-Object System.Drawing.Size(($tabxstart +290),$tabystart) 
$tabNetworkIP1Label.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabNetworkIP1Label.Text = "IP Address 1"
$tabCRGOnlineNetwork.Controls.Add($tabNetworkIP1Label)

$tabNetworkIP2Label = New-Object System.Windows.Forms.Label
$tabNetworkIP2Label.Location = New-Object System.Drawing.Size(($tabxstart +385),$tabystart)
$tabNetworkIP2Label.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabNetworkIP2Label.Text = "IP Address 2"
$tabCRGOnlineNetwork.Controls.Add($tabNetworkIP2Label)

$tabNetworkOptionLabel = New-Object System.Windows.Forms.Label
$tabNetworkOptionLabel.Location = New-Object System.Drawing.Size(($tabxstart+480),$tabystart) 
$tabNetworkOptionLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabNetworkOptionLabel.Text = "Option"
$tabCRGOnlineNetwork.Controls.Add($tabNetworkOptionLabel)

$tabNetworkDefaultCredLabel = New-Object System.Windows.Forms.Label
$tabNetworkDefaultCredLabel.Location = New-Object System.Drawing.Size(($tabxstart+600),$tabystart) 
$tabNetworkDefaultCredLabel.Size = New-Object System.Drawing.Size(($tabxsize+30),$tabysize) 
$tabNetworkDefaultCredLabel.Text = "Default Credentials"
$tabCRGOnlineNetwork.Controls.Add($tabNetworkDefaultCredLabel)

$3560CheckBox = New-Object System.Windows.Forms.CheckBox
$3560CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +22)) 
$3560CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$3560CheckBox.Text = "Catalyst 3560"
$tabCRGOnlineNetwork.Controls.Add($3560CheckBox)

$3560userTextBox = New-Object System.Windows.Forms.TextBox 
$3560userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +20))
$3560userTextBox.Size = New-Object System.Drawing.Size(140,20)
$3560userTextBox.Text = "admin"
$3560userTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($3560userTextBox)

$3560passTextBox = New-Object System.Windows.Forms.TextBox 
$3560passTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +20)) 
$3560passTextBox.Size = New-Object System.Drawing.Size(140,20)
$3560passTextBox.Text = $regions.item($region)
$3560passTextBox.UseSystemPasswordChar = $True
$3560passTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($3560passTextBox)

$3560IP1TextBox = New-Object System.Windows.Forms.TextBox 
$3560IP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +20))
$3560IP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($3560IP1TextBox)

$3560IP2TextBox = New-Object System.Windows.Forms.TextBox 
$3560IP2TextBox.Location = New-Object System.Drawing.Size(505,($tabystart +20)) 
$3560IP2TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($3560IP2TextBox)

$3560DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$3560DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +20))
$3560DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$3560DefaultCheckBox.Checked = $True
$tabCRGOnlineNetwork.Controls.Add($3560DefaultCheckBox)

$3560DefaultCheckBox.Add_CheckStateChanged({
    IF($3560DefaultCheckBox.checked)
    {
        $3560userTextBox.Text = "admin"
        $3560userTextBox.ReadOnly = $true
        $3560passTextBox.Text = $regions.item($region)
        $3560passTextBox.ReadOnly = $true
    }
    IF(!$3560DefaultCheckBox.checked)
    {
        $3560userTextBox.ReadOnly = $false
        $3560passTextBox.ReadOnly = $false
    }
})

$3750CheckBox = New-Object System.Windows.Forms.CheckBox
$3750CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +52)) 
$3750CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$3750CheckBox.Text = "Catalyst 3750"
$tabCRGOnlineNetwork.Controls.Add($3750CheckBox)

$3750userTextBox = New-Object System.Windows.Forms.TextBox 
$3750userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +50))
$3750userTextBox.Size = New-Object System.Drawing.Size(140,20)
$3750userTextBox.Text = "admin"
$3750userTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($3750userTextBox)

$3750passTextBox = New-Object System.Windows.Forms.TextBox 
$3750passTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +50)) 
$3750passTextBox.Size = New-Object System.Drawing.Size(140,20)
$3750passTextBox.Text = $regions.item($region)
$3750passTextBox.UseSystemPasswordChar = $True
$3750passTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($3750passTextBox)

$3750IP1TextBox = New-Object System.Windows.Forms.TextBox 
$3750IP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +50))
$3750IP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($3750IP1TextBox)

$3750DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$3750DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +50))
$3750DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$3750DefaultCheckBox.Checked = $True
$tabCRGOnlineNetwork.Controls.Add($3750DefaultCheckBox)

$3750DefaultCheckBox.Add_CheckStateChanged({
    IF($3750DefaultCheckBox.checked)
    {
        $3750userTextBox.Text = "admin"
        $3750userTextBox.ReadOnly = $true
        $3750passTextBox.Text = $regions.item($region)
        $3750passTextBox.ReadOnly = $true
    }
    IF(!$3750DefaultCheckBox.checked)
    {
        $3750userTextBox.ReadOnly = $false
        $3750passTextBox.ReadOnly = $false
    }
})

$3048CheckBox = New-Object System.Windows.Forms.CheckBox
$3048CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +82)) 
$3048CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$3048CheckBox.Text = "Nexus 3K"
$tabCRGOnlineNetwork.Controls.Add($3048CheckBox)

$3048userTextBox = New-Object System.Windows.Forms.TextBox 
$3048userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +80))
$3048userTextBox.Size = New-Object System.Drawing.Size(140,20)
$3048userTextBox.Text = "admin"
$3048userTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($3048userTextBox)

$3048passTextBox = New-Object System.Windows.Forms.TextBox 
$3048passTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +80)) 
$3048passTextBox.Size = New-Object System.Drawing.Size(140,20)
$3048passTextBox.Text = $regions.item($region)
$3048passTextBox.UseSystemPasswordChar = $True
$3048passTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($3048passTextBox)

$3048IP1TextBox = New-Object System.Windows.Forms.TextBox 
$3048IP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +80))
$3048IP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($3048IP1TextBox)

$3048IP2TextBox = New-Object System.Windows.Forms.TextBox 
$3048IP2TextBox.Location = New-Object System.Drawing.Size(505,($tabystart +80)) 
$3048IP2TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($3048IP2TextBox)

$3048DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$3048DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +80))
$3048DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$3048DefaultCheckBox.Checked = $True
$tabCRGOnlineNetwork.Controls.Add($3048DefaultCheckBox)

$3048DefaultCheckBox.Add_CheckStateChanged({
    IF($3048DefaultCheckBox.checked)
    {
        $3048userTextBox.Text = "admin"
        $3048userTextBox.ReadOnly = $true
        $3048passTextBox.Text = $regions.item($region)
        $3048passTextBox.ReadOnly = $true
    }
    IF(!$3048DefaultCheckBox.checked)
    {
        $3048userTextBox.ReadOnly = $false
        $3048passTextBox.ReadOnly = $false
    }
})

$55XXCheckBox = New-Object System.Windows.Forms.CheckBox
$55XXCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +112)) 
$55XXCheckBox.Size = New-Object System.Drawing.Size(115,20) 
$55XXCheckBox.Text = "Nexus Aggregate"
$tabCRGOnlineNetwork.Controls.Add($55XXCheckBox)

$55XXuserTextBox = New-Object System.Windows.Forms.TextBox 
$55XXuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +110))
$55XXuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$55XXuserTextBox.Text = "admin"
$55XXuserTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($55XXuserTextBox)

$55XXpassTextBox = New-Object System.Windows.Forms.TextBox 
$55XXpassTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +110)) 
$55XXpassTextBox.Size = New-Object System.Drawing.Size(140,20)
$55XXpassTextBox.Text = $regions.item($region)
$55XXpassTextBox.UseSystemPasswordChar = $True
$55XXpassTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($55XXpassTextBox)

$55XXIP1TextBox = New-Object System.Windows.Forms.TextBox 
$55XXIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +110))
$55XXIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($55XXIP1TextBox)

$55XXIP2TextBox = New-Object System.Windows.Forms.TextBox 
$55XXIP2TextBox.Location = New-Object System.Drawing.Size(505,($tabystart +110)) 
$55XXIP2TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($55XXIP2TextBox)

$55XXDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$55XXDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +110))
$55XXDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$55XXDefaultCheckBox.Checked = $True
$tabCRGOnlineNetwork.Controls.Add($55XXDefaultCheckBox)

$55XXDefaultCheckBox.Add_CheckStateChanged({
    IF($55XXDefaultCheckBox.checked)
    {
        $55XXuserTextBox.Text = "admin"
        $55XXuserTextBox.ReadOnly = $true
        $55XXpassTextBox.Text = $regions.item($region)
        $55XXpassTextBox.ReadOnly = $true
    }
    IF(!$55XXDefaultCheckBox.checked)
    {
        $55XXuserTextBox.ReadOnly = $false
        $55XXpassTextBox.ReadOnly = $false
    }
})

$55XX2CheckBox = New-Object System.Windows.Forms.CheckBox
$55XX2CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +142)) 
$55XX2CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$55XX2CheckBox.Text = "Nexus BRS"
$tabCRGOnlineNetwork.Controls.Add($55XX2CheckBox)

$55XX2userTextBox = New-Object System.Windows.Forms.TextBox 
$55XX2userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +140))
$55XX2userTextBox.Size = New-Object System.Drawing.Size(140,20)
$55XX2userTextBox.Text = "admin"
$55XX2userTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($55XX2userTextBox)

$55XX2passTextBox = New-Object System.Windows.Forms.TextBox 
$55XX2passTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +140)) 
$55XX2passTextBox.Size = New-Object System.Drawing.Size(140,20)
$55XX2passTextBox.Text = $regions.item($region)
$55XX2passTextBox.UseSystemPasswordChar = $True
$55XX2passTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($55XX2passTextBox)

$55XX2IP1TextBox = New-Object System.Windows.Forms.TextBox 
$55XX2IP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +140))
$55XX2IP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($55XX2IP1TextBox)

$55XX2IP2TextBox = New-Object System.Windows.Forms.TextBox 
$55XX2IP2TextBox.Location = New-Object System.Drawing.Size(505,($tabystart +140)) 
$55XX2IP2TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($55XX2IP2TextBox)

$55XX2DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$55XX2DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +140))
$55XX2DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$55XX2DefaultCheckBox.Checked = $True
$tabCRGOnlineNetwork.Controls.Add($55XX2DefaultCheckBox)

$55XX2DefaultCheckBox.Add_CheckStateChanged({
    IF($55XX2DefaultCheckBox.checked)
    {
        $55XX2userTextBox.Text = "admin"
        $55XX2userTextBox.ReadOnly = $true
        $55XX2passTextBox.Text = $regions.item($region)
        $55XX2passTextBox.ReadOnly = $true
    }
    IF(!$55XX2DefaultCheckBox.checked)
    {
        $55XX2userTextBox.ReadOnly = $false
        $55XX2passTextBox.ReadOnly = $false
    }
})

$55XX3CheckBox = New-Object System.Windows.Forms.CheckBox
$55XX3CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +172)) 
$55XX3CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$55XX3CheckBox.Text = "Nexus Isilon"
$tabCRGOnlineNetwork.Controls.Add($55XX3CheckBox)

$55XX3userTextBox = New-Object System.Windows.Forms.TextBox 
$55XX3userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +170))
$55XX3userTextBox.Size = New-Object System.Drawing.Size(140,20)
$55XX3userTextBox.Text = "admin"
$55XX3userTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($55XX3userTextBox)

$55XX3passTextBox = New-Object System.Windows.Forms.TextBox 
$55XX3passTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +170)) 
$55XX3passTextBox.Size = New-Object System.Drawing.Size(140,20)
$55XX3passTextBox.Text = $regions.item($region)
$55XX3passTextBox.UseSystemPasswordChar = $True
$55XX3passTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($55XX3passTextBox)

$55XX3IP1TextBox = New-Object System.Windows.Forms.TextBox 
$55XX3IP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +170))
$55XX3IP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($55XX3IP1TextBox)

$55XX3IP2TextBox = New-Object System.Windows.Forms.TextBox 
$55XX3IP2TextBox.Location = New-Object System.Drawing.Size(505,($tabystart +170)) 
$55XX3IP2TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($55XX3IP2TextBox)

$55XX3DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$55XX3DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +170))
$55XX3DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$55XX3DefaultCheckBox.Checked = $True
$tabCRGOnlineNetwork.Controls.Add($55XX3DefaultCheckBox)

$55XX3DefaultCheckBox.Add_CheckStateChanged({
    IF($55XX3DefaultCheckBox.checked)
    {
        $55XX3userTextBox.Text = "admin"
        $55XX3userTextBox.ReadOnly = $true
        $55XX3passTextBox.Text = $regions.item($region)
        $55XX3passTextBox.ReadOnly = $true
    }
    IF(!$55XX3DefaultCheckBox.checked)
    {
        $55XX3userTextBox.ReadOnly = $false
        $55XX3passTextBox.ReadOnly = $false
    }
})

$1000CheckBox = New-Object System.Windows.Forms.CheckBox
$1000CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +202)) 
$1000CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$1000CheckBox.Text = "Nexus 1000V"
$tabCRGOnlineNetwork.Controls.Add($1000CheckBox)

$1000userTextBox = New-Object System.Windows.Forms.TextBox 
$1000userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +200))
$1000userTextBox.Size = New-Object System.Drawing.Size(140,20)
$1000userTextBox.Text = "admin"
$1000userTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($1000userTextBox)

$1000passTextBox = New-Object System.Windows.Forms.TextBox 
$1000passTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +200)) 
$1000passTextBox.Size = New-Object System.Drawing.Size(140,20)
$1000passTextBox.Text = $regions.item($region)
$1000passTextBox.UseSystemPasswordChar = $True
$1000passTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($1000passTextBox)

$1000IP1TextBox = New-Object System.Windows.Forms.TextBox 
$1000IP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +200))
$1000IP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($1000IP1TextBox)

$1000DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$1000DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +200))
$1000DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$1000DefaultCheckBox.Checked = $True
$tabCRGOnlineNetwork.Controls.Add($1000DefaultCheckBox)

$1000DefaultCheckBox.Add_CheckStateChanged({
    IF($1000DefaultCheckBox.checked)
    {
        $1000userTextBox.Text = "admin"
        $1000userTextBox.ReadOnly = $true
        $1000passTextBox.Text = $regions.item($region)
        $1000passTextBox.ReadOnly = $true
    }
    IF(!$1000DefaultCheckBox.checked)
    {
        $1000userTextBox.ReadOnly = $false
        $1000passTextBox.ReadOnly = $false
    }
})

$MDSCheckBox = New-Object System.Windows.Forms.CheckBox
$MDSCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +232)) 
$MDSCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$MDSCheckBox.Text = "Cisco MDS"
$tabCRGOnlineNetwork.Controls.Add($MDSCheckBox)

$MDSuserTextBox = New-Object System.Windows.Forms.TextBox 
$MDSuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +230))
$MDSuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$MDSuserTextBox.Text = "admin"
$MDSuserTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($MDSuserTextBox)

$MDSpassTextBox = New-Object System.Windows.Forms.TextBox 
$MDSpassTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +230)) 
$MDSpassTextBox.Size = New-Object System.Drawing.Size(140,20)
$MDSpassTextBox.Text = $regions.item($region)
$MDSpassTextBox.UseSystemPasswordChar = $True
$MDSpassTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($MDSpassTextBox)

$MDSIP1TextBox = New-Object System.Windows.Forms.TextBox 
$MDSIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +230))
$MDSIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($MDSIP1TextBox)

$MDSIP2TextBox = New-Object System.Windows.Forms.TextBox 
$MDSIP2TextBox.Location = New-Object System.Drawing.Size(505,($tabystart +230)) 
$MDSIP2TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($MDSIP2TextBox)

$MDSDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$MDSDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +230))
$MDSDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$MDSDefaultCheckBox.Checked = $True
$tabCRGOnlineNetwork.Controls.Add($MDSDefaultCheckBox)

$MDSDefaultCheckBox.Add_CheckStateChanged({
    IF($MDSDefaultCheckBox.checked)
    {
        $MDSuserTextBox.Text = "admin"
        $MDSuserTextBox.ReadOnly = $true
        $MDSpassTextBox.Text = $regions.item($region)
        $MDSpassTextBox.ReadOnly = $true
    }
    IF(!$MDSDefaultCheckBox.checked)
    {
        $MDSuserTextBox.ReadOnly = $false
        $MDSpassTextBox.ReadOnly = $false
    }
})

$N7KCheckBox = New-Object System.Windows.Forms.CheckBox
$N7KCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +262)) 
$N7KCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$N7KCheckBox.Text = "Nexus Core"
$tabCRGOnlineNetwork.Controls.Add($N7KCheckBox)

$N7KuserTextBox = New-Object System.Windows.Forms.TextBox 
$N7KuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +260))
$N7KuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$N7KuserTextBox.Text = "admin"
$N7KuserTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($N7KuserTextBox)

$N7KpassTextBox = New-Object System.Windows.Forms.TextBox 
$N7KpassTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +260)) 
$N7KpassTextBox.Size = New-Object System.Drawing.Size(140,20)
$N7KpassTextBox.Text = $regions.item($region)
$N7KpassTextBox.UseSystemPasswordChar = $True
$N7KpassTextBox.ReadOnly = $true
$tabCRGOnlineNetwork.Controls.Add($N7KpassTextBox)

$N7KIP1TextBox = New-Object System.Windows.Forms.TextBox 
$N7KIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +260))
$N7KIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($N7KIP1TextBox)

$N7KIP2TextBox = New-Object System.Windows.Forms.TextBox 
$N7KIP2TextBox.Location = New-Object System.Drawing.Size(505,($tabystart +260)) 
$N7KIP2TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineNetwork.Controls.Add($N7KIP2TextBox)

$N7KDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$N7KDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +260))
$N7KDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$N7KDefaultCheckBox.Checked = $True
$tabCRGOnlineNetwork.Controls.Add($N7KDefaultCheckBox)

$N7KDefaultCheckBox.Add_CheckStateChanged({
    IF($N7KDefaultCheckBox.checked)
    {
        $N7KuserTextBox.Text = "admin"
        $N7KuserTextBox.ReadOnly = $true
        $N7KpassTextBox.Text = $regions.item($region)
        $N7KpassTextBox.ReadOnly = $true
    }
    IF(!$N7KDefaultCheckBox.checked)
    {
        $N7KuserTextBox.ReadOnly = $false
        $N7KpassTextBox.ReadOnly = $false
    }
})

#endregion tabCRGNetwork

#region tabCRGStorage

$tabCRGOnlineStorage = New-Object System.Windows.Forms.TabPage
$tabCRGOnlineStorage.UseVisualStyleBackColor = $True
$tabCRGOnlineStorage.Text = "Storage"
$tabctrlCRG.TabPages.Add($tabCRGOnlineStorage)

$tabStorageUserLabel = New-Object System.Windows.Forms.Label
$tabStorageUserLabel.Location = New-Object System.Drawing.Size($tabxstart,$tabystart) 
$tabStorageUserLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabStorageUserLabel.Text = "Username"
$tabCRGOnlineStorage.Controls.Add($tabStorageUserLabel)

$tabStoragePassLabel = New-Object System.Windows.Forms.Label
$tabStoragePassLabel.Location = New-Object System.Drawing.Size(($tabxstart +145),$tabystart)
$tabStoragePassLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabStoragePassLabel.Text = "Password"
$tabCRGOnlineStorage.Controls.Add($tabStoragePassLabel)

$tabStorageIP1Label = New-Object System.Windows.Forms.Label
$tabStorageIP1Label.Location = New-Object System.Drawing.Size(($tabxstart +290),$tabystart) 
$tabStorageIP1Label.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabStorageIP1Label.Text = "IP Address 1"
$tabCRGOnlineStorage.Controls.Add($tabStorageIP1Label)

$tabStorageIP2Label = New-Object System.Windows.Forms.Label
$tabStorageIP2Label.Location = New-Object System.Drawing.Size(($tabxstart +385),$tabystart) 
$tabStorageIP2Label.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabStorageIP2Label.Text = "IP Address 2"
$tabCRGOnlineStorage.Controls.Add($tabStorageIP2Label)

$tabStorageOptionLabel = New-Object System.Windows.Forms.Label
$tabStorageOptionLabel.Location = New-Object System.Drawing.Size(($tabxstart+480),$tabystart) 
$tabStorageOptionLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabStorageOptionLabel.Text = "Option"
$tabCRGOnlineStorage.Controls.Add($tabStorageOptionLabel)

$tabStorageDefaultCredLabel = New-Object System.Windows.Forms.Label
$tabStorageDefaultCredLabel.Location = New-Object System.Drawing.Size(($tabxstart+600),$tabystart) 
$tabStorageDefaultCredLabel.Size = New-Object System.Drawing.Size(($tabxsize+30),$tabysize) 
$tabStorageDefaultCredLabel.Text = "Default Credentials"
$tabCRGOnlineStorage.Controls.Add($tabStorageDefaultCredLabel)

$VNXeCheckBox = New-Object System.Windows.Forms.CheckBox
$VNXeCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +22)) 
$VNXeCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$VNXeCheckBox.Text = "VNXe"
$tabCRGOnlineStorage.Controls.Add($VNXeCheckBox)

$VNXeuserTextBox = New-Object System.Windows.Forms.TextBox 
$VNXeuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +20))
$VNXeuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$VNXeuserTextBox.Text = "admin"
$VNXeuserTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($VNXeuserTextBox)

$VNXepassTextBox = New-Object System.Windows.Forms.TextBox 
$VNXepassTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +20)) 
$VNXepassTextBox.Size = New-Object System.Drawing.Size(140,20)
$VNXepassTextBox.Text = $regions.item($region)
$VNXepassTextBox.UseSystemPasswordChar = $True
$VNXepassTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($VNXepassTextBox)

$VNXeIP1TextBox = New-Object System.Windows.Forms.TextBox 
$VNXeIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +20))
$VNXeIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineStorage.Controls.Add($VNXeIP1TextBox)

$VNXeDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$VNXeDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +20))
$VNXeDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$VNXeDefaultCheckBox.Checked = $True
$tabCRGOnlineStorage.Controls.Add($VNXeDefaultCheckBox)

$VNXeDefaultCheckBox.Add_CheckStateChanged({
    IF($VNXeDefaultCheckBox.checked)
    {
        $VNXeuserTextBox.Text = "admin"
        $VNXeuserTextBox.ReadOnly = $true
        $VNXepassTextBox.Text = $regions.item($region)
        $VNXepassTextBox.ReadOnly = $true
    }
    IF(!$VNXeDefaultCheckBox.checked)
    {
        $VNXeuserTextBox.ReadOnly = $false
        $VNXepassTextBox.ReadOnly = $false
    }
})

$VNXCheckBox = New-Object System.Windows.Forms.CheckBox
$VNXCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +52)) 
$VNXCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$VNXCheckBox.Text = "VNX-Block"
$tabCRGOnlineStorage.Controls.Add($VNXCheckBox)

$VNXuserTextBox = New-Object System.Windows.Forms.TextBox 
$VNXuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +50))
$VNXuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$VNXuserTextBox.Text = "sysadmin"
$VNXuserTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($VNXuserTextBox)

$VNXpassTextBox = New-Object System.Windows.Forms.TextBox 
$VNXpassTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +50)) 
$VNXpassTextBox.Size = New-Object System.Drawing.Size(140,20)
$VNXpassTextBox.Text = "sysadmin"
$VNXpassTextBox.UseSystemPasswordChar = $True
$VNXpassTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($VNXpassTextBox)

$VNXIP1TextBox = New-Object System.Windows.Forms.TextBox 
$VNXIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +50))
$VNXIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineStorage.Controls.Add($VNXIP1TextBox)

$authtypes = @("global","local","ldap")

$VNXOptionComboBox = New-Object System.Windows.Forms.ComboBox
$VNXOptionComboBox.Location = New-Object System.Drawing.Size(($tabxstart+480),($tabystart +50)) 
$VNXOptionComboBox.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabCRGOnlineStorage.Controls.Add($VNXOptionComboBox)
ForEach ($item in $authtypes){$VNXOptionComboBox.Items.Add($item) | Out-Null}
$VNXOptionComboBox.SelectedItem = "global"

$VNXDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$VNXDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +50))
$VNXDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$VNXDefaultCheckBox.Checked = $True
$tabCRGOnlineStorage.Controls.Add($VNXDefaultCheckBox)

$VNXDefaultCheckBox.Add_CheckStateChanged({
    IF($VNXDefaultCheckBox.checked)
    {
        $VNXuserTextBox.Text = "sysadmin"
        $VNXuserTextBox.ReadOnly = $true
        $VNXpassTextBox.Text = "sysadmin"
        $VNXpassTextBox.ReadOnly = $true
    }
    IF(!$VNXDefaultCheckBox.checked)
    {
        $VNXuserTextBox.ReadOnly = $false
        $VNXpassTextBox.ReadOnly = $false
    }
})

$NASCheckBox = New-Object System.Windows.Forms.CheckBox
$NASCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +82)) 
$NASCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$NASCheckBox.Text = "VNX-File"
$tabCRGOnlineStorage.Controls.Add($NASCheckBox)

$NASuserTextBox = New-Object System.Windows.Forms.TextBox 
$NASuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +80))
$NASuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$NASuserTextBox.Text = "root"
$NASuserTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($NASuserTextBox)

$NASpassTextBox = New-Object System.Windows.Forms.TextBox 
$NASpassTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +80)) 
$NASpassTextBox.Size = New-Object System.Drawing.Size(140,20)
$NASpassTextBox.Text = "nasadmin"
$NASpassTextBox.UseSystemPasswordChar = $True
$NASpassTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($NASpassTextBox)

$NASIP1TextBox = New-Object System.Windows.Forms.TextBox 
$NASIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +80))
$NASIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineStorage.Controls.Add($NASIP1TextBox)

$NASDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$NASDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +80))
$NASDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$NASDefaultCheckBox.Checked = $True
$tabCRGOnlineStorage.Controls.Add($NASDefaultCheckBox)

$NASDefaultCheckBox.Add_CheckStateChanged({
    IF($NASDefaultCheckBox.checked)
    {
        $NASuserTextBox.Text = "root"
        $NASuserTextBox.ReadOnly = $true
        $NASpassTextBox.Text = "nasadmin"
        $NASpassTextBox.ReadOnly = $true
    }
    IF(!$NASDefaultCheckBox.checked)
    {
        $NASuserTextBox.ReadOnly = $false
        $NASpassTextBox.ReadOnly = $false
    }
})

$XtremIOCheckBox = New-Object System.Windows.Forms.CheckBox
$XtremIOCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +112)) 
$XtremIOCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$XtremIOCheckBox.Text = "XtremIO VM"
$tabCRGOnlineStorage.Controls.Add($XtremIOCheckBox)

$XtremIOuserTextBox = New-Object System.Windows.Forms.TextBox 
$XtremIOuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +110))
$XtremIOuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$XtremIOuserTextBox.Text = "tech"
$XtremIOuserTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($XtremIOuserTextBox)

$XtremIOpassTextBox = New-Object System.Windows.Forms.TextBox 
$XtremIOpassTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +110)) 
$XtremIOpassTextBox.Size = New-Object System.Drawing.Size(140,20)
$XtremIOpassTextBox.Text = "X10Tech!"
$XtremIOpassTextBox.UseSystemPasswordChar = $True
$XtremIOpassTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($XtremIOpassTextBox)

$XtremIOIP1TextBox = New-Object System.Windows.Forms.TextBox 
$XtremIOIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +110))
$XtremIOIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineStorage.Controls.Add($XtremIOIP1TextBox)

$XtremIODefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$XtremIODefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +110))
$XtremIODefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$XtremIODefaultCheckBox.Checked = $True
$tabCRGOnlineStorage.Controls.Add($XtremIODefaultCheckBox)

$XtremIODefaultCheckBox.Add_CheckStateChanged({
    IF($XtremIODefaultCheckBox.checked)
    {
        $XtremIOuserTextBox.Text = "tech"
        $XtremIOuserTextBox.ReadOnly = $true
        $XtremIOpassTextBox.Text = "X10Tech!"
        $XtremIOpassTextBox.ReadOnly = $true
    }
    IF(!$XtremIODefaultCheckBox.checked)
    {
        $XtremIOuserTextBox.ReadOnly = $false
        $XtremIOpassTextBox.ReadOnly = $false
    }
})

$VPLEXCheckBox = New-Object System.Windows.Forms.CheckBox
$VPLEXCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +142)) 
$VPLEXCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$VPLEXCheckBox.Text = "VPLEX"
$tabCRGOnlineStorage.Controls.Add($VPLEXCheckBox)

$VPLEXUserTextBox = New-Object System.Windows.Forms.TextBox 
$VPLEXuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +140))
$VPLEXuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$VPLEXuserTextBox.Text = "service"
$VPLEXuserTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($VPLEXuserTextBox)

$VPLEXpassTextBox = New-Object System.Windows.Forms.TextBox 
$VPLEXpassTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +140)) 
$VPLEXpassTextBox.Size = New-Object System.Drawing.Size(140,20)
$VPLEXpassTextBox.Text = "Mi@Dim7T"
$VPLEXpassTextBox.UseSystemPasswordChar = $True
$VPLEXpassTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($VPLEXpassTextBox)

$VPLEXIP1TextBox = New-Object System.Windows.Forms.TextBox 
$VPLEXIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +140))
$VPLEXIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineStorage.Controls.Add($VPLEXIP1TextBox)

$VPLEXIP2TextBox = New-Object System.Windows.Forms.TextBox 
$VPLEXIP2TextBox.Location = New-Object System.Drawing.Size(505,($tabystart +140))
$VPLEXIP2TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineStorage.Controls.Add($VPLEXIP2TextBox)

$VPLEXDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$VPLEXDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +140))
$VPLEXDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$VPLEXDefaultCheckBox.Checked = $True
$tabCRGOnlineStorage.Controls.Add($VPLEXDefaultCheckBox)

$VPLEXDefaultCheckBox.Add_CheckStateChanged({
    IF($VPLEXDefaultCheckBox.checked)
    {
        $VPLEXuserTextBox.Text = "service"
        $VPLEXuserTextBox.ReadOnly = $true
        $VPLEXpassTextBox.Text = "Mi@Dim7T"
        $VPLEXpassTextBox.ReadOnly = $true
    }
    IF(!$VPLEXDefaultCheckBox.checked)
    {
        $VPLEXuserTextBox.ReadOnly = $false
        $VPLEXpassTextBox.ReadOnly = $false
    }
})

$IsilonCheckBox = New-Object System.Windows.Forms.CheckBox
$IsilonCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +172)) 
$IsilonCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$IsilonCheckBox.Text = "Isilon"
$tabCRGOnlineStorage.Controls.Add($IsilonCheckBox)

$IsilonUserTextBox = New-Object System.Windows.Forms.TextBox 
$IsilonuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +170))
$IsilonuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$IsilonuserTextBox.Text = "admin"
$IsilonuserTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($IsilonuserTextBox)

$IsilonpassTextBox = New-Object System.Windows.Forms.TextBox 
$IsilonpassTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +170)) 
$IsilonpassTextBox.Size = New-Object System.Drawing.Size(140,20)
$IsilonpassTextBox.Text = $regions.item($region)
$IsilonpassTextBox.UseSystemPasswordChar = $True
$IsilonpassTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($IsilonpassTextBox)

$IsilonIP1TextBox = New-Object System.Windows.Forms.TextBox 
$IsilonIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +170))
$IsilonIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineStorage.Controls.Add($IsilonIP1TextBox)

$IsilonDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$IsilonDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +170))
$IsilonDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$IsilonDefaultCheckBox.Checked = $True
$tabCRGOnlineStorage.Controls.Add($IsilonDefaultCheckBox)

$IsilonDefaultCheckBox.Add_CheckStateChanged({
    IF($IsilonDefaultCheckBox.checked)
    {
        $IsilonuserTextBox.Text = "admin"
        $IsilonuserTextBox.ReadOnly = $true
        $IsilonpassTextBox.Text = $regions.item($region)
        $IsilonpassTextBox.ReadOnly = $true
    }
    IF(!$IsilonDefaultCheckBox.checked)
    {
        $IsilonuserTextBox.ReadOnly = $false
        $IsilonpassTextBox.ReadOnly = $false
    }
})

$UnityCheckBox = New-Object System.Windows.Forms.CheckBox
$UnityCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart +202)) 
$UnityCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$UnityCheckBox.Text = "Unity"
$tabCRGOnlineStorage.Controls.Add($UnityCheckBox)

$UnityuserTextBox = New-Object System.Windows.Forms.TextBox 
$UnityuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart +200))
$UnityuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$UnityuserTextBox.Text = "admin"
$UnityuserTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($UnityuserTextBox)

$UnitypassTextBox = New-Object System.Windows.Forms.TextBox 
$UnitypassTextBox.Location = New-Object System.Drawing.Size(265,($tabystart +200)) 
$UnitypassTextBox.Size = New-Object System.Drawing.Size(140,20)
$UnitypassTextBox.Text = $regions.item($region)
$UnitypassTextBox.UseSystemPasswordChar = $True
$UnitypassTextBox.ReadOnly = $true
$tabCRGOnlineStorage.Controls.Add($UnitypassTextBox)

$UnityIP1TextBox = New-Object System.Windows.Forms.TextBox 
$UnityIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart +200))
$UnityIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGOnlineStorage.Controls.Add($UnityIP1TextBox)

$UnityDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$UnityDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),($tabystart +200))
$UnityDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$UnityDefaultCheckBox.Checked = $True
$tabCRGOnlineStorage.Controls.Add($UnityDefaultCheckBox)

$UnityDefaultCheckBox.Add_CheckStateChanged({
    IF($UnityDefaultCheckBox.checked)
    {
        $UnityuserTextBox.Text = "admin"
        $UnityuserTextBox.ReadOnly = $true
        $UnitypassTextBox.Text = $regions.item($region)
        $UnitypassTextBox.ReadOnly = $true
    }
    IF(!$UnityDefaultCheckBox.checked)
    {
        $UnityuserTextBox.ReadOnly = $false
        $UnitypassTextBox.ReadOnly = $false
    }
})

#endregion tabCRGStorage

#region tabCRGVMware

$tabCRGVMware = New-Object System.Windows.Forms.TabPage
$tabCRGVMware.UseVisualStyleBackColor = $True
$tabCRGVMware.Text = "VMware"
$tabctrlCRG.TabPages.Add($tabCRGVMware)

$tabVMwareUserLabel = New-Object System.Windows.Forms.Label
$tabVMwareUserLabel.Location = New-Object System.Drawing.Size($tabxstart,$tabystart) 
$tabVMwareUserLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabVMwareUserLabel.Text = "Username"
$tabCRGVMware.Controls.Add($tabVMwareUserLabel)

$tabVMwarePassLabel = New-Object System.Windows.Forms.Label
$tabVMwarePassLabel.Location = New-Object System.Drawing.Size(($tabxstart +145),$tabystart)
$tabVMwarePassLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabVMwarePassLabel.Text = "Password"
$tabCRGVMware.Controls.Add($tabVMwarePassLabel)

$tabVMwareIP1Label = New-Object System.Windows.Forms.Label
$tabVMwareIP1Label.Location = New-Object System.Drawing.Size(($tabxstart +290),$tabystart) 
$tabVMwareIP1Label.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabVMwareIP1Label.Text = "IP Address"
$tabCRGVMware.Controls.Add($tabVMwareIP1Label)

$tabVMWareOptionLabel = New-Object System.Windows.Forms.Label
$tabVMWareOptionLabel.Location = New-Object System.Drawing.Size(($tabxstart+380),$tabystart) 
$tabVMWareOptionLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabVMWareOptionLabel.Text = "Option"
$tabCRGVMware.Controls.Add($tabVMWareOptionLabel)

$tabVMWareDefaultCredLabel = New-Object System.Windows.Forms.Label
$tabVMWareDefaultCredLabel.Location = New-Object System.Drawing.Size(($tabxstart+600),$tabystart) 
$tabVMWareDefaultCredLabel.Size = New-Object System.Drawing.Size(($tabxsize+30),$tabysize) 
$tabVMWareDefaultCredLabel.Text = "Default Credentials"
$tabCRGVMware.Controls.Add($tabVMWareDefaultCredLabel)

$tabystart += 25

$vCenter1CheckBox = New-Object System.Windows.Forms.CheckBox
$vCenter1CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart)) 
$vCenter1CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$vCenter1CheckBox.Text = "vCenter 1"
$tabCRGVMware.Controls.Add($vCenter1CheckBox)

$vc1userTextBox = New-Object System.Windows.Forms.TextBox 
$vc1userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart)) 
$vc1userTextBox.Size = New-Object System.Drawing.Size(140,20)
$vc1userTextBox.Text = "administrator@vsphere.local"
$VC1userTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($vc1userTextBox)

$vc1passwordTextBox = New-Object System.Windows.Forms.TextBox 
$vc1passwordTextBox.Location = New-Object System.Drawing.Size(265,($tabystart)) 
$vc1passwordTextBox.Size = New-Object System.Drawing.Size(140,20)
$vc1passwordTextBox.UseSystemPasswordChar = $true
$vc1passwordTextBox.Text = $regions.item($region)
$vc1passwordTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($vc1passwordTextBox)

$vCenter1TextBox = New-Object System.Windows.Forms.TextBox 
$vCenter1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart)) 
$vCenter1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGVMware.Controls.Add($vCenter1TextBox)

$VC1LogOnCredsCheckBox = New-Object System.Windows.Forms.CheckBox
$VC1LogOnCredsCheckBox.Location = New-Object System.Drawing.Size(505,($tabystart)) 
$VC1LogOnCredsCheckBox.Size = New-Object System.Drawing.Size(200,20) 
$VC1LogOnCredsCheckBox.Text = "Use Windows Credentials"
$VC1LogOnCredsCheckBox.add_click({IF($VC1LogOnCredsCheckBox.checked){$VC1DefaultCheckBox.checked = $False}
                                   IF($vc1usertextbox.readonly -eq $False)
                                   {
                                      $vc1userTextBox.readonly = $true
                                      $vc1userTextBox.text = "$env:userdomain\$env:username"
                                      $vc1passwordTextBox.readonly = $true
                                      $vc1passwordTextBox.Text = ""
                                   }
                                   ELSE
                                   {
                                      $vc1userTextBox.readonly = $false 
                                      $vc1userTextBox.text = ""
                                      $vc1passwordTextBox.readonly = $false
                                   }                                
                                 })
$tabCRGVMware.Controls.Add($VC1LogOnCredsCheckBox)

$VC1DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$VC1DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),$tabystart)
$VC1DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$VC1DefaultCheckBox.Checked = $True
$tabCRGVMware.Controls.Add($VC1DefaultCheckBox)

$VC1DefaultCheckBox.Add_CheckStateChanged({IF($VC1DefaultCheckBox.checked){$VC1LogOnCredsCheckBox.checked = $false}
    IF($VC1DefaultCheckBox.checked)
    {
        $VC1userTextBox.Text     = "administrator@vsphere.local"
        $VC1userTextBox.ReadOnly = $true
        $vc1passwordTextBox.Text     = $regions.item($region)
        $vc1passwordTextBox.ReadOnly = $true
    }
    IF(!$VC1DefaultCheckBox.checked)
    {
        $VC1userTextBox.ReadOnly = $false
        $vc1passwordTextBox.ReadOnly = $false
    }
})

$tabystart += 25

$vCenter2CheckBox = New-Object System.Windows.Forms.CheckBox
$vCenter2CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart)) 
$vCenter2CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$vCenter2CheckBox.Text = "vCenter 2"
$tabCRGVMware.Controls.Add($vCenter2CheckBox)

$vc2userTextBox = New-Object System.Windows.Forms.TextBox 
$vc2userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart)) 
$vc2userTextBox.Size = New-Object System.Drawing.Size(140,20)
$vc2userTextBox.Text = "administrator@vsphere.local"
$VC2userTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($vc2userTextBox)

$vc2passwordTextBox = New-Object System.Windows.Forms.TextBox 
$vc2passwordTextBox.Location = New-Object System.Drawing.Size(265,($tabystart)) 
$vc2passwordTextBox.Size = New-Object System.Drawing.Size(140,20)
$vc2passwordTextBox.Text = $regions.item($region)
$vc2passwordTextBox.UseSystemPasswordChar = $true
$VC2passwordTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($vc2passwordTextBox)

$vCenter2TextBox = New-Object System.Windows.Forms.TextBox 
$vCenter2TextBox.Location = New-Object System.Drawing.Size(410,($tabystart)) 
$vCenter2TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGVMware.Controls.Add($vCenter2TextBox)

$VC2LogOnCredsCheckBox = New-Object System.Windows.Forms.CheckBox
$VC2LogOnCredsCheckBox.Location = New-Object System.Drawing.Size(505,($tabystart)) 
$VC2LogOnCredsCheckBox.Size = New-Object System.Drawing.Size(200,20) 
$VC2LogOnCredsCheckBox.Text = "Use Windows Credentials"
$VC2LogOnCredsCheckBox.add_click({IF($VC2LogOnCredsCheckBox.checked){$VC2DefaultCheckBox.checked = $False}
                                   IF($vc2usertextbox.readonly -eq $False)
                                   {
                                      $vc2userTextBox.readonly = $true
                                      $vc2userTextBox.text = "$env:userdomain\$env:username"
                                      $vc2passwordTextBox.readonly = $true
                                      $vc2passwordTextBox.Text = ""
                                   }
                                   ELSE
                                   {
                                      $vc2userTextBox.readonly = $false 
                                      $vc2userTextBox.text = ""
                                      $vc2passwordTextBox.readonly = $false
                                   }                                
                                 })
$tabCRGVMware.Controls.Add($VC2LogOnCredsCheckBox)

$VC2DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$VC2DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),$tabystart)
$VC2DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$VC2DefaultCheckBox.Checked = $True
$tabCRGVMware.Controls.Add($VC2DefaultCheckBox)

$VC2DefaultCheckBox.Add_CheckStateChanged({IF($VC2DefaultCheckBox.checked){$VC2LogOnCredsCheckBox.checked = $false}
    IF($VC2DefaultCheckBox.checked)
    {
        $VC2userTextBox.Text     = "administrator@vsphere.local"
        $VC2userTextBox.ReadOnly = $true
        $VC2passwordTextBox.Text     = $regions.item($region)
        $VC2passwordTextBox.ReadOnly = $true
    }
    IF(!$VC2DefaultCheckBox.checked)
    {
        $VC2userTextBox.ReadOnly = $false
        $VC2passwordTextBox.ReadOnly = $false
    }
})

$tabystart += 25

$vCenter3CheckBox = New-Object System.Windows.Forms.CheckBox
$vCenter3CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart)) 
$vCenter3CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$vCenter3CheckBox.Text = "vCenter 3"
$tabCRGVMware.Controls.Add($vCenter3CheckBox)

$vc3userTextBox = New-Object System.Windows.Forms.TextBox 
$vc3userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart)) 
$vc3userTextBox.Size = New-Object System.Drawing.Size(140,20)
$vc3userTextBox.Text = "administrator@vsphere.local"
$VC3userTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($vc3userTextBox)

$vc3passwordTextBox = New-Object System.Windows.Forms.TextBox 
$vc3passwordTextBox.Location = New-Object System.Drawing.Size(265,($tabystart)) 
$vc3passwordTextBox.Size = New-Object System.Drawing.Size(140,20)
$vc3passwordTextBox.Text = $regions.item($region)
$vc3passwordTextBox.UseSystemPasswordChar = $true
$VC3passwordTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($vc3passwordTextBox)

$vCenter3TextBox = New-Object System.Windows.Forms.TextBox 
$vCenter3TextBox.Location = New-Object System.Drawing.Size(410,($tabystart)) 
$vCenter3TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGVMware.Controls.Add($vCenter3TextBox)

$VC3LogOnCredsCheckBox = New-Object System.Windows.Forms.CheckBox
$VC3LogOnCredsCheckBox.Location = New-Object System.Drawing.Size(505,($tabystart)) 
$VC3LogOnCredsCheckBox.Size = New-Object System.Drawing.Size(200,20) 
$VC3LogOnCredsCheckBox.Text = "Use Windows Credentials"
$VC3LogOnCredsCheckBox.add_click({IF($VC3LogOnCredsCheckBox.checked){$VC3DefaultCheckBox.checked = $False}
                                   IF($vc3usertextbox.readonly -eq $False)
                                   {
                                      $vc3userTextBox.readonly = $true
                                      $vc3userTextBox.text = "$env:userdomain\$env:username"
                                      $vc3passwordTextBox.readonly = $true
                                      $vc3passwordTextBox.Text = ""
                                   }
                                   ELSE
                                   {
                                      $vc3userTextBox.readonly = $false 
                                      $vc3userTextBox.text = ""
                                      $vc3passwordTextBox.readonly = $false
                                   }                                
                                 })
$tabCRGVMware.Controls.Add($VC3LogOnCredsCheckBox)

$VC3DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$VC3DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),$tabystart)
$VC3DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$VC3DefaultCheckBox.Checked = $True
$tabCRGVMware.Controls.Add($VC3DefaultCheckBox)

$VC3DefaultCheckBox.Add_CheckStateChanged({IF($VC3DefaultCheckBox.checked){$VC3LogOnCredsCheckBox.checked = $false}
    IF($VC3DefaultCheckBox.checked)
    {
        $VC3userTextBox.Text     = "administrator@vsphere.local"
        $VC3userTextBox.ReadOnly = $true
        $VC3passwordTextBox.Text     = $regions.item($region)
        $VC3passwordTextBox.ReadOnly = $true
    }
    IF(!$VC3DefaultCheckBox.checked)
    {
        $VC3userTextBox.ReadOnly = $false
        $VC3passwordTextBox.ReadOnly = $false
    }
})

$tabystart += 25

$vCenter4CheckBox = New-Object System.Windows.Forms.CheckBox
$vCenter4CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart)) 
$vCenter4CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$vCenter4CheckBox.Text = "vCenter 4"
$tabCRGVMware.Controls.Add($vCenter4CheckBox)

$vc4userTextBox = New-Object System.Windows.Forms.TextBox 
$vc4userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart)) 
$vc4userTextBox.Size = New-Object System.Drawing.Size(140,20)
$vc4userTextBox.Text = "administrator@vsphere.local"
$VC4userTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($vc4userTextBox)

$vc4passwordTextBox = New-Object System.Windows.Forms.TextBox 
$vc4passwordTextBox.Location = New-Object System.Drawing.Size(265,($tabystart)) 
$vc4passwordTextBox.Size = New-Object System.Drawing.Size(140,20)
$vc4passwordTextBox.Text = $regions.item($region)
$vc4passwordTextBox.UseSystemPasswordChar = $true
$VC4passwordTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($vc4passwordTextBox)

$vCenter4TextBox = New-Object System.Windows.Forms.TextBox 
$vCenter4TextBox.Location = New-Object System.Drawing.Size(410,($tabystart)) 
$vCenter4TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGVMware.Controls.Add($vCenter4TextBox)

$VC4LogOnCredsCheckBox = New-Object System.Windows.Forms.CheckBox
$VC4LogOnCredsCheckBox.Location = New-Object System.Drawing.Size(505,($tabystart)) 
$VC4LogOnCredsCheckBox.Size = New-Object System.Drawing.Size(200,20) 
$VC4LogOnCredsCheckBox.Text = "Use Windows Credentials"
$VC4LogOnCredsCheckBox.add_click({IF($VC4LogOnCredsCheckBox.checked){$VC4DefaultCheckBox.checked = $False}
                                   IF($vc4usertextbox.readonly -eq $False)
                                   {
                                      $vc4userTextBox.readonly = $true
                                      $vc4userTextBox.text = "$env:userdomain\$env:username"
                                      $vc4passwordTextBox.readonly = $true
                                      $vc4passwordTextBox.Text = ""
                                   }
                                   ELSE
                                   {
                                      $vc4userTextBox.readonly = $false 
                                      $vc4userTextBox.text = ""
                                      $vc4passwordTextBox.readonly = $false
                                   }                                
                                 })
$tabCRGVMware.Controls.Add($VC4LogOnCredsCheckBox)

$VC4DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$VC4DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),$tabystart)
$VC4DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$VC4DefaultCheckBox.Checked = $True
$tabCRGVMware.Controls.Add($VC4DefaultCheckBox)

$VC4DefaultCheckBox.Add_CheckStateChanged({IF($VC4DefaultCheckBox.checked){$VC4LogOnCredsCheckBox.checked = $false}
    IF($VC4DefaultCheckBox.checked)
    {
        $VC4userTextBox.Text     = "administrator@vsphere.local"
        $VC4userTextBox.ReadOnly = $true
        $VC4passwordTextBox.Text     = $regions.item($region)
        $VC4passwordTextBox.ReadOnly = $true
    }
    IF(!$VC4DefaultCheckBox.checked)
    {
        $VC4userTextBox.ReadOnly = $false
        $VC4passwordTextBox.ReadOnly = $false
    }
})

$tabystart += 25

$vCenter5CheckBox = New-Object System.Windows.Forms.CheckBox
$vCenter5CheckBox.Location = New-Object System.Drawing.Size(5,($tabystart)) 
$vCenter5CheckBox.Size = New-Object System.Drawing.Size(100,20) 
$vCenter5CheckBox.Text = "vCenter 5"
$tabCRGVMware.Controls.Add($vCenter5CheckBox)

$vc5userTextBox = New-Object System.Windows.Forms.TextBox 
$vc5userTextBox.Location = New-Object System.Drawing.Size(120,($tabystart)) 
$vc5userTextBox.Size = New-Object System.Drawing.Size(140,20)
$vc5userTextBox.Text = "administrator@vsphere.local"
$VC5userTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($vc5userTextBox)

$vc5passwordTextBox = New-Object System.Windows.Forms.TextBox 
$vc5passwordTextBox.Location = New-Object System.Drawing.Size(265,($tabystart)) 
$vc5passwordTextBox.Size = New-Object System.Drawing.Size(140,20)
$vc5passwordTextBox.Text = $regions.item($region)
$vc5passwordTextBox.UseSystemPasswordChar = $true
$VC5passwordTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($vc5passwordTextBox)

$vCenter5TextBox = New-Object System.Windows.Forms.TextBox 
$vCenter5TextBox.Location = New-Object System.Drawing.Size(410,($tabystart)) 
$vCenter5TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGVMware.Controls.Add($vCenter5TextBox)

$VC5LogOnCredsCheckBox = New-Object System.Windows.Forms.CheckBox
$VC5LogOnCredsCheckBox.Location = New-Object System.Drawing.Size(505,($tabystart)) 
$VC5LogOnCredsCheckBox.Size = New-Object System.Drawing.Size(200,20) 
$VC5LogOnCredsCheckBox.Text = "Use Windows Credentials"
$VC5LogOnCredsCheckBox.add_click({IF($VC5LogOnCredsCheckBox.checked){$VC5DefaultCheckBox.checked = $False}
                                   IF($vc5usertextbox.readonly -eq $False)
                                   {
                                      $vc5userTextBox.readonly = $true
                                      $vc5userTextBox.text = "$env:userdomain\$env:username"
                                      $vc5passwordTextBox.readonly = $true
                                      $vc5passwordTextBox.Text = ""
                                   }
                                   ELSE
                                   {
                                      $vc5userTextBox.readonly = $false 
                                      $vc5userTextBox.text = ""
                                      $vc5passwordTextBox.readonly = $false
                                   }                                
                                 })
$tabCRGVMware.Controls.Add($VC5LogOnCredsCheckBox)

$VC5DefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$VC5DefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),$tabystart)
$VC5DefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$VC5DefaultCheckBox.Checked = $True
$tabCRGVMware.Controls.Add($VC5DefaultCheckBox)

$VC5DefaultCheckBox.Add_CheckStateChanged({IF($VC5DefaultCheckBox.checked){$VC5LogOnCredsCheckBox.checked = $false}
    IF($VC5DefaultCheckBox.checked)
    {
        $VC5userTextBox.Text     = "administrator@vsphere.local"
        $VC5userTextBox.ReadOnly = $true
        $VC5passwordTextBox.Text     = $regions.item($region)
        $VC5passwordTextBox.ReadOnly = $true
    }
    IF(!$VC5DefaultCheckBox.checked)
    {
        $VC5userTextBox.ReadOnly = $false
        $VC5passwordTextBox.ReadOnly = $false
    }
})

$tabystart += 25

$NSXCheckBox = New-Object System.Windows.Forms.CheckBox
$NSXCheckBox.Location = New-Object System.Drawing.Size(5,($tabystart)) 
$NSXCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$NSXCheckBox.Text = "NSX"
$tabCRGVMware.Controls.Add($NSXCheckBox)

$NSXuserTextBox = New-Object System.Windows.Forms.TextBox 
$NSXuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart)) 
$NSXuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$NSXuserTextBox.Text = "admin"
$NSXuserTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($NSXuserTextBox)

$NSXpasswordTextBox = New-Object System.Windows.Forms.TextBox 
$NSXpasswordTextBox.Location = New-Object System.Drawing.Size(265,($tabystart)) 
$NSXpasswordTextBox.Size = New-Object System.Drawing.Size(140,20)
$NSXpasswordTextBox.Text = $regions.item($region)
$NSXpasswordTextBox.UseSystemPasswordChar = $true
$NSXpasswordTextBox.ReadOnly = $true
$tabCRGVMware.Controls.Add($NSXpasswordTextBox)

$NSXIPTextBox = New-Object System.Windows.Forms.TextBox 
$NSXIPTextBox.Location = New-Object System.Drawing.Size(410,($tabystart)) 
$NSXIPTextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGVMware.Controls.Add($NSXIPTextBox)

$NSXDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$NSXDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),$tabystart)
$NSXDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$NSXDefaultCheckBox.Checked = $True
$tabCRGVMware.Controls.Add($NSXDefaultCheckBox)

$NSXDefaultCheckBox.Add_CheckStateChanged({
    IF($NSXDefaultCheckBox.checked)
    {
        $NSXuserTextBox.Text     = "admin"
        $NSXuserTextBox.ReadOnly = $true
        $NSXpasswordTextBox.Text     = $regions.item($region)
        $NSXpasswordTextBox.ReadOnly = $true
    }
    IF(!$NSXDefaultCheckBox.checked)
    {
        $NSXuserTextBox.ReadOnly = $false
        $NSXpasswordTextBox.ReadOnly = $false
    }
})

#endregion tabCRGVMware

#region tabCRGMISC

$tabystart = 10

$tabCRGMISC = New-Object System.Windows.Forms.TabPage
$tabCRGMISC.UseVisualStyleBackColor = $True
$tabCRGMISC.Text = "MISC"
$tabctrlCRG.TabPages.Add($tabCRGMISC)

$tabMISCUserLabel = New-Object System.Windows.Forms.Label
$tabMISCUserLabel.Location = New-Object System.Drawing.Size($tabxstart,$tabystart) 
$tabMISCUserLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabMISCUserLabel.Text = "Username"
$tabCRGMISC.Controls.Add($tabMISCUserLabel)

$tabMISCPassLabel = New-Object System.Windows.Forms.Label
$tabMISCPassLabel.Location = New-Object System.Drawing.Size(($tabxstart +145),$tabystart)
$tabMISCPassLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabMISCPassLabel.Text = "Password"
$tabCRGMISC.Controls.Add($tabMISCPassLabel)

$tabMISCIP1Label = New-Object System.Windows.Forms.Label
$tabMISCIP1Label.Location = New-Object System.Drawing.Size(($tabxstart +290),$tabystart) 
$tabMISCIP1Label.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabMISCIP1Label.Text = "IP Address 1"
$tabCRGMISC.Controls.Add($tabMISCIP1Label)

$tabMISCIP2Label = New-Object System.Windows.Forms.Label
$tabMISCIP2Label.Location = New-Object System.Drawing.Size(($tabxstart +385),$tabystart)
$tabMISCIP2Label.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabMISCIP2Label.Text = "IP Address 2"
$tabCRGMISC.Controls.Add($tabMISCIP2Label)

$tabMISCOptionLabel = New-Object System.Windows.Forms.Label
$tabMISCOptionLabel.Location = New-Object System.Drawing.Size(($tabxstart+480),$tabystart) 
$tabMISCOptionLabel.Size = New-Object System.Drawing.Size($tabxsize,$tabysize) 
$tabMISCOptionLabel.Text = "Option"
$tabCRGMISC.Controls.Add($tabMISCOptionLabel)

$tabMISCDefaultCredLabel = New-Object System.Windows.Forms.Label
$tabMISCDefaultCredLabel.Location = New-Object System.Drawing.Size(($tabxstart+600),$tabystart) 
$tabMISCDefaultCredLabel.Size = New-Object System.Drawing.Size(($tabxsize+30),$tabysize) 
$tabMISCDefaultCredLabel.Text = "Default Credentials"
$tabCRGMISC.Controls.Add($tabMISCDefaultCredLabel)

$tabystart += 25

$IPICheckBox = New-Object System.Windows.Forms.CheckBox
$IPICheckBox.Location = New-Object System.Drawing.Size(5,($tabystart)) 
$IPICheckBox.Size = New-Object System.Drawing.Size(100,20) 
$IPICheckBox.Text = "IPI"
$tabCRGMISC.Controls.Add($IPICheckBox)

$IPIuserTextBox = New-Object System.Windows.Forms.TextBox 
$IPIuserTextBox.Location = New-Object System.Drawing.Size(120,($tabystart)) 
$IPIuserTextBox.Size = New-Object System.Drawing.Size(140,20)
$IPIuserTextBox.Text = "admin"
$IPIuserTextBox.ReadOnly = $true
$tabCRGMISC.Controls.Add($IPIuserTextBox)

$IPIpasswordTextBox = New-Object System.Windows.Forms.TextBox 
$IPIpasswordTextBox.Location = New-Object System.Drawing.Size(265,($tabystart)) 
$IPIpasswordTextBox.Size = New-Object System.Drawing.Size(140,20)
$IPIpasswordTextBox.UseSystemPasswordChar = $true
$IPIpasswordTextBox.Text = "acadia"
$IPIpasswordTextBox.ReadOnly = $true
$tabCRGMISC.Controls.Add($IPIpasswordTextBox)

$IPIIP1TextBox = New-Object System.Windows.Forms.TextBox 
$IPIIP1TextBox.Location = New-Object System.Drawing.Size(410,($tabystart)) 
$IPIIP1TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGMISC.Controls.Add($IPIIP1TextBox)

$IPIIP2TextBox = New-Object System.Windows.Forms.TextBox 
$IPIIP2TextBox.Location = New-Object System.Drawing.Size(505,($tabystart)) 
$IPIIP2TextBox.Size = New-Object System.Drawing.Size(90,20)
$tabCRGMISC.Controls.Add($IPIIP2TextBox)

$IPIRangeCheckBox = New-Object System.Windows.Forms.CheckBox
$IPIRangeCheckBox.Location = New-Object System.Drawing.Size(605,$tabystart)
$IPIRangeCheckBox.Size = New-Object System.Drawing.Size(100,20) 
$IPIRangeCheckBox.Text = "Range?"
$tabCRGMISC.Controls.Add($IPIRangeCheckBox)

$IPIDefaultCheckBox = New-Object System.Windows.Forms.CheckBox
$IPIDefaultCheckBox.Location = New-Object System.Drawing.Size(($tabxstart+610),$tabystart)
$IPIDefaultCheckBox.Size = New-Object System.Drawing.Size(100,20)
$IPIDefaultCheckBox.Checked = $True
$tabCRGMISC.Controls.Add($IPIDefaultCheckBox)

$IPIDefaultCheckBox.Add_CheckStateChanged({
    IF($IPIDefaultCheckBox.checked)
    {
        $IPIuserTextBox.Text     = "admin"
        $IPIuserTextBox.ReadOnly = $true
        $IPIpasswordTextBox.Text     = "acadia"
        $IPIpasswordTextBox.ReadOnly = $true
    }
    IF(!$IPIDefaultCheckBox.checked)
    {
        $IPIuserTextBox.ReadOnly = $false
        $IPIpasswordTextBox.ReadOnly = $false
    }
})

#endregion tabCRGMISC

#region tabCRGOffline

$tabCRGOffline = New-Object System.Windows.Forms.TabPage
$tabCRGOffline.UseVisualStyleBackColor = $True
$tabCRGOffline.Text = "Offline"
$tabCRGOffline.AutoScroll = $true
$tabctrlCRG.TabPages.Add($tabCRGOffline)

$networkswitches = @{
    "Nexus Switch 1" = "Nexus Management"
    "Nexus Switch 2" = "Nexus Aggregate"
    "Nexus Switch 3" = "Nexus BRS"
    "Nexus Switch 4" = "Nexus Isilon"
    "Nexus Switch 5" = "Nexus Core" 
}

$tabCRGOfflinedatagrid = New-Object System.Windows.Forms.DataGridView
$tabCRGOfflinedatagrid.location = New-Object System.Drawing.Size(2,2)
$tabCRGOfflinedatagrid.Size     = New-Object System.Drawing.Size($tabCRGOffline.Width,$tabCRGOffline.Height)
$tabCRGOfflinedatagrid.ReadOnly = $True
$tabCRGOfflinedatagrid.AllowUserToAddRows = $false
$tabCRGOfflinedatagrid.AllowUserToDeleteRows = $false
$tabCRGOfflinedatagrid.Anchor = "Right,Left,Top,Bottom"
$tabCRGOffline.Controls.Add($tabCRGOfflinedatagrid)

$tabCRGOfflinedatagrid.ColumnHeadersVisible = $false
$tabCRGOfflinedatagrid.RowHeadersVisible    = $false

$tabCRGOfflinedatagridcol1 = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$tabCRGOfflinedatagridcol2 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$tabCRGOfflinedatagridcol3 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$tabCRGOfflinedatagridcol4 = New-Object System.Windows.Forms.DataGridViewButtonColumn

$tabCRGOfflinedatagridcol1.Width = "50"
$tabCRGOfflinedatagridcol2.Width = "120"
$tabCRGOfflinedatagridcol3.Width = "805"
$tabCRGOfflinedatagridcol4.Width = "60"

$tabCRGOfflinedatagrid.Columns.AddRange($tabCRGOfflinedatagridcol1,$tabCRGOfflinedatagridcol2,$tabCRGOfflinedatagridcol3,$tabCRGOfflinedatagridcol4)

ForEach($psscript in $arraypsscripts)
{
    $i = 1
    do
    {
        IF($psscript.Instance -eq 1)
        {
            $tabCRGOfflinedatagrid.Rows.Add($false,$psscript.alias,"","Browse") | Out-Null
        }
        ELSE
        {
            IF($psscript.alias -like "Nexus*")
            {
                $tabCRGOfflinedatagrid.Rows.Add($false,$networkswitches[$psscript.alias + " $i"],"","Browse") | Out-Null
            }
            ELSE
            {
                $tabCRGOfflinedatagrid.Rows.Add($false,($psscript.alias + " $i"),"","Browse") | Out-Null
            }
        }            
        $i++
    }while($i -le $psscript.Instance)
}

$tabCRGOfflinedatagrid.add_cellclick({

    IF($_.ColumnIndex -eq 0)
    {
        IF($tabCRGOfflinedatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $false){$tabCRGOfflinedatagrid.Rows[$_.RowIndex].Cells[0].Value = $true}
        ELSEIF($tabCRGOfflinedatagrid.Rows[$_.RowIndex].Cells[0].Value -eq $true){$tabCRGOfflinedatagrid.Rows[$_.RowIndex].Cells[0].Value = $false}
    }

    if($_.ColumnIndex -eq 3)
    {
        $xmlfile       = $tabCRGOfflinedatagrid.Rows[$_.RowIndex].Cells[1].Value

        IF($tabCRGOfflinedatagrid.Rows[$_.RowIndex].Cells[1].Value -eq "VMAX")
        {
            IF(($temp = Get-FileName -initialdirectory $OutputTextBox.Text -filetype 'BIN (*.bin) | *.bin') -ne "")
            {
                $tabCRGOfflinedatagrid.Rows[$_.RowIndex].Cells[2].Value = $temp
                $tabCRGOfflinedatagrid.Rows[$_.RowIndex].Cells[0].Value = $true
            }
        }
        ELSE
        {
            IF(($temp = Get-FileName -initialdirectory $OutputTextBox.Text -filetype 'XML (*.xml) | *.xml') -ne "")
            {
                $tabCRGOfflinedatagrid.Rows[$_.RowIndex].Cells[2].Value = $temp
                $tabCRGOfflinedatagrid.Rows[$_.RowIndex].Cells[0].Value = $true
            }
        }
    }
})

#endregion tabCRGOffline

$vconlinecheckboxes     = $vCenter1CheckBox,$vCenter2CheckBox,$vCenter3CheckBox,$vCenter4CheckBox,$vCenter5CheckBox
$ucsonlinecheckboxes    = $UCS1CheckBox,$UCS2CheckBox,$UCS3CheckBox,$UCS4CheckBox,$UCS5CheckBox
$otheronlinecheckboxes  = $C2XXCheckBox,$3560CheckBox,$3750CheckBox,$3048CheckBox,$55XXCheckBox,$55XX2CheckBox,$55XX3CheckBox,$1000CheckBox,$MDSCheckBox,$N7KCheckBox,
                          $VNXeCheckBox,$UnityCheckBox,$VNXCheckBox,$NASCheckBox,$XtremIOCheckBox,$VPLEXCheckBox,$IsilonCheckBox,$NSXCheckBox,$IPICheckBox

$arrayonlinecheckboxes  = $vconlinecheckboxes,$ucsonlinecheckboxes,$otheronlinecheckboxes
$arrayucscheckboxes     = $ucsonlinecheckboxes
$arrayvccheckboxes      = $vconlinecheckboxes
$arrayothercheckboxes   = $otheronlinecheckboxes

#endregion CRG

#region Settings

$PanelSettings = New-Object System.Windows.Forms.Panel
$PanelSettings.Location = New-Object System.Drawing.Point($MainPanelLocation)
$PanelSettings.Size = New-Object System.Drawing.Size($MainPanelSize)
$PanelSettings.Visible = $false
$PanelSettings.Anchor = "Right,Left,Top,Bottom"
$objForm.Controls.Add($PanelSettings)

$settingsLabel = New-Object System.Windows.Forms.Label
$settingsLabel.Location = New-Object System.Drawing.Size(5,5) 
$settingsLabel.Size = New-Object System.Drawing.Size(120,20) 
$settingsLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",12,1,3,1)
$settingsLabel.Text = "Settings"
$PanelSettings.Controls.Add($settingsLabel)

$tabHost = New-Object System.Windows.Forms.TabControl
$tabHost.Location = New-Object System.Drawing.Size(2,30)
$tabHost.Size     = New-Object System.Drawing.Size($MainPanelWidth,$MainPanelTabHeight)
$tabHost.Anchor   = "Right,Left,Top,Bottom"
$PanelSettings.Controls.Add($tabHost)

$labelxSize = 100
$textboxxSize = 160

#region settingsTab

$tabSettings = New-Object System.Windows.Forms.TabPage
$tabSettings.UseVisualStyleBackColor = $True
$tabSettings.text = "Main"
$tabHost.TabPages.Add($tabSettings)

$i = 0
$labelxSize = 100
$textboxxSize = 115

$settingitialx = 0
$settingitialy = 5

$dns1Label = New-Object System.Windows.Forms.Label
$dns1Label.Location = New-Object System.Drawing.Size($settingitialx,($settingitialy+2+$i)) 
$dns1Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$dns1Label.Text = "Primary DNS"
$tabSettings.Controls.Add($dns1Label)

$dns1TextBox = New-Object System.Windows.Forms.TextBox 
$dns1TextBox.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize),($settingitialy+$i))
$dns1TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20)
$tabSettings.Controls.Add($dns1TextBox)

$dns2Label = New-Object System.Windows.Forms.Label
$dns2Label.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize+$textboxxSize+5),($settingitialy+2+$i)) 
$dns2Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$dns2Label.Text = "Secondary DNS"
$tabSettings.Controls.Add($dns2Label)

$dns2TextBox = New-Object System.Windows.Forms.TextBox 
$dns2TextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+$textboxxSize+5),($settingitialy+$i))
$dns2TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20)

$tabSettings.Controls.Add($dns2TextBox)

$domainLabel = New-Object System.Windows.Forms.Label
$domainLabel.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+($textboxxSize*2)+10),($settingitialy+2+$i))
$domainLabel.Size = New-Object System.Drawing.Size($labelxSize,20) 
$domainLabel.Text = "Domain Name"
$tabSettings.Controls.Add($domainLabel)

$domainTextBox = New-Object System.Windows.Forms.TextBox 
$domainTextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*3)+($textboxxSize*2)+10),($settingitialy+$i))
$domainTextBox.Size = New-Object System.Drawing.Size($textboxxSize,20) 
$tabSettings.Controls.Add($domainTextBox)

$i += 25

$ntp1Label = New-Object System.Windows.Forms.Label
$ntp1Label.Location = New-Object System.Drawing.Size($settingitialx,($settingitialy+2+$i)) 
$ntp1Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$ntp1Label.Text = "First NTP"
$tabSettings.Controls.Add($ntp1Label)

$ntp1TextBox = New-Object System.Windows.Forms.TextBox 
$ntp1TextBox.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize),($settingitialy+$i))
$ntp1TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20)
$tabSettings.Controls.Add($ntp1TextBox)

$ntp2Label = New-Object System.Windows.Forms.Label
$ntp2Label.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize+$textboxxSize+5),($settingitialy+2+$i)) 
$ntp2Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$ntp2Label.Text = "Second NTP"
$tabSettings.Controls.Add($ntp2Label)

$ntp2TextBox = New-Object System.Windows.Forms.TextBox 
$ntp2TextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+$textboxxSize+5),($settingitialy+$i)) 
$ntp2TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20)
$tabSettings.Controls.Add($ntp2TextBox)

$ntp3Label = New-Object System.Windows.Forms.Label
$ntp3Label.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+($textboxxSize*2)+10),($settingitialy+2+$i))
$ntp3Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$ntp3Label.Text = "Third NTP"
$tabSettings.Controls.Add($ntp3Label)

$ntp3TextBox = New-Object System.Windows.Forms.TextBox 
$ntp3TextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*3)+($textboxxSize*2)+10),($settingitialy+$i))
$ntp3TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20)
$tabSettings.Controls.Add($ntp3TextBox)

$i += 25

$syslog1Label = New-Object System.Windows.Forms.Label
$syslog1Label.Location = New-Object System.Drawing.Size($settingitialx,($settingitialy+2+$i)) 
$syslog1Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$syslog1Label.Text = "First Syslog"
$tabSettings.Controls.Add($syslog1Label)

$syslog1TextBox = New-Object System.Windows.Forms.TextBox 
$syslog1TextBox.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize),($settingitialy+$i)) 
$syslog1TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20)
$tabSettings.Controls.Add($syslog1TextBox)

$syslog2Label = New-Object System.Windows.Forms.Label
$syslog2Label.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize+$textboxxSize+5),($settingitialy+2+$i))
$syslog2Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$syslog2Label.Text = "Second Syslog"
$tabSettings.Controls.Add($syslog2Label)

$syslog2TextBox = New-Object System.Windows.Forms.TextBox 
$syslog2TextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+$textboxxSize+5),($settingitialy+$i))  
$syslog2TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20)
$tabSettings.Controls.Add($syslog2TextBox)

$syslog3Label = New-Object System.Windows.Forms.Label
$syslog3Label.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+($textboxxSize*2)+10),($settingitialy+2+$i))
$syslog3Label.Size = New-Object System.Drawing.Size(75,20) 
$syslog3Label.Text = "Third Syslog"
$tabSettings.Controls.Add($syslog3Label)

$syslog3TextBox = New-Object System.Windows.Forms.TextBox 
$syslog3TextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*3)+($textboxxSize*2)+10),($settingitialy+$i))
$syslog3TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20)
$tabSettings.Controls.Add($syslog3TextBox)

$i += 25

$community1Label = New-Object System.Windows.Forms.Label
$community1Label.Location = New-Object System.Drawing.Size($settingitialx,($settingitialy+2+$i)) 
$community1Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$community1Label.Text = "Community 1"
$tabSettings.Controls.Add($community1Label)

$community1TextBox = New-Object System.Windows.Forms.TextBox 
$community1TextBox.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize),($settingitialy+$i)) 
$community1TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20)
$tabSettings.Controls.Add($community1TextBox)

$target1Label = New-Object System.Windows.Forms.Label
$target1Label.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize+$textboxxSize+5),($settingitialy+2+$i))
$target1Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$target1Label.Text = "SNMP Target 1"
$tabSettings.Controls.Add($target1Label)

$target1TextBox = New-Object System.Windows.Forms.TextBox 
$target1TextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+$textboxxSize+5),($settingitialy+$i))  
$target1TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20) 
$tabSettings.Controls.Add($target1TextBox)

$snmpport1Label = New-Object System.Windows.Forms.Label
$snmpport1Label.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+($textboxxSize*2)+10),($settingitialy+2+$i))
$snmpport1Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$snmpport1Label.Text = "SNMP Port 1"
$tabSettings.Controls.Add($snmpport1Label)

$snmpport1TextBox = New-Object System.Windows.Forms.TextBox 
$snmpport1TextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*3)+($textboxxSize*2)+10),($settingitialy+$i)) 
$snmpport1TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20) 
$snmpport1TextBox.Text = "162"
$tabSettings.Controls.Add($snmpport1TextBox)

$i += 25

$community2Label = New-Object System.Windows.Forms.Label
$community2Label.Location = New-Object System.Drawing.Size($settingitialx,($settingitialy+2+$i)) 
$community2Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$community2Label.Text = "Community 2"
$tabSettings.Controls.Add($community2Label)

$community2TextBox = New-Object System.Windows.Forms.TextBox 
$community2TextBox.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize),($settingitialy+$i)) 
$community2TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20)
$tabSettings.Controls.Add($community2TextBox)

$target2Label = New-Object System.Windows.Forms.Label
$target2Label.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize+$textboxxSize+5),($settingitialy+2+$i))
$target2Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$target2Label.Text = "SNMP Target 2"
$tabSettings.Controls.Add($target2Label)

$target2TextBox = New-Object System.Windows.Forms.TextBox 
$target2TextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+$textboxxSize+5),($settingitialy+$i))  
$target2TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20) 
$tabSettings.Controls.Add($target2TextBox)

$snmpport2Label = New-Object System.Windows.Forms.Label
$snmpport2Label.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+($textboxxSize*2)+10),($settingitialy+2+$i))
$snmpport2Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$snmpport2Label.Text = "SNMP Port 2"
$tabSettings.Controls.Add($snmpport2Label)

$snmpport2TextBox = New-Object System.Windows.Forms.TextBox 
$snmpport2TextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*3)+($textboxxSize*2)+10),($settingitialy+$i)) 
$snmpport2TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20) 
$snmpport2TextBox.Text = "162"
$tabSettings.Controls.Add($snmpport2TextBox)

$i += 25

$community3Label = New-Object System.Windows.Forms.Label
$community3Label.Location = New-Object System.Drawing.Size($settingitialx,($settingitialy+2+$i)) 
$community3Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$community3Label.Text = "Community 3"
$tabSettings.Controls.Add($community3Label)

$community3TextBox = New-Object System.Windows.Forms.TextBox 
$community3TextBox.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize),($settingitialy+$i)) 
$community3TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20)
$tabSettings.Controls.Add($community3TextBox)

$target3Label = New-Object System.Windows.Forms.Label
$target3Label.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize+$textboxxSize+5),($settingitialy+2+$i))
$target3Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$target3Label.Text = "SNMP Target 3"
$tabSettings.Controls.Add($target3Label)

$target3TextBox = New-Object System.Windows.Forms.TextBox 
$target3TextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+$textboxxSize+5),($settingitialy+$i))  
$target3TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20) 
$tabSettings.Controls.Add($target3TextBox)

$snmpport3Label = New-Object System.Windows.Forms.Label
$snmpport3Label.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*2)+($textboxxSize*2)+10),($settingitialy+2+$i))
$snmpport3Label.Size = New-Object System.Drawing.Size($labelxSize,20) 
$snmpport3Label.Text = "SNMP Port 3"
$tabSettings.Controls.Add($snmpport3Label)

$snmpport3TextBox = New-Object System.Windows.Forms.TextBox 
$snmpport3TextBox.Location = New-Object System.Drawing.Size(($settingitialx+($labelxSize*3)+($textboxxSize*2)+10),($settingitialy+$i)) 
$snmpport3TextBox.Size = New-Object System.Drawing.Size($textboxxSize,20) 
$snmpport3TextBox.Text = "162"
$tabSettings.Controls.Add($snmpport3TextBox)

$i += 25

$coredumpLabel = New-Object System.Windows.Forms.Label
$coredumpLabel.Location = New-Object System.Drawing.Size($settingitialx,($settingitialy+2+$i)) 
$coredumpLabel.Size = New-Object System.Drawing.Size($labelxSize,20) 
$coredumpLabel.Text = "Core Dump"
$tabSettings.Controls.Add($coredumpLabel)

$coredumpTextBox = New-Object System.Windows.Forms.TextBox 
$coredumpTextBox.Location = New-Object System.Drawing.Size(($settingitialx+$labelxSize),($settingitialy+$i))
$coredumpTextBox.Size = New-Object System.Drawing.Size($textboxxSize,20) 
$tabSettings.Controls.Add($coredumpTextBox)

#endregion settingsTab

#endregion Settings

#region Credentials

$PanelCredentials = New-Object System.Windows.Forms.Panel
$PanelCredentials.Location = New-Object System.Drawing.Point($MainPanelLocation)
$PanelCredentials.Size = New-Object System.Drawing.Size($MainPanelSize)
$PanelCredentials.Anchor = "Right,Left,Top,Bottom"
$PanelCredentials.Visible = $false
$objForm.Controls.Add($PanelCredentials)

#region Credentials Header

$VblockLabel = New-Object System.Windows.Forms.Label
$VblockLabel.Location = New-Object System.Drawing.Size(5,8) 
$VblockLabel.Size = New-Object System.Drawing.Size(130,20) 
$VblockLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",12,1,3,1)
$VblockLabel.Text = "Credentials"
$PanelCredentials.Controls.Add($VblockLabel)

#endregion Credentials Header

#region Credentials Main

$credsGridView = New-Object System.Windows.Forms.DataGridView
$credsGridView.location = New-Object System.Drawing.Size(5,40)
$credsGridView.Size=New-Object System.Drawing.Size(($PanelCredentials.Width - 5),($PanelCredentials.Height - 75))
$credsGridView.Anchor = "Left,Right,Top,Bottom"
$PanelCredentials.Controls.Add($credsGridView)

$credsGridView.ColumnCount = 5
$credsGridView.ColumnHeadersVisible = $true
$credsGridView.Columns[0].Name  = "Device Name"
$credsGridView.Columns[0].width = 200
$credsGridView.Columns[1].Name  = "Hostname"
$credsGridView.Columns[1].width = 200
$credsGridView.Columns[2].Name  = "IP Address"
$credsGridView.Columns[2].width = 90
$credsGridView.Columns[3].Name  = "Username"
$credsGridView.Columns[3].width = 175
$credsGridView.columns[4].Name  = "Password"
$credsGridView.columns[4].Width = 175

#endregion Credentials Main

#region Credentials Footer

$buttonImport          = New-Object System.Windows.Forms.Button
$buttonImport.Name     = "ImportLCS"
$buttonImport.Location = New-Object System.Drawing.Point(0,($PanelCredentials.Height - ($buttonimport.Height) -5))
$buttonImport.Size     = New-Object System.Drawing.Point(100,22)
$buttonImport.Left     = 5
$buttonImport.Anchor   = "Left,Bottom"
$buttonImport.Text     = "Import LCS"
$buttonImport.add_click({import-lcs})
$PanelCredentials.Controls.Add($buttonImport)

$buttonClear          = New-Object System.Windows.Forms.Button
$buttonClear.Name     = "ClearDataGrid"
$buttonClear.Location = New-Object System.Drawing.Point(0,($PanelCredentials.Height - ($buttonClear.Height) -5))
$buttonClear.Size     = New-Object System.Drawing.Point(100,22)
$buttonClear.Left     = ($buttonClear.Width + 5)
$buttonClear.Anchor   = "Left,Bottom"
$buttonClear.Text     = "Clear DataGrid"
$buttonClear.add_click({$credsGridView.ColumnCount = 5; $credsGridView.Rows.Clear()})
$PanelCredentials.Controls.Add($buttonClear)

$buttonHostsFile          = New-Object System.Windows.Forms.Button
$buttonHostsFile.Name     = "HostsFile"
$buttonHostsFile.Location = New-Object System.Drawing.Point(($PanelCredentials.Width - ($buttonHostsFile.Width*4)-35*4),($PanelCredentials.Height - ($buttonHostsFile.Height) -5))
$buttonHostsFile.Size     = New-Object System.Drawing.Point(110,22)
$buttonHostsFile.Anchor   = "Right,Bottom"
$buttonHostsFile.Text     = "Create Hosts File"
$buttonHostsFile.add_click({create-hostsfile})
$PanelCredentials.Controls.Add($buttonHostsFile)

$buttonPingTest          = New-Object System.Windows.Forms.Button
$buttonPingTest.Name     = "PingTest"
$buttonPingTest.Location = New-Object System.Drawing.Point(($PanelCredentials.Width - ($buttonPingTest.Width*3) -35*3),($PanelCredentials.Height - ($buttonPingTest.Height) -5))
$buttonPingTest.Size     = New-Object System.Drawing.Point(110,22)
$buttonPingTest.Anchor   = "Right,Bottom"
$buttonPingTest.Text     = "Test Connection"
$buttonPingTest.add_click({ping-test})
$PanelCredentials.Controls.Add($buttonPingTest)

$buttonExportXLS          = New-Object System.Windows.Forms.Button
$buttonExportXLS.Name     = "ExportXLS"
$buttonExportXLS.Location = New-Object System.Drawing.Point(($PanelCredentials.Width - ($buttonExportXLS.Width*2) -35*2),($PanelCredentials.Height - ($buttonExportXLS.Height) -5))
$buttonExportXLS.Size     = New-Object System.Drawing.Point(110,22)
$buttonExportXLS.Anchor   = "Right,Bottom"
$buttonExportXLS.Text     = "Create Credentials"
$buttonExportXLS.add_click({create-credentials})
$PanelCredentials.Controls.Add($buttonExportXLS)

$buttonExportTXT          = New-Object System.Windows.Forms.Button
$buttonExportTXT.Name     = "ExportTXT"
$buttonExportTXT.Location = New-Object System.Drawing.Point((($PanelCredentials.Width - ($buttonExportTXT.Width) -35),($PanelCredentials.Height - ($buttonExportTXT.Height) -5)))
$buttonExportTXT.Size     = New-Object System.Drawing.Point(110,22)
$buttonExportTXT.Anchor   = "Right,Bottom"
$buttonExportTXT.Text     = "Export TXT"
$buttonExportTXT.add_click({

$export = export-credentials | Select-Object Device,Hostname,IP | Format-Table -AutoSize | Out-String

$primarydns   = $dns1TextBox.Text
$secondarydns = $dns2TextBox.Text
$primaryntp   = $ntp1TextBox.Text
$secondaryntp = $ntp2TextBox.Text
$syslog1      = $syslog1TextBox.Text
$syslog2      = $syslog2textbox.Text
$syslog3      = $syslog3TextBox.text
$community    = $community1TextBox.Text
$snmp1        = $target1TextBox.Text  
$snmp2        = $target2TextBox.Text
$snmp3        = $target3TextBox.Text
$domain       = $domainTextBox.Text

$text =
@"
Components
---------------------
$export
Settings
---------------------
Primary DNS:   $primarydns
Secondary DNS: $secondarydns
Primary NTP:   $primaryntp
Secondary NTP: $secondaryntp
Syslog 1:      $syslog1
Syslog 2:      $syslog2
Syslog 3:      $syslog3
Community:     $community
SNMP 1:        $snmp1
SNMP 2:        $snmp2
SNMP 3:        $snmp3
Domain Name:   $domain
"@

$text | Out-File ($OutputTextBox.text + "\exportlcs.txt")

write-host ("Export Text to " + $OutputTextBox.text + "\exportlcs.txt Complete")

})

$PanelCredentials.Controls.Add($buttonExportTXT)

#endregion Credentials Footer

#endregion Credentials

#region Version

$PanelVersion = New-Object System.Windows.Forms.Panel
$PanelVersion.Location = New-Object System.Drawing.Point($MainPanelLocation)
$PanelVersion.Size = New-Object System.Drawing.Size($MainPanelSize)
$PanelVersion.Anchor = "Right,Left,Top,Bottom"
$PanelVersion.Visible = $false
$objForm.Controls.Add($PanelVersion)

$VersionLabel = New-Object System.Windows.Forms.Label
$VersionLabel.Location = New-Object System.Drawing.Size(5,5) 
$VersionLabel.Size = New-Object System.Drawing.Size(170,20) 
$VersionLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",12,1,3,1)
$VersionLabel.Text = "Version"
$PanelVersion.Controls.Add($VersionLabel)

$tabCtrlVer = New-Object System.Windows.Forms.TabControl
$tabCtrlVer.Location = New-Object System.Drawing.Size(2,30)
$tabCtrlVer.Size     = New-Object System.Drawing.Size($MainPanelWidth,($MainPanelTabHeight - 30))
$tabCtrlVer.Anchor   = "Right,Left,Top,Bottom"
$PanelVersion.Controls.Add($tabCtrlVer)

#region Version Tab Device

$tabDeviceVer = New-Object System.Windows.Forms.TabPage
$tabDeviceVer.UseVisualStyleBackColor = $True
$tabDeviceVer.Text = "Devices"
$tabCtrlVer.TabPages.Add($tabDeviceVer)

$versionGridView1 = New-Object System.Windows.Forms.DataGridView
$versionGridView1.location = New-Object System.Drawing.Size(2,2)
$versionGridView1.Size     = New-Object System.Drawing.Size(($tabDeviceVer.Width - 5),($tabDeviceVer.Height - 5))
$versionGridView1.ReadOnly = $True
$versionGridView1.AllowUserToAddRows = $false
$versionGridView1.AllowUserToDeleteRows = $false
$versionGridView1.Anchor = "Right,Left,Top,Bottom"
$tabDeviceVer.Controls.Add($versionGridView1)

$versionGridView1.ColumnCount = 6
$versionGridView1.ColumnHeadersVisible = $true
$versionGridView1.RowHeadersVisible    = $false
$versionGridView1.Columns[0].Name = "Device"
$versionGridView1.Columns[0].width = 100
$versionGridView1.Columns[1].Name = "Hostname"
$versionGridView1.Columns[1].width = 170
$versionGridView1.Columns[2].Name = "Model"
$versionGridView1.Columns[2].width = 150
$versionGridView1.Columns[3].Name = "Serial Number"
$versionGridView1.Columns[3].width = 206
$versionGridView1.Columns[4].Name = "Version"
$versionGridView1.Columns[4].width = 130
$versionGridView1.Columns[5].Name = "RCM Version"
$versionGridView1.Columns[5].width = 110

#endregion Version Tab Device

#region Version Tab UCS Blades

$tabUCSVer = New-Object System.Windows.Forms.TabPage
$tabUCSVer.UseVisualStyleBackColor = $True
$tabUCSVer.Text = "UCS Blades"
$tabCtrlVer.TabPages.Add($tabUCSVer)

$versionGridView2 = New-Object System.Windows.Forms.DataGridView
$versionGridView2.location = New-Object System.Drawing.Size(2,2)
$versionGridView2.Size     = New-Object System.Drawing.Size(($tabUCSVer.Width - 5),($tabUCSVer.Height - 5))
$versionGridView2.ReadOnly = $True
$versionGridView2.AllowUserToAddRows = $false
$versionGridView2.AllowUserToDeleteRows = $false
$versionGridView2.Anchor = "Right,Left,Top,Bottom"
$tabUCSVer.Controls.Add($versionGridView2)

$versionGridView2.ColumnCount = 10
$versionGridView2.ColumnHeadersVisible = $true
$versionGridView2.RowHeadersVisible    = $false
$versionGridView2.Columns[0].Name = "UCS Domain"
$versionGridView2.Columns[0].width = 80
$versionGridView2.Columns[1].Name = "Chassis/Slot"
$versionGridView2.Columns[1].width = 70
$versionGridView2.Columns[2].Name = "Model"
$versionGridView2.Columns[2].width = 85
$versionGridView2.Columns[3].Name = "Serial"
$versionGridView2.Columns[4].Name = "CIMC"
$versionGridView2.Columns[4].width = 50
$versionGridView2.Columns[5].Name = "BIOS"
$versionGridView2.Columns[5].width = 170
$versionGridView2.Columns[6].Name = "Adapter(s)FW"
$versionGridView2.Columns[6].width = 170
$versionGridView2.Columns[7].Name = "Adapter(s)SN"
$versionGridView2.Columns[7].width = 170
$versionGridView2.Columns[8].Name = "CPU ID"
$versionGridView2.Columns[8].width = 290
$versionGridView2.Columns[9].Name = "Service Profile"
$versionGridView2.Columns[9].width = 170

#endregion Version Tab UCS Blades

#region Version Tab ESXi Hosts

$tabESXiVer = New-Object System.Windows.Forms.TabPage
$tabESXiVer.UseVisualStyleBackColor = $True
$tabESXiVer.Text = "ESXi"
$tabCtrlVer.TabPages.Add($tabESXiVer)

$versionGridView3 = New-Object System.Windows.Forms.DataGridView
$versionGridView3.location = New-Object System.Drawing.Point(2,2)
$versionGridView3.Size     = New-Object System.Drawing.Size(($tabESXiVer.Width - 5),($tabESXiver.Height - 5))
$versionGridView3.ReadOnly = $True
$versionGridView3.AllowUserToAddRows = $false
$versionGridView3.AllowUserToDeleteRows = $false
$versionGridView3.Anchor = "Right,Left,Top,Bottom"
$tabESXiVer.Controls.Add($versionGridView3)

$versionGridView3.ColumnCount = 7
$versionGridView3.ColumnHeadersVisible = $true
$versionGridView3.RowHeadersVisible    = $false
$versionGridView3.Columns[0].Name = "vCenter"
$versionGridView3.Columns[0].width = 152
$versionGridView3.Columns[1].Name = "ESXi Name"
$versionGridView3.Columns[1].width = 150
$versionGridView3.Columns[2].Name = "Version"
$versionGridView3.Columns[2].width = 144
$versionGridView3.Columns[3].Name = "ENIC"
$versionGridView3.Columns[3].width = 92
$versionGridView3.Columns[4].Name = "FNIC"
$versionGridView3.Columns[4].width = 94
$versionGridView3.Columns[5].Name = "PPVE"
$versionGridView3.Columns[5].width = 116
$versionGridView3.Columns[6].Name = "VEM"
$versionGridView3.Columns[6].width = 118

#endregion Version Tab ESXi Hosts

#region Version Footer

$buttonExportEXCEL          = New-Object System.Windows.Forms.Button
$buttonExportEXCEL.Name     = "VersiontoEXCEL"
$buttonExportEXCEL.Location = New-Object System.Drawing.Point(($PanelVersion.Width - ($buttonExportEXCEL.Width) -75),($PanelVersion.Height - ($buttonExportEXCEL.Height) -5))
$buttonExportEXCEL.Size     = New-Object System.Drawing.Point(150,22)
$buttonExportEXCEL.Anchor   = "Right,Bottom"
$buttonExportEXCEL.Text     = "EXCEL Version RPT"
$buttonExportEXCEL.add_click(
{
    IF($vercustRadio.Checked){$VersionType =  "Original"}
    ELSEIF($veraddenradio.Checked){$VersionType = "Addendum"}
    
    IF($dropdownsystype.SelectedItem.ToString() -ne "System Type"){$systemmodel = $dropdownsystype.SelectedItem.ToString()}ELSE{$systemmodel = $null}
    IF($dropdownrcm.SelectedItem.ToString() -ne "RCM Version"){$systemrcm = $dropdownrcm.SelectedItem.ToString()}ELSE{$systemrcm = $null}
    
    & $PS_Version -ReportXmlFiles (collect-xmldata -xmlfiles offline) -OutputPath $OutputTextBox.Text -outputtype "Excel" -VBID $SerialNumberTextBox.Text -scrubbed:([System.Convert]::ToBoolean($SCRUBDATA)) `
                  -SystemModel $systemmodel `
                  -SystemRCM $systemrcm `
                  -VersionType $VersionType
})
$PanelVersion.Controls.Add($buttonExportEXCEL)

$buttonExportHTML          = New-Object System.Windows.Forms.Button
$buttonExportHTML.Name     = "VersiontoHTML"
$buttonExportHTML.Location = New-Object System.Drawing.Point(($PanelVersion.Width - ($buttonExportHTML.Width*2) -75*2),($PanelVersion.Height - ($buttonExportHTML.Height) -5))
$buttonExportHTML.Size     = New-Object System.Drawing.Point(150,22)
$buttonExportHTML.Anchor   = "Right,Bottom"
$buttonExportHTML.Text     = "HTML Version RPT"
$buttonExportHTML.add_click({& $PS_Version -ReportXmlFiles (collect-xmldata -xmlfiles offline) -OutputPath $OutputTextBox.Text -outputtype "HTML" -VBID $SerialNumberTextBox.Text -scrubbed:([System.Convert]::ToBoolean($SCRUBDATA))})
$PanelVersion.Controls.Add($buttonExportHTML)

$buttonExportTXT          = New-Object System.Windows.Forms.Button
$buttonExportTXT.Name     = "Refresh"
$buttonExportTXT.Location = New-Object System.Drawing.Point(($PanelVersion.Width - ($buttonExportTXT.Width*3) -75*3),($PanelVersion.Height - ($buttonExportTXT.Height) -5))
$buttonExportTXT.Size     = New-Object System.Drawing.Point(150,22)
$buttonExportTXT.Anchor   = "Right,Bottom"
$buttonExportTXT.Text     = "Refresh"
$buttonExportTXT.add_click({$versionGridView1.Rows.Clear(); $versionGridView2.Rows.Clear(); $versionGridView3.Rows.Clear(); import-version; check-versions})
$PanelVersion.Controls.Add($buttonExportTXT)

#endregion Version Footer

#endregion Version

#region Reports

$PanelReport          = New-Object System.Windows.Forms.Panel
$PanelReport.Location = New-Object System.Drawing.Point($MainPanelLocation)
$PanelReport.Size     = New-Object System.Drawing.Size($MainPanelSize)
$PanelReport.Visible  = $false
$PanelReport.Anchor   = "Right,Left,Top,Bottom"
$objForm.Controls.Add($PanelReport)

$reportLabel = New-Object System.Windows.Forms.Label
$reportLabel.Location = New-Object System.Drawing.Size(5,5) 
$reportLabel.Size = New-Object System.Drawing.Size(120,20) 
$reportLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",12,1,3,1)
$reportLabel.Text = "Reports"
$PanelReport.Controls.Add($reportLabel)

$tabReport = New-Object System.Windows.Forms.TabControl
$tabReport.Location = New-Object System.Drawing.Size(2,30)
$tabReport.Size     = New-Object System.Drawing.Size($MainPanelWidth,$MainPanelTabHeight)
$tabReport.Anchor   = "Right,Left,Top,Bottom"
$PanelReport.Controls.Add($tabReport)

$labelxSize = 100
$textboxxSize = 160

#region ReportTab

$tabReports = New-Object System.Windows.Forms.TabPage
$tabReports.UseVisualStyleBackColor = $True
$tabReports.text = "Reports"
$tabReport.TabPages.Add($tabReports)

$reportGridView          = New-Object System.Windows.Forms.DataGridView
$reportGridView.location = New-Object System.Drawing.Size(2,2)
$reportGridView.Size     = New-Object System.Drawing.Size(($tabReport.Width-5),($tabreport.Height-5))

$reportGridView.AllowUserToAddRows    = $false
$reportgridview.AllowUserToDeleteRows = $false
$reportGridView.RowHeadersVisible     = $false
$reportGridView.Anchor = "Right,Left,Top,Bottom"
$tabReports.Controls.Add($reportGridView)

$reportGridView.ColumnHeadersVisible = $false
$reportGridView.RowHeadersVisible    = $false

$reportGridViewcol1 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$reportGridViewcol2 = New-Object System.Windows.Forms.DataGridViewTextboxColumn
$reportGridViewcol3 = New-Object System.Windows.Forms.DataGridViewButtonColumn

$reportGridViewcol1.Width = "150"
$reportGridViewcol2.Width = "570"
$reportGridViewcol3.Width = "150"

$reportGridView.Columns.AddRange($reportGridViewcol1,$reportGridViewcol2,$reportGridViewcol3)

ForEach($rpscript in $arrayrpscripts)
{
    $reportGridView.Rows.Add($rpscript.Name,$rpscript.Description,"Run") | out-null
}

$reportGridView.add_cellclick(
{
    IF($_.ColumnIndex -eq 2)
    {
        $rpscriptname = $reportGridView.Rows[$_.RowIndex].Cells[0].Value

        IF($rpscriptname -eq "BladeSummary")
        {
            run-bladesummary
        }

        IF($rpscriptname -eq "PortMap")
        {
            run-portmapreport
        }

        IF($rpscriptname -eq "Version")
        {
            run-versionreport
        }
        IF($rpscriptname -eq "XtremIO")
        {
            run-xtremioreport
        }
        IF($rpscriptname -eq "Assessment")
        {
            run-assessmentreport
        }
    }
})

#endregion ReportTab

#endregion Reports

#region Assessment

$PanelAssessment          = New-Object System.Windows.Forms.Panel
$PanelAssessment.Location = New-Object System.Drawing.Point($MainPanelLocation)
$PanelAssessment.Size     = New-Object System.Drawing.Size($MainPanelSize)
$PanelAssessment.Visible  = $false
$PanelAssessment.Anchor   = "Right,Left,Top,Bottom"
$objForm.Controls.Add($PanelAssessment)

#region Assessment Header

$assessmentLabel = New-Object System.Windows.Forms.Label
$assessmentLabel.Location = New-Object System.Drawing.Size(5,8) 
$assessmentLabel.Size = New-Object System.Drawing.Size(180,20) 
$assessmentLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",12,1,3,1)
$assessmentLabel.Text = "Health Assessments"
$Panelassessment.Controls.Add($assessmentLabel)

#endregion Assessment Header

#region AssessmentTab

$assessmentGridView = New-Object System.Windows.Forms.DataGridView
$assessmentGridView.location = New-Object System.Drawing.Size(5,40)
$assessmentGridView.Size=New-Object System.Drawing.Size(($PanelAssessment.Width - 5),($PanelAssessment.Height - 75))
$assessmentGridView.ReadOnly = $True
$assessmentGridView.AllowUserToAddRows = $false
$assessmentGridView.AllowUserToDeleteRows = $false
$assessmentGridView.RowHeadersVisible    = $false
$assessmentGridView.Anchor = "Left,Right,Top,Bottom"
$PanelAssessment.Controls.Add($assessmentGridView)

$assessmentGridView.ColumnCount = 5
$assessmentGridView.ColumnHeadersVisible = $true
$assessmentGridView.Columns[0].Name  = "Discipline"
$assessmentGridView.Columns[0].width = 88
$assessmentGridView.Columns[1].Name  = "Component"
$assessmentGridView.Columns[1].width = 130
$assessmentGridView.Columns[2].Name  = "Description"
$assessmentGridView.Columns[2].width = 478
$assessmentGridView.Columns[3].Name  = "Date Checked"
$assessmentGridView.Columns[3].width = 100
$assessmentGridView.columns[4].Name  = "Status"
$assessmentGridView.columns[4].Width = 80

#endregion AssessmentTab

#region Assessment Footer

$buttonAssessmentClear          = New-Object System.Windows.Forms.Button
$buttonAssessmentClear.Name     = "ClearAssessmentDataGrid"
$buttonAssessmentClear.Size     = New-Object System.Drawing.Point(110,22)
$buttonAssessmentClear.Location = New-Object System.Drawing.Point((($PanelAssessment.Width - (($buttonAssessmentClear.Width*2))),($PanelAssessment.Height - ($buttonAssessmentClear.Height) -5)))
$buttonAssessmentClear.Anchor   = "Right,Bottom"
$buttonAssessmentClear.Text     = "Clear DataGrid"
$buttonAssessmentClear.add_click({$AssessmentGridView.Rows.Clear()})
$PanelAssessment.Controls.Add($buttonAssessmentClear)

$buttonAssessmentRun          = New-Object System.Windows.Forms.Button
$buttonAssessmentRun.Name     = "RunAssessment"
$buttonAssessmentRun.Size     = New-Object System.Drawing.Point(110,22)
$buttonAssessmentRun.Location = New-Object System.Drawing.Point((($PanelAssessment.Width - ($buttonAssessmentRun.Width)),($PanelAssessment.Height - ($buttonAssessmentRun.Height) -5)))
$buttonAssessmentRun.Anchor   = "Right,Bottom"
$buttonAssessmentRun.Text     = "Run"
$buttonAssessmentRun.add_click({

        $assessmentGridView.rows.Clear()

        $assessmentdata = get-assessment -ReportXMLFiles (collect-xmldata -xmlfiles offline)

        IF($assessmentdata -ne $null)
        {
            Foreach($item in $assessmentdata)
            {
                $assessmentGridView.Rows.Add($item.discipline,$item.component,$item.description,$item."checked",$item.status) 
            }
        }

    #assessment

    For($i=0;$i -lt $assessmentGridView.RowCount;$i++)
    {
        IF($assessmentGridView.Rows[$i].Cells['Status'].Value -eq "Good")
        {
            $assessmentGridView.Rows[$i].DefaultCellStyle.BackColor = "lightGreen"
            $assessmentGridView.Rows[$i].DefaultCellStyle.ForeColor = "Black"
        }
        ELSEIF($assessmentGridView.Rows[$i].Cells['Status'].Value -eq "Critical")
        {
            $assessmentGridView.Rows[$i].DefaultCellStyle.BackColor = "Red"
            $assessmentGridView.Rows[$i].DefaultCellStyle.ForeColor = "White"
        }
        ELSEIF($assessmentGridView.Rows[$i].Cells['Status'].Value -eq "Recommended")
        {
            $assessmentGridView.Rows[$i].DefaultCellStyle.BackColor = "orange"
            $assessmentGridView.Rows[$i].DefaultCellStyle.ForeColor = "black"
        }
        ELSEIF($assessmentGridView.Rows[$i].Cells['Status'].Value -eq "Warning")
        {
            $assessmentGridView.Rows[$i].DefaultCellStyle.BackColor = "lightYellow"
            $assessmentGridView.Rows[$i].DefaultCellStyle.ForeColor = "Black"
        }
        ELSE
        {
            $assessmentGridView.Rows[$i].DefaultCellStyle.BackColor = "White"
            $assessmentGridView.Rows[$i].DefaultCellStyle.ForeColor = "Black"
        }       
    }
})

$PanelAssessment.Controls.Add($buttonAssessmentRun)

#endregion Assessment Footer

#endregion Assessment

#endregion Panels

# Check Prerequisites
if ($CHECK_PREREQS -eq "true")
{
    $prereq = "true"
    Write-Host "`n**Started checking for 3rd party tools.**"

    $installed = @{}

    IF($psversiontable.psversion.major -ge 3)
    {
        $installed.Add("PowerShell 3","Installed")
    }
    ELSE
    {
        $installed.Add("PowerShell 3","Not Installed")
    }
    Try{
        start-process -erroraction STOP uemcli.exe -WindowStyle Hidden
        $installed.Add("uemcli","Installed")
    }
    Catch{
        $installed.Add("uemcli","Not Installed")
    }
    Try{
        start-process -erroraction STOP naviseccli.exe -WindowStyle Hidden
        $installed.Add("naviseccli","Installed")
    }
    Catch{
        $installed.Add("naviseccli","Not Installed")
    }
    Try{
        start-process -erroraction STOP symcli.exe -WindowStyle Hidden
        $installed.Add("symcli","Installed")
    }
    Catch{
        $installed.Add("symcli","Not Installed")
    }
    IF((get-PsSnapin -registered | ? {$_.Name -eq "VMware.VimAutomation.Core"}) -ne $null)
    {
        $installed.Add("PowerCLI","Installed")
    }
    ELSE
    {
        $installed.Add("PowerCLI","Not Installed")
    }
    Try{
        $net4installed = Get-ItemProperty -path "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -ErrorAction STOP | Select-Object -ExpandProperty Install
        IF($net4installed -eq 1)
        {
            $installed.Add(".net v4","Installed")
        }
        ELSE{$installed.Add(".net v4","Not Installed")}
    }
    Catch{
        $installed.Add(".net v4","Not Installed")
    }    
	Try{
       $telnetConfigFile= "$pwd\Bin\configs\telnet.config"
	   IF(Test-Path $telnetConfigFile) {
			$telnet=ConvertFrom-Json (gc $telnetConfigFile -raw)
			IF($telnet.enabled -eq $TRUE) {
				$python=$telnet.pythonPath

				$cmdoutput=cmd /c $python --version '2>&1'
				$pythonVersion=$cmdoutput.split(" ")[1]
				$vc=$pythonVersion.split(".")
				if($vc[0] -ne 2 -or $vc[1] -ne 7 -or $vc[2] -lt 12) {
					$installed.Add("Python 2.7.12","Not Installed")
				} ELSE {
					$installed.Add("Python $pythonVersion","Installed")
				}
			}
		}
    }
    Catch{
        $installed.Add("Python 2.7.12","Not Installed")
    }    

    ForEach($item in $installed.keys)
    {
		IF($ITEM.length -gt 12) {
			write-host "   $item " -NoNewline
		} ELSE {
			write-host "   $item`t " -NoNewline
		}

        IF($installed[$item] -eq "installed")
        {
            write-host $installed[$item] -ForegroundColor Green}ELSE{Write-Host $installed[$item] -ForegroundColor Red
        }
    }

    Write-Host "**Finished checking for 3rd party tools.**"  
}
else{$prereq = "false"}

#Show Form

IF($panel -eq "Components")     {visible-panel -Panel $PanelCRG}
ELSEIF($panel -eq "Settings")   {visible-panel -Panel $PanelSettings}
ELSEIF($panel -eq "Credentials"){visible-panel -Panel $PanelCredentials}
ELSEIF($panel -eq "Version")    {visible-panel -Panel $PanelVersion}
ELSEIF($panel -eq "Reports")    {visible-panel -Panel $PanelReport}
ELSEIF($panel -eq "Assessment") {visible-panel -Panel $PanelAssessment}

$date = [datetime]::ParseExact($lastupdated, "MMMM %d, yyyy", $null)

IF((get-date) -lt $date.adddays(6999))
{
    IF($SystemConfigFile -ne $null){load-config -SystemConfigFile $SystemConfigFile}
    $objForm.Add_Shown({$objForm.Activate()})
    [void]$objForm.ShowDialog()
}
Else
{
    $message = "CRG is over 30 days old.  Please download the latest version."
    [Windows.Forms.MessageBox]::Show($message, “”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information) 
}