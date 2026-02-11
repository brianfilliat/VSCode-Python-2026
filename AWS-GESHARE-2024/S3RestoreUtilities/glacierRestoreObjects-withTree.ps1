########
#
#   Name: glacierRestoreObjects-Folder.ps1
#   Author: Michael Hultquist
#   Company: CBTS
#   Date: 4/17/2023
#   Purpose: To allow users to restore an entire folder from Glacier including all subfolders and files
#
########

# Import needed libraries

import-module awspowershell
#Add-Type -AssemblyName Microsoft.VisualBasic

# Set GE Credential and Region
``
Set-AWSCredential -ProfileName saml
Set-DefaultAWSRegion -Region us-east-1

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
function groupResultsBy{
# Funciton to take a large arrayas input and create an array of arrays based on the array length provided
# Parameters input the array to be broken up and the amount of items that can be in each smaller array
    param([array]$arrayToGroup, [int]$groupByAmount)

# Variables
    $collectionArray = @()
    $returnArray = @()

# Loop to create the smaller arrays and add them to the return array
    foreach($atg in $arrayToGroup){
        if($collectionArray.Length -le $groupByAmount){
            $collectionArray += $atg
        }
        else{
            $returnArray += ,($collectionArray)
            $collectionArray = @()
            $collectionArray += $atg
        }
    }

# Returns the array or arrays created
    return $returnArray
}
function getTargetBucket{
# Function to locate and retieve all S3 buckets in a specified region
# Parameters to accept input of hte specified region
param( [string]$targetRegion)

# Variables
$targetBucket = get-s3bucket | Out-GridView  -OutputMode Multiple -Title "Choose Target S3 Bucket"
$targetKey    = get-s3object -BucketName $targetBucket.BucketName -region $targetRegion

$restoreArray = @()
$returnValue = @()

$returnValue += $targetBucket.BucketName

# Loop - Formates the S3 bucket data for dispaly to the user
foreach($tk in $targetKey){
    
    if($tk.key.lastindexof("/") -ne -1){
    
        $resultsObject = New-Object -TypeName System.Management.Automation.PSObject -Property ([ordered]@{

        "Key"      = $tk.key.substring(0, $tk.key.lastindexof("/"))
    })

        $restoreArray += $resultsObject
    }


}

$targetKey = $restoreArray.key | Sort-Object | get-unique | out-gridview -OutputMode Multiple -Title "Choose target restore directory"

$returnValue += $targetKey

# Returns the array of S3 buckets in the specified region
return $returnValue
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

    $logFileName = "restoreFromGlacier" + $(get-date -Format 'ddMMyyyy') + ".csv"
    $logFileLocation = "C:\temp\logs\"
    $logFile = $logFileLocation + $logFileName 

    [pscustomobject]@{

        Time = (Get-Date -f g)
        Message = $Message
        Severity = $Severity

    } | Export-Csv -Path $logfile -Append -NoTypeInformation
}

########
# Variables that require user input: Options: USe interactive prompts (default) or add explicit values and update
#
# CHANGE VALUE: The date of the intended object restore
#$compareDate   = "March 30, 2023"
$compareDate =   read-host -Prompt "Please enter the target date of the restore. (FORMAT January 1, 2001)"
#
# CHANGE VALUE: The name of the bucket the object restore needs to be run against
#$bucketName    = ''
$bucketName     = read-host -Prompt "Please enter the name of the S3 Bucket."
#
# CHANGE VALUE:
$bucketPrefix   = read-host -Prompt "Please enter the name of the object bucket prefix with a trailing /."
#
# CHANGE VALUE: The desired location for thelog files for the object restore
$outputList            = "C:\temp\listfiles\RestoreObjectsList" + $(get-date -Format 'ddMMyyyy') + ".csv"
#
# CHANGE VALUE: The region the Storage Gateway resides in
$sGRegion              = Get-AWSRegion -IncludeGovCloud |out-gridview -OutputMode Multiple -Title "Select AWS Region of the Storage Gateway"
#
# CHANGE VALUE: The target bucket and key as collected and identified by the script
$restoreTarget         = getTargetBucket -targetRegion $sGRegion
########

# Variables that require no changes
$wshell          = New-Object -ComObject Wscript.Shell
$workingArray    = @()
$restoreArray    = @()
$selectArray     = @()
$tempArray       = @()
$workingArray    = @()
$completedArray  = @()
$incompleteArray = @()
$jobs            = @()
$jobs2           = @()

$targetBucket  = $restoreTarget[0]
$targetKey     = $restoreTarget[1]

$bucketObjectname  = ""
$cacheRefreshList  = ""
$path              = ""
$restoreInProgress = ""
$finalDestination  = ""
$finalTargetBucket = ""
$sGateway          = ""
$sGatewayName      = ""
$sGatewayShare     = ""
$tempKey           = ""
$tempKey2          = ""
$logPath           = "C:\temp\logs"
$listPath          = "C:\temp\listFiles"

$statusComplete    = 0
$statusJobsCount   = 0
$statusMarker      = 0
$maxthreads        = 0
$counter           = 0
$progress          = 0

$restoreSyncHashTbl  = [hashtable]::Synchronized(@{})
$restoreSyncHashTbl2 = [hashtable]::Synchronized(@{})

$scriptblock1      = {}
$scriptblock2      = {}

# Log Starting

if(!(test-path -Path $logPath)){
    try{
        New-Item -ItemType Directory -Path $logPath
        write-log -Message "Logs folder successfully created" -Severity Information
    }
    catch{
        write-warning -Message "Logs folder failed to create"
        break
    }
}

if(!(test-path -Path $listPath)){
    try{
        New-Item -ItemType Directory -Path $listPath
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

# Retreive object versions to be restored before specified date
try{
    $s3BucketItems = (get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion).Versions | Where-Object {$_.LastModified -le [DateTime]$compareDate}
    write-log -Message "Glacier objects inventory retrieval  @bucketName before $compareDate successful" -Severity Information
}
catch{
    write-log -Message "Glacier objects inventory retrieval  @bucketName failed: $_" -Severity Error
    write-log -Message "Glacier objects inventory retrieval  @bucketName - failed with errors" -Severity Error
    }

try{
    $tempBucketItems = get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion
    write-log -Message "Glacier objects inventory retrieval  @bucketName before $compareDate successful" -Severity Information
}
catch{
    write-log -Message "Glacier objects inventory retrieval  @bucketName failed: $_" -Severity Error
    write-log -Message "Glacier objects inventory retrieval  @bucketName - failed with errors" -Severity Error
}

while($tempBucketItems.IsTruncated -eq "true"){
    
    $counter = $s3BucketItems.count
    Write-Progress -Activity "Retrieving S3 Objects to restore" -Status "$counter objects retrieved ...."
    
    try{
        $nextKey = (get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion -KeyMarker $nextKey).NextKeyMarker
        $s3BucketItems += (get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion -KeyMarker $nextKey).Versions | Where-Object {$_.LastModified -le [DateTime]$compareDate}
        $tempBucketItems = get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion -KeyMarker $nextKey
        write-host $nextKey
        write-log -Message "Glacier objects inventory retrieval  @bucketName before $compareDate successful" -Severity Information
    }
    catch
        {
        write-log -Message "Glacier objects inventory retrieval  @bucketName failed: $_" -Severity Error
        write-log -Message "Glacier objects inventory retrieval  @bucketName - failed with errors" -Severity Error
    }
}

if($nextKey -ne ""){
    try{
        $s3BucketItems += (get-s3version -bucketname $bucketName -Prefix $bucketPrefix -Region $sGRegion -KeyMarker $nextKey).Versions | Where-Object {$_.LastModified -le [DateTime]$compareDate}
        write-log -Message "Glacier objects inventory retrieval  @bucketName before $compareDate successful" -Severity Information
    }
    catch
    {
        write-log -Message "Glacier objects inventory retrieval  @bucketName failed: $_" -Severity Error
        write-log -Message "Glacier objects inventory retrieval  @bucketName - failed with errors" -Severity Error
    }
}

if($s3BucketItems.length -eq 0){
    $wshell.Popup("No objects available to restore in S3 bucket $bucketName/$bucketPrefix",0,"Information",64+0)
    write-log -Message "No objects available to restore in S3 bucke $bucketName/$bucketPrefix" -Severity Information
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

# Second Loop - Creates a custom object to contain all objects to be restored
foreach($entry in $workingArray){

    $progress = ($counter / $workingArray.Count) * 100

    write-progress -Activity "Creating array of Custom PSObjects for restore." -Status "$progress % complete..." -PercentComplete $progress  

    # Conditional to build the S3 path from the key and bucket data
    if($entry.key.Contains("/")){
        
        $path = "/" + $entry.key.Substring(0,$entry.key.LastIndexOf("/"))
    }
    
    else{
        
        $path = ""
    }


    # Builds the custom object used for List Object generation and on screen display of objects to restore
    $resultsObject = New-Object -TypeName System.Management.Automation.PSObject -Property ([ordered]@{

        "File_Name"     = $entry.key.substring($entry.key.lastindexof("/")+1);
        "Location"      = "S3://" + $entry.BucketName + $path;
        "Last_Modified" = [DateTime]$entry.LastModified;
        "Version_ID"    = $entry.VersionId;
        "Is_Latest"     = $entry.IsLatest;
        "Key"           = $entry.key;
        "BucketName"    = $entry.BucketName
    })

    $restoreArray += $resultsObject
    $counter++

}

# Creates GUI representation of objects available to restore and outputs same in CSV to outputList location
$restoreArray | Sort-Object Location | Out-GridView 
$restoreArray | export-csv -Path $outputList

# Creates GUI box to ask for approval to restore objects from displayed list
$answer = $wshell.Popup("Do you want to restore the files listed?",0,"Question",64+4)

# If yes, restores objects, creates log file of objects 
if($answer -eq 6){

$selectArray += $restoreArray

    # Conditional to break the array down into smaller arrays to be run in threads
    if($restoreArray.Length -ge 999){

        $selectArray = groupResultsBy -arrayToGroup $selectArray -groupByAmount 999
    }

    # Initialize runspace pool for running multiple threads
    $MaxThreads   = [math]::Ceiling($selectArray.Count)
    $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $SessionState, $Host)
    $RunspacePool.Open()
    $Jobs = @()

    foreach($sa in $selectArray){
    
        # Synchronized hash table to allow threaded commands to have access to script variables
        $restoreSyncHashTbl = [hashtable]::Synchronized(@{})
        $restoreSyncHashTbl.data = $sa
        $restoreSyncHashTbl.bucketname = $bucketName
        $restoreSyncHashTbl.copyLifetime = "7"

        #variable to contain the code to be run in threads
        $scriptblock1 = {
 
            param($restoreSyncHashTbl)

            $temparray = $restoreSyncHashTbl.data
            
            # Loop to initiate restore for each object selected
            foreach($rsht in $temparray){

                $tempKey = $rsht.Key

                try{ 
                    Restore-S3Object -BucketName $restoreSyncHashTbl.bucketName -Key $rsht.key -CopyLifetimeInDays $restoreSyncHashTbl.copyLifetime -Tier Expedited
                    Write-Host "Restore request for object $tempKey successfully submitted" -ForegroundColor Yellow
                }
                catch{
                    Write-Warning -Message "Restore request for object $tempKey failed: $_"
                    }
            }
        }

        #Create runspace pool and add job to it
        $PowerShell = [powershell]::Create()
        $PowerShell.RunspacePool = $RunspacePool
        $PowerShell.AddScript($scriptblock1).AddArgument($restoreSyncHashTbl) | Out-Null
        $Jobs += $PowerShell.BeginInvoke()

        # Loop to keep track of the running threads
        while ($Jobs.IsCompleted -contains $false) {
            
            Start-Sleep -Milliseconds 100
        }
    }

    # Close first runspace pool
    $RunspacePool.close()

    # Initialize runspace pool for running multiple threads
    $MaxThreads   = [math]::Ceiling($selectArray.Count)
    $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $SessionState, $Host)
    $RunspacePool.Open()
    $Jobs2 = @()

    foreach($sa2 in $selectArray){

        # Synchronized hash table to allow threaded commands to have access to script variables
        $restoreSyncHashTbl2 = [hashtable]::Synchronized(@{})
        $restoreSyncHashTbl2.data = $sa2
        $restoreSyncHashTbl2.bucketname = $bucketName
        $restoreSyncHashTbl2.targetBucket = $targetBucket.BucketName
        $restoreSyncHashTbl2.targetKey = $targetKey

        #variable to contain the code to be run in threads
        $scriptblock2 = {

                param($restoreSyncHashTbl2)

                    $workingArray = @()
                    $completedArray = @()
                    $incompleteArray = @()

                    $workingArray += $restoreSyncHashTbl2.data

                # Loop to check restore status and copy restored objects to the specified location
                while($workingArray.length -ge 1){
                    
                    $completedArray = @()
                    $incompleteArray = @()
                    
                    #Checks the restore status of each object
                    foreach ($a1 in $workingArray){
                        
                        $restoreInProgress = ((get-s3objectmetadata -BucketName $a1.bucketname -key $a1.key).RestoreInProgress)

                        if($restoreInProgress -match "False"){
                
                            $completedArray += $a1
                        }
                        else{
            
                            $incompleteArray += $a1
                        }

                    }
                    $workingArray = @()
                    $workingArray += $incompleteArray

                    #Copies restored object to specified bucket and key
                    foreach($a2 in $completedArray){
                        
                        $tempKey2 = $a2.key
                        $finalDestination = $restoreSyncHashTbl2.targetKey + "/" + $a2.key
                        $finalTargetBucket = $restoreSyncHashTbl2.targetBucket

                        try{
                            Copy-S3Object -BucketName $a2.bucketName -Key $tempKey2 -DestinationBucket $finalTargetBucket -DestinationKey $finalDestination -StorageClass "Standard"
                            Write-Host "Copy restored object $tempKey2 to $finalTargetBucket succeeded" -ForegroundColor Yellow
                        }
                        catch{
                            Write-Warning -Message "Copy restored object $tempKey2 to $finalTargetBucket failed: $_"
                        }
                    }
                }
            }
        
        #Create runspace pool and add job to it
        $PowerShell = [powershell]::Create()
        $PowerShell.RunspacePool = $RunspacePool
        $PowerShell.AddScript($scriptblock2).AddArgument($restoreSyncHashTbl2) | Out-Null
        $Jobs2 += $PowerShell.BeginInvoke()

        # Loop to keep track of running threads and display progress bar
        while ($Jobs2.IsCompleted -contains $false) {
            Start-Sleep -Milliseconds 100
            $statusComplete = ($jobs2 | where-object{$_.iscompleted -match "true"}).count
            $statusJobsCount = $jobs2.Count
            $statusMarker = ($statusComplete/$statusJobsCount) * 100
            write-progress -Activity "Checking restore status and copying to target location ($statusJobsCount Threads : $statusComplete Jobs Complete)" -Status "$statusMarker % Complete" -percentComplete $statusMarker
        }

    }
}
# If no, ends and outputs list of objects located to address
else{

    $wshell.Popup("No changes were made, List File Created: " + $outputList + " For smaller restores use the individual file Glacier restore",0,"Information",64+0)
    write-log -Message "Restore actions completed for S3 bucket $bucketName" -Severity Information
    break
}

$RunspacePool.close()

# Create folder list variable to target cache refresh action

$cacheRefreshList = $targetKey.Substring(0,$targetKey.LastIndexOf("/"))
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
    Invoke-SGCacheRefresh -FileShareARN $sGatewayShare.FileShareARN -region $sGRegion  -FolderList $cacheRefreshList
    $wshell.Popup("Gateway Share $sGatewayShareName on Storage Gateway $sGatewayName cache refresh request completed.  Please see AWS console for more information",0,"Information",64+0)
    write-log -Message "Gateway Share $sGatewayShareName on Storage Gateway $sGatewayName cache refresh request completed." -Severity Information
    write-log -Message "Storage Gateway Share cache refresh request completed successfully" -Severity Information
}
catch{
    Write-Warning -Message "Storage Gateway cache refresh request failed to complete"
    write-log -Message "Storage Gateway Share cache refresh request failed to complete: $_" -Severity Error
    write-log -Message "Storage Gateway Share cache refresh request failed to complete with errors" -Severity Error
}