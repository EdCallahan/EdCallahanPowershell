@{

# Module Loader File
RootModule = 'loader.psm1'

# Version Number
ModuleVersion = '1.1'

# Unique Module ID
GUID = 'a3256007-086e-4a72-b210-f2177e3e2d57'

# Module Author
Author = 'Ed Callahan'

# Module Description
Description = 'Bulk copy from a datatable/reader to a SQL database table'

# Minimum PowerShell Version Required
PowerShellVersion = ''

# Name of Required PowerShell Host
PowerShellHostName = ''

# Minimum Host Version Required
PowerShellHostVersion = ''

# Minimum .NET Framework-Version
DotNetFrameworkVersion = ''

# Minimum CLR (Common Language Runtime) Version
CLRVersion = ''

# Processor Architecture Required (X86, Amd64, IA64)
ProcessorArchitecture = ''

# Required Modules (will load before this module loads)
RequiredModules = @()

# Required Assemblies
RequiredAssemblies = @('CsvHelper.dll')

# PowerShell Scripts (.ps1) that need to be executed before this module loads
ScriptsToProcess = @()

# Type files (.ps1xml) that need to be loaded when this module loads
TypesToProcess = @()

# Format files (.ps1xml) that need to be loaded when this module loads
FormatsToProcess = @()

#
NestedModules = @()

# List of exportable functions
FunctionsToExport = @('Get-SQLData', 'Invoke-SqlBulkCopy', 'Get-SqlConnection', 'Invoke-SqlNonQuery')

# List of exportable cmdlets
CmdletsToExport = @()

# List of exportable variables
VariablesToExport = @()

# List of exportable aliases
AliasesToExport = @()

# List of all modules contained in this module
ModuleList = @()

# List of all files contained in this module
FileList = @()

# Private data that needs to be passed to this module
PrivateData = ''

}