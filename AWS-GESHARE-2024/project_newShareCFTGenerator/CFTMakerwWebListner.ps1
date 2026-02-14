$website = @"
<HTML>
    <HEAD>
        <section class="header" style="width:100%; padding:60px 0; text-align:center; background: rgb(146, 172, 154); color: white;">
            <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAOEAAADhCAMAAAAJbSJIAAAAWlBMVEX///8paTQmaDE0cD4PXyDAz8IeZizF0scbYynN2c+Go4qMqJA5cUL6/PoGXhwRYCHj6uR4mXzv8/BGe0/C0cR4mnxgimY/dkjU3tZoj26SrZY0bz65ybuww7ImqsoxAAAB4klEQVR4nO3c207CMACAYSgORXSIzBPq+7+mF8YEyWg4lLaM77+FZP12s6WHjUaSJEmSJEmSJP3VNV2dNV0iYWhv6qwNiYSTMK6zMCEkJCwdISFh+QgJCctHSEhYPkJCwvIREsaE07vd5bsfZxSG5ctyZ6/ZiGcUTmN/n90MXXhLSEhISEhISEhISEhISHh9wsh8ziH1T4zUIJzM71M0X/USKxCGVaIhLO8IT4pwK8JjIjwxwq02ZvXD2/ssRe8fuZ+HIfZ43hxNSLQrP/s7TfRlbBCra5VESEhYPkJCwvIREhKWj5DwuoWLSL1TKpcmDM3Xzpp1NmIFc22EhISEhISEhISEhISEhIQDEV7sXoy9dwy9zW5TNOs/W1yDcJh7ogiPifDECLciPKZqhePP9TxF6+znLcKk74K//f/pUs/MjEOk3fjUWSElJCwfISFh+QgJCctHSHjdwjbSYgjC6XOkr2zEGuZpCAkJCQkJCQkJCQkJCQmvRBhbDj+gioUPaapWOPz9NIR7R3hihFsRHlPNwscUjZbTzMLwFOl7436H2BLOAeXfmxgbzSC+/FFJhISE5SMkJCwfISFh+QgJCctHSEhYPsK9C22ir8ykrg2JhF1Ta10ioSRJkiRJkiRpCP0Ag3yifPI9tpYAAAAASUVORK5CYII=" width="150" height="150" style="float:middle">
            <h1>AWS Storage Gateway CFT Utility</h1>
            <p>CloudFormation Templage Generator for New Storage Gateway Shares</p>
        </section>
    </HEAD>
    <BODY class="label">
        <FORM action="http://localhost:5001/" method="POST" enctype="text/plain">
            <table style="width:100%">
                <tr>
                    <th style="width:30%"></th>
                    <th style="width:30%"></th>
                    <th style="width:40%"></th>
                </tr>
                <tr>
                    <td>
                        <label for="description">Enter CloudFormation Template Description:</label> 
                    </td>
                    <td>
                        <input name="description" id="sdescriptionso" size="40" />
                    </td>
                    <td>
                        Example: 'ATC Storage Gateway CFT V1.1'
                    </td>
                </tr>
                <tr>
                    <td>
                        <label for="sso">Enter GE SSO ID:</label>
                    </td>
                    <td>
                        <input name="sso" id="sso" size="40" />
                    </td>
                    <td>
                        Example: 503357265
                    </td>
                </tr>
                <tr>
                    <td>
                        <label for="UAI">Enter UAI for Site:</label>
                    </td>
                    <td>
                        <input name="UAI" id="UAI" size="40" />
                    </td>
                    <td>
                        Example: UAI3037768
                    </td>
                </tr>    
                <tr>
                    <td>
                        <label for="Stack">Enter CloudFormation Stack Name</label> 
                    </td>
                    <td>
                        <input name="Stack" id="Stack" size="40" />
                    </td>
                    <td>
                        Example: cf-atc-sgw-atc-meltpool
                    </td>
                </tr>
                <tr>
                    <td>
                        <label for="Site">Enter Site Name:</label>
                    </td>
                    <td>
                        <input name="Site" id="Site" size="40" />
                    </td>
                    <td>
                        Example: atc
                    </td>
                </tr>
                <tr>
                    <td>
                        <label for="logsBucket">Enter Logs Bucket for Region:</label>
                    </td>
                    <td>
                        <input name="logsBucket" id="logsBucket" size="40" />
                    </td>
                    <td>
                        Example: av-goveast-658233819642-s3-logs
                    </td>
                </tr>  
                <tr>
                    <td>
                        <label for="Share">Enter Name of Share:</label> 
                    </td>
                    <td>
                        <input name="Share" id="Share" size="40" />
                    </td>
                    <td>
                        Example: atc-meltpool
                    </td>
                </tr>
                <tr>
                    <td>
                        <label for="KMSKey">Enter KMS Key Name:</label>
                    </td>
                    <td>
                        <input name="KMSKey" id="KMSKey" size="40" />
                    </td>
                    <td>
                        Example: ATC Storage Gateway KMS key
                    </td>
                </tr>
                <tr>
                    <td>
                        <label for="Alais">Enter Alais Name:</label>
                    </td>
                    <td>
                        <input name="Alais" id="Alais" size="40" />
                    </td>
                    <td>
                        Example: alias/av-useast1-storage-gateway-atc-gwy01-atc-meltpool
                    </td>
                </tr> 
                <tr>
                    <td>
                        <label for="Region">Enter AWS Region:</label>
                    </td>
                    <td>
                        <input name="Region" id="Region" size="40" />
                    </td>
                    <td>
                        Example: us-gov-east-1
                    </td>
                </tr>  
            <div><a><tr><td align="left">
                <button class="button, button1" onClick="myFunction()" type="submit">Generate Template</button>
                <td align="left"></tr>
                <script>
                    function myFunction() {
                        var element = document.getElementById("bodySection");
                        element.classList.toggle("ring");}
                </script></div></FORM></BODY></HTML>
"@
$website | out-file -FilePath "./temp.html"

Invoke-Expression "./temp.html"

$httpListener = New-Object System.Net.HttpListener
$httpListener.Prefixes.Add('http://localhost:5001/')
$httpListener.Start()

while($httpListener.IsListening){
    $context = $httpListener.GetContext()


    $request = $context.Request

    $Reader = New-Object System.IO.StreamReader($request.InputStream)
    $inputs = $Reader.ReadToEnd()

    $inputsArray = $inputs.split([Environment]::NewLine)
    $resultsArray = @()

    if($inputs -ne $Null){

        foreach($ia in $inputsArray){

    if($ia -ne ''){
    $resultsObject = New-Object -TypeName System.Management.Automation.PSObject -Property ([ordered]@{

        "Label" = $ia.substring(0,$ia.indexof("="))
        "Value" = $ia.substring($ia.indexof("=")+1)

        })
    $resultsArray += $resultsObject
    }
}

            $descriptionText = ($resultsArray| where-object {$_.Label -eq "description"}).value
            $ssoText         = ($resultsArray| where-object {$_.Label -eq "sso"}).value
            $uaiText         = ($resultsArray| where-object {$_.Label -eq "UAI"}).value
            $stackNameText   = ($resultsArray| where-object {$_.Label -eq "Stack"}).value
            $siteName        = ($resultsArray| where-object {$_.Label -eq "Site"}).value
            $logsBucket      = ($resultsArray| where-object {$_.Label -eq "logsBucket"}).value
            $shareName       = ($resultsArray| where-object {$_.Label -eq "Share"}).value
            $kmsKeyName      = ($resultsArray| where-object {$_.Label -eq "KMSKey"}).value
            $aliasName       = ($resultsArray| where-object {$_.Label -eq "Alais"}).value
            $region          = ($resultsArray| where-object {$_.Label -eq "Region"}).value

            $cftBody = @"
AWSTemplateFormatVersion: "2010-09-09"
Description: `"$descriptionText`"
Parameters:
  createdBy:
    Default: `"$ssoText`"
    Description: 'Who to email when something goes wrong. This is where your SSO goes'
    Type: String
  uai:
    Default: `"$uaiText`"
    Description: "The UAI used to track billing and costs"
    Type: String
  env:
    Default: "prod"
    Description: 'Environment Label. Must be on of these prod, qa, dev, build, nonprod. Everything also need to be lowercase.'
    Type: String
  stackName:
    Default: `"$stackNameText`"
    Description: 'Must be the name of the stack that this cft is going to apart of. Must be between 1 and 255 characters and cannot start with a number'
    Type: String
  siteName:
    Default: `"$siteName`"
    Type: String
  fileShareName:
    Default: `"$shareName`"
    Type: String
  loggingBucketName:
    Default: `"$logsBucket`"
    Type: String
    Description: "Name of the logging bucket for the S3 Access Logs"
  noncurrentDays:   
    Default: 5
    Type: Number
    Description: "Number of days to retain a noncurrent version of a file"
  noncurrentGlacierDays:
    Default: 90
    Type: Number
    Description: "Number of days to retain a noncurrent version of a file in Gliacier backup directory"
Resources:
  KMSKEY:
    Type: AWS::KMS::Key
    Properties:
      Description: `"$kmsKeyName`"

"@
            $cftBody += @'
      EnableKeyRotation: True
      KeyPolicy:
        Id: key-default-1
        Version: '2012-10-17'
        Statement:
        - Sid: Enable IAM User Permissions
          Effect: Allow
          Principal:
            AWS: !Sub arn:${AWS::Partition}:iam::${AWS::AccountId}:root
          Action: kms:*
          Resource: "*"
        - Sid: Allow access for Key Administrators
          Effect: Allow
          Principal:
            AWS:

'@

if($region.contains("gov") -or $region.Contains("ap-southeast")){
$cftBody += @'
            - !Sub arn:${AWS::Partition}:iam::${AWS::AccountId}:role/av-bu-poweruser

'@
}
else{
$cftBody += @'
            - !Sub arn:${AWS::Partition}:iam::${AWS::AccountId}:role/bu-poweruser

'@

}
$cftBody += @'
            - !Sub arn:${AWS::Partition}:iam::${AWS::AccountId}:role/av-cbts-storage-gateway
          Action:
          - kms:Create*
          - kms:Describe*
          - kms:Enable*
          - kms:List*
          - kms:Put*
          - kms:Update*
          - kms:Revoke*
          - kms:Disable*
          - kms:Get*
          - kms:Delete*
          - kms:TagResource
          - kms:UntagResource
          - kms:ScheduleKeyDeletion
          - kms:CancelKeyDeletion
          Resource: "*"
        - Sid: Allow use of the key
          Effect: Allow
          Principal:

'@

        if(!($region.contains("gov"))){
            $cftBody += @'
            AWS: 
            - !GetAtt ReplicationRole.Arn
            - !Sub arn:${AWS::Partition}:iam::${AWS::AccountId}:role/av-cbts-storage-gateway

'@
        }
        else{
            $cftBody += @'
            AWS: !GetAtt ReplicationRole.Arn

'@        
        }

                $cftBody += @'
          Action:
          - kms:Encrypt
          - kms:Decrypt
          - kms:ReEncrypt*
          - kms:GenerateDataKey*
          - kms:DescribeKey
          Resource: "*"
        - Sid: Allow attachment of persistent resources
          Effect: Allow
          Principal:
            AWS: !GetAtt ReplicationRole.Arn
          Action:
          - kms:CreateGrant
          - kms:ListGrants
          - kms:RevokeGrant
          Resource: "*"
          Condition:
            Bool:
              kms:GrantIsForAWSResource: 'true'
      KeyUsage: ENCRYPT_DECRYPT
      Tags:
      - Key: uai
        Value: !Ref uai
      - Key: created_by
        Value: !Ref createdBy
      - Key: env
        Value: !Ref env
  KMSALIAS:
    Type: AWS::KMS::Alias
    Properties:

'@

$aliasRegion = $region.Replace("-","")
                $cftBody += @"
      AliasName: `'$aliasName`'
      #        - `'alias/av-$aliasRegion-storage-gateway-{siteName}`'

"@
                $cftBody += @'
      #        - {siteName: !Ref siteName}
      TargetKeyId: !Ref KMSKEY
  S3Primary:
    Type: AWS::S3::Bucket
    Properties:
      AccessControl: "Private"
      BucketEncryption:
        ServerSideEncryptionConfiguration:
        - ServerSideEncryptionByDefault:
            KMSMasterKeyID: !Ref KMSKEY
            SSEAlgorithm: aws:kms
      BucketName: !Sub
      - 'av-sgw-${siteName}-${fileShareName}'
      - {siteName: !Ref siteName}
      LoggingConfiguration:
        DestinationBucketName: !Ref loggingBucketName
        LogFilePrefix: !Sub
        - 'av-sgw-${siteName}-${fileShareName}'
        - {siteName: !Ref siteName}
      PublicAccessBlockConfiguration:
        BlockPublicAcls: True
        BlockPublicPolicy: True
        IgnorePublicAcls: True
        RestrictPublicBuckets: True
      ReplicationConfiguration:
        Role: !GetAtt ReplicationRole.Arn
        Rules:
        - Destination:
            Bucket: !GetAtt S3Secondary.Arn
            EncryptionConfiguration:
              ReplicaKmsKeyID: !GetAtt KMSKEY.Arn
            StorageClass: GLACIER
          Id: "Rule1"
          Priority: 1
          Filter:
            Prefix: ""
          DeleteMarkerReplication:
            Status: Enabled
          SourceSelectionCriteria:
            SseKmsEncryptedObjects:
              Status: Enabled
          Status: Enabled
      LifecycleConfiguration:
        Rules:
            - Id: av-version-retention-policy
              NoncurrentVersionExpiration:
                NoncurrentDays: !Ref noncurrentDays
              ExpiredObjectDeleteMarker: true
              Status: Enabled
      Tags:
      - Key: uai
        Value: !Ref uai
      - Key: created_by
        Value: !Ref createdBy
      - Key: env
        Value: !Ref env
      VersioningConfiguration:
        Status: Enabled
  S3Secondary:
    Type: AWS::S3::Bucket
    Properties:
      AccessControl: "Private"
      BucketEncryption:
        ServerSideEncryptionConfiguration:
        - ServerSideEncryptionByDefault:
            KMSMasterKeyID: !Ref KMSKEY
            SSEAlgorithm: aws:kms
      BucketName: !Sub
      - 'av-sgw-${siteName}-${fileShareName}-backup'
      - {siteName: !Ref siteName}
      LoggingConfiguration:
        DestinationBucketName: !Ref loggingBucketName
        LogFilePrefix: !Sub
        - 'av-sgw-${siteName}-${fileShareName}-backup'
        - {siteName: !Ref siteName}
      PublicAccessBlockConfiguration:
        BlockPublicAcls: True
        BlockPublicPolicy: True
        IgnorePublicAcls: True
        RestrictPublicBuckets: True
      LifecycleConfiguration:
        Rules:
            - Id: av-version-retention-policy-glacier
              NoncurrentVersionExpiration:
                NoncurrentDays: !Ref noncurrentGlacierDays
              ExpiredObjectDeleteMarker: true
              Status: Enabled
      Tags:
      - Key: uai
        Value: !Ref uai
      - Key: created_by
        Value: !Ref createdBy
      - Key: env
        Value: !Ref env
      VersioningConfiguration:
        Status: Enabled
  ReplicationRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub
      - 'av-sgw-${siteName}-${fileShareName}-bucket-backup-role'
      - {siteName: !Ref siteName}
      AssumeRolePolicyDocument:
        Statement:
        - Action: ['sts:AssumeRole']
          Effect: Allow
          Principal:
            Service: [s3.amazonaws.com]
        - Action: ['sts:AssumeRole']
          Effect: Allow
          Principal:
            Service: [storagegateway.amazonaws.com]
  BucketBackupPolicy:
    Type: AWS::IAM::Policy
    Properties:
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
        - Action:
          - s3:ListBucket
          - s3:GetObjectVersion
          - s3:GetAccelerateConfiguration
          - s3:GetReplicationConfiguration
          - s3:GetObjectVersionForReplication
          - s3:GetObjectVersionAcl
          - s3:GetObjectVersionTagging
          - s3:GetObjectRetention
          - s3:GetObjectLegalHold
          - s3:ReplicateObject
          - s3:ReplicateDelete
          - s3:ReplicateTags
          - s3:ListBucket
          - s3:ListBucketMultipartUploads
          - s3:ListBucketVersions
          - s3:ListMultipartUploadParts
          - s3:GetBucketLocation
          - s3:GetBucketLocation
          - s3:GetBucketLogging
          - s3:GetBucketNotification
          - s3:GetBucketObjectLockConfiguration
          - s3:GetBucketPolicy
          - s3:GetBucketTagging
          - s3:GetBucketVersioning
          - s3:GetEncryptionConfiguration
          - s3:GetIntelligentTieringConfiguration
          - s3:GetInventoryConfiguration
          - s3:GetLifecycleConfiguration
          - s3:GetMetricsConfiguration
          - s3:GetObject
          - s3:GetObjectAcl
          - s3:GetObjectLegalHold
          - s3:GetObjectRetention
          - s3:GetBucketPolicyStatus
          - s3:GetObjectTagging
          - s3:GetObjectTorrent
          - s3:GetObjectVersionAcl
          - s3:GetObjectVersionForReplcation
          - s3:GetObjectVersionTagging
          - s3:GetObjectVersionTorrent
          - s3:GetReplicationConfiguration
          - s3:DeleteObjectTagging
          - s3:DeleteObjectVersionTagging
          - s3:PutBucketTagging
          - s3:PutObjectAcl
          - s3:PutObjectVersionTagging
          - s3:ReplicateTags
          - s3:AbortMultipartUpload
          - s3:DeleteObject
          - s3:DeleteObjectVersion
          - s3:PutAccelerateConfiguration
          - s3:PutBucketNotification
          - s3:PutBucketObjectLockConfiguration
          - s3:PutBucketOwnershipControls
          - s3:PutBucketVersioning
          - s3:PutEncryptionConfiguration
          - s3:PutIntelligentTieringConfiguration
          - s3:PutInventoryConfiguration
          - s3:PutLifecycleConfiguration
          - s3:PutMetricsConfiguration
          - s3:PutObject
          - s3:PutObjectAcl
          - s3:PutObjectLegalHold
          - s3:PutReplicationConfiguration
          - s3:ReplicateDelete
          - s3:ReplicateObject
          - s3:RestoreObject
          Effect: Allow
          Resource:

'@

            if($region.contains("gov")){

                $cftBody += @'
          - !Join ['', ['arn:aws-us-gov:s3:::', !Ref 'S3Primary']]
          - !Join ['', ['arn:aws-us-gov:s3:::', !Ref 'S3Primary','/*']]
        - Action:
          - s3:ReplicateObject
          - s3:ReplicateDelete
          - s3:ReplicateTags
          - s3:GetObjectVersionTagging
          Effect: Allow
          Condition:
            StringLikeIfExists:
              s3:x-amz-server-side-encryption:
              - aws:kms
              - AES256
              s3:x-amz-server-side-encryption-aws-kms-key-id:
              - !GetAtt KMSKEY.Arn
          Resource: !Join ['', ['arn:aws-us-gov:s3:::', !Ref 'S3Secondary', '/*']]
        - Action:
          - kms:Decrypt
          - kms:GenerateDataKey
          Effect: Allow
          Condition:
            StringLike:

'@
                $cftBody += @"
              kms:ViaService: s3.$region.amazonaws.com
              kms:EncryptionContext:aws:s3:arn:
              - !Join ['', ['arn:aws-us-gov:s3:::', !Ref 'S3Primary']]
          Resource:
          - !GetAtt KMSKEY.Arn
        - Action:
          - kms:Encrypt
          Effect: Allow
          Condition:
            StringLike:
              kms:ViaService: s3.$region.amazonaws.com

"@
                $cftBody += @'
              kms:EncryptionContext:aws:s3:arn:
              - !Join ['', ['arn:aws-us-gov:s3:::', !Ref 'S3Secondary']]
          Resource:
          - !GetAtt KMSKEY.Arn
      PolicyName: !Sub
      - 'av-sgw-${siteName}-${fileShareName}-bucket-backup-policy'
      - {siteName: !Ref siteName}
      Roles:
      - !Ref ReplicationRole
'@
            }
            else{
                $cftBody += @'
          - !Join ['', ['arn:aws:s3:::', !Ref 'S3Primary']]
          - !Join ['', ['arn:aws:s3:::', !Ref 'S3Primary','/*']]
        - Action:
          - s3:ReplicateObject
          - s3:ReplicateDelete
          - s3:ReplicateTags
          - s3:GetObjectVersionTagging
          Effect: Allow
          Condition:
            StringLikeIfExists:
              s3:x-amz-server-side-encryption:
              - aws:kms
              - AES256
              s3:x-amz-server-side-encryption-aws-kms-key-id:
              - !GetAtt KMSKEY.Arn
          Resource: !Join ['', ['arn:aws:s3:::', !Ref 'S3Secondary', '/*']]
        - Action:
          - kms:Decrypt
          - kms:GenerateDataKey
          Effect: Allow
          Condition:
            StringLike:

'@
                $cftBody += @"
              kms:ViaService: s3.$region.amazonaws.com
              kms:EncryptionContext:aws:s3:arn:
              - !Join ['', ['arn:aws:s3:::', !Ref 'S3Primary']]
          Resource:
          - !GetAtt KMSKEY.Arn
        - Action:
          - kms:Encrypt
          Effect: Allow
          Condition:
            StringLike:
              kms:ViaService: s3.$region.amazonaws.com

"@
                $cftBody += @'
              kms:EncryptionContext:aws:s3:arn:
              - !Join ['', ['arn:aws:s3:::', !Ref 'S3Secondary']]
          Resource:
          - !GetAtt KMSKEY.Arn
      PolicyName: !Sub
      - 'av-sgw-${siteName}-${fileShareName}-bucket-backup-policy'
      - {siteName: !Ref siteName}
      Roles:
      - !Ref ReplicationRole
'@
            }

            $folderName = $stackNameText.replace("-","")
            $filename = "C:\temp\$folderName\" + $stackNameText + ".yml"

            if(!(test-path -Path "C:\temp\$folderName")){
                New-Item -ItemType Directory -Path "C:\temp\$folderName"
            }

            New-Item -ItemType File -Path $filename

            set-content -Path $filename -Value $cftBody

            $fileURL = @"
  <HTML>
    <HEAD>
        <section class="header" style="width:100%; padding:60px 0; text-align:center; background: rgb(146, 172, 154); color: white;">
            <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAOEAAADhCAMAAAAJbSJIAAAAWlBMVEX///8paTQmaDE0cD4PXyDAz8IeZizF0scbYynN2c+Go4qMqJA5cUL6/PoGXhwRYCHj6uR4mXzv8/BGe0/C0cR4mnxgimY/dkjU3tZoj26SrZY0bz65ybuww7ImqsoxAAAB4klEQVR4nO3c207CMACAYSgORXSIzBPq+7+mF8YEyWg4lLaM77+FZP12s6WHjUaSJEmSJEmSJP3VNV2dNV0iYWhv6qwNiYSTMK6zMCEkJCwdISFh+QgJCctHSEhYPkJCwvIREsaE07vd5bsfZxSG5ctyZ6/ZiGcUTmN/n90MXXhLSEhISEhISEhISEhISHh9wsh8ziH1T4zUIJzM71M0X/USKxCGVaIhLO8IT4pwK8JjIjwxwq02ZvXD2/ssRe8fuZ+HIfZ43hxNSLQrP/s7TfRlbBCra5VESEhYPkJCwvIREhKWj5DwuoWLSL1TKpcmDM3Xzpp1NmIFc22EhISEhISEhISEhISEhIQDEV7sXoy9dwy9zW5TNOs/W1yDcJh7ogiPifDECLciPKZqhePP9TxF6+znLcKk74K//f/pUs/MjEOk3fjUWSElJCwfISFh+QgJCctHSHjdwjbSYgjC6XOkr2zEGuZpCAkJCQkJCQkJCQkJCQmvRBhbDj+gioUPaapWOPz9NIR7R3hihFsRHlPNwscUjZbTzMLwFOl7436H2BLOAeXfmxgbzSC+/FFJhISE5SMkJCwfISFh+QgJCctHSEhYPsK9C22ir8ykrg2JhF1Ta10ioSRJkiRJkiRpCP0Ag3yifPI9tpYAAAAASUVORK5CYII=" width="150" height="150" style="float:middle">
            <h1>AWS Storage Gateway CFT Utility</h1>
            <p>CloudFormation Templage Generator for New Storage Gateway Shares</p>
        </section>
    </HEAD>
	<BODY>
        <br>
        <br>
        Your generated template:
        <a href=`"file://C:\temp\$folderName\`">$filename</a>
	</BODY>
</HTML>          
"@

            $response = $context.Response
            $response.Headers.Add("Content-Type","HTML")
            $response.StatusCode = 200
            $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes("$fileURL")
            $response.ContentLength64 = $ResponseBuffer.Length
            $response.OutputStream.Write($ResponseBuffer,0,$ResponseBuffer.Length)
            $response.close()

            $httpListener.stop()
        }

}

$httpListener.Dispose()


