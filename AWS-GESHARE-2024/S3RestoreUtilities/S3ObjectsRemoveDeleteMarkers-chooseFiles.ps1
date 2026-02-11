########
#
#   Name: S3ObjectsRemoveDeleteMarkers-chooseFiles.ps1
#   Author: Michael Hultquist
#   Company: CBTS
#   Date: 3/29/2023
#   Purpose: To parse a target S3 bucket for versions of objects created before a specified date and allow user to select files to remove delete markers from
#
########

# Import needed libraries

import-module awspowershell
Add-Type -AssemblyName Microsoft.VisualBasic

# Set GE Credential and Region

Set-AWSCredential -ProfileName gov-mfa
Set-DefaultAWSRegion -Region us-gov-east-1

# Functions

function rebuildArray {
# Function to replace an existing array member with an object of the same name with a different LastModified date
# Parameters input the existing array and the item to be inserted
    param ([array]$inputArray,[array]$item)

# Variables
    $returnArray = @()
    $itemDate = $item.LastModified
    $itemName = $item.Key

# Loop 1 - Locates and removes object to be replaced with specified object
    foreach($i in $inputArray){
        
        $inputArrayDate = [DateTime]$i.LastModified
        $inputArrayName = $i.Key
        
        if ($itemName -eq $inputArrayName){
            
            if($itemDate -ge $inputArrayDate){
                
                $returnArray += $item
            }

            else{
                
                $returnArray += $i
            }
        }

        else {
            
            $returnArray += $i    
        }
        
    }

# Returns new array with replaced item
    return [array]$returnArray
}
function write-log {

    [CmdletBinding()]

    param(

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )

    $logFileName = "removeDeleteMarkers" + $(get-date -Format 'ddMMyyyy') + ".csv"
    $logFileLocation = "C:\temp\logs\"
    $logFile = $logFileLocation + $logFileName 

    [pscustomobject]@{

        Time = (Get-Date -f g)
        Message = $Message
        Severity = $Severity

    } | Export-Csv -Path $logfile -Append -NoTypeInformation
}

########
# Variables that require user input: Options: USe interactive prompts (default) or or add explicit values and update
#
# CHANGE VALUE: The date of the intended object restore
#$compareDate = ""
$compareDate =   read-host -Prompt "Pease enter the target date of the restore. (FORMAT January 1, 2001)"
#
# CHANGE VALUE: The name of the bucket the object restore needs to be run against
#$bucketName     = ""
$bucketName     = read-host -Prompt "Pease enter the name of the S3 Bucket."
# CHANGE VALUE:
#$bucketPrefix   = ""
$bucketPrefix   = read-host -Prompt "Pease enter the name of the object bucket prefix with a trailing /."
#
# CHANGE VALUE: The desired location for thelog files for the object restore
$outputList     = "C:\temp\listfiles\DeleteMarkerObjectsList" + $(get-date -Format 'ddMMyyyy') + ".csv"

# CHANGE VALUE: The region the Storage Gateway resides in
#$sGRegion = ""
$sGRegion       = Get-AWSRegion -IncludeGovCloud |out-gridview -OutputMode Multiple -Title "Select AWS Region of the Storage Gateway"
########

# Variables that require no changes
$wshell        = New-Object -ComObject Wscript.Shell
$keyVersions   = @()
$keyVerArray   = @()
$workingArray  = @()
$restoreArray  = @()
$selectArray   = @()

$logpath  = "C:\temp\logs"
$listpath = "C:\temp\listFiles"

$bucketObjectname  = ""
$path              = ""
$sGateway          = ""
$sGatewayName      = ""
$sGatewayShare     = ""
$sGatewayShareName = ""
$cacheRefreshList  = ""

$counter           = 0
$answer            = 0
$progress          = 0

# Log Starting

if(!(test-path -Path $logpath)){
    try{
        New-Item -ItemType Directory -Path $logpath
        write-log -Message "Logs folder successfully created" -Severity Information
    }
    catch{
        write-warning -Message "Logs folder failed to create"
        break
    }
}

if(!(test-path -Path $listpath)){
    try{
        New-Item -ItemType Directory -Path $listpath
        write-log -Message "Lists folder successfully created" -Severity Information
    }
    catch{
        write-warning -Message "Lists folder failed to create"
        break
    }
}

# Adds trailing / if user did not enter it

if(!($bucketPrefix -match "\/$") -and $bucketPrefix -ne ""){
    
    $bucketPrefix = $bucketPrefix + "/"
}

write-log -Message "Restore Starting for S3 Bucket $bucketName"

