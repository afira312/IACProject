function Add-BlueprintToSubscription {
    [CmdletBinding()]
    param (
        # Name of the Blueprint
        [Parameter(Mandatory = $true)]
        [string]
        $name,

        # Version of the Blueprint
        [Parameter(Mandatory = $true)]
        [string]
        $version,

        # Subscription Id
        [Parameter(Mandatory = $true)]
        [string]
        $subscriptionId,

        # Shortcode for the environment
        [Parameter(Mandatory = $true)]
        [string]
        $platformPrefix,

        # version number of assignment
        [Parameter(Mandatory = $true)]
        [string]
        $asversion
    )

    begin {
        #region Functions

        # Validates if Blueprint exists in Subscription
        function Confirm-BlueprintExistsWithVersion {
            param(
                [Parameter(Mandatory = $true)]
                [ValidateNotNullorEmpty()]
                $name,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullorEmpty()]
                $version,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullorEmpty()]
                $subscriptionId
            )
            try {
                $blueprint = Get-AzBlueprint -Name $name -subscriptionId $subscriptionId -Version $version -ErrorAction Stop
            }
            catch {
                if ($_ -match "could not be found in subscription") {
                    return $null
                }
                else {
                    throw $_
                }
            }
            return $blueprint
        }

        # Validates if Blueprint is assigned to Subscription
        function Confirm-BlueprintIsAssignedToSubscription {
            param(
                [Parameter(Mandatory = $true)]
                [ValidateNotNullorEmpty()]
                $subscriptionId,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullorEmpty()]
                $name,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullorEmpty()]
                $version
            )

            try {
                $blueprintAssignment = Get-AzBlueprintAssignment -subscriptionId $subscriptionId -Name $name -ErrorAction Stop
            }
            catch {
                if ($_ -match "could not be found in subscription") {
                    return $False
                }
                throw $_
            }

            if ($null -eq $blueprintAssignment) {
                return $False
            }
            else {
                return ($blueprintAssignment.BlueprintId -match "$version$")
            }
        }

        # Get the Blueprint assignment object
        function Get-BlueprintAssignment {
            param(
                [Parameter(Mandatory = $true)]
                [ValidateNotNullorEmpty()]
                $subscriptionId,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullorEmpty()]
                $name,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullorEmpty()]
                $version
            )

            try {
                $blueprintAssignment = Get-AzBlueprintAssignment -subscriptionId $subscriptionId -Name $name -ErrorAction Stop
            }
            catch {
                if ($_ -match "could not be found in subscription") {
                    return $False
                }
                throw $_
            }

            if ($null -eq $blueprintAssignment) {
                return $False
            }
            else {
                return $blueprintAssignment
            }
        }
        #endregion Functions

        #$CWD = [Environment]::CurrentDirectory

        Push-Location $MyInvocation.MyCommand.Path
        [Environment]::CurrentDirectory = $PWD
        ##  Your script code calling a native executable
        Pop-Location

        $assignmentFiles = Get-ChildItem .\$($platformPrefix)-assignments\$($name) -Filter "*$name*"

    }

    process {
        try {
            #Blueprint object
            $blueprintReference = Confirm-BlueprintExistsWithVersion -name $name -version $version -subscriptionId $subscriptionId
            #Find assigment
            $bluePrintIsAssignedWithVersion = Confirm-BlueprintIsAssignedToSubscription -subscriptionId $subscriptionId -name "$($platformPrefix)-$($name)-$($asversion)" -version $version
            #Get the existing assigment
            $bluePrintAssignment = Get-BlueprintAssignment -subscription $subscriptionId -name "$($platformPrefix)-$($name)-$($asversion)" -version $version

        }
        catch {
            Write-Error "Failed to retrieve blueprint $($name)"
            Write-Error $_
        }
        if ($blueprintReference) {

            foreach ($assignmentFile in $assignmentFiles) {

                #Pulls the number from the assignment file
                $vers = (($assignmentFile.BaseName).split("-"))[-1]

                $bpobject = Get-AzBlueprint -subscriptionId $subscriptionId -Name $name

                $blueprintAssignmentParameters = @{
                    Name           = "$($platformPrefix)-$($name)-$($vers)"
                    Blueprint      = $bpobject
                    subscriptionId = $subscriptionId
                    AssignmentFile = $assignmentFile.PSPath
                }

                try {
                    $assignment = $null

                    if ($False -eq $bluePrintIsAssignedWithVersion) {
                        Write-Output "Assigning blueprint $($blueprintReference.name)-$($blueprintReference.id) to $($subscriptionId)"
                        $assignment = New-AzBlueprintAssignment @blueprintAssignmentParameters -ErrorAction Stop -Verbose
                    }

                    if ($True -eq $bluePrintIsAssignedWithVersion -and $bluePrintAssignment.ProvisioningState -ne "Succeeded") {
                        Write-Output "Updating assignment of blueprint $($blueprintReference.name)-$($blueprintReference.id) on $($subscriptionId)"
                        $assignment = Set-AzBlueprintAssignment @blueprintAssignmentParameters -ErrorAction Stop
                    }

                    if ($True -eq $bluePrintIsAssignedWithVersion -and $bluePrintAssignment.ProvisioningState -eq "Succeeded") {
                        Write-Output "$($blueprintReference.name) ($($blueprintReference.version)) is already assigned to $($subscription.name). (id: $($blueprintReference.id))"
                    }

                    while ($assignment -and $status.ProvisioningState -ne "Succeeded" -and $status.ProvisioningState -ne "Failed") {
                        $status = Get-AzBlueprintAssignment -subscriptionId $subscriptionId -Name "$($platformPrefix)-$($name)-$($vers)" -ErrorAction SilentlyContinue
                        Write-Output "Provisioning in progress..."
                        Start-Sleep -Seconds 30
                    }
                }
                catch {
                    Write-Error -Message "Failed to assign or update Blueprint $($blueprintReference.name) on $($subscription.name)."
                    Write-Error $_
                }
            }
        }
        else {
            if ($null -eq $blueprintReference) {
                Write-Error -Message "$($blueprint.name) ($($blueprint.version)) does not exist, cannot be assigned."
            }
        }
    }

    end {

    }
}