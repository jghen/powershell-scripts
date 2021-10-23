'<------------------------- ENDRE NAVN - NY FDV --------------------------->
'
#input - skriv inn mappenavn
$path = Read-Host ‘Lim inn lokasjonen på NY FDV, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Lade skole] ‘
Set-Location $path
#input - byggeår
$year_built = Read-Host 'Skriv inn byggeår [yyyy]: '
'<---------------------------- FILER FLYTTES ----------------------------->
'
#telle flytting totalt
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
    $fileName = $file.Name
    $parentFolder = $file.Directory.Name
    try {
        $file | Rename-Item -NewName { $year_built + ”_” + $parentFolder.substring(0, 2) + ” ” + $fileName }
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
        Write-Verbose "Removing empty folder at path '${Path}'." -Verbose
        Remove-Item -Force -LiteralPath $Path
        $countRemovedFolders++
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