# Retreive object versions with delete markers on or before specified date
try{
    $s3BucketItems = (get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion -Delimiter '/').Versions | Where-Object {$_.LastModified -lt [DateTime]$compareDate -and $_.IsDeleteMarker -eq "True"}
    write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName before $compareDate successful" -Severity Information
}
catch{
    write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName failed: $_" -Severity Error
    write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName - failed with errors" -Severity Error
    }

try{
    $tempBucketItems = get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion -Delimiter '/'
    write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName before $compareDate successful" -Severity Information
}
catch{
    write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName failed: $_" -Severity Error
    write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName - failed with errors" -Severity Error
}

while($tempBucketItems.IsTruncated -eq "true"){
    
    $counter = $s3BucketItems.count
    Write-Progress -Activity "Retrieving S3 Objects with Delete Markers" -Status "$counter objects retrieved ...."
    
    try{
        $nextKey = (get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion -Delimiter '/' -KeyMarker $nextKey).NextKeyMarker
        $s3BucketItems += (get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion -KeyMarker $nextKey -Delimiter '/').Versions | Where-Object {$_.LastModified -lt [DateTime]$compareDate -and $_.IsDeleteMarker -eq "True"}
        $tempBucketItems = get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion -KeyMarker $nextKey -Delimiter '/'
        write-host $nextKey
        write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName before $compareDate successful" -Severity Information
    }
    catch
        {
        write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName failed: $_" -Severity Error
        write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName - failed with errors" -Severity Error
    }
}

if($nextKey -ne ""){
    try{
        $s3BucketItems += (get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion -KeyMarker $nextKey -Delimiter '/').Versions | Where-Object {$_.LastModified -lt [DateTime]$compareDate -and $_.IsDeleteMarker -eq "True"}
        write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName before $compareDate successful" -Severity Information
    }
    catch
    {
        write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName failed: $_" -Severity Error
        write-log -Message "Object metadata retreival for objects with Delete Markers from S3 Bucket @bucketName - failed with errors" -Severity Error
    }
}

if($s3BucketItems.length -eq 0){
    $wshell.Popup("No objects with delete markers present in s3 bucket $bucketName/$bucketPrefix",0,"Information",64+0)
    write-log -Message "No objects with active delete markers located in specified S3 bucket $bucketName/$bucketPrefix" -Severity Information
    break
}

$counter = 0

# First Loop - Filters results to only include latest version of S3 object before date specified
foreach ($item in $s3BucketItems){
    
    $bucketObjectname = $item.key
    $progress = ($counter / $s3BucketItems.Count) * 100
    
    write-progress -Activity "Selecting only the most recent version of each object." -Status "$progress % complete..." -PercentComplete $progress
    
    if($workingArray.key -notcontains $bucketObjectname){
        
        [array]$workingArray += $item
    }

    if($workingArray.key -contains $bucketObjectname){
        
        [array]$workingArray = rebuildArray -inputArray $workingArray -item $item        
    }    

    $counter++

} 

$counter = 0

# Second Loop - Creates a custom object to contain all objects to have delete markers removed
#               Also creates an array of object keys and version IDs from which to remove delete markers
foreach($entry in $workingArray){

    $progress = ($counter / $workingArray.Count) * 100

    write-progress -Activity "Creating key/version arrays for delete marker removal" -Status "$progress % complete..." -PercentComplete $progress

# Conditional to build the S3 path from the key and bucket data
    if($entry.key.Contains("/")){
        
        $path = "/" + $entry.key.Substring(0,$entry.key.LastIndexOf("/"))
    }
    
    else{
        
        $path = ""
    }
    
# Conditional to build 1000 item Key and Version data to compensate for API limitation
    if($keyversions.length -le 999){
    
        $keyVersions += @{ Key = $entry.Key; VersionId = $entry.VersionId }     
    }
    else{
    
        $keyVerArray += ,$keyVersions
        $keyVersions = @()
    }

# Builds the custom object used for List File generation and on screen display of objects to restore
    $resultsObject = New-Object -TypeName System.Management.Automation.PSObject -Property ([ordered]@{

        "File_Name"     = $entry.key.substring($entry.key.lastindexof("/")+1);
        "Location"      = "S3://" + $entry.BucketName + $path;
        "Last_Modified" = [DateTime]$entry.LastModified;
        "Version_ID"    = $entry.VersionId;
        "Is_Latest"     = $entry.IsLatest;
        "Delete_Marker" = $entry.IsDeleteMarker
    })

    $restoreArray += $resultsObject
    $counter++
}
# Add the final collection of the keyVersions variable to the submission array
$keyVerArray += ,$keyVersions

# Creates GUI selection box to allow users to select files to be recovered
$selectArray +=  $restoreArray | Sort-Object Location | out-gridview -OutputMode Multiple -Title "Select S3 objects to restore."

# Conditional to determine if files were chosen to remove delete markers from and moves to delete request for each 
if($selectArray.Length -ge 1){

# Third Loop - Loops thropugh array of selected items to request deletion of delete marker from each item chosen
    foreach($keyVerSet in $keyVerArray){
        foreach($key in $keyVerSet){
        
            if($selectArray.version_id -contains $key.VersionId){
                try{
                    Remove-S3Object -BucketName $bucketName -KeyAndVersionCollection $key -region $sGRegion -Force
                    write-log -Message "Successfully removed delete marker from specified objects" -Severity Information
                }
                catch{
                    write-warning -Message "Failed to remove delete marker from specified objects.  See CloudWatch Logs for details"
                    write-log -Message "Deletion of delete markers from specified objects failed: $_" -Severity Error
                    write-log -Message "Deletion of delete markers from specified objects failed with errors" -Severity Error
                    write-log -Message "Restore actions not completed for S3 bucket $bucketName" -Severity Error
                }
            }
        }
    }
    
    $wshell.Popup("List File Created: " + $outputList,0,"Information",64+0)
    $selectArray | export-csv -Path $outputList
    write-log -Message "List exported successfullt to location $outputList" -Severity Information
    write-log -Message "Restore actions completed for S3 bucket $bucketName" -Severity Information
}

# If no, ends and outputs list of objects located to address
else{

    $wshell.Popup("No changes were made, List File Created: " + $outputList,0,"Information",64+0)
    write-log -Message "Restore actions completed for S3 bucket $bucketName" -Severity Information
    break
}

# Create folder list variable to target cache refresh action

$cacheRefreshList = $bucketPrefix.Substring(0,$bucketPrefix.LastIndexOf("/"))
$cacheRefreshList = $cacheRefreshList.substring(0,$cacheRefreshList.LastIndexOf("/"))

# Creates GUI of available storage gateways in the specified region and allows user to select the correct gateway from list
try{
    $sGateway = Get-SGGateway -Region $sGRegion | out-gridview -OutputMode Multiple -Title "Select Storage Gateway to Refresh."
    $sGatewayName = $sGateway.GatewayName
    write-log -Message "Storage Gateway $sGatewayName selected to refresh cache" -Severity Information
    write-log -Message "Storage Gateway Enumeration and Selection succeeded." -Severity Information
}
catch{
    write-warning -Message "Storage Gateway enumeration and Selection failed to complete."
    write-log -Message "Storage Gateway Enumeration and Selection failed to complete: $_" -Severity Error
    write-log -Message "Storage Gateway Enumeration and Selection failed to complete with errors" -Severity Error
}

# Creates GUI of available shares on the selected storage gateway and allows user to select which share is to be refreshed in cache
try{
    $sGatewayShare = get-sgfilesharelist -GatewayARN $sGateway.GatewayARN -region $sGRegion| out-gridview -OutputMode Multiple -Title "Select share on Storage Gateway Selected to refresh."
    $sGatewayShareName = $sGatewayShare.FileShareId
    write-log -Message "File Share $sGatewayShareName selected to refresh cache"
    write-log -Message "File Share Enumeration and Selection succeeded"
}
catch{
    write-warning -Message "File Share Enumeration and Seletion failed to complete"
    write-log -Message "File Share Enumeration and Selection failed to complete: $_" -Severity Error
    write-log -Message "File Share Enumeration and Selection failed to complete with errors" -Severity Error
}

#Sends the refresh cache command to the specified share on teh specified storage gateway
try{
    Invoke-SGCacheRefresh -FileShareARN $sGatewayShare.FileShareARN -region $sGRegion -FolderList $cacheRefreshList
    $wshell.Popup("Gateway Share $sGatewayShareName on Storage Gateway $sGatewayName cache refresh request completed.  Please see AWS console for more information",0,"Information",64+0)
    write-log -Message "Gateway Share $sGatewayShareName on Storage Gateway $sGatewayName cache refresh request completed." -Severity Information
    write-log -Message "Storage Gateway Share cache refresh request completed successfully" -Severity Information
}
catch{
    Write-Warning -Message "Storage Gateway cache refresh request failed to complete"
    write-log -Message "Storage Gateway Share cache refresh request failed to complete: $_" -Severity Error
    write-log -Message "Storage Gateway Share cache refresh request failed to complete with errors" -Severity Error
}