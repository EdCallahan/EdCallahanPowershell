<#
.SYNOPSIS

    Run a SQL query that results in a table of data, returns data as a DataTable object

.DESCRIPTION

    Run a SQL query that results in a table of data, return data as a DataTable object

    A server/database can be specified via parameters, or a SQL Connection object can be pass

    Paramers can be passed in a name-value hash.

.PARAMETER Sql

    SQL that will be executed

.PARAMETER Connection

    A System.Data.SQLClient.SQLConnection for the database the query will be run on

.PARAMETER Database

    The name of the database the query will be run on

.PARAMETER Server

    The name of the server the query will be run on

.PARAMETER Parameters

    Name/value pairs for the parameters that will be used in the SQL query

.PARAMETER Timeout

    Timeout, in seconds

.EXAMPLE

$dt = Get-SQLData -Server localhost\SQL2019 -Database OpData -SQL 'select * from dbo.Table'
$dt

.EXAMPLE

$conn = Get-SqlConnection -Server localhost\SQL2019 -Database OpData
$dt = Get-SQLData -Connection $conn -SQL 'select * from dbo.Table'
$dt

.EXAMPLE

$conn = Get-SqlConnection -Server localhost\SQL2019 -Database OpData
$dt = Get-SQLData -Connection $conn -SQL 'select * from dbo.Table'
$dt

.EXAMPLE

$dt = Get-SQLData -Server localhost\SQL2019 -Database OpData -SQL 'select * from dbo.Table where LVL_UG=@lvl' -Parameters @{lvl='U'}
$dt

.INPUTS

None. You cannot pipe objects to Get-SQLData

.OUTPUTS

System.Data.DataTable

.NOTES
When passing a Server/Database pair, integrated security is always used. If you need to use different credentials create a
System.Data.SQLClient.SQLConnection object and pass that to Get-SQLData

You may use $null when passing parameters to Get-SQLData, they will be converted to [DBNull]::Value
#>
function Get-SQLData {

    [CmdletBinding()]
    param
    (

        [parameter(ParameterSetName = 'Connection', Position = 0, Mandatory = $true)]
        [parameter(ParameterSetName = 'NoConnection', Position = 0, Mandatory = $true)]
        #SQL that will be executed
        [String]$Sql,

        [parameter(ParameterSetName = 'Connection', Position = 1, Mandatory = $true)]
        # A System.Data.SQLClient.SQLConnection for the database the query will be run on
        [System.Data.SQLClient.SQLConnection]$Connection,

        [parameter(ParameterSetName = 'NoConnection', Position = 1, Mandatory = $true)]
        # The name of the database the query will be run on
        [String]$Database,

        [parameter(ParameterSetName = 'NoConnection', Position = 2, Mandatory = $true)]
        # The name of the server the query will be run on
        [String]$Server,

        [parameter(ParameterSetName = 'Connection', Position = 2, Mandatory = $false)]
        [parameter(ParameterSetName = 'NoConnection', Position = 3, Mandatory = $false)]
        # Name/value pairs for the parameters that will be used in the SQL query
        [hashtable]$Parameters = @{ },

        [parameter(ParameterSetName = 'Connection', Position = 3, Mandatory = $false)]
        [parameter(ParameterSetName = 'NoConnection', Position = 4, Mandatory = $false)]
        # Timeout, in seconds
        [int]$Timeout = 30


    )

    try {

        if ( $PSCmdlet.ParameterSetName -eq 'NoConnection' ) {

            $Connection = New-Object System.Data.SqlClient.SqlConnection
            $Connection.ConnectionString = "Server=$Server;Database=$Database;Integrated Security=True"
            $Connection.Open()

        }

        $cmd = new-object system.Data.SqlClient.SqlCommand($Sql, $Connection)
        $cmd.CommandTimeout = $Timeout

        foreach ($p in $($Parameters.Keys)) {
            if ($null -eq $Parameters[$p]) {
                [Void] $cmd.Parameters.AddWithValue("@$p", [DBNull]::Value)
            }
            else {
                [Void] $cmd.Parameters.AddWithValue("@$p", $Parameters[$p])
            }
        }

        $DataTable = New-Object System.Data.DataTable
        $SqlDataReader = $cmd.ExecuteReader()
        $DataTable.Load($SqlDataReader)

        # a return datatable needs to be wrapped: otherwise it's returned as an array of datarows
        return @(, ($DataTable))

    }
    finally {
        $cmd = $null

        if ( $PSCmdlet.ParameterSetName -eq 'NoConnection' ) {

            $Connection.Close()
            $Connection = $null

        }

    }

}