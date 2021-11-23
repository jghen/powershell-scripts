'<------------------------- ENDRE NAVN - NY FDV --------------------------->
'
#inputs
$oldPath = Read-Host 'Lim inn lokasjonen på NY FDV, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Lade skole]'
Set-Location $oldPath
$year_built = Read-Host 'Skriv inn byggeår [yyyy]: '

'
<------------------------- KOPIERER TIL NY MAPPE ------------------------->
'
#failsafe 1 - lag en ny mappe og kopier alt dit. set ny path
$newMainFolder = "00 FDV - for innlegging i Main Manager"
$path = $oldPath + '\' + $newMainFolder

#Delete if new main folder already exists:
foreach ($child in Get-Childitem) {
    if ($child.Name -eq $newMainFolder) {
        $child | Remove-Item -Force -Recurse
    }
}

$children = Get-Childitem -Exclude ('10 Originaldokumentasjon', '11 Revisjoner')

write-Host ('Creating new main folder:' + $newMainFolder)
write-Host ('Copying everything to new path:' + $path)

#create new main folder
New-Item -Path $oldPath -Name $newMainFolder -ItemType "directory"

foreach ($item in $children) {
    if ($item.Name -ne $newMainFolder) {
        Write-Host ('Copying:  ' + $item + ' to new folder: ' + $newMainFolder)
        $item | Copy-Item -Destination $path -Recurse
    } 
}

Set-Location $path

#failsafe 2 - alle mapper som starter på 80 må starte på 17
foreach ($folder in (Get-ChildItem -Recurse -Directory)) {
    if ($folder.Name.substring(0,2) -eq 80) {
        $folder | Rename-Item -NewName {'17 - ' + $folder.Name}
    }
}
Write-Host ('Copy complete')

'
<----------------------------- ZIP-FILER PAKKES UT -------------------------->
'
foreach ($zipFile in (Get-ChildItem -Filter *.zip -Recurse)) {
    $destination = $zipfile.Directory.fullName
    Write-Host ("Unzipping file: " + $zipFile.Name)
    Expand-Archive -Path $zipFile.fullName -DestinationPath $destination -Force
}
Write-Host ('Unzip complete')

'
<---------------------------- FILER FLYTTES ----------------------------->
'
function parentDirMatchNewMainDir {
    param (
        $ParentDirName
    )
    if ($ParentDirName -eq $newMainFolder) {
        return $true
    }else {
        return $false
    }
}
function charIsSpace {
    param (
        $char
    )
    if ($char -eq " ") {
        return $true
    }else {
        return $false
    }
}
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
function match2DigitFdvDir{
    param (
        $ParentDir
    )
    $parentDir2Digits = $ParentDir.substring(0, 2)

    $thirdCharIsSpace = charIsSpace $ParentDir.substring(2, 1)
    $first2DigitsAreNumbers = stringIsOnlyNumbers $parentDir2Digits
    $matchFdvFolder2Digits = ($parentDir2Digits -eq 17) -Or (($parentDir2Digits -gt 19) -And ($parentDir2Digits -lt 80))

    if ($first2DigitsAreNumbers -And $thirdCharIsSpace -And $matchFdvFolder2Digits) {
        return $true
    }else {
        return $false
    }
}
function match3DigitFdvDir{
    param (
        $ParentDir
    )
    $parentDir3Digits = $ParentDir.substring(0, 3)

    $fourthCharIsSpace = charIsSpace $ParentDir.substring(3, 1)
    $first3DigitsAreNumbers = stringIsOnlyNumbers $parentDir3Digits
    $matchFdvFolder3Digits = ($parentDir3Digits -gt 210) -And ($parentDir3Digits -lt 790)

    if ($first3DigitsAreNumbers -And $fourthCharIsSpace -And $matchFdvFolder3Digits) {
        return $true
    }else {
        return $false
    } 
}
function ShallFileStayInFolder {
    param (
        $File
    )
    $parentDir = $File.Directory.Name

    if (parentDirMatchNewMainDir $parentDir){
        #file stay
        return $true
    } elseif (match2DigitFdvDir $parentDir) {
        #file stay
        return $true
    } elseif (match3DigitFdvDir $parentDir) {
        #file stay
        return $true
    }
    else {
        #file move
        return $false
    }
}

#count total files to move
$countMovedTot = 0
$countNotMovedTot = 0
foreach ($file in (Get-ChildItem -Recurse -File)) {
    
    if (ShallFileStayInFolder $file){
        #stay
        $countNotMovedTot++
    }
    else {
        #move
        $countMovedTot++
    }
}

#moving files:
while ($true) {
    $countMoved = 0
    $countNotMoved = 0
    
    foreach ($file in (Get-ChildItem -Recurse -File)) {
        $destination = $file.Directory.Parent.FullName
        try {
            if (ShallFileStayInFolder $file){
                #stay
                $countNotMoved++
            }
            else {
                #move file to parent folder
                $file | Move-Item -Destination $destination -Force
                Write-Host ('File moved: ' + $file.Name)
                Write-Host ('Moved to: ' + $destination)
                $countMoved++
            } 
        }
        catch {
            Write-Host ("--> File: " + $file.Name + " - ERROR: " + $_.Exception.message)
        }
    } 
    Write-Host ('Moved: ' + $countMoved)
    Write-Host ('Not moved: ' + $countNotMoved)
    if ($countMoved -eq 0) {
        Write-Host ('Relocation process complete')
        break
    }
}

'
<----------------------------- FILER DØPES OM -------------------------->
'
$counterRenamed = 0
$counterNotRenamed = 0
foreach ($file in (Get-ChildItem -Recurse -File)) {
    $fileName = $file.Name
    $parentFolder = $file.Directory.Name

    #conditions
    $is2DigitFolder = match2DigitFdvDir $parentFolder
    $is3DigitFolder = match3DigitFdvDir $parentFolder

    try {
        if ($is2DigitFolder) {
            $file | Rename-Item -NewName { $year_built + ”_” + $parentFolder.substring(0, 2) + ” ” + $fileName }
        }
        elseif ($is3DigitFolder) {
            $file | Rename-Item -NewName { $year_built + ”_” + $parentFolder.substring(0, 3) + ” ” + $fileName }
        }
        else {
            $file | Rename-Item -NewName { $fileDate + “_” + $parentFolder.substring(0, 2) + ” ” + $fileName } 
        }
        Write-Host ("File renamed: " + $file.Name)
        $counterRenamed++
    }
    catch {
        Write-Host ("File not renamed: " + $file.Name + " --- ERROR: " + $_.Exception.message)
        $counterNotRenamed++
    }
}
Write-Host ('Renaming files - completed')

'
<-------------------------- TOMME MAPPER SLETTES ------------------------>
'
$totalRemoved = 0
function removeEmptyFolders {
    param (
        $totalRemoved
    )
    $localRemoved = 0
    Get-ChildItem $path -Recurse -Directory | ForEach-Object {
        if(!(Get-ChildItem -Path $_.FullName)) {
            $localRemoved++
            Write-Host ("Folder removed: " + $_.Name)
            Remove-Item -Force -Recurse -LiteralPath $_.FullName
        }
    }
    $totalRemoved += $localRemoved
    if ($localRemoved -eq 0) {
        Write-Host ("Folder removal - complete")
        return $totalRemoved
    } else {
        Write-Host ("Removed: " + $localRemoved)
        Write-Host ("Total removed: " + $totalRemoved)
        removeEmptyFolders $totalRemoved
    }
}

$countRemovedFolders = removeEmptyFolders

'
<-------------------------------- STATUS -------------------------------->
'
Write-Host ('Files moved: ' + $countMovedTot)
Write-Host ('Files not moved: ' + $countNotMovedTot)
Write-Host ('Empty folders deleted: ' + $countRemovedFolders)
Write-Host ('Total files renamed: ' + $counterRenamed)
Write-Host ('Total files not renamed: ' + $counterNotRenamed)
Get-ChildItem -Path $path
