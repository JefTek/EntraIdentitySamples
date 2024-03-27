<#
.SYNOPSIS
    Adds an SPO site to an EM Catalog and AccessPackage
.DESCRIPTION
    Adds an SPO site to an EM Catalog and AccessPackage
.PARAMETER AccessPackageCatalogId
    The Id of the Access Pacjage Catalog (GUID)
.PARAMETER AccessPackageId
    The Id of the Access Package in the Catalog (GUID)
.PARAMETER SiteUri
    The URI of the SharePoint Online Site that is being added to the Catalog/Access Package
.PARAMETER SiteRoleName
    The name of the Role in the SharePoint Online site being added to the Access Package
.NOTES
    General notes
#>
function Add-spoSiteToEmAccessPackage {
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
                   SupportsShouldProcess=$false,
                   PositionalBinding=$false,
                   HelpUri = 'http://www.microsoft.com/',
                   ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        ValueFromRemainingArguments=$false, 
        ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]
        $AccessPackageCatalogId,
        [Parameter(Mandatory=$true,
        Position=1,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        ValueFromRemainingArguments=$false, 
        ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]
        $AccessPackageId,
        [Parameter(Mandatory=$true,
        Position=2,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        ValueFromRemainingArguments=$false, 
        ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]
        $SiteUri,
        [Parameter(Mandatory=$true,
        Position=3,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        ValueFromRemainingArguments=$false, 
        ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]
        $SiteRoleName
    )
    
    begin {
        
    }
    
    process {

        Write-Verbose ("Adding SPO Site {0} to Catalog {1}" -f $SiteUri,$AccessPackageCatalogId)
        $params = @{
            CatalogId = $AccessPackageCatalogId
            AccessPackageResource = @{
                ResourceType = "SharePoint Online Site"
                OriginId = $SiteUri
                OriginSystem = "SharePointOnline"
                "AccessPackageResourceEnvironment@odata.bind" = "accessPackageResourceEnvironments/a3ed4bb5-7d6b-4706-a12c-27cc86b14928"
            }
            RequestType = "AdminAdd"
        }
        
        try {
            New-MgEntitlementManagementAccessPackageResourceRequest -BodyParameter $params -ErrorAction Stop
        }
        catch {

            if ((get-error).Exception.Code -eq "ResourceAlreadyOnboarded")
            {
                Write-Warning ("Resource already exists in Catalog {0}" -f $accessPackageCatalogId)
            }
            else {
                Write-Error ((get-error).Exception.Message) -ErrorAction Stop
            }
        }
        
        
        
        $resource = Get-MgEntitlementManagementAccessPackageCatalogAccessPackageResource -AccessPackageCatalogId $accessPackageCatalogId -Filter ("resourceType eq 'SharePoint Online Site'") -ExpandProperty "accessPackageResourceRoles,accessPackageResourceScopes"
        $r = $resource|Where-Object {$_.OriginId -eq $SiteUri}
        
       
        Write-Verbose ("Resource ID {0}" -f $r.id)
       
        $rr = $r.accessPackageResourceRoles|Where-Object {$_.DisplayName -eq $SiteRoleName}
        Write-Debug ($rr|out-string)
        Write-Verbose ("Resource Roles retrieved for {0} - {1} - {2} - {3}" -f $SiteRole, $rr.id,$rr.OriginId,$rr.OriginSystem)
        
        $rs = $r.accessPackageResourceScopes|Where-Object {$_.OriginId -eq $SiteUri}
        Write-Verbose ("Resource Scopes retrieved for {0} - {1} - {2} - {3}" -f $SiteUri, $rs.id,$rs.OriginId,$rs.OriginSystem)

        $paramsRRS = @{
            accessPackageResourceRole = @{
                originId = $rr.OriginId
                originSystem = $rr.OriginSystem
                accessPackageResource = @{
                    id = $r.id
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
        Write-Verbose ("Adding SPOSite to Access Package {0}" -f $AccessPackageId)
        New-MgEntitlementManagementAccessPackageResourceRoleScope -AccessPackageId $AccessPackageId -BodyParameter $paramsRRS


    }
    
    end {
        
    }
}