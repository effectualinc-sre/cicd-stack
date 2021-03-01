Param(
    [object[]] $Customer
)

$config = (Get-Content -Raw "config.json") -join "`n" | convertfrom-json

function Deploy-MCMStack {
    Import-Module AWSPowerShell.NetCore
    if(Get-MCMStack){
        Write-Host -ForegroundColor Blue $("INFO : {0} : Stack {1} already deployed. Will attempt to update stack." -f $Customer.Name, $config.Service.StackName)
        Update-MCMStack
    } else {
        try {
            New-CFNStack `
                -StackName $config.Service.StackName `
                -Description $config.Service.Description `
                -Region $config.Service.Region `
                -Capability 'CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM', 'CAPABILITY_AUTO_EXPAND' `
                -TemplateURL $config.Service.TemplateUrl `
                -Credential $AccountCred
            Write-Host -ForegroundColor Blue $("INFO : {0} : Deploying Stack {1}." -f $Customer.Name, $config.Service.StackName)
        } catch {
            Write-Host -ForegroundColor Red $("ERROR : {0} : {1}." -f $Customer.Name, $_.Exception.Message)
        }
    }
}

function Update-MCMStack {
    try {
        Update-CFNStack `
            -StackName $config.Service.StackName `
            -Description $config.Service.Description `
            -Region $config.Service.Region `
            -Capability 'CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM', 'CAPABILITY_AUTO_EXPAND' `
            -TemplateURL $config.Service.TemplateUrl `
            -Credential $AccountCred
        Write-Host -ForegroundColor Blue $("INFO : {0} : Updating Stack instances for {1}." -f $Customer.Name, $config.Service.StackName)
    } catch {
        Write-Host -ForegroundColor Red $("ERROR : {0} : {1}." -f $Customer.Name, $_.Exception.Message)
    }
}

function Get-MCMStack {
    try {
        $stackDetails = (Get-CFNStack -StackName $config.Service.StackName -Region $config.Service.Region -Credential $AccountCred)
    } catch {
        Write-Host -ForegroundColor Blue $("INFO : {0} : {1}" -f $Customer.Name, $_.Exception.Message)
    }
    return $stackDetails
 }

$AccountCred = ./Get-MCMCredential.ps1

Deploy-MCMStack