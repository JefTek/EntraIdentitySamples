function Get-AADApplicationUsageInfo {
    [CmdletBinding()]
    param (
        $AppId,
        $DaysAgo=1
    )
    
    begin {
        $queryDate = get-date (get-date).AddDays($(0-$DaysAgo)) -UFormat %Y-%m-%dT00:00:00Z
        Write-verbose $queryDate
    }
    
    process {

        $logs = @("interactiveUser", "nonInteractiveUser", "servicePrincipal", "managedIdentity")

        $lastUsedDate = $null
        Write-Verbose ("Retrieving Sign-Ins to Application {0}" -f $AppId)

        $appInfo = [ordered]@{}
        $appInfo.AppId = $AppId
        $appInfo.AppDisplayName = (Get-MgServicePrincipal -Filter ("appId eq '{0}'" -f $AppId)).DisplayName

        foreach ($logName in $logs)
        {
            
        
             $events = $null
            Write-Verbose ("Counting events for the $log...")
            

            $filter = ("appId eq '{0}' and signInEventTypes/any(t: t eq '{1}') and createdDateTime ge {2}" -f $appId, $logName, $queryDate)

            Write-Verbose $filter
            $events = Get-MgAuditLogSignIn -all:$true -Filter $filter
            Write-Verbose ("{0} events for {1} eventType" -f $events.count,$logName)

            $appInfo.$($LogName+"_Count") =  $events.count

            if ($null -eq $events)
            {
                $appInfo.$($LogName+"_LastSignIn") = "N/A"
            }
            else {
                $appInfo.$($LogName+"_LastSignIn") = $events|sort CreatedDateTime|select -last 1|% CreatedDateTime

                if ($null = $lastUsedDate)
                {
                $lastUsedDate = $appInfo.$($LogName+"_LastSignIn")
                }
                else {
                    if ($appInfo.$($LogName+"_LastSignIn") -gt $lastUsedDate)
                    {
                        $lastUsedDate = $appInfo.$($LogName+"_LastSignIn")
                    }   
                }
            }
            
          
        }

        if ($null -ne $lastUsedDate)
        {
        $appInfo.LastUsageDate = $lastUsedDate
        }
        else {
            $appInfo.LastUsageDate = "Unknown"
        }

        Write-Output ([pscustomobject]$appInfo)
        
    }
    
    end {
        
    }
}