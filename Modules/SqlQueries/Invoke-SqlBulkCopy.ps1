<#
.SYNOPSIS

    Bulk load the contents of a DataTable or a CSV file into a SQL Table

.DESCRIPTION

    Bulk load the contents of a DataTable or a CSV file into a SQL Table

    A server/database can be specified via parameters, or a SQL Connection object can be pass

    Either a DataTable object or the name of a CSV file are provided

.PARAMETER Connection

    A System.Data.SQLClient.SQLConnection for the database the query will be run on

.PARAMETER Database

    The name of the database the query will be run on

.PARAMETER Server

    The name of the server the query will be run on

.Parameter DestinationTable

    The SQL table that data will be pushed into

.Parameter DataTable

    The DataTable object that will be pushed to SQL

.Parameter FileName

    The name, including path, of the CSV file that will be processed

.PARAMETER Timeout

    Timeout, in seconds

.EXAMPLE

$null = Invoke-SqlBulkCopy -Server localhost\SQL2019 -Database OpData -DestinationTable 'dbo.Table' -DataTable $dt

.EXAMPLE

$conn = Get-SqlConnection -Server localhost\SQL2019 -Database OpData
$null = Invoke-SqlBulkCopy -Connection $conn -DestinationTable 'dbo.Table' -DataTable $dt

.EXAMPLE

$null = Invoke-SqlBulkCopy -Server localhost\SQL2019 -Database OpData -DestinationTable 'dbo.Table' -FileName 'c:\temp\Table.csv'

.INPUTS

None. You cannot pipe objects to Get-SQLData

.OUTPUTS

None.

.NOTES
When passing a Server/Database pair, integrated security is always used. If you need to use different credentials create a
System.Data.SQLClient.SQLConnection object and pass that to Get-SQLData

The DestinationTable must already exist and contain the necessary fields that exist in the DataTable or CSV file

CSV files are processed using the CVSHelper utility dll from https://joshclose.github.io/CsvHelper/
#>
function Invoke-SqlBulkCopy {
    [CmdletBinding()]
    param
    (

        [parameter(ParameterSetName = 'ConnectionDT', Position = 0, Mandatory = $true)]
        [parameter(ParameterSetName = 'ConnectionFile', Position = 0, Mandatory = $true)]
        [System.Data.SQLClient.SQLConnection]$Connection,

        [parameter(ParameterSetName = 'NoConnectionDT', Position = 0, Mandatory = $true)]
        [parameter(ParameterSetName = 'NoConnectionFile', Position = 0, Mandatory = $true)]
        [String]$Database,

        [parameter(ParameterSetName = 'NoConnectionDT', Position = 1, Mandatory = $true)]
        [parameter(ParameterSetName = 'NoConnectionFile', Position = 1, Mandatory = $true)]
        [String]$Server,

        [parameter(ParameterSetName = 'ConnectionDT', Position = 1, Mandatory = $true)]
        [parameter(ParameterSetName = 'NoConnectionDT', Position = 2, Mandatory = $true)]
        [parameter(ParameterSetName = 'ConnectionFile', Position = 1, Mandatory = $true)]
        [parameter(ParameterSetName = 'NoConnectionFile', Position = 2, Mandatory = $true)]
        [String]$DestinationTable,

        [parameter(ParameterSetName = 'ConnectionDT', Position = 2, Mandatory = $true)]
        [parameter(ParameterSetName = 'NoConnectionDT', Position = 3, Mandatory = $true)]
        [System.Data.DataTable]$DataTable,

        [parameter(ParameterSetName = 'ConnectionFile', Position = 2, Mandatory = $true)]
        [parameter(ParameterSetName = 'NoConnectionFile', Position = 3, Mandatory = $true)]
        [String]$FileName,

        [parameter(ParameterSetName = 'ConnectionDT', Position = 3, Mandatory = $false)]
        [parameter(ParameterSetName = 'NoConnectionDT', Position = 4, Mandatory = $false)]
        [parameter(ParameterSetName = 'ConnectionFile', Position = 3, Mandatory = $false)]
        [parameter(ParameterSetName = 'NoConnectionFile', Position = 4, Mandatory = $false)]
        [int]$Timeout = 30

    )
    PROCESS {

        try {
            if ( $PSCmdlet.ParameterSetName -match '^NoConnection' ) {
                $Connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
                $Connection.ConnectionString = "Server=$Server;Database=$Database;Integrated Security=True"
                $Connection.Open()
            }

            $BulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($Connection)
            $BulkCopy.DestinationTableName = $DestinationTable
            $BulkCopy.BulkCopyTimeout = $Timeout

            if ( $PSCmdlet.ParameterSetName -match 'DT$' )
            {
                $BulkCopy.WriteToServer($DataTable)
            }

            if ( $PSCmdlet.ParameterSetName -match 'File$' )
            {

                # if we're processing a CSV file, make sure the column names match the db table
                # we handle the case of the file only having the header line with no data
                $header = Get-Content $FileName -First 1
                $file_columns = ("$header`n$header" | ConvertFrom-CSV)[0].psobject.properties | ForEach-Object {$_.Name}
                $db_columns = (Get-SQLData -Connection $connection -Sql "select * from $DestinationTable where 1=0").Columns.ColumnName
                0..($file_columns.Count - 1) | ForEach-Object { if ( $file_columns[$_] -ne $db_columns[$_] ) { throw ('Database columns in {0} do not match CSV columns in {1}' -f $DestinationTable, $FileName) } }

                $sr = New-Object System.IO.StreamReader($FileName)
                $csv = New-Object CsvHelper.CsvReader($sr)
                $reader = New-Object CsvHelper.CsvDataReader($csv)

                $BulkCopy.WriteToServer($reader)
            }

        }
        finally {

            $BulkCopy.Close()

            if ( $PSCmdlet.ParameterSetName -match 'File$' )
            {
                if ( $null -ne $reader )
                {
                    $reader.Close()
                    $reader = $null
                }
                $csv = $null
                if ($null -ne $sr)
                {
                    $sr.Close()
                    $sr = $null
                }
            }

            if ( $PSCmdlet.ParameterSetName -match '^NoConnection' ) {
                $Connection.Close()
                $Connection = $null
            }

        }

    }
}
