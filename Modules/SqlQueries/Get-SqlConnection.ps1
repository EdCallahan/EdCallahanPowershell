function Get-SqlConnection {

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Server,

        [Parameter(Mandatory = $true, Position = 1)]
        [System.String]
        $Database
    )

    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server=$Server;Database=$Database;Integrated Security=True"
    $conn.Open()

    return $conn
}