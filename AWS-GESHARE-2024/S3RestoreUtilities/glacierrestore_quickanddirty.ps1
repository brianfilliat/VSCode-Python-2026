Set-AWSCredential -ProfileName gov
Set-DefaultAWSRegion -Region us-east-1


foreach($ra in $restoreArray){

    Restore-S3Object -BucketName $ra.bucketName -Key $ra.key -CopyLifetimeInDays 3 -Tier Expedited -Region us-gov-east-1
}

foreach($ra in $restoreArray){

    $destinationKey = $ra.key.Replace("S3KEY","S3KEY+/RESTORE/")
    Copy-S3Object  -Region REGION -BucketName $ra.BucketName -Key $ra.Key -DestinationBucket 'DESTINATIONBUCKET' -DestinationKey $destinationKey -StorageClass "Standard"

}

Invoke-SGCacheRefresh -FileShareARN 'FILESHAREARN' -region us-gov-east-1 -FolderList 'S3KEY'