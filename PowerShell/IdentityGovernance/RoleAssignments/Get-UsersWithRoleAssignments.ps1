<#
.SYNOPSIS
    Enumerate Users with Role Assignments
.DESCRIPTION
    Enumerate Uses with Eligible and Active Role Assignments
.NOTES
    https://github.com/JefTek/AzureADSamples
.LINK
    https://github.com/JefTek/AzureADSamples
.EXAMPLE
    Connect-MgGraph -scopes RoleManagement.Read.Directory,UserAuthenticationMethod.Read.All,AuditLog.Read.All,User.Read.All,Group.Read.All,Application.Read.All
    Get-UsersWithRoleAssignments
    Enumerate Users with Role Assignments
#>

{0}
function Get-UsersWithRoleAssignments()
{
    [CmdletBinding()]
    param (
        
    )
    
    begin {

    $uniquePrincipals = $null
    $usersWithRoles = $Null
    $groupsWithRoles = $null
    $servicePrincipalsWithRoles = $null
    $roleAssignments = @()
    $activeRoleAssignments = $null
    $eligibleRoleAssignments = $null
    $AssignmentSchedule =@()
        
    }
    
    process {

        Write-Verbose "Retrieving Active Role Assignments..."
    $activeRoleAssignments = Get-MgRoleManagementDirectoryRoleAssignmentSchedule -All:$true -ExpandProperty Principal|Add-Member -MemberType NoteProperty -Name AssignmentScope -Value "Active" -Force -PassThru|Add-Member -MemberType ScriptProperty -Name PrincipalType -Value {$this.Principal.AdditionalProperties."@odata.type".split('.')[2] } -Force -PassThru
    Write-Verbose ("{0} Active Role Assignments..." -f $activeRoleAssignments.count)
    $AssignmentSchedule += $activeRoleAssignments
    

    Write-Verbose "Retrieving Eligible Role Assignments..."
    $eligibleRoleAssignments = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All:$true -ExpandProperty Principal|Add-Member -MemberType NoteProperty -Name AssignmentScope -Value "Eligible" -Force -PassThru|Add-Member -MemberType ScriptProperty -Name PrincipalType -Value {$this.Principal.AdditionalProperties."@odata.type".split('.')[2] } -Force -PassThru
    Write-Verbose ("{0} Eligible Role Assignments..." -f $eligibleRoleAssignments.count)
    $AssignmentSchedule += $eligibleRoleAssignments

    Write-Verbose ("{0} Total Role Assignments to all principals..." -f $AssignmentSchedule.count)
    $uniquePrincipals = $AssignmentSchedule.PrincipalId|Get-Unique
    Write-Verbose ("{0} Total Role Assignments to unique principals..." -f $uniquePrincipals.count)

    foreach ($type in ($AssignmentSchedule|Group-Object PrincipalType))
    {
        Write-Verbose ("{0} assignments to {1} type" -f $type.count, $type.name)
    }
    
    foreach ($assignment in ($AssignmentSchedule))
    {
        

        if ($assignment.PrincipalType -eq 'user')
        {
            $roleAssignment = @{}
            $roleAssignment.PrincipalId = $assignment.PrincipalId
            $roleAssignment.PrincipalType = $assignment.PrincipalType
            $roleAssignment.AssignmentType = $assignment.AssignmentScope
            $roleAssignment.RoleDefinitionId = $assignment.RoleDefinitionId
            $roleAssignment.RoleAssignedBy = "user"
            $roleAssignment.RoleName = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $assignment.RoleDefinitionId|Select-Object -ExpandProperty displayName
            $roleAssignments += ([pscustomobject]$roleAssignment)
        }
       
        if ($assignment.PrincipalType -eq 'group')
        {
            Write-Verbose ("Expanding Group Members for Role Assignable Group {0}" -f $assignment.PrincipalId)
            $groupMembers = Get-MgGroupMember -GroupId $assignment.PrincipalId|Select-Object -ExpandProperty Id

            $RoleName = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $assignment.RoleDefinitionId|Select-Object -ExpandProperty displayName

            foreach ($member in $groupMembers)
            {
                Write-Verbose ("Adding Group Member {0} for Role Assignable Group {0}" -f $member,$assignment.PrincipalId)
               
                $roleAssignment = @{}
                $roleAssignment.PrincipalId = $member
                $roleAssignment.PrincipalType = "user"
                $roleAssignment.AssignmentType = $assignment.AssignmentScope
                $roleAssignment.RoleDefinitionId = $assignment.RoleDefinitionId
                $roleAssignment.RoleAssignedBy = "group"
                $roleAssignment.RoleName = $RoleName
                $roleAssignments += ([pscustomobject]$roleAssignment)

            }
        }

    }
    

    
    $usersWithRoles = $roleAssignments|Where-Object -FilterScript {$_.PrincipalType -eq 'user'}
    Write-Verbose ("{0} Total Role Assignments to Users" -f $usersWithRoles.count)
        
    }
    
    end {

        Write-Output $usersWithRoles
        
    }
    
}