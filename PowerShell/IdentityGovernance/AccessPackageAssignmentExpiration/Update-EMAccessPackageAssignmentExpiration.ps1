<#
.SYNOPSIS
    Update Expiration date for existing assignment
.DESCRIPTION
    Update Expiration date for existing assignment
.EXAMPLE
    Update the assignment to expire 10 days from today
    Update-EMAccessPackageAssignmentExpiration -AccessPackageAssignmentId c6c63746-3a6a-45c9-adad-fce7ac4bbb73 -ExpirationDateTime (get-date).AddDays(10)
.EXAMPLE
    Update the assignment to set to expire, to not expire
    Update-EMAccessPackageAssignmentExpiration -AccessPackageAssignmentId c6c63746-3a6a-45c9-adad-fce7ac4bbb73 -SetNoExpiration
.NOTES
 - Assignment dates are bound by the policy of the original assignment (I cannot set an expiration date greater than the policy for the assignment allows)
 - Assignment policy must allow setting custom time spans for assignment
 - Assignment policy for existing assignment must be set for no expiration before setting an expiring assignment to no expiration
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
            ValueFromRemainingArguments = $false)]
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
            ParameterSetName = 'Set New Expiration Date')]
        [String]
        $ExpirationDateTime,
        [Parameter(Mandatory = $true,
            Position = 2,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Set No Expiration')]
        [switch]
        $SetNoExpiration

    )

    begin {

        $apiVersion = "beta"
        $GraphEndpoint = (Get-MgEnvironment | Where-Object Name -eq $Environment).GraphEndpoint
        $assignmentRequestsUri = ("{0}/{1}/identityGovernance/entitlementManagement/accessPackageAssignmentRequests/" -f $GraphEndpoint, $apiVersion)

        $RequestType = "AdminUpdate"


    }


    process {

        Write-Verbose "Retrieving AccessPackageAssignment $AccessPackageAssignmentId"

        $currentAssignment = $null
        $currentAssignment = Get-MgEntitlementManagementAccessPackageAssignment -AccessPackageAssignmentId $AccessPackageAssignmentId

        If ($currentAssignment.schedule.expiration.type -ne "noExpiration") {


            $currentExpirationDateTime = $currentAssignment.schedule.expiration.endDateTime

            $currentExpirationDays = (New-TimeSpan -End $currentExpirationDateTime -Start (get-date)).Days

            Write-verbose ("{0} Assignment currently expires on {1} ({2} Days)" -f $currentAssignment.id, $currentExpirationDateTime, $currentExpirationDays)

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

                If ($PSCmdlet.ParameterSetName -eq "Set New Expiration Date") {
                    $dtExpire = [System.DateTime]::Parse($ExpirationDateTime, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
                    if ($dtExpire.Kind -ne "Utc") {
                        $dtu = [System.DateTime]::SpecifyKind($dtExpire.ToUniversalTime(), [System.DateTimeKind]::Utc)
                    }
                    else {
                        $dtu = $dtExpire
                    }

                    $expiration.type = "afterDateTime"
                    $expiration.endDateTime = $dtu
                }

                If ($PSCmdlet.ParameterSetName -eq "Set No Expiration") {
                    Write-verbose ("Setting Assignment {0} to not expire." -f $currentAssignment.id)

                    if ($SetNoExpiration) {
                        $expiration.type = "noExpiration"
                        $expiration.endDateTime = $null
                    }
                }





                $schedule.expiration = $expiration

                $accessPackageAssignment.schedule = $schedule

                $accessPackageAssignmentRequest.accessPackageAssignment = $accessPackageAssignment

                $newRequestBody = $accessPackageAssignmentRequest | ConvertTo-Json -Depth 10


                $result = Invoke-MgGraphRequest -Method POST -uri $assignmentRequestsUri -Body $newRequestBody

                Write-Output ([pscustomobject]$result)
            }



        }
        else {
            Write-Warning ("Assignment {0} is currently set to not Expire, No updates needed!" -f $currentAssignment.id )
        }

    }

    end {
    }
}