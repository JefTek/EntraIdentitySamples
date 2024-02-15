function New-EMGovernedExternalUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $EmailAddress,
        [Parameter(Mandatory = $true)]
        [string]
        $DisplayName,
        [Parameter(Mandatory = $true)]
        [string]
        $FirstName,
        [Parameter(Mandatory = $true)]
        [string]
        $LastName,
        [Parameter(Mandatory = $true)]
        [string]
        $Company,
        [Parameter(Mandatory = $true)]
        [string]
        $Department,
        [Parameter(Mandatory = $true)]
        [string]
        $ManagerEmail,
        [Parameter(Mandatory = $true)]
        [string]
        $SponsorEmail,
        [Parameter(Mandatory = $true)]
        [string]
        $AccessPackageId = "029ca931-0cb5-4e30-82a6-350190116b53",
        [Parameter(Mandatory = $true)]
        [string]
        $AccessPackageAssignmentPolicyId = "b29c4d17-3315-4351-9147-f9629ddb8bc2"

    )
    
    begin {
        Write-Verbose "Creating a new external user via Entitlement Management Assignment"
        
    }
    
    process {

        $params = @{
            "@odata.type"           = "#microsoft.graph.accessPackageAssignmentRequest"
            requestType             = "adminAdd"
            accessPackageAssignment = @{
                target             = @{email = $EmailAddress
                    displayName  = $DisplayName
                }
                assignmentPolicyId = $AccessPackageAssignmentPolicyId
                accessPackageId    = $AccessPackageId

            }
            answers                 = @(
                @{
                    "@odata.type"    = "#microsoft.graph.accessPackageAnswerString"
                    value            = $ManagerEmail
                    displayValue     = "Manager Email"
                    answeredQuestion = @{
                        "@odata.type" = "#microsoft.graph.accessPackageMultipleChoiceQuestion"
                        id            = "ef399958-8420-4dfa-8b3d-e24fa0048f16"
                    }
                }
                @{
                    "@odata.type"    = "#microsoft.graph.accessPackageAnswerString"
                    value            = $SponsorEmail
                    displayValue     = "Sponsor Email"
                    answeredQuestion = @{
                        "@odata.type" = "#microsoft.graph.accessPackageTextInputQuestion"
                        id            = "42760cf8-6f73-4713-aa44-89695babb31b"
                    }
                }
                @{
                    "@odata.type"    = "#microsoft.graph.accessPackageAnswerString"
                    value            = $FirstName
                    displayValue     = "First Name"
                    answeredQuestion = @{
                        "@odata.type" = "#microsoft.graph.accessPackageTextInputQuestion"
                        id            = "09364788-dbef-4400-bd3f-3e72a2c5007d"
                    }
                }
                @{
                    "@odata.type"    = "#microsoft.graph.accessPackageAnswerString"
                    value            = $LastName
                    displayValue     = "Last Name"
                    answeredQuestion = @{
                        "@odata.type" = "#microsoft.graph.accessPackageTextInputQuestion"
                        id            = "224a3d98-2e75-4503-840c-a9270dafeeae"
                    }
                }
                @{
                    "@odata.type"    = "#microsoft.graph.accessPackageAnswerString"
                    value            = $DisplayName
                    displayValue     = "Display Name"
                    answeredQuestion = @{
                        "@odata.type" = "#microsoft.graph.accessPackageTextInputQuestion"
                        id            = "de4e3976-7377-4762-bda5-38880267357f"
                    }
                }
                @{
                    "@odata.type"    = "#microsoft.graph.accessPackageAnswerString"
                    value            = $Company
                    displayValue     = "Company"
                    answeredQuestion = @{
                        "@odata.type" = "#microsoft.graph.accessPackageTextInputQuestion"
                        id            = "511eae79-26f2-4a69-959e-55aad3758765"
                    }
                }
                @{
                    "@odata.type"    = "#microsoft.graph.accessPackageAnswerString"
                    value            = $Department
                    displayValue     = "Department"
                    answeredQuestion = @{
                        "@odata.type" = "#microsoft.graph.accessPackageTextInputQuestion"
                        id            = "a4712315-3939-4b7e-8285-3cb48dcbf583"
                    }
                }
            )
           
        }


        try {
            Write-Verbose ("Inviting external user: " + $EmailAddress)
           

            
            $bodyParams = ($params | ConvertTo-Json -Depth 10)

            write-verbose $bodyParams
            New-MgBetaEntitlementManagementAccessPackageAssignmentRequest -BodyParameter $bodyParams

        }
        catch {
            Write-Error ("Error Assigning {0} to Access Package: {1}" -f $EmailAddress, $_.ErrorDetails)
        }
        
    }
    
    end {
        
    }
}