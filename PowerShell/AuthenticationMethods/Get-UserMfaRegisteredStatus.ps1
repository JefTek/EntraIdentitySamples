<#
.SYNOPSIS
    Get the status of registered authentication methods that support MFA
.DESCRIPTION
    Get the status of registered authentication methods that support MFA
.EXAMPLE
    Get-UserMfaRegisteredStatus -UserId bbe132a5-02dc-42e0-8eca-7f7849823e76
.EXAMPLE
    Another example of how to use this cmdlet
.NOTES
    Before running, be connected with Connect-MGGraph with the appropriate scopes for reading authentication methods
#>
function Get-UserMfaRegisteredStatus ([string]$UserId) {

    #Collection of Authentication Methods that are able to be used to respond to MFA challenges
    $mfaMethods = @("#microsoft.graph.fido2AuthenticationMethod", "#microsoft.graph.softwareOathAuthenticationMethod", "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod", "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod", "#microsoft.graph.phoneAuthenticationMethod")

    $authMethods = (Get-MgUserAuthenticationMethod -UserId $UserId).AdditionalProperties."@odata.type"

    $isMfaRegistered = $false
    foreach ($mfa in $MfaMethods) { if ($authmethods -contains $mfa) { $isMfaRegistered = $true } }
    
    $results = @{}
    $results.IsMfaRegistered = $isMfaRegistered
    $results.AuthMethodsRegistered = $authMethods

    Write-Output ([pscustomobject]$results)

}