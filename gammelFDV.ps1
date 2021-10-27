'<----------------Endre navn på gammel FDV fra u-området----------------->
'
#failsafe - alle mapper som starter på 8, 80 eller 08 må starte på 17

foreach ($folder in (Get-ChildItem -Recurse -Directory)) {
    if (
        ($folder.Name.substring(0,1) -like '8') -Or 
        ($folder.Name.substring(0,2) -like '80') -Or 
        ($folder.Name.substring(0,2) -like '08')
        ) {
        $folder | Rename-Item -NewName {'17 - ' + $folder.Name}
    }
}

#input - skriv inn mappenavn
$path = Read-Host ‘Lim inn lokasjonen på gammel FDV, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Berg skole] ‘
Set-Location $path
#input - byggeår
$year_built = Read-Host 'Skriv inn byggeår [yyyy]: '
#input - året originalfilene (scannet) ble lagt inn på u
$year_original_files_scanned = Read-Host ‘Når ble originalfilene lagt på u-området? [yyyy]: ‘
'<---------------------------- FILER FLYTTES ----------------------------->
'


$countMovedTot = 0
$countNotMovedTot = 0
foreach ($file in (Get-ChildItem -Recurse -File)) {
    if ($file.Directory.Name.substring(0, 2) -notmatch '^\d+$') {
        $countMovedTot++
    }
    else {
        $countNotMovedTot++
    } 
}
#flytting - filer i mapper som ikke starter med 2 siffer - flyttes opp
#$i = 0
while ($true) {
    $countMoved = 0
    $countNotMoved = 0
    #$j = $i
    foreach ($file in (Get-ChildItem -Recurse -File)) {
        $fileName = $file.Name
        $parentFolder = $file.Directory.Name
        $destination = $file.Directory.Parent.FullName
        try {
            if ($parentFolder.substring(0, 2) -notmatch '^\d+$') {
                #move file to parent folder
                $file | Move-Item -Destination $destination -Force
                Write-Host ($filename + ' --- MOVED TO PARENT FOLDER')
                $countMoved++
                #$i++
            }
            else {
                $countNotMoved++
            } 
        }
        catch {
            Write-Host ("FILE: " + $file.Name + " ERROR: " + $_.Exception.message)
        }
    } 
    Write-Output 'Moved: ' $countMoved
    Write-Output 'Not moved: ' $countNotMoved
    if ($countMoved -eq 0 <# -or $j -eq $i #>) {
        'Relocation process complete'
        break
    }
}
'<----------------------------- FILER DØPES OM -------------------------->
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
        Write-Host ("FILE " + $file.Name + " --- RENAMED")
        $counterRenamed++
    }
    catch {
        Write-Host ("FILE " + $file.Name + " --- NOT RENAMED: ERROR: " + $_.Exception.message)
        $counterNotRenamed++
    }
}
'<-------------------------- TOMME MAPPER SLETTES ------------------------>
'
$countRemovedFolders = 0
$tailRecursion = {
    param(
        $Path
    )
    foreach ($childDirectory in Get-ChildItem -Force -LiteralPath $Path -Directory) {
        & $tailRecursion -Path $childDirectory.FullName
    }
    $currentChildren = Get-ChildItem -Force -LiteralPath $Path
    $isEmpty = $currentChildren -eq $null
    if ($isEmpty) {
        $countRemovedFolders++
        Write-Verbose "Removing empty folder at path '${Path}'." -Verbose
        Remove-Item -Force -LiteralPath $Path
        
    }
}
#call function:
& $tailRecursion -Path $path
'<-------------------------------- STATUS -------------------------------->
'
Write-Output 'Files moved: ' $countMovedTot
Write-Output 'Files not moved: ' $countNotMovedTot
Write-Output 'Empty folders deleted: ' $countRemovedFolders
Write-Output 'Total files renamed: ' $counterRenamed
Write-Output 'Total files not renamed: ' $counterNotRenamed
