<#
.SYNOPSIS
    Convert an existing external guest to a governed guest in scope of Entitlement Management Lifecycle policy
.DESCRIPTION
    Convert an existing external guest to a governed guest in scope of Entitlement Management Lifecycle policy
.PARAMETER UserId
    UserIds of External Guest User Objects to be converted to governed guests
.PARAMETER AccessPackageId
    ID of the AccessPackage that a external guest who may not have existing Access Package assignments
.PARAMETER AccessPackagePolicyId
    ID of the policy that a external guest who may not have existing Access Package assignments
.PARAMETER ForceAssign
    Force Assign the Access Package even if the guest has active assignments
.EXAMPLE
    ConvertTo-EmGovernedGuest -UserIds a55b82e7-1454-4f84-8b1c-b534f1dcf555 -AccessPackageId 7e251175-6169-4d34-b541-3fea2cbb396b -AccessPackagePolicyId de2f2618-decf-458f-8a6b-452b331fc256
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    See detailed documentation for using Entitlement Management services using Microsoft Fraph SDK Powershell module at https://docs.microsoft.com/en-us/azure/active-directory/governance/entitlement-management-access-package-assignments

#>
function ConvertTo-EmGovernedGuest {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [Alias("id")]
        [string[]]

        $UserId,
        [string]
        $AccessPackageId = "40fcf15b-30d7-46f0-a861-1e8e80343b79",
        [string]
        $AccessPackagePolicyId = "2a6334c7-f190-4385-afcc-6b91c5dd69f3",
        [switch]
        $ForceAssign
        
    )
    
    begin {
        

    }
    
    process {

        foreach ($uid in $UserId) {
            $cUser = [ordered]@{}
            $cUser.Id = $uid


            Write-Debug ("Retrieving User Object for ID {0}" -f $uid)
            $g = Get-MgUser -filter ("(id eq '{0}')" -f $uid) -Property UserType, UserPrincipalName

            if ($null -ne $g) {
                write-Debug ("Retrieved User: " + ($g | out-string))
                Write-Verbose ("Retrieved User: " + $g.UserPrincipalName)

                $cUser.UserPrincipalName = $g.UserPrincipalName
                $cUser.UserType = $g.UserType

                $subjectUri = ("https://graph.microsoft.com/beta/identityGovernance/entitlementManagement/subjects(objectId='{0}')" -f $uid)
                $subjectInfo = Invoke-MgGraphRequest -Method GET -Uri $subjectUri

                $cUser.subjectLifecycle = $subjectInfo.subjectLifecycle
                $cUser.connectedOrganizationId = $subjectInfo.connectedOrganizationId

                
                Write-Verbose ("User Lifecycle State: " + $cUser.subjectLifecycle)

                $existingEMAssignments = $null

                $emAssignmentsFilter = ("target/objectid+eq+'{0}'" -f $cUser.Id)

                write-debug $emAssignmentsFilter
                Write-Verbose ("Retrieving existing Access Package Assignments!")
                $existingEMAssignments = Get-MgBetaEntitlementManagementAccessPackageAssignment  -Filter $emAssignmentsFilter -Expand target
                

                $assignAccessPackage = $false

                if ($null -eq $existingEMAssignments) {
                    Write-Verbose ("No Access Packages Assignments for {0}" -f $cUser.UserPrincipalName)
                    $cUser.ExistingAssignments = $null
                    $assignAccessPackage = $true

                    
                }
                else {

                    $cUser.ExistingAssignments = $existingEMAssignments
                    Write-Verbose ("{0} existing Access Package Assignments!" -f ($cUser.ExistingAssignments).count)
                    if ($null -eq ($existingEMAssignments | Where-Object -FilterScript { $_.AssignmentState -eq 'Delivered' })) {
                        $assignAccessPackage = $true
                    }
                    else {
                        
                        if ($ForceAssign) {
                            if ($null -eq ($existingEMAssignments | Where-Object -FilterScript { $_.AccessPackageID -eq $AccessPackageId })) {
                                $assignAccessPackage = $true
                            }
                        }
                        else {
                            $cUser.AssignmentResult = "Skipped"
                       $cUser.AssignmentResultDetails = "Default Access Package Assignment Skipped!"
                        }
                    }

                }


                if ($assignAccessPackage) {
                    Write-Verbose ("Assigning user to Access Package!")


                    try {

                       $req = New-MgBetaEntitlementManagementAccessPackageAssignmentRequest -AccessPackageId $AccessPackageId -AssignmentPolicyId $AccessPackagePolicyId -TargetId $cUser.id
                        
                       $cUser.AssignmentResult = "Assigned"
                       $cUser.AssignmentResultDetails = "Default Access Package Assigned!"
                    }
                    catch {
                        $cUser.AssignmentResult = "Error"
                        $cUser.AssignmentResultDetails = $_.Exception.Message
                    }
                }


                if ($cUser.subjectLifecycle -ne 'governed') {
                    Write-Verbose ("Converting Guest to Governed")

                    try {
                        Invoke-MgGraphRequest -Method Patch -uri $subjectUri -Body (@{"subjectLifecycle" = "governed" } | ConvertTo-Json) -ContentType "application/json"
                   
                        $cUser.ConversionResult = "Converted"
                        $cUser.ConversionResultDetails = $null
                        Write-Verbose ("{0} Converted to governed!" -f $cuser.UserPrincipalName)
                    }
                    catch {
                        $cUser.ConversionResult = "Error"
                        $cUser.ConversionResultDetails = $_.Exception.Message
                    }

                }
                else {
                    $cUser.ConversionResult = "Skipped"
                    $cUser.ConversionResultDetails = "User is Already Governed!"
                    Write-Verbose ("{0} skipped and is already governed!" -f $cuser.UserPrincipalName)
                }


                Write-Output([PSCustomObject]$cUser)

            }
        }
        
        
    }
    
    end {

        write-verbose "Complete!"
        
    }
}