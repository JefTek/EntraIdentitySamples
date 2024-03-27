BeforeAll {
    . $PSScriptRoot\Update-EMAccessPackageAssignmentExpiration.ps1
    $assignmentId1 = "d219cafc-e735-4972-a452-a05b2255de34"
    $assignmentId2 = "c6c63746-3a6a-45c9-adad-fce7ac4bbb73"
    $assignmentId3 = "3fd22841-fbd1-4b8b-a59b-9027fb67a6fd"
}
Describe InScopeDate {
    It 'Should return Correct Expiration endDateTime' {
        $ExpirationDate = ((get-date -AsUTC)).AddDays(20)
        $updated = Update-EMAccessPackageAssignmentExpiration -AccessPackageAssignmentId $assignmentId1 -ExpirationDateTime $ExpirationDate
        $updated.requestStatus | Should -be "Accepted"
        ((Get-Date $updated.schedule.expiration.endDateTime -AsUTC)) | Should -be $ExpirationDate
    }

    It 'Attempting to set assignment to not expire should throw exception when not allowed by policy' {
        Update-EMAccessPackageAssignmentExpiration -AccessPackageAssignmentId $assignmentId1  -SetNoExpiration | should -Throw

    }

    It 'Attempting to set assignment that is already set to not expired to not expire throw warning' {
        Update-EMAccessPackageAssignmentExpiration -AccessPackageAssignmentId $assignmentId3  -SetNoExpiration | should -Throw

    }

    It 'Attempting to set assignment to timespan outside of the assignment policy timespan should throw exception' {
        $ExpirationDate = ((get-date -AsUTC).ToUniversalTime()).AddDays(1000)
        Update-EMAccessPackageAssignmentExpiration -AccessPackageAssignmentId $assignmentId2 -ExpirationDateTime $ExpirationDate | should -Throw

    }

}