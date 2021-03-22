param(

    [Parameter(Mandatory = $true)]
    $subscriptionId
)

Import-Module Az.Blueprint

$blueprints = Get-ChildItem -Path "blueprints"

foreach ($blueprint in $blueprints) {
    $fullpath = Join-Path -Path $blueprint.FullName -ChildPath "metadata.json"

    try {
        $metaData = (Get-Content $fullpath -ErrorAction Stop | ConvertFrom-Json)
    }
    catch [Exception] {
        Write-Error "Unable to retrieve metadata.json for $blueprint. Will not publish this blueprint."
        continue
    }

    $blueprintName = Split-Path -Path $blueprint -Leaf
    Write-Output "$blueprintName ($($metaData.version))"

    $blueprintDetails = Get-AzBluePrint -subscriptionId $subscriptionId -Name $blueprintName -ErrorAction SilentlyContinue
    
    if ($metaData.version -in $blueprintDetails.Versions) {
        Write-Output "Version $($metaData.version) of $blueprintName already exists in the Azure Portal."
        continue
    }

    Import-AzBlueprintWithArtifact -Name $blueprintName -subscriptionId $subscriptionId -InputPath $blueprint.FullName -Force
    $azBluePrint = Get-AzBluePrint -subscriptionId $subscriptionId -Name $blueprintName
    Publish-AzBlueprint -Blueprint $azBluePrint -Version $metaData.version -ChangeNote $metaData.changeNote
}