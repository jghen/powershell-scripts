'<----------------Endre navn på gammel FDV fra u-området----------------->
'
#inputs
$oldPath = Read-Host ‘Lim inn lokasjonen på gammel FDV, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Berg skole] ‘
Set-Location $oldPath
$year_built = Read-Host 'Skriv inn byggeår [yyyy]: '
$year_original_files_scanned = Read-Host ‘Når ble originalfilene lagt på u-området? [yyyy]: ‘

'
<------------------------- KOPIERER TIL NY MAPPE ------------------------->
'
#failsafe 1 - lag en ny mappe og kopier alt dit. set ny path
$newMainFolder = "00 FDV - med nye filnavn"
$path = $oldPath + '\' + $newMainFolder

write-output 'Creating new main folder:' $newMainFolder
write-output 'Copying everything to new path:' $path

$children = Get-Childitem
New-Item -Path $oldPath -Name $newMainFolder -ItemType "directory" 

foreach ($item in $children) {
    Write-Output 'Copying item:  ' $item ' to new folder: ' $newMainFolder 
    $item | Copy-Item -Destination $path -Recurse
}

Set-Location $path

#failsafe 2 - alle mapper som starter på 80 må starte på 17
foreach ($folder in (Get-ChildItem -Recurse -Directory)) {
    if ($folder.Name.substring(0,2) -eq 80) {
        $folder | Rename-Item -NewName {'17 - ' + $folder.Name}
    }
}
Write-Output 'Copy complete'

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
function ShallFileStayInFolder {
    param (
        $File
    )
    $parentDir = $File.Directory.Name.substring(0, 2)
    $parentDirName = $File.Directory.Name

    $thirdCharIsSpace = $File.Directory.Name.substring(2, 1) -eq " " 
    $parentDirMatchNewMainDir = $parentDirName -eq $newMainFolder
    $parentDirIsNumber = $parentDir -match '^\d+$'
    $parentDirMatchFdvDirs = ($parentDir -eq 17) -Or ($parentDir -gt 19) -And ($parentDir -lt 80)
    
    if (($parentDirIsNumber -And $parentDirMatchFdvDirs -And $thirdCharIsSpace) -Or $parentDirMatchNewMainDir){
        #stay
        return $true
    }
    else {
        #move
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
    $fileDate = $file.LastWriteTime.ToString("yyyy")
    $fileName = $file.Name
    $parentFolder = $file.Directory.Name
    try {
        if ($year_original_files_scanned -eq $fileDate) {
            $file | Rename-Item -NewName { $year_built + ”_” + $parentFolder.substring(0, 2) + ” ” + $fileName }
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
$totalReturn = 0
function removeEmptyFolders {
    param (
        $totalReturn
    )
    $foldersRemoved = 0
    Get-ChildItem $path -Recurse -Directory | ForEach-Object {
        if(!(Get-ChildItem -Path $_.FullName)) {
            $foldersRemoved++
            Write-Host ("Folder removed: " + $_.Name)
            Remove-Item -Force -Recurse -LiteralPath $_.FullName
        }
    }
    $totalReturn += $foldersRemoved
    if ($foldersRemoved -eq 0) {
        Write-Host ("Folder removal - complete")
        return $totalReturn
    } else {
        Write-Host ("Removed: " + $foldersRemoved)
        Write-Host ("Total removed: " + $totalReturn)
        removeEmptyFolders $totalReturn  
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
