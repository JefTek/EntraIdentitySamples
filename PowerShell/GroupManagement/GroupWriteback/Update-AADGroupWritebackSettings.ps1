function Update-AADGroupWritebackSettings {
    [CmdletBinding()]
    param (
        [string[]]
        $GroupId,
        [bool]
        $WriteBackEnabled,
        [ValidateSet("universalDistributionGroup", "universalSecurityGroup", "universalMailEnabledSecurityGroup",$null)]
        [string]
        $WriteBackOnPremGroupType
    )
    
    begin {

        if ($null -eq (Get-MgContext)) {
            Write-Error "$(Get-Date -f T) - Please Connect to MS Graph API with the Connect-MgGraph cmdlet from the Microsoft.Graph.Authentication module first before calling functions!" -ErrorAction Stop
        }
        else {
            
            if (((Get-MgContext).Scopes -notcontains "Directory.ReadWrite.All") -and ((Get-MgContext).Scopes -notcontains "Group.ReadWrite.All"))
            {
                Write-Error "$(Get-Date -f T) - Please Connect to MS Graph API with the 'Connect-MgGraph -Scopes Group.ReadWrite.All' to include the Group.ReadWrite.All scope to update groups from MS Graph API." -ErrorAction Stop
            }
            
            if ((Get-MgProfile).Name -ne "beta")
            {
                Write-Error "$(Get-Date -f T) - Please select the beta profile with 'Select-MgProfile -Name beta' to use this cmdlet" -ErrorAction Stop
            }
            

        }
        
    }
    
    process {

        foreach ($gid in $GroupId)
        {

            $group = Get-MgGroup -GroupId $gid

            if ($group.GroupTypes -notcontains 'Unified')
            {
                if ($WriteBackOnPremGroupType -ne 'universalSecurityGroup')
                {
                    write-error ("{0} is not an M365 Group and can only be written back as a univeralSecurityGroup type!" -f $gid) -ErrorAction Stop
                }
            }


            $wbc = @{}
            $updates = @{}
            $updates.isEnabled = $WriteBackEnabled
            $updates.onPremisesGroupType = $WriteBackOnPremGroupType
            $wbc.writebackConfiguration = $updates

            Write-Verbose ("Updating Group {0} with Group Writeback settings of Writebackenabled={1} and onPremisesGroupType={2}" -f $gid,$WriteBackEnabled,$WriteBackOnPremGroupType )
            Update-MgGroup -GroupId $gid -BodyParameter ($wbc|convertto-json -depth 10)
            Write-Verbose ("Group Updated!")
    }
}
    
    end {
        
    }
}