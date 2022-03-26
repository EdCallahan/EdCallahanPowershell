# EdCallahanPowershell

Powershell to interact with several platforms such as Windows 10, Backblaze, Dynamics CRM and Salesforce. Not a comprehensive code set, but these module address specific issues are good starting points for others starting out using the ame resources.

Contact me directly or create an Issue for any questions, comments or suggestions.

Ed Callahan
ed@edcallahan.com


## Modules

### Windows Tools

- WallPaper.ps1: Get the location of the current wallpaper, set the wallpaper and cycle through a directory of wallpaper images. Especially helpful if you have multiple monitors and want a slideshow with the same wallpaper image on each screen.

- SQL Tools: There are pretty basic modules here to run SQL queries returning a data table, and to run non-query SQL commands. The cool parts are:

    - Invoke-NonQuerySQL can be called to run a stored procedure with both parameterse and output parameters
    - Invoke-SQLBulkCopy will very quickly push huge (gigabyte-sized) CSV tables into a SQL table. 

- SecurityTools: Nothing groundbreaking but I use these in a lot of my other scripts so I include them in the repository. Allows you store store passwords and other sensitive values in an ecrypted text file or SQL table.

## Scripts


