<#
.SYNOPSIS
    Sample Script to bulk direct assignments by a text file of email addresses
.DESCRIPTION
    Sample Script to bulk direct assignments by a text file of email addresses
.EXAMPLE
    New-EMRequestsFromTextFile -TextFile C:\temp\NewEmails.txt -AccessPackageName "External User Onboarding"
.EXAMPLE
    New-EMRequestsFromTextFile -TextFile C:\temp\NewEmails.txt
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    SEe detailed documentation for using Entitlement Maanagement services using Microsoft Fraph SDK Powershell module at https://docs.microsoft.com/en-us/azure/active-directory/governance/entitlement-management-access-package-assignments

#>
function New-EMRequestsFromTextFile {
    [CmdletBinding()]
    param (
        # Full Path to Text File of email addresses to directly assign to Entitlement Management Access Package (1 address per line)
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Default')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $TextFilePath,
        # Display Name of the Access Package for Assignment
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Default')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $AccessPackageName = "B2B_Onboarding"

    )
    
    begin {

        Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All"
        Select-MgProfile -Name "beta"

        if ($true -eq (Test-Path -Path $TextFilePath)) {
            $TextData = get-content $TextFilePath

        }
        else {
            New-Error  ("Text File {0} could not be found!  Please check the TextFilePath!" -f $TextFilePath)
        }
        
    }
    
    process {


        foreach ($EmailAddress in $TextData) {
            $accesspackage = Get-MgEntitlementManagementAccessPackage -DisplayNameEq $AccessPackageName -ExpandProperty "accessPackageAssignmentPolicies"
            $policy = $accesspackage.AccessPackageAssignmentPolicies[0]

            try {
            
                Write-Verbose ("Assigning {0} to Access Package!" -f $EmailAddress)
                $req = New-MgEntitlementManagementAccessPackageAssignmentRequest -AccessPackageId $accesspackage.Id -AssignmentPolicyId $policy.Id -TargetEmail $EmailAddress
            }
            catch {
                Write-Error ("Error Assigning {0} to Access Package: {1}" -f $EmailAddress, $_.ErrorDetails)
            }
            
        }
    }
    
    end {
        Write-Verbose "Complete!"
    }
}
