<#
.SYNOPSIS
    Add a new connected organization by resolving the provided domain name first
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function New-EntraIDConnectedOrganization {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        HelpUri = 'https://github.com/JefTek/AzureADSamples',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    param (
        # The DNS domain name to create a connected organization for
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Default')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $DomainName,
        # The display name of the connected organization.   If not provided, will default to the DNS Domain Name
        [Parameter(Mandatory = $false,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Default')]
        $DisplayName,
        # The display name of the connected organization.   If not provided, will default to the DNS Domain Name
        [Parameter(Mandatory = $false,
            Position = 2,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Default')]
        $Description,
        # The state of the new connected organization of either proposed or configured.  Defaults to proposed.
        [Parameter(Mandatory = $false,
            Position = 3,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Default')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("configured", "proposed")]
        $State = "proposed",
        # Create a new connected organization ad identity source type
        [Parameter(Mandatory = $false,
            Position = 4,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Default')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("azureActiveDirectoryTenant", "domainIdentitySource", "externalDomainFederation")]
        $IdentitySourceType,
        [switch]
        $ResolveOnly
    )
    
    begin {
        
    }
    
    process {


        foreach ($name in $DomainName) {
            
            $existingConnectedOrg = $null
            
            $domainResults = @{}
            $domainResults.domainName = $DomainName
            $domainResults.displayName = $displayName

            Write-Verbose ("Resolving DomainName {0} to determine if it is verified in an Azure Active Directory Tenant" -f $name)
            $resolvedDomain = Resolve-DomainNamForConnectedOrganization -DomainName $name


            switch ($resolvedDomain.IdentitySourceType) {
                "azureActiveDirectoryTenant" {   
                    Write-Verbose ("Determining if Connected Organization already exists for tenant {0} that the {0} is verified in" -f $resolvedDomain.domainNAme, $resolvedDomain.tenantid )
                    $existingConnectedOrg = Get-MgEntitlementManagementConnectedOrganization  -filter ("identitySources/any(is:is/microsoft.graph.azureActiveDirectoryTenant/tenantId eq '{0}')" -f $resolvedDomain.tenantId)
                }

                "domainIdentitySource" {
                    Write-Verbose ("Determining if Connected Organization already exists for Domain Name {0}" -f $resolvedDomain.domainName )
                    $existingConnectedOrg = Get-MgEntitlementManagementConnectedOrganization  -filter ("identitySources/any(is:is/microsoft.graph.domainIdentitySource/domainName eq '{0}')" -f $resolvedDomain.domainName)
                }

                "externalDomainFederation" {
                    Write-Warning ("Not Currently in scope of this process")
                }

                Default {
                    Write-Warning ("{0} was not resolved, so it will be skipped!" -f $resolvedDomain.domainName)
                }   

            }

            $domainResults.existingConnectedOrg = $existingConnectedOrg

            $ConnectedOrg = $null

            if ($null -eq $domainResults.existingConnectedOrg) {

                $domainResults.Action = "Create"
                $domainResults.Description = $Description
                $domainResults.State = $State
                if ($null -ne $displayName) {
                
                    $domainResults.DisplayName = $DisplayName
                }
                else {
                    $domainResults.DisplayNAme = $DomainName
                }

                if ($ResolveOnly) {
                    Write-Verbose "Running in ResolveOnly Mode.   New Connected Organization will not be created."
                
                }
                else {
                    
                
                    if ($pscmdlet.ShouldProcess($DomainName, "Create Connected Organization")) {
            
                        $NewCO = @{}
                        $NewCO.Description = $domainResults.Description
                        $NewCo.DisplayName = $domainResults.displayName
                        $NewCo.DomainName = $domainResults.domainName
                        $Newco.State = $State
                        New-MgEntitlementManagementConnectedOrganization @NewCO

                    }
                }
            }
            else {
                
                $domainResults.Action = "Existing"
                $ConnectedOrg = $existingConnectedOrg
                
                Write-Verbose ("An existing Connected Organization already exists for domain name {0}" -f $($resolvedDomain.domainName))
                Write-Verbose ("The existing Connected Organization is {0} with id of {1}" -f $($existingConnectedOrg.Id), $($existingConnectedOrg.DisplayName))
            }
        
                
                
           
        
            
            $domainResults.ConnectedOrgId = $ConnectedOrg.Id
            $domainResults.ConnectedOrgDisplayName = $ConnectedOrg.DisplayName
            $domainResults.ConnectedOrgDescription = $ConnectedOrg.Description
            $domainResults.ConnectedOrgState = $ConnectedOrg.state


            

            Write-Output ([PSCustomObject]$domainResults)

        }



       
  
    }
    
    end {
        
    }
}

function Resolve-DomainNamForConnectedOrganization {
    [CmdletBinding()]
    param (
        $DomainName
    )
    
    begin {

        # Global Endpoint
        $loginEndpoint = "https://login.microsoftonline.com"
        
        
    }
    
    process {

        
        
        $resolvedDomain = @{}

        $resolvedDomain.domainName = $DomainName
        $TenantMetadataUri = "$loginEndpoint/$DomainName/.well-known/openid-configuration"

   
        try {
            Write-Debug $TenantMetadataUri
            Write-verbose ("Checking for the presence of the Domain Name {0} as a verified domain in an Azure AD Tenant" -f $DomainName)
            $Tenant = $null
            $Tenant = Invoke-RestMethod -ContentType "application/json; charset=utf-8" -Uri $TenantMetadataUri

            
           
            $resolvedDomain.NameFound = $true
            $resolvedDomain.TenantFound = $true
            $resolvedDomain.TenantId = $Tenant.issuer.split("/")[3]

            if ($resolvedDomain.TenantId -eq '9cd80435-793b-4f48-844b-6b3f37d1c1f3') {
                Write-Verbose ("{0} has been resolved to the public Microsoft Accounts Tenant, so domain will be treated as a Domain Identity Source Type!" -f $($domainName))
                $resolvedDomain.TenantFound = $false
                $resolvedDomain.IdentitySourceType = "domainIdentitySource"
            }


            $resolvedDomain.NameStatus = "ResolvedToTenant"
            $resolvedDomain.MetadataEndpoint = "$loginEndpoint/$Name/.well-known/openid-configuration"
            $resolvedDomain.IdentitySourceType = "azureActiveDirectoryTenant"

        }
        catch {
            $resolvedDomain.NameStatus = $_.errordetails
            Write-Verbose ($resolvedDomain.NameStatus)
            $ResolvedDomain.TenantFound = $false
            $resolvedDomain.IdentitySourceType = "domainIdentitySource"
        }


    }
    
    end {
        
        Write-Output ([pscustomobject]$resolvedDomain)
        
    }
}