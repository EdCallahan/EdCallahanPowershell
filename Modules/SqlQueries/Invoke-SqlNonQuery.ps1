<#
.SYNOPSIS

  Run a SQL Command that does not return results

.DESCRIPTION

  Run a SQL Command that does not return results (insert, update, exec, etc)

  A server/database can be specified via parameters, or a SQL Connection object can be pass

  Paramers can be passed in a name-value hash. Parameters can also be passed with name/value/type information (especially for passing table paramters)

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

.PARAMETER Typed_Parameters

  Array of hashes containig parameter definitions, including Name, Value and Type

.PARAMETER Output_Parameters

  Array of names of output parameters, used when calling a stored procedure

.PARAMETER CommandType

  'Text' or 'StoredProcedure'

.PARAMETER Timeout

    Timeout, in seconds

.EXAMPLE

 Invoke-SqlNonQuery -Server sqlsrv1 -Database localhost\sql2019 -SQL 'dbo.spDoThings' -CommandType StoredProcedure -Typed_Parameters @(@{Name='dt'; Type=[System.Data.SqlDbType]::Structured; Value=$dt})

.NOTES

When using Typed_Paramters, $null values are not allowed. Use [DBNull]::Value instead.

#>

function Invoke-SqlNonQuery
{
  [CmdletBinding()]
  param
  (

    [parameter(ParameterSetName = 'Connection', Position = 0, Mandatory = $true)]
    [parameter(ParameterSetName = 'NoConnection', Position = 0, Mandatory = $true)]
    [String]$Sql,

    [parameter(ParameterSetName = 'Connection', Position = 1, Mandatory = $true)]
    [System.Data.SQLClient.SQLConnection]$Connection,

    [parameter(ParameterSetName = 'NoConnection', Position = 1, Mandatory = $true)]
    [String]$Database,

    [parameter(ParameterSetName = 'NoConnection', Position = 2, Mandatory = $true)]
    [String]$Server,

    [parameter(ParameterSetName = 'Connection', Position = 2, Mandatory = $false)]
    [parameter(ParameterSetName = 'NoConnection', Position = 3, Mandatory = $false)]
    [hashtable]$Parameters = @{},

    [parameter(ParameterSetName = 'Connection', Position = 3, Mandatory = $false)]
    [parameter(ParameterSetName = 'NoConnection', Position = 4, Mandatory = $false)]
    [object[]]$Typed_Parameters = @(),

    [parameter(ParameterSetName = 'Connection', Position = 4, Mandatory = $false)]
    [parameter(ParameterSetName = 'NoConnection', Position = 5, Mandatory = $false)]
    [hashtable]$Output_Parameters = @{},

    [parameter(ParameterSetName = 'Connection', Position = 5, Mandatory = $false)]
    [parameter(ParameterSetName = 'NoConnection', Position = 6, Mandatory = $false)]
    [ValidateSet('Text', 'StoredProcedure', ignorecase = $true)]
    [String]$CommandType = 'Text',

    [parameter(ParameterSetName = 'Connection', Position = 6, Mandatory = $false)]
    [parameter(ParameterSetName = 'NoConnection', Position = 7, Mandatory = $false)]
    [int]$Timeout = 30

  )
  PROCESS
  {

    try
    {
      if ( $PSCmdlet.ParameterSetName -eq 'NoConnection' )
      {
        $Connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
        $Connection.ConnectionString = "Server=$Server;Database=$Database;Integrated Security=True"
        $Connection.Open()
      }

      $cmd = New-Object -TypeName system.Data.SqlClient.SqlCommand -ArgumentList ($Sql, $Connection)
      $cmd.CommandTimeout = $Timeout
      $cmd.CommandType = [System.Data.CommandType]$CommandType

      foreach($p in $Parameters.Keys)
      {
        #if ($null -eq $Parameters[$p] ) {$Parameters[$p] = [DBNull]::Value}
        [Void] $cmd.Parameters.AddWithValue("@$p", $(switch ($Parameters[$p]) { $null {[DBNull]::Value} default {$Parameters[$p]} }))
      }

      foreach($p in $Typed_Parameters)
      {
        $param = New-Object -TypeName System.Data.SqlClient.SqlParameter
        $param.ParameterName = $p.Name
        $param.SqlDbType = $p.Type
        $param.Value = $p.Value
        [Void] $cmd.Parameters.Add($param)
      }

      foreach($p in $Output_Parameters.Keys)
      {
        $param = New-Object -TypeName System.Data.SqlClient.SqlParameter
        $param.ParameterName = "@$p"

        if ($null -eq $Output_Parameters[$p]) { $Output_Parameters[$p] = [DBNull]::Value }
        $param.Value = $Output_Parameters[$p]

        #without this line, varchars were being truncated to one character
        $param.Size = $param.Size

        $param.Direction = [System.Data.ParameterDirection]'Output'

        $null = $cmd.Parameters.Add($param)
      }

      $ret = $cmd.ExecuteNonQuery()

      $ret_param = @{}
      foreach($p in $Output_Parameters.Keys)
      {
        $ret_param[$p] = $cmd.Parameters["@$p"].Value
      }

      return @{
        'ReturnValue'     = $ret
        'Output_Parameters' = $ret_param
      }
    }
    finally
    {
      $cmd = $null
      if ( $PSCmdlet.ParameterSetName -eq 'NoConnection' )
      {
        $Connection.Close()
        $Connection = $null
      }
    }

  }
}
