<#
.SYNOPSIS
    Update Expiration date for existing assignment
.DESCRIPTION
    Update Expiration date for existing assignment
.EXAMPLE
    Update the assignment to expire 10 days from today
    Update-EMAccessPackageAssignmentExpiration -AccessPackageAssignmentId c6c63746-3a6a-45c9-adad-fce7ac4bbb73 -ExpirationDateTime (get-date).AddDays(10)

.NOTES
Assignment dates are bound by the policy of the original assignment

#>
function Update-EMAccessPackageAssignmentExpiration {
    [CmdletBinding(DefaultParameterSetName = 'Core',
        SupportsShouldProcess = $false,
        PositionalBinding = $false,
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
        # The ObjectID of the Access Package Assignment that will be updated
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Core')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                try {
                    [System.Guid]::Parse($_) | Out-Null
                    $true
                }
                catch {
                    throw "$_ is not a valid ObjectID format. Valid value is a GUID format only."
                }
            })]
        [Alias("AssignmentId")]
        $AccessPackageAssignmentId,

        # The Expiration Date for the assignment
        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Core')]
        [String]
        $ExpirationDateTime

    )

    begin {

        $apiVersion = "beta"
        $GraphEndpoint = (Get-MgEnvironment | Where-Object Name -eq $Environment).GraphEndpoint
        $assignmentRequestsUri = ("{0}/{1}/identityGovernance/entitlementManagement/accessPackageAssignmentRequests/" -f $GraphEndpoint, $apiVersion)

        $RequestType = "AdminUpdate"

        $dtExpire = [System.DateTime]::Parse($ExpirationDateTime, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
        if ($dtExpire.Kind -ne "Utc") {
            $dtu = [System.DateTime]::SpecifyKind($dtExpire.ToUniversalTime(), [System.DateTimeKind]::Utc)
        }
        else {
            $dtu = $dtExpire
        }
    }


    process {

        Write-Verbose "Retrieving AccessPackageAssignment $AccessPackageAssignmentId"

        $currentAssignment = $null
        $currentAssignment = Get-MgEntitlementManagementAccessPackageAssignment -AccessPackageAssignmentId $AccessPackageAssignmentId

        If ($null -eq $currentAssignment) {
            Write-Error ("Assignment not found for $AccessPackageAssignmentId!")

        }
        else {

            $AssignmentPolicyId = $currentAssignment.assignmentPolicyId

            $accessPackageAssignmentRequest = @{}
            $accessPackageAssignmentRequest.requestType = $RequestType

            $accessPackageAssignment = @{}
            $accessPackageAssignment.id = $currentAssignment.id
            $accessPackageAssignment.assignmentPolicyId = $AssignmentPolicyId





            $schedule = @{}

            $schedule.startDateTime = $currentAssignment.schedule.StartDateTime
            $expiration = @{}

            $expiration.type = "afterDateTime"
            $expiration.endDateTime = $dtu

            $schedule.expiration = $expiration

            $accessPackageAssignment.schedule = $schedule




            $accessPackageAssignmentRequest.accessPackageAssignment = $accessPackageAssignment

            $newRequestBody = $accessPackageAssignmentRequest | ConvertTo-Json -Depth 10

            try {

                Invoke-MgGraphRequest -Method POST -uri $assignmentRequestsUri -Body $newRequestBody
            }
            catch {

                write-error $_

            }


        }

    }

    end {
    }
}