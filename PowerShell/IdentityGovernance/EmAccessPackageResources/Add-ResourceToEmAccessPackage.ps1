function Add-ResourceToEmAccessPackage {
    [CmdletBinding()]
    param (
        $AccessPackageId,
        $CatalogId,
        [Parameter(Mandatory)]
        [ValidateSet("Application", "Group")]
        $ResourceType,
        $ResourceId,
        $ResourceDisplayName
        
    )
    
    begin {
        
    }
    
    process {

        $accessPackageResource = @{}

        switch ($ResourceType)
        {

            "Application" {
                Write-Verbose "Adding Application!"
                $accessPackageResource.resourceType = $ResourceType
                $accessPackageResource.originSystem = "AadApplication"
                $accessPackageResource.displayName = $ResourceDisplayName
                $accessPackageResource.description = ""
                $accessPackageResource.originId = $ResourceId
        
                
            }
            "Group" {

            }


        }
        #foreach($k in $accessPackageResource.Keys){Write-Verbose "$k $($accessPackageResource[$k])"}
          New-MgEntitlementManagementAccessPackageResourceRequest -CatalogId $CatalogId -RequestType "AdminAdd" -AccessPackageResource $accessPackageResource -Justification "Test"


            $CatalogResource = Get-MgEntitlementManagementAccessPackageCatalogAccessPackageResource -AccessPackageCatalogId $CatalogId -Filter ("OriginId eq '{0}'" -f $ResourceId) -ExpandProperty AccessPackageResourceRoles,AccessPackageResourceScopes

            Write-host $CatalogResource.Id

                $rr = $CatalogResource.AccessPackageResourceRoles|Select -first 1
                $rs = $CatalogResource.AccessPackageResourceScopes|Select -first 1
                


                $paramsRRS = @{
                    accessPackageResourceRole = @{
                        originId = $ResourceId
                        originSystem = $rs.OriginSystem
                        accessPackageResource = @{
                            id = $CatalogResource.id
                        }
                    }
                    accessPackageResourceScope = @{
                        id = $rs.id
                        originId = $rs.OriginId
                        originSystem = $rs.OriginSystem
                        isRootScope = $rs.IsRootScope
                    }
                }
        
        
        

        Write-debug ($paramsRRS|ConvertTo-Json|Out-String)
        Write-Verbose ("Adding App to Access Package {0}" -f $AccessPackageId)
        New-MgEntitlementManagementAccessPackageResourceRoleScope -AccessPackageId $AccessPackageId  -BodyParameter $paramsRRS

        
    }
    
    end {
        
    }
}