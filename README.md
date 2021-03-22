# Blueprints

This Repository is used to deploy the infrastructure of NoteJam application on Azure

# Steps

## Step 1

Begin with connecting to Azure Account with the right context (connect-azaccount)
Next in the file .\src\main\pwsh\secrets.txt enter a sqlserver password. This is needed to add the secret in keyvault and then use the keyvault secret as reference during sql server deployment.

## Step 2

Run the publishBlueprints.ps1 script from .\src\main\pwsh location.
Provide the subscription ID you wish to deploy these blueprints.

## Step 3

Note : In case of any assignment failure in azure, please unassign the assignment from the portal and then rerun the Scripts

Run the AssignmentsLoop.ps1 script to deploy to a respective environment.

-platformPrefix (this is the environment to which you wish to deploy, eg tst,acc or prd)

-subscriptionId (same subscription id where the blueprints were published)

This script calls the assignment files within the folder of the environment prefix provided. Eg: if platformPrefix was tst then tst-assignments folder is initiated and all the blueprint assignment files will be deployed.

These assignment files have a location to the blueprint where they were published hence when you deploy to a subscription be ware to change the subscription ID of the assignment files as shown below.

"blueprintId": "/subscriptions/{SUBSCRIPTIONID}/providers/Microsoft.Blueprint/blueprints/KeyVault",