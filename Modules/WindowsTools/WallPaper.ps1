<#

Win10 Personlize desktop allows you to setup a slideshow so you can rotate yous wallpapers on a schedule.
But if you have multiple monitors you'll have different images on each monitor, which seems busy. You can
create the images to the exact right size and tile them, but if your monitors have differnet pixel
dimensions it won't look good.

The Powershell Get-WallPaper function below will set the same image on all monitors. You can cycle
through images in a directory, or randomly select one each time.

I use Task Scheduler to reset the wallpaper periodically

Ed Callahan
ed@edcallahan.com
3/21/2022

#>

function fnSetWallPaper {

    <#

    .SYNOPSIS
    Internal non-exported function that applies a specified wallpaper to the current user's desktop.

    Internal function used by the exported function Set-WallPaper in this module

    .PARAMETER Image
    Provide the exact path to the image

    .PARAMETER Style
    Provide wallpaper style (Example: Fill, Fit, Stretch, Tile, Center, or Span)

    .EXAMPLE
    fnSetWallPaper -Image "C:\Wallpaper\Default.jpg"
    fnSetWallPaper -Image "C:\Wallpaper\Background.jpg" -Style Fit

    #>

    param (
        # path to image
        [parameter(Mandatory = $True)]
        [string]$Image,

        # wallpaper style
        [parameter(Mandatory = $False)]
        [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
        [string]$Style = 'Fit'
    )

    $WallpaperStyle = Switch ($Style) {
        'Tile' { '0' }
        'Center' { '0' }
        'Stretch' { '2' }
        'Fit' { '6' }
        'Fill' { '10' }
        'Span' { '22' }
    }

    # error if file doesn't exist
    if ( -not (Test-Path -Path $Image -PathType leaf) ) {
        throw ('Image Not Found: {0}' -f $Image)
        return
    }

    if ($Style -eq "Tile") {

        $null = New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
        $null = New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 1 -Force

    } `
    else {

        $null = New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
        $null = New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 0 -Force

    }

    $class_def = '
        using System.Runtime.InteropServices;

        namespace Win32 {

            public class Wallpaper{

                [DllImport("user32.dll", CharSet=CharSet.Auto)]
                static extern int SystemParametersInfo (int uAction , int uParam , string lpvParam , int fuWinIni) ;

                public static void SetWallpaper(string thePath){
                    SystemParametersInfo(0x0014, 0, thePath, 0x01 | 0x02);
                }

            }

        }
    '

    Add-Type -TypeDefinition $class_def

    $null = [Win32.WallPaper]::SetWallpaper($Image)

}

function Get-WallPaper {

    <#

    .SYNOPSIS
    Get the image file name with directory of the current desktop background.

    In the case of an error $null is returned and no error is thrown.

    Ed Callahan 3/19/2022

    .EXAMPLE
    $image_fn = Get-WallPaper

    #>

    $try_again = $false # we'll use this to indicate if we need to try a second method to retrieve the current wallpaper
    try {
        $fn = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' Wallpaper -ErrorAction Stop).Wallpaper
    }
    catch {
        # This is really only an error if there is not a Wallpaper value in this key. If not we'll try another method
        # if this key exists but is null, it appears the user currently doesn't have a wallpaper set
        $try_again - $true
    }

    if ( $try_again ) {

        # This method is commonly used to pull wallpaper, although you'll see it paired with regex that fails in serveral edge cases
        # The trivial problem with this method is it will return an image name when there is not currenlty a wallpaper set but there has been previously.

        try {

            # read the image name as a byte string from the registry
            $tic = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' TranscodedImageCache -ErrorAction Stop).TranscodedImageCache

            # extract the image name, ignoring special characters in the first 12 positions and remove trailing null characters
            $fn = [System.Text.Encoding]::Unicode.GetString($tic).SubString(12).TrimEnd("`0")

        }
        catch {
            # no background image found
            $fn = $null
        }

    } # end if ($try_again)

    # make sure this is actually a file that exists
    try {
        if ( -not (Test-Path $fn -PathType leaf -ErrorAction Stop) ) { $fn = $null }
    }
    catch {
        $fn = $null
    }

    return $fn


}

function Set-WallPaper {

    <#

    .SYNOPSIS
    Change the wallpaper, either by specifying the image file, or by choosing one
    from sapecified directory (either random selection, or rotate sequentially).

    Ed Callahan 3/19/2021

    .PARAMETER Image
    Image to use when setting wallpaper

    .PARAMETER Directory
    Directory that holds the wallpaper images we'll choose from

    .PARAMETER Style
    Provide wallpaper style (Example: Fill, Fit, Stretch, Tile, Center, or Span)
    Defaults to Fit

    .EXAMPLE
    Set-WallPaper -Image "C:\Wallpaper\Default.jpg"
    Set-WallPaper -Image "C:\Wallpaper\Background.jpg" -Style Fit
    Set-WallPaper -Directory "C:\Wallpaper" -Method Cycle

    #>

    param (

        # Image to set wallpaper to
        [parameter(ParameterSetName = 'Set', Position = 0, Mandatory = $true)]
        [string]$Image,

        # Provide path to wallpaper images to rotate through
        [parameter(ParameterSetName = 'Rotate', Position = 0, Mandatory = $true)]
        [string]$Directory,

        # Set how you select the next image from the directory, cycle through them in order or pick a random one
        [parameter(ParameterSetName = 'Rotate', Position = 1, Mandatory = $false)]
        [ValidateSet('Random', 'Cycle')]
        [string]$Method = 'Random',

        # Provide wallpaper style that you would like applied
        [parameter(ParameterSetName = 'Set', Position = 1)]
        [parameter(ParameterSetName = 'Rotate', Position = 2)]
        [parameter(Mandatory = $false)]
        [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
        [string]$Style = 'Fit',

        # determine if we should fine image files recursively in the specified directory
        [parameter(ParameterSetName = 'Rotate')]
        [switch]$Recurse

    )

    # allowed image extensions
    $valid_file_exts = ('.jpg', '.jpeg', '.png', '.bmp', '.gif', '.tif')

    if ( $PSCmdlet.ParameterSetName -eq 'Set' ) {

        # a image was passed to the function, make sure it's valid

        # make sure this is actually a file that exists
        try {
            if ( -not (Test-Path $Image -PathType leaf -ErrorAction Stop) ) { throw }
        }
        catch {
            throw 'File Not Found'
        }

        # make sure this is actually a file that exists
        try {
            if ( $valid_file_exts -notcontains (Get-Item $Image).Extension ) {
                throw 'Invalid extension of file name'
            }
        }
        catch {
            # throw 'File Not Found (Invalid extension check)'
            throw $_
        }

    }

    if ( $PSCmdlet.ParameterSetName -eq 'Rotate' ) {

        # an image wasn't passed to the function, so we choose one from the specified directory using the specified $Method

        # get a list of the images in the specified directory, recursively if requested. Only include files with the allowed file nanme extensions
        $images = @(, (Get-ChildItem $Directory -Recurse:$Recurse | Where-Object { -not $_.PSIsContainer -and $valid_file_exts -contains $_.Extension }).FullName) | Sort-Object

        if ($images.Count -eq 0) {
            # error if there are no images to pick from
            throw 'No images found'
            return
        } `
        elseif ($images.Count -eq 1) {
            # if only one image is found, set the wallpaper to it
            $Image = $images[0]
        } `
        elseif ( $Method -eq 'Random' ) {

            # pick a random image from the directory, making sure we don't pick the same as the currently set one

            $count = 0
            $current_wallpaper = Get-WallPaper
            $new_wallpaper = $current_wallpaper
            while ( $current_wallpaper -eq $new_wallpaper) {
                # prevent an infinite loop
                if ($count++ -gt 5) { break }

                # Pick a random image
                $new_wallpaper = Get-Random -InputObject $images
            }

            $Image = $new_wallpaper

        } `
        elseif ( $Method -eq 'Cycle') {

            # pick the next image, sequentially alphabetically

            $current_wallpaper = Get-WallPaper
            $current_int = 0..($images.Count - 1) | Where-Object { $images[$_] -eq $current_wallpaper }
            if ( $null -eq $current_int -or $current_int -eq ($images.Count - 1) ) {
                # if the current wallpaper isn't in the image list, just show the first one
                # and if we're at the last image of the list, show the first one
                $Image = $images[0]
            } `
            else {
                # show the next image
                $Image = $images[$current_int + 1]
            }

        } `
        else {
            throw 'Unexpected value of Method'
        }

    }

    if ($null -eq $Image ) {
        throw 'Unable to determine a wallpaper image'
        return
    }

    # set the wallpaper to the specified/selected image
    return fnSetWallPaper -Image $Image -Style $Style

}
