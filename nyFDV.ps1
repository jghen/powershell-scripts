'<------------------------- ENDRE NAVN - NY FDV --------------------------->
'
#inputs
$oldPath = Read-Host ‘Lim inn lokasjonen på NY FDV, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Lade skole] ‘
Set-Location $oldPath
$year_built = Read-Host 'Skriv inn byggeår [yyyy]: '

'
<------------------------- KOPIERER TIL NY MAPPE ------------------------->
'
#failsafe 1 - lag en ny 00 fdv mappe - kopier alt dit. set ny path
$newMainFolder = "20 FDV - med nye filnavn"
$path = $oldPath + '\' + $newMainFolder

write-output 'Creating new main folder:' $newMainFolder
write-output 'Copying everything to new path:' $path

$children = Get-Childitem
New-Item -Path $oldPath -Name $newMainFolder -ItemType "directory" 

foreach ($item in $children) {
    Write-Output 'Copying:  ' $item ' to new folder: ' $newMainFolder 
    $item | Copy-Item -Destination $path -Recurse
}

Set-Location $path

#failsafe 2 - alle mapper som starter på 8, 80 eller 08 må starte på 17
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
    Expand-Archive -Path $zipFile.fullName -DestinationPath $destination
}
Write-Output 'Unzip complete'

'
<---------------------------- FILER FLYTTES ----------------------------->
'
#telle flytting totalt
$countMovedTot = 0
$countNotMovedTot = 0
foreach ($file in (Get-ChildItem -Recurse -File)) {
    $parentDir =$file.Directory.Name.substring(0, 2)
    if (
        ($parentDir -match '^\d+$') -And (
            ($parentDir -eq 17) -Or    
            ($parentDir -gt 19) -And
            ($parentDir -lt 80)
            )
        ){
        #stay
        $countNotMovedTot++
    }
    else {
        #move
        $countMovedTot++
    }
}

#flytting - filer i mapper som ikke starter med 2 siffer - flyttes opp
#$i = 0
while ($true) {
    $countMoved = 0
    $countNotMoved = 0
    #$j = $i
    foreach ($file in (Get-ChildItem -Recurse -File)) {
        $parentFolder = $file.Directory.Name.substring(0, 2)
        $destination = $file.Directory.Parent.FullName
        try {
            if (
                ($parentFolder -match '^\d+$') -And (
                    ($parentFolder -eq 17) -Or    
                    ($parentFolder -gt 19) -And
                    ($parentFolder -lt 80)
                    )
                ){
                #stay
                $countNotMoved++
            }
            else {
                #move file to parent folder
                $file | Move-Item -Destination $destination -Force
                Write-Host ($file.Name + ' - moved to parent directory')
                $countMoved++
                #$i++
            } 
        }
        catch {
            Write-Host ("--> File: " + $file.Name + " - ERROR: " + $_.Exception.message)
        }
    } 
    Write-Output 'Moved: ' $countMoved
    Write-Output 'Not moved: ' $countNotMoved
    if ($countMoved -eq 0 <# -or $j -eq $i #>) {
        'Relocation process complete'
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
    try {
        $file | Rename-Item -NewName { $year_built + ”_” + $parentFolder.substring(0, 2) + ” ” + $fileName }
        Write-Host ("File " + $file.Name + " - renamed")
        $counterRenamed++
    }
    catch {
        Write-Host ("File " + $file.Name + " --- NOT RENAMED: ERROR: " + $_.Exception.message)
        $counterNotRenamed++
    }
}
Write-Output 'Renaming files - completed'
'
<-------------------------- TOMME MAPPER SLETTES ------------------------>
'
function removeEmptyFolders {
    $foldersRemoved = 0
    Get-ChildItem $path -Recurse -Directory | ForEach-Object {
        if(!(Get-ChildItem -Path $_.FullName)) {
            Remove-Item -Force -Recurse -LiteralPath $_.FullName -Verbose
            $foldersRemoved++ #also deletes desktop.ini at same time
        }
    }
    return $foldersRemoved
}
#call 2 times to remove top folder layer
$iteration1 = removeEmptyFolders 
$iteration2 = removeEmptyFolders 
$countRemovedFolders = $iteration1 + $iteration2

'
<-------------------------------- STATUS -------------------------------->
'
Write-Output 'Files moved: ' $countMovedTot
Write-Output 'Files not moved: ' $countNotMovedTot
Write-Output 'Empty folders deleted: ' $countRemovedFolders 
Write-Output 'Total files renamed: ' $counterRenamed
Write-Output 'Total files not renamed: ' $counterNotRenamed
