function Get-AADGroupWritebackSettings {
    [CmdletBinding()]
    param (
        [string[]]
        $GroupId
    )
    
    begin {

        if ($null -eq (Get-MgContext)) {
            Write-Error "$(Get-Date -f T) - Please Connect to MS Graph API with the Connect-MgGraph cmdlet from the Microsoft.Graph.Authentication module first before calling functions!" -ErrorAction Stop
        }
        else {
            
            
            if ((Get-MgProfile).Name -ne "beta")
            {
                Write-Error "$(Get-Date -f T) - Please select the beta profile with 'Select-MgProfile -Name beta' to use this cmdlet" -ErrorAction Stop
            }
            

        }
        
    }
    
    process {

        foreach ($gid in $GroupId)
        {
            Write-Verbose ("Retrieving Group Writeback Settings for Group ID {0}" -f $gid)
            $checkedGroup = [ordered]@{}
            $group = $null
            $group = Get-MgGroup -GroupId $gid
            $checkedGroup.id = $group.Id
            $checkedGroup.DisplayName = $group.DisplayName


            $groupType = ($group.GroupTypes -contains 'Unified') ? 'M365' : 'Security'
            $checkedGroup.Type = $groupType
        
            $writebackEnabled = $null

            switch ($group.AdditionalProperties['writebackConfiguration'].isEnabled)
            {
                $true { $writebackEnabled = "TRUE"}
                $false { $writebackEnabled = "FALSE"}
                $null { $writebackEnabled = "NOTSET"}
            }
            
            
            if ($null -ne ($group.AdditionalProperties['writebackConfiguration'].onPremisesGroupType))
            {
                $WriteBackOnPremGroupType = $group.AdditionalProperties['writebackConfiguration'].onPremisesGroupType
            }
            else {
                if ($checkedGroup.Type -eq 'M365')
                {
                $WriteBackOnPremGroupType = "universalDistributionGroup (M365 DEFAULT)"
                }
                else {
                    $WriteBackOnPremGroupType = "universalSecurityGroup (Security DEFAULT)"
                }
            }

            $checkedGroup.WriteBackEnabled = $writebackEnabled
            $checkedGroup.WriteBackOnPremGroupType = $WriteBackOnPremGroupType

            if ($checkedGroup.Type -eq 'M365')
            {
                if ($checkedGroup.WriteBackEnabled -ne $false)
                {
                    $checkedGroup.EffectiveWriteBack = ("Cloud M365 group will be writtenback onprem as {0} grouptype" -f $WriteBackOnPremGroupType)
                }
                else {
                    $checkedGroup.EffectiveWriteBack = "Cloud M365 group will NOT be writtenback onprem"
                }
            }

            if ($checkedGroup.Type -eq 'Security')
            {
                if ($checkedGroup.WriteBackEnabled -eq $true)
                {
                    $checkedGroup.EffectiveWriteBack = ("Cloud security group will be writtenback onprem as {0} grouptype" -f $WriteBackOnPremGroupType)
                }
                else {
                    $checkedGroup.EffectiveWriteBack = "Cloud security will NOT be writtenback onprem"
                }
            }

            Write-Output ([pscustomobject]$checkedGroup)


        }
    }
    
    
    end {
        
    }
}