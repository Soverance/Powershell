# Setup Pod Distribution SQL Configuration
# Scott McCutchen
# DevOps Engineer
# scott.mccutchen@soverance.com

# this script leverages the Microsoft SqlServer PowerShell Module to configure a SQL Server database,
# containing information about the distribution of customers across all nodes in the application infrastructure.
# this database can then be queried by the application to direct users towards a node containing a certain customer.

# Note that these commands from the SqlServer module get their credentials from the user context of the current PSSession
# to use SQL-Authentication instead of Windows, specify the -Credential param
# Note that the -Credential param will not work for Windows Authentication against SQL Server - you must use the current PSSession security context
# https://trello.com/c/yU17g25J/201-get-sqlinstance-doesnt-work

# Customers reporting on each node is done using a different script.  On each node, a file is created to store customer information. 
# This file is then read, the information is parsed into a custom PS Object called "AllCubes", which is then passed to this script.
# The "AllCubes" object must at a minimum contain the following information:

# $CubeInfo | Add-Member -MemberType NoteProperty -Name Cube -Value "BT1"  # this should be the customer's three-digit short code
# $CubeInfo | Add-Member -MemberType NoteProperty -Name "Build01" -Value "12:00 AM"  # you may create columns up to "Build12", to document multiple daily build times for the customer's data

#region Parameters
##############################################
###
###  Parameters
###
##############################################

param
(
    # the desired name of the SQL database
    # if this var is not specified, you'll get a new database called "Sisense.Pods" by default
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseName,

    # the fully-qualified name or address of the SQL Server instance 
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$ServerInstance,

    # the ID that has been assigned to this Node
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$NodeId,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$webServer = $(throw "-webServer : You must specify the app server URL."),

    # the ID that has been assigned to this Node
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$DeploymentEnvironment,

    # an array of the objects available on this node
    # this object must include the following parameters:

    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [array]$AllCubes,

    # the SQL Admin User
    [Parameter(ParameterSetName="SQLAuthentication", Mandatory=$False)]
    [string]$SqlAdminUser,

    # the SQL Admin password
    [Parameter(ParameterSetName="SQLAuthentication", Mandatory=$True)]
    [string]$SqlAdminPass
)
#endregion

#region Module Configuration
##############################################
###
###  Module Configuration
###
##############################################

$parent = (Get-Item $PSScriptRoot).Parent.FullName
$currentLocation = ";" + $parent + "\Modules"
$env:PSModulePath = $env:PSModulePath + $currentLocation
Import-Module SqlServer

#endregion

#region Functions
##############################################
###
###  Functions
###
##############################################

function New-Database()
{
    param
    (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$DatabaseName,
        
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$DeploymentEnvironment,

        [Parameter(ParameterSetName="SQLFiles", Mandatory=$False)]
        [string]$CreateDatabase = "$($PSScriptRoot)\Create-Database.sql",

        [Parameter(ParameterSetName="SQLAuthentication", Mandatory=$False)]
        [string]$SqlAdminUser,

        [Parameter(ParameterSetName="SQLAuthentication", Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]$creds
    )

    Write-Output "Database not found.  Creating..."
    $var_DatabaseName = "databaseName=$($DatabaseName)"  # name of database
    $var_DeploymentEnvironment = "DeploymentEnvironment=$($DeploymentEnvironment)" # name of table
    $variableArray = $var_DatabaseName, $var_DeploymentEnvironment

    if ($SqlAdminUser)
    {
        Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile $CreateDatabase -Variable $variableArray -Credential $creds 
    }
    else 
    {
        Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile $CreateDatabase -Variable $variableArray
    } 
}

function New-Table()
{
    param
    (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$DatabaseName,
        
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$DeploymentEnvironment,

        [Parameter(ParameterSetName="SQLFiles", Mandatory=$False)]
        [string]$CreateTable = "$($PSScriptRoot)\Create-Table.sql",

        [Parameter(ParameterSetName="SQLAuthentication", Mandatory=$False)]
        [string]$SqlAdminUser,

        [Parameter(ParameterSetName="SQLAuthentication", Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]$creds
    )

    Write-Output "Table not found.  Creating..."
    $var_DatabaseName = "databaseName=$($DatabaseName)"  # name of database
    $var_DeploymentEnvironment = "DeploymentEnvironment=$($DeploymentEnvironment)" # name of table
    $variableArray = $var_DatabaseName, $var_DeploymentEnvironment

    if ($SqlAdminUser)
    {
        Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile $CreateTable -Variable $variableArray -Credential $creds 
    }
    else 
    {
        Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile $CreateTable -Variable $variableArray
    } 
}

function Update-Documentation()
{
    param
    (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$DatabaseName,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$NodeId,
        
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$DeploymentEnvironment,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [array]$AllCubes,

        [Parameter(ParameterSetName="SQLFiles", Mandatory=$False)]
        [string]$AddCustomer = "$($PSScriptRoot)\Add-Customer.sql",

        [Parameter(ParameterSetName="SQLFiles", Mandatory=$False)]
        [string]$GetCustomers = "$($PSScriptRoot)\Get-Customers.sql",

        [Parameter(ParameterSetName="SQLFiles", Mandatory=$False)]
        [string]$RemoveCustomers = "$($PSScriptRoot)\Remove-Customers.sql",

        [Parameter(ParameterSetName="SQLAuthentication", Mandatory=$False)]
        [string]$SqlAdminUser,

        [Parameter(ParameterSetName="SQLAuthentication", Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]$creds
    )

    $var_DatabaseName = "databaseName=$($DatabaseName)"  # name of database
    $var_DeploymentEnvironment = "DeploymentEnvironment=$($DeploymentEnvironment)" # name of table
    $var_NodeId = "NodeId=$($NodeId)"  
    $var_AppUrl = "AppUrl=$($webServer)"   

    $variableArray = $var_DatabaseName, $var_NodeId, $var_DeploymentEnvironment, $var_AppUrl

    # Get current customers in database for this pod
    if ($SqlAdminUser)
    {
        $Customers = Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile $GetCustomers -Variable $variableArray -Credential $creds 
    }
    else 
    {
        $Customers = Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile $GetCustomers -Variable $variableArray  
    }        

    # if Customers are found for this pod, remove them all from the table to ensure we start with a clean inventory
    if ($Customers)
    {
        Write-Output "Found $($Customers.Count) Customers on $($DeploymentEnvironment) Node $($NodeId)."
        Write-Output "Deleting current records..."

        if ($SqlAdminUser)
        {
            $RemovedCustomers = Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile $RemoveCustomers -Variable $variableArray -Credential $creds 
        }
        else 
        {
            $RemovedCustomers = Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile $RemoveCustomers -Variable $variableArray
        }            

        if ($?)
        {
            Write-Output "Successfully deleted $($Customers.Count) records from the $($DeploymentEnvironment) table."
        }
    }
    else 
    {
        Write-Output "No Customers found for $($DeploymentEnvironment) Node $($NodeId)..."
    }

    Write-Output "Restoring records for Node $($NodeId) from latest Customer Registry..."

    # add each customer from the orchestrator schedule to the sql table
    foreach ($customer in $AllCubes)
    {
        # we have to perform error checking on the build time values, since they may not be set depending on how often the cube refreshes
        # if they are unset, we must set the value to NULL before inserting the data into the sql table
        if ($customer.Cube)
        {
            $var_CustomerId = "CustomerId=$($customer.Cube)" 
        }
        else 
        {
            $var_CustomerId = "CustomerId=NULL" 
        }
        if ($customer.Build1)
        {
            $var_Build01 = "Build01=$($customer.Build1)"
        } 
        else 
        {
            $var_Build01 = "Build01=NULL"
        }
        if ($customer.Build2)
        {
            $var_Build02 = "Build02=$($customer.Build2)"
        } 
        else 
        {
            $var_Build02 = "Build02=NULL"
        }
        if ($customer.Build3)
        {
            $var_Build03 = "Build03=$($customer.Build3)"
        } 
        else 
        {
            $var_Build03 = "Build03=NULL"
        }
        if ($customer.Build4)
        {
            $var_Build04 = "Build04=$($customer.Build4)"
        } 
        else 
        {
            $var_Build04 = "Build04=NULL"
        }
        if ($customer.Build5)
        {
            $var_Build05 = "Build05=$($customer.Build5)"
        } 
        else 
        {
            $var_Build05 = "Build05=NULL"
        }
        if ($customer.Build6)
        {
            $var_Build06 = "Build06=$($customer.Build6)"
        } 
        else 
        {
            $var_Build06 = "Build06=NULL"
        }
        if ($customer.Build7)
        {
            $var_Build07 = "Build07=$($customer.Build7)"
        } 
        else 
        {
            $var_Build07 = "Build07=NULL"
        }
        if ($customer.Build8)
        {
            $var_Build08 = "Build08=$($customer.Build8)"
        } 
        else 
        {
            $var_Build08 = "Build08=NULL"
        }
        if ($customer.Build9)
        {
            $var_Build09 = "Build09=$($customer.Build9)"
        } 
        else 
        {
            $var_Build09 = "Build09=NULL"
        }
        if ($customer.Build10)
        {
            $var_Build10 = "Build10=$($customer.Build10)"
        } 
        else 
        {
            $var_Build10 = "Build10=NULL"
        }
        if ($customer.Build11)
        {
            $var_Build11 = "Build11=$($customer.Build11)"
        } 
        else 
        {
            $var_Build11 = "Build11=NULL"
        }
        if ($customer.Build12)
        {
            $var_Build12 = "Build12=$($customer.Build12)"
        } 
        else 
        {
            $var_Build12 = "Build12=NULL"
        }

        $InsertVariableArray = $var_DatabaseName, $var_NodeId, $var_AppUrl, $var_DeploymentEnvironment, $var_CustomerId, $var_Build01, $var_Build02, $var_Build03, $var_Build04, $var_Build05, $var_Build06, $var_Build07, $var_Build08, $var_Build09, $var_Build10, $var_Build11, $var_Build12
        Write-Output "Adding record for ElastiCube $($customer.Cube) to $($DeploymentEnvironment) Pod $($NodeId)."

        # add all customers in pod to documentation table
        if ($SqlAdminUser)
        {
            $Entry = Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile $AddCustomer -Variable $InsertVariableArray -Credential $creds 
        }
        else 
        {
            $Entry = Invoke-Sqlcmd -ServerInstance $ServerInstance -InputFile $AddCustomer -Variable $InsertVariableArray
        }                
    }

    if ($?)
    {
        Write-Output "All Customers updated for $($DeploymentEnvironment) Pod $($NodeId)."
    }    
}

#endregion

#region Main
##############################################
###
###  Main
###
##############################################
try 
{ 
    # There may be cases where you'd rather just call this script outside of the customer application release pipeline (such as when seeding the table/schema into a DB without having an application node)
    # so if you require this use case, you can call this script without the -AllCubes param and this block will generate a dummy cube for you
    if (!$AllCubes)
    {
        [array]$AllCubes = @()
        $CubeInfo = New-Object -TypeName PSObject # make a new object for each cube
        $CubeInfo | Add-Member -MemberType NoteProperty -Name Cube -Value "BT1"
        $CubeInfo | Add-Member -MemberType NoteProperty -Name "Build01" -Value "12:00 AM"
        $AllCubes += $CubeInfo
    }

    # Get SQL Database
    if ($SqlAdminUser)
    {
        $pass = ConvertTo-SecureString -String $SQLAdminPass -AsPlainText -Force
        $creds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $SQLAdminUser, $pass

        $database = Get-SqlDatabase -Name $DatabaseName -ServerInstance $ServerInstance -Credential $creds
    }
    else 
    {
        $database = Get-SqlDatabase -Name $DatabaseName -ServerInstance $ServerInstance
    }    

    if ($database)
    {
        Write-Output "Found database $($DatabaseName) on server $($ServerInstance)"
        Write-Output "Checking for existence of Pod Documentation table..."

        if ($SqlAdminUser)
        {
            # NOTE:  I think this may require an error action of -SilentlyContinue
            # because when this cmdlet fails to read from the table (when it does not yet exist) it returns a non-zero exit code, which causes ADS pipeline to fail
            # however, this works as-is with standard error actions within a standard powershell session, so I'm not sure.
            $table = Read-SqlTableData -ServerInstance $ServerInstance -DatabaseName $DatabaseName -SchemaName "dbo" -TableName $DeploymentEnvironment -TopN 3 -Credential $creds 
        }
        else 
        {
            $table = Read-SqlTableData -ServerInstance $ServerInstance -DatabaseName $DatabaseName -SchemaName "dbo" -TableName $DeploymentEnvironment -TopN 3
        }  

        if ($table)
        {
            Write-Output "Found table $($DeploymentEnvironment) in database $($DatabaseName) on server $($ServerInstance)"
            Write-Output "Scanning for Customers located in $($DeploymentEnvironment) associated with Pod $($NodeId)..."
            
            # update the documentation table with new values
            if ($SqlAdminUser)
            {
                Update-Documentation -ServerInstance $ServerInstance -DatabaseName $DatabaseName -PodId $NodeId -DeploymentEnvironment $DeploymentEnvironment -AllCubes $AllCubes -SqlAdminUser $SqlAdminUser -creds $creds
            }
            else 
            {
                Update-Documentation -ServerInstance $ServerInstance -DatabaseName $DatabaseName -PodId $NodeId -DeploymentEnvironment $DeploymentEnvironment -AllCubes $AllCubes 
            }  
        }
        else 
        {
            # create a new documentation table because although the database exists, the specified table was not found
            if ($SqlAdminUser)
            {
                New-Table -ServerInstance $ServerInstance -DatabaseName $DatabaseName -DeploymentEnvironment $DeploymentEnvironment -SqlAdminUser $SqlAdminUser -creds $creds
            }
            else 
            {
                New-Table -ServerInstance $ServerInstance -DatabaseName $DatabaseName -DeploymentEnvironment $DeploymentEnvironment 
            }     

            # update the documentation table with new values
            if ($SqlAdminUser)
            {
                Update-Documentation -ServerInstance $ServerInstance -DatabaseName $DatabaseName -PodId $NodeId -DeploymentEnvironment $DeploymentEnvironment -AllCubes $AllCubes -SqlAdminUser $SqlAdminUser -creds $creds
            }
            else 
            {
                Update-Documentation -ServerInstance $ServerInstance -DatabaseName $DatabaseName -PodId $NodeId -DeploymentEnvironment $DeploymentEnvironment -AllCubes $AllCubes 
            }  
        }        
    }
    else 
    {     
        # create a new database and documentation table because the specified database was not found   
        if ($SqlAdminUser)
        {
            New-Database -ServerInstance $ServerInstance -DatabaseName $DatabaseName -DeploymentEnvironment $DeploymentEnvironment -SqlAdminUser $SqlAdminUser -creds $creds
        }
        else 
        {
            New-Database -ServerInstance $ServerInstance -DatabaseName $DatabaseName -DeploymentEnvironment $DeploymentEnvironment 
        }          
        
        # update the documentation table with new values
        if ($SqlAdminUser)
        {
            Update-Documentation -ServerInstance $ServerInstance -DatabaseName $DatabaseName -PodId $NodeId -DeploymentEnvironment $DeploymentEnvironment -AllCubes $AllCubes -SqlAdminUser $SqlAdminUser -creds $creds
        }
        else 
        {
            Update-Documentation -ServerInstance $ServerInstance -DatabaseName $DatabaseName -PodId $NodeId -DeploymentEnvironment $DeploymentEnvironment -AllCubes $AllCubes 
        }  
    }    
}
catch
{
    Write-Output "ERROR in $($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    exit 1
}
#endregion
