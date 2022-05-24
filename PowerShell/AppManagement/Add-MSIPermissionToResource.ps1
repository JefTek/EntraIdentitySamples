function Add-MSIPermission {
    [CmdletBinding()]
    param (
        $SpId,

        $ResourceApp="Microsoft Graph",
        $PermissionName
    )
    
    begin {
        
    }
    
    process {
        $sp = Get-MgServicePrincipal -ServicePrincipalId $SpId

        switch ($ResourceApp) {
            "Microsoft Graph" { $ResourceAppId = "00000003-0000-0000-c000-000000000000"  }
            Default {}
        }
        $resourceSp = Get-MgServicePrincipal -filter ("AppId eq '{0}'" -f $ResourceAppId)

        $AppRole = $resourceSp.AppRoles|Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains "Application"}
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $resourceSp.Id -AppRoleId $AppRole.Id

    }
    
    end {
        
    }
}