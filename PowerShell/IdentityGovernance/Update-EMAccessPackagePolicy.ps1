<#
.SYNOPSIS
    Update limited properties of Entitlement Management Access Package Policies
.DESCRIPTION
    Update limited properties of Entitlement Management Access Package Policies
.EXAMPLE
    Update the name and description of the access package policy
    Update-EMAccessPackagePolicy -PolicyId 1f0d6301-1bc3-4ef8-b5b0-06b2f91cc915 -Description "Internal Users who are accessing Teams resources" -Name "Internal Users Only"
.EXAMPLE
    Disable Policy for accepting requests
    Update-EMAccessPackagePolicy -PolicyId 1f0d6301-1bc3-4ef8-b5b0-06b2f91cc915 -Enabled $false
.NOTES
    Workaround for msgraph-sdk-powershell module issue reported https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/870
    Must already be connected to MS Graph using the MS Graph PowerShell SDK Module  with the proper permissions
    ex: Connect-MgGraph -scopes EntitlementManagement.ReadWrite.All
    See https://docs.microsoft.com/en-us/graph/api/accesspackageassignmentpolicy-update?view=graph-rest-beta for needed permissions

#>
function Update-EMAccessPackagePolicy {
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
                   SupportsShouldProcess=$true,
                   PositionalBinding=$false,
                   HelpUri = 'https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/870',
                   ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
        # The ObjectID of the Access Package Policy that will be updated
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false, 
                   ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $PolicyId,
        
        # The Display Name of the Access Package Policy
        [Parameter(ParameterSetName='Parameter Set 1')]
        [alias("DisplayName")]
        [String]
        $Name,
        # The Description of the Access Package Policy
        [Parameter(ParameterSetName='Parameter Set 1')]
        [String]
        $Description,
        # The status of the if the policy should be enabled to accepted requests
        [bool]
        $Enabled
        
    )
    
    begin {

        $apiVersion = "beta"

        $policyUri = ("https://graph.microsoft.com/{0}/identityGovernance/entitlementManagement/accessPackageAssignmentPolicies/{1}" -f $apiVersion, $PolicyId)
    }

    
    process {
      
        Write-Verbose "Retrieving Policy $PolicyId"
        $currentPolicy = Invoke-MgGraphRequest -Method GET -Uri $policyUri -OutputType Json
        $newPolicy = $currentPolicy|ConvertFrom-Json -Depth 10

        if ($Name)
        {
            $newPolicy.displayName = $Name
            write-verbose "Setting Name to $Name"
        }

        if ($Description)
        {
            $newPolicy.description = $Description
            Write-Verbose "Setting Description to $Description"
        }

        if ($Enabled)
        {
            $newPolicy.requestorSettings.acceptRequests = $Enabled
            write-verbose "Setting Enabled to $Enabled"
        }

        $updatedPolicy = $newPolicy|ConvertTo-Json -Depth 10
        Write-Verbose "Updating Policy $PolicyId"
        Invoke-MgGraphRequest -Method PUT -Uri $policyUri -Body $updatedPolicy

    }
    
    end {
    }
}