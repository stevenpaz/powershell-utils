param (
    [string]$folderPath,
    [switch]$recursive,
    [switch]$randomizeFirst
)

if (-Not (Test-Path $folderPath)) {
    Write-Error "The specified folder does not exist."
    return
}

function Rename-FilesInFolder {
    param (
        [string]$path,
        [switch]$randomize
    )

    $folderName = [System.IO.Path]::GetFileName($path)

    # Get all the files in the folder
    $files = Get-ChildItem -Path $path | Where-Object {!$_.PSIsContainer}

    # Rename files to random names if -randomizeFirst switch is set
    if ($randomize) {
        foreach ($file in $files) {
            $randomName = [guid]::NewGuid().ToString() + $file.Extension
            Rename-Item -Path $file.FullName -NewName $randomName -ErrorAction SilentlyContinue
        }

        # Refresh the file list after random renaming
        $files = Get-ChildItem -Path $path | Where-Object {!$_.PSIsContainer}
    }

    # Calculate the starting number for renaming
    $counter = 0

    # Rename the files
    foreach ($file in $files) {
        $counter++
        $newName = "$folderName-$counter$($file.Extension)"
            
        # Ensure the new name does not already exist
        while (Test-Path (Join-Path -Path $path -ChildPath $newName)) {
            $counter++
            $newName = "$folderName-$counter$($file.Extension)"
        }

        Rename-Item -Path $file.FullName -NewName $newName -ErrorAction SilentlyContinue
    }

    # If the recursive switch is set, process the subfolders
    if ($recursive) {
        $subfolders = Get-ChildItem -Path $path -Directory | Select-Object FullName

        foreach ($folder in $subfolders) {
            Rename-FilesInFolder -path $folder.FullName -randomize:$randomize
        }
    }
}

# Call the function to rename files in the specified folder
Rename-FilesInFolder -path $folderPath -randomize:$randomizeFirst
