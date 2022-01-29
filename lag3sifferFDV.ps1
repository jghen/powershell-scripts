function stringIsOnlyNumbers {
    param (
        $String
    )
    if ($String -match '^\d+$') {
        return $true
    }else {
        return $false
    }
}
function create10Folders {
    param (
        $Folder
    )
    $path = $Folder.FullName
    $folderDigits = $Folder.Name.substring(0, 2)

    for ($i = 1; $i -lt 10; $i++) {
        $NewDirName = $folderDigits + $i + " -"
        New-Item -Path $path -Name $NewDirName -ItemType "directory" -Verbose
    }
}

function isNotGeneralFolder {
    param (
        $FolderDigits
    )
    for ($i = 2; $i -lt 8; $i++) {
        $j = $i * 10
        if ($FolderDigits -eq $j) {
            return $false
        }
    }
    return $true 
}
function matchFdvDir {
    param (
        $Folder
    )
    $folderName = $Folder.Name
    $folderDigits = $folderName.substring(0, 2)

    $hasFdvDirNumbers = ($folderDigits -gt 19) -And ($folderDigits -lt 80)

    if ($hasFdvDirNumbers -And (stringIsOnlyNumbers $folderDigits) -And (isNotGeneralFolder $folderDigits)) {
        return $true
    }
    return $false
    
}
function create3DigitFdv {
    foreach ($folder in Get-ChildItem -Recurse -Directory) {
        $isFdvDir = matchFdvDir $folder
        if ($isFdvDir) {
            create10Folders $folder 
        }
    }
}

create3DigitFDV