<#
    Write a set of encrypted keys and passwords to a text file

    EdC 1/19/2021
#>
function Write-SecretKeys
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
        [string]$Application,

        [Parameter(ParameterSetName = 'File', Mandatory=$true, Position=1)]
        [Parameter(ParameterSetName = 'Database', Mandatory=$true, Position=4)]
        [HashTable]$Keys

    )

    <#

    ---
    --- The SQL table expected for $Table
    ---

    CREATE TABLE [dbo].[PasswordVault](
        [Application] [NVARCHAR](50) NOT NULL,
        [Username] [NVARCHAR](50) NOT NULL,
        [Key] [NVARCHAR](50) NOT NULL,
        [Value] [NVARCHAR](4000) NULL,
        [ServerName] [NVARCHAR](50) NOT NULL,
    CONSTRAINT [PK_PasswordVault] PRIMARY KEY CLUSTERED
    (
        [Application] ASC,
        [Username] ASC,
        [Key] ASC,
        [ServerName] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    ) ON [PRIMARY]
    #>

    if ( $PSCmdlet.ParameterSetName -eq 'File' ) {
        $null = $Keys.GetEnumerator() |
            Where-Object { $_.Value -ne '' } |
            ForEach-Object {($_.Key, (ConvertTo-SecureString -String $_.Value -AsPlainText -Force | ConvertFrom-SecureString)) -join ','} |
            Out-File -FilePath $FileName
    }

    if ( $PSCmdlet.ParameterSetName -eq 'Database' ) {

        $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $server = $env:COMPUTERNAME

        $sql = "delete from {0} where Application=@app and UserName=@user and ServerName=@server" -f $Table
        $null = Invoke-SqlNonQuery -Server $SqlServer -Database $Database -SQL $sql -Parameters @{app=$Application; user=$username; server=$server}

        $sql = "
            if not exists (select * from {0} where Application=@app and UserName=@user and ServerName=@server and [Key]=@key)
                insert into {0} (Application, UserName, ServerName, [Key], [Value]) values (@app, @user, @server, @key, @val)
            else
                update {0} set [Value]=@val where Application=@app and UserName=@user and ServerName=@server and [Key]=@key
        " -f $Table

        foreach ( $key in $Keys.Keys ) {
            $value = (ConvertTo-SecureString -String $keys[$key] -AsPlainText -Force | ConvertFrom-SecureString)
            $null = Invoke-SqlNonQuery -Server $SqlServer -Database $Database -SQL $sql -Parameters @{app=$Application; user=$username; server=$server; key=$key; val=$value}
        }

    }
}
