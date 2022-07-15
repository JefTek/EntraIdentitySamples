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
        
    }
    
    process {

        foreach ($gid in $GroupId)
        {

            $group = Get-MgGroup -GroupId $gid

            if ($group.GroupTypes -notcontains 'Unified')
            {
                if ($WriteBackOnPremGroupType -ne 'universalSecurityGroup')
                {
                    throw ("{0} is not an M365 Group and can only be written back as a univeralSecurityGroup type!" -f $gid)
                }
            }


            $wbc = @{}
            $updates = @{}
            $updates.isEnabled = $WriteBackEnabled
            $updates.onPremisesGroupType = $WriteBackOnPremGroupType
            $wbc.writebackConfiguration = $updates

            write-verbose ($wbc|convertto-json|out-string)
            Update-MgGroup -GroupId $gid -BodyParameter ($wbc|convertto-json -depth 10)
    }
}
    
    end {
        
    }
}