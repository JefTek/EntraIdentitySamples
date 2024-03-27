function Add-CustomManagedResourceToEmCatalog {
    [CmdletBinding()]
    param (
        $CatalogId,
        [ValidateSet("SAP Business Role")]
        $ResourceType,
        $ResourceId,
        $ResourceDisplayName,
        $ResourceDescription,
        [ValidateSet("SecurityGroup")]
        $targetResourceType
        
    )
    
    begin {
        
    }
    
    process {

        $accessPackageResource = @{}

                Write-Verbose "Adding $ResourceType!"
                $accessPackageResource.resourceType = $ResourceType
                $accessPackageResource.originSystem = "CustomManaged"
                $accessPackageResource.displayName = $ResourceDisplayName
                $accessPackageResource.description = $ResourceDescription
                $accessPackageResource.originId = $ResourceId
        
                
                $params = @{
                    catalogid = $CatalogId
                    requestType = "AdminAdd"
                    accessPackageResource = @{
                        '@odata.type' = "microsoft.graph.accessPackageCustomManagedResource"
                        displayName = $accessPackageResource.displayName
                        originId = $accessPackageResource.originId
                        originSystem = $accessPackageResource.originSystem
                        resourceType = $accessPackageResource.resourceType
                        targetResource = @{
                            originSystem = "AadGroup"
                            resourceType = "Security Group"
                        
                        }
                    }
                   
                }


          Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/identityGovernance/entitlementManagement/accessPackageResourceRequests" -Method POST -Body ($params|ConvertTo-Json)

        
    }
    
    end {
        
    }
}