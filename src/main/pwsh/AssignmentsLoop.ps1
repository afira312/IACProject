param(

    [Parameter(Mandatory = $true)]
    $subscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidateSet("tst", "acc", "prd")]
    $platformPrefix
)

. .\src\main\pwsh\Add-BlueprintToSubscription.ps1

$assignments = Get-ChildItem -Path "$platformPrefix-assignments" -Recurse -Filter "*.json" | Sort-Object -Property DirectoryName

foreach ($assignment in $assignments) {
    Write-Output "--------------------------"
    Write-Output "$($assignment.name)"
    Write-Output "--------------------------"
    
    $BPname = $($assignment.name).Split("-")[0]
    Write-Output "Blueprint name is $BPname"
    $assvertemp = $($assignment.name).Split("-")[1]
    $assver = $($assvertemp).Split(".")[0]
    Write-Output "Assignement version is $assver"
    if (
        $verobj = Get-Content .\blueprints\$BPname\metadata.json | ConvertFrom-Json | Select-Object Version -ErrorAction SilentlyContinue ) {
        $version = $verobj.version
        Write-Output '------------------------------------------------------'
        Write-Output " This will assign $BPname $version on $platformPrefix"
        Write-Output '------------------------------------------------------'
        Add-BlueprintToSubscription -subscriptionId $subscriptionId -name $BPname -version $version -platformPrefix $platformPrefix -asversion $assver
        Write-Output "Assignement $BPname is finished"

        if ($assignment.name -like '*KeyVault*') {
            $pass = Get-Content ".\src\main\pwsh\secrets.txt"
            $pass = ConvertTo-SecureString $pass -AsPlainText -Force
            Set-AzKeyVaultSecret -VaultName "notejam-keyvault" -Name 'administratorLoginPassword' -SecretValue $pass -ErrorAction SilentlyContinue
            Write-Output 'Setting the keyvault secret'
        }
    }
}