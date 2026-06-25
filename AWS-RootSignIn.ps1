<#
.SYNOPSIS
Open the AWS root user sign-in page for the specified account.
.DESCRIPTION
This script launches the default browser to the AWS root user login page and displays the root account email.
It does not store or automate password entry for security reasons.
.PARAMETER RootEmail
The root account email address.
.PARAMETER SignInUrl
The AWS root sign-in URL to open in the browser.
#>
[CmdletBinding()]
param(
    [string]$RootEmail = 'filliat@ascto.com',
    [string]$AwsArn = 'arn:aws:account::430606112332:account',
    [string]$SignInUrl = 'https://us-east-1.signin.aws.amazon.com/v1/authorize?response_type=code&client_id=arn%3Aaws%3Asignin%3A%3A%3Adevtools%2Fsame-device&state=66358125-9e5b-45b7-91ff-507512030059&code_challenge_method=SHA-256&scope=openid&redirect_uri=http%3A%2F%2F127.0.0.1%3A62435%2Foauth%2Fcallback&code_challenge=j0SxZXBO7qXIYSRfVn4-Jd2L30XQZYUCFmUxvXFexdo'
)

$ErrorActionPreference = 'Stop'

Write-Host 'AWS Root User Sign-In Helper' -ForegroundColor Cyan
Write-Host '---------------------------------------'
Write-Host "Root Email       : $RootEmail"
Write-Host "AWS Account ARN   : $AwsArn"
Write-Host "AWS Sign-in URL   : $SignInUrl"
Write-Host ''

if (-not $SignInUrl) {
    Write-Error 'The SignInUrl parameter is required.'
    exit 1
}

Try {
    Write-Host 'Opening AWS root sign-in page in your default browser...'
    Start-Process -FilePath $SignInUrl
}
Catch {
    Write-Warning 'Could not open the browser automatically.'
    Write-Host 'Please copy and paste this URL into your browser:'
    Write-Host $SignInUrl -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Enter your Root user credentials in the browser manually.'
Write-Host 'Do not store root passwords in scripts for security reasons.'
