<#
.SYNOPSIS
    Measures the count of events in the specified sign-in log stream
.DESCRIPTION
    Measures the count of events in the specified sign-in log stream
.NOTES
- Review the signInEventTypes availiable in the MS Graph API -  https://docs.microsoft.com/en-us/graph/api/resources/signin?view=graph-rest-beta
- The SignIn API doesn't currently support advanced queries for count, so this can be a very long query depending on the amount of data - https://docs.microsoft.com/en-us/graph/aad-advanced-queries?context=graph%2Fapi%2Fbeta&view=graph-rest-beta&tabs=http
#>
function Measure-AADSignInLogEvents {
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
                   SupportsShouldProcess=$true,
                   PositionalBinding=$false,
                   HelpUri = 'http://www.microsoft.com/',
                   ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
        # Log Event Types to Count
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false, 
                   ParameterSetName='Parameter Set 1')]
        [ValidateSet("All", "interactiveUser", "nonInteractiveUser", "servicePrincipal", "managedIdentity")]
        $LogEventTypes="All",
        $DaysAgo=1
    )
    
    begin {

        switch ($LogEventTypes)
        {
            "All" {

                $logs = @("interactiveUser", "nonInteractiveUser", "servicePrincipal", "managedIdentity")
            }
            default{
                $logs = $LogEventTypes
            }
        }

    }
    
    process {
       $LogCounts = @{}
        
        foreach ($eventType in $logs)
        {
            $events = $null
            Write-Verbose ("Counting events for the $eventType...")
            $queryDate = get-date (get-date).AddDays($(0-$DaysAgo)) -UFormat %Y-%m-%dT00:00:00Z
            Write-verbose $queryDate
            $events = Get-MgAuditLogSignIn -all:$true -Filter ("signInEventTypes/any(t: t eq '{0}') and createdDateTime ge {1}" -f $eventType, $queryDate)
            Write-Verbose ("{0} events for {1} eventType" -f $events.count,$eventType)
            $logCounts.$eventType = $events.count
        }

        Write-output ([PSCustomObject]$logCounts)
    }
    
    end {
    }
}