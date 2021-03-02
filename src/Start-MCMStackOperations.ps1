#Import-Module AWSPowerShell.NetCore

$config = (Get-Content -Raw config.json) -join "`n" | convertfrom-json

function Start-MCMStackOperations {
    if($config.Customers.length -eq 0){
        Write-Host -ForegroundColor Magenta $("INFO : No customer accounts configured for this Stack.")
    } else {
        $deploy = @()
        $update = @()
        $remove = @()
        foreach ($customer in $config.Customers) {
            Switch (($customer.Status).ToLower()) {
                "deploy" { $deploy += $customer }
                "update" { $update += $customer }
                "remove" { $remove += $customer }
            }
        }
    }

    if($deploy){
        $deploy | ForEach-Object -Parallel {
            $function:MCMDeployStack = $using:funcDeployDef
            MCMDeployStack $_
        }
    }

    if($update){
        $update | ForEach-Object -Parallel {
            $function:MCMDeployStack = $using:funcDeployDef
            MCMDeployStack $_
        }
    }

    if($remove){
        $remove | ForEach-Object -Parallel {
            $function:MCMRemoveStack = $using:funcRemoveDef
            MCMRemoveStack $_
        }
    }
}

function MCMRemoveStack {
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object[]] $customer
    )
    Write-Host -ForegroundColor Blue $("INFO : {0} : Creating [ REMOVE ] Job." -f $customer.Name)
    .\Remove-MCMStack.ps1 -Customer $customer
}
$funcRemoveDef = $function:MCMRemoveStack.ToString() ## Get the function's definition *as a string* for paralle job

function MCMDeployStack {
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object[]] $customer
    )

    Write-Host -ForegroundColor Blue $("INFO : {0} : Creating [ DEPLOY ] Job." -f $customer.Name)
    .\Deploy-MCMStack.ps1 -Customer $customer
}
$funcDeployDef = $function:MCMDeployStack.ToString() ## Get the function's definition *as a string* for paralle job

Start-MCMStackOperations