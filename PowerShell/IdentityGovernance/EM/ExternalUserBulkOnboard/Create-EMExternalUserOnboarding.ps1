function Create-EMExternalUserOnboarding {
    [CmdletBinding()]
    param (
        $Name
    )
    
    begin {
        
    }
    
    process {
        
       
        $newCatalog = New-MgEntitlementManagementCatalog -DisplayName $name -Description "This catalog is used to onboard external users" -IsExternallyVisible:$true -State "published"
        $catalog = Get-MgEntitlementManagementCatalog -DisplayNameEq $name
        $accessPackage = New-MgEntitlementManagementAccessPackage -DisplayName "External User Onboarding Model" -Description "This access package is used to onboard external users" -Catalog $catalog -IsHidden:$false

        

        $accessPackage
            
            $params = @{
                accessPackageId = $($accesspackage.id)
                displayName = "Assign Any - No Approval"
                description = "Invite external users to the organization without requiring approval"
                accessReviewSettings = $null
                requestorSettings = @{
                    scopeType = "AllExternalSubjects"
                    acceptRequests = $false
                    allowedRequestors = @(
                    )
                }
                requestApprovalSettings = @{
                    isApprovalRequired = $false
                    isApprovalRequiredForExtension = $false
                    isRequestorJustificationRequired = $false
                    approvalMode = "NoApproval"
                    approvalStages = @(
                    )
                }
            }

            New-MgBetaEntitlementManagementAccessPackageAssignmentPolicy -BodyParameter $params
        

    }
    
    end {
        
    }
}

