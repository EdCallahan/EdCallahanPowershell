<#
    Read and decrypt a set of keys from a file written by the Write-SecretKeys function

    EdC 1/19/2021
#>

function Read-SecretKeys
{
    [CmdletBinding()]
    Param
    (

        [Parameter(ParameterSetName = 'File', Mandatory=$true, Position=0)]
        [string]$FileName,

        [Parameter(ParameterSetName = 'Database', Mandatory=$false, Position=0)]
        [string]$SqlServer = $env:SecretKeyServer,

        [Parameter(ParameterSetName = 'Database', Mandatory=$false, Position=1)]
        [string]$Database = $env:SecretKeyDatabase,

        [Parameter(ParameterSetName = 'Database', Mandatory=$false, Position=2)]
        [string]$Table = $env:SecretKeyTable,

        [Parameter(ParameterSetName = 'Database', Mandatory=$true, Position=3)]
        [string]$Application

    )

    $keys = @{}

    if ( $PSCmdlet.ParameterSetName -eq 'File' ) {
        $null = Get-Content $FileName |
            ForEach-Object{ $c = $_ -split ','; $keys[$c[0]] = $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'N/A', (ConvertTo-SecureString $c[1])).GetNetworkCredential().Password }
    }

    if ( $PSCmdlet.ParameterSetName -eq 'Database' ) {

        $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $server = $env:COMPUTERNAME

        $sql = 'select [Key], [Value] from {0} where Application=@app and Username=@user and Servername=@server' -f $Table

        foreach ($row in (Get-SQLData -Server $SqlServer -Database $Database -Sql $sql -Parameters @{app=$Application; user=$username; server=$server}).Rows ) {
            $keys[$row.Key] = $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'N/A', (ConvertTo-SecureString $row.Value)).GetNetworkCredential().Password
        }

    }

    $keys

}