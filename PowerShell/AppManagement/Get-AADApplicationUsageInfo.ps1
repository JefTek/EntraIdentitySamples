function Get-AADApplicationUsageInfo {
    [CmdletBinding(DefaultParameterSetName = "AppId")]
    param (
        # The AppId to retrieve the service principal activity for
        # App ID for Service Principal
        [Parameter(Mandatory = $true, ParameterSetName = 'AppId', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript( {
                try {
                    [System.Guid]::Parse($_) | Out-Null
                    $true
                }
                catch {
                    throw "$_ is not a valid AppId format. Valid value is a GUID format only."
                }
            })]
        [string[]] $AppId,

        # Service Principal Object
        [Parameter(Mandatory = $true, ParameterSetName = 'GraphServicePrincipal', Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Object[]]
        $ServicePrincipal,
        # Days ago to look at Audit Log history (ex 7 Days Ago)
        [ValidateRange(1, 30)]
        [int]
        $DaysAgo = 1
    )

    begin {

        ## Initialize Critical Dependencies
        $CriticalError = $null
        try {


            ## Check MgModule Connection
            $MgContext = Get-MgContext
            if ($MgContext) {
                ## Check MgModule Consented Scopes
                $cmdletsUsed = @("Get-MgServicePrincipal", "Get-MgAuditLogSignIn")

                foreach ($c in $cmdletsUsed) {
                    $MgPermissions = Find-MgGraphCommand -Command $c -ApiVersion beta | Select-Object -First 1 -ExpandProperty Permissions
                    if (!(Compare-Object $MgPermissions.Name -DifferenceObject $MgContext.Scopes -ExcludeDifferent)) {
                        Write-Error "Additional scope needed for $c, call Connect-MgGraph with one of the following scopes: $($MgPermissions.Name -join ', ')" -ErrorAction Stop
                    }
                }
            }
            else {
                Write-Error "Authentication needed, call Connect-MgGraph." -ErrorAction Stop
            }
        }
        catch { Write-Error -ErrorRecord $_ -ErrorVariable CriticalError; return }

        ## Save Current MgProfile to Restore at End
        $previousMgProfile = Get-MgProfile
        if ($previousMgProfile.Name -ne 'beta') {
            Select-MgProfile -Name 'beta'
        }

        $queryDate = get-date (get-date).AddDays($(0 - $DaysAgo)) -UFormat %Y-%m-%dT00:00:00Z
        Write-verbose $queryDate
    }

    process {

        $logs = @("interactiveUser", "nonInteractiveUser", "servicePrincipal", "managedIdentity")

        if ($null -ne $ServicePrincipal) {
            $AppId = $ServicePrincipal.AppId
        }

        foreach ($aId in $appId) {

            $lastUsedDate = $null
            Write-Verbose ("Retrieving Sign-Ins to Application {0}" -f $aId)

            $appInfo = [ordered]@{}
            $appInfo.AppId = $aId
            $appInfo.AppDisplayName = (Get-MgServicePrincipal -Filter ("appId eq '{0}'" -f $aId)).DisplayName

            foreach ($logName in $logs) {


                $events = $null
                Write-Verbose ("Counting events for the $log...")


                $filter = ("appId eq '{0}' and signInEventTypes/any(t: t eq '{1}') and createdDateTime ge {2}" -f $aId, $logName, $queryDate)

                Write-Verbose $filter
                $events = Get-MgAuditLogSignIn -all:$true -Filter $filter
                Write-Verbose ("{0} events for {1} eventType" -f $events.count, $logName)

                $appInfo.$($LogName + "_Count") = $events.count

                if ($null -eq $events) {
                    $appInfo.$($LogName + "_LastSignIn") = "N/A"
                }
                else {
                    $appInfo.$($LogName + "_LastSignIn") = $events | Sort-Object CreatedDateTime | Select-Object -last 1 | ForEach-Object CreatedDateTime

                    if ($null = $lastUsedDate) {
                        $lastUsedDate = $appInfo.$($LogName + "_LastSignIn")
                    }
                    else {
                        if ($appInfo.$($LogName + "_LastSignIn") -gt $lastUsedDate) {
                            $lastUsedDate = $appInfo.$($LogName + "_LastSignIn")
                        }
                    }
                }


            }

            if ($null -ne $lastUsedDate) {
                $appInfo.LastUsageDate = $lastUsedDate
            }
            else {
                $appInfo.LastUsageDate = "Unknown"
            }

            Write-Output ([pscustomobject]$appInfo)

        }

    }

    end {

    }
}