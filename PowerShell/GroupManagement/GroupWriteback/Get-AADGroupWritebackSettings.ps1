function Get-AADGroupWritebackSettings {
    [CmdletBinding()]
    param (
        [string[]]
        $GroupId
    )
    
    begin {
        
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
                $WriteBackOnPremGroupType = "NOT DEFINED"
            }

            $checkedGroup.WriteBackEnabled = $writebackEnabled
            $checkedGroup.WriteBackOnPremGroupType = $WriteBackOnPremGroupType

            if ($checkedGroup.Type -eq 'M365')
            {
                if ($checkedGroup.WriteBackEnabled -ne $false)
                {
                    $checkedGroup.EffectiveWriteBack = "will be writtenback onprem"
                }
                else {
                    $checkedGroup.EffectiveWriteBack = "will NOT be writtenback onprem"
                }
            }

            if ($checkedGroup.Type -eq 'Security')
            {
                if ($checkedGroup.WriteBackEnabled -eq $true)
                {
                    $checkedGroup.EffectiveWriteBack = "will be writtenback onprem"
                }
                else {
                    $checkedGroup.EffectiveWriteBack = "will NOT be writtenback onprem"
                }
            }

            Write-Output ([pscustomobject]$checkedGroup)


        }
    }
    
    
    end {
        
    }
}