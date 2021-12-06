'<------------------------Endre navn på ny FDV-------------------------->
 
Revisjon: 04
Dato: 05.12.2021
 
Nytt i denne versjonen:
1. Reparert problem med omdøping av mappen 80 brannsikkerhet
 
<----------------------------------------------------------------------->
'
 
#inputs
$oldPath = Read-Host 'Lim inn lokasjonen på NY FDV, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Lade skole]'
Set-Location $oldPath
$year_built = Read-Host 'Skriv inn byggeår [yyyy]: '
 
'
<------------------------- KOPIERER TIL NY MAPPE ------------------------->
'
#failsafe 1 - lag en ny mappe og kopier alt dit. sett ny path. korrigert for lange tall
$newMainFolder = "00 FDV MainManager"
$path = $oldPath + '\' + $newMainFolder
 
#Delete if new main folder already exists:
foreach ($child in Get-ChildItem) {
    if ($child.Name -eq $newMainFolder) {
        write-Host ($newMainFolder + ' finnes fra før. Den slettes og lages på nytt... ')
        $childLong = '\\?\' + $child.FullName
        Remove-Item -LiteralPath $childLong -Force -Recurse
    }
}
 
write-Host ('Creating new main folder:' + $newMainFolder)
write-Host ('Copying everything to new path:' + $path)
 
#create new main folder
New-Item -Path $oldPath -Name $newMainFolder -ItemType "directory"
 
$children = Get-ChildItem -Exclude ('10 Originaldokumentasjon', '11 Revisjoner')
 
$longPath = '\\?\' + $path
 
foreach ($item in $children) {
    if ($item.Name -ne $newMainFolder) {
        $itemLong = '\\?\' + $item.FullName
        Write-Host ('Copying item: ' + $item.Name)
        Write-Host ('Copying to: ' + $longPath)
        $itemLong | Copy-Item -Recurse -Destination $longPath
    }
}
 
Write-Host ('Copy complete')
 
Set-Location $longPath
 
#failsafe 3 - alle mapper som starter på 80 må starte på 17
foreach ($folder in (Get-ChildItem -Recurse -Directory)) {
    if ( ($folder.Name.Length -gt 2) -And ($folder.Name.substring(0,3) -eq '80 ') ) {
        $folder | Rename-Item -NewName "17 Branndokumentasjon"
    }
}
 
'
<----------------------------- ZIP-FILER PAKKES UT -------------------------->
'
Set-Location $path
foreach ($zipFile in (Get-ChildItem -Filter *.zip -Recurse)) {
    $destination = $zipfile.Directory.fullName
    Write-Host ("Unzipping file: " + $zipFile.Name)
    Expand-Archive -Path $zipFile.fullName -DestinationPath $destination -Force
}
Write-Host ('Unzip complete')
Set-Location $longPath
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
function checkSpaceAtIndex {
    param (
        $dirName,
        $index
    )
    if ($dirName.substring($index,1) -eq " ") {
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
    if ($ParentDir.Length -lt 3) {return $false}
 
    $thirdCharIsSpace = checkSpaceAtIndex $ParentDir 2
    $first2DigitsAreNumbers = stringIsOnlyNumbers $ParentDir.substring(0, 2)
    $matchFdvFolder2Digits = ($ParentDir.substring(0, 2) -eq 17) -Or (($ParentDir.substring(0, 2) -gt 19) -And ($ParentDir.substring(0, 2) -lt 80))
 
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
    if ($ParentDir.Length -lt 4) {return $false}
 
    $fourthCharIsSpace = checkSpaceAtIndex $ParentDir 3
    $first3DigitsAreNumbers = stringIsOnlyNumbers $ParentDir.substring(0, 3)
    $matchFdvFolder3Digits = ($ParentDir.substring(0, 3) -gt 210) -And ($ParentDir.substring(0, 3) -lt 790)
 
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
        $longFullName = '\\?\' + $_.FullName
        if(!(Get-ChildItem -Path $_.FullName)) {
            $localRemoved++
            Write-Host ("Folder removed: " + $_.Name)
            Remove-Item -Force -Recurse -LiteralPath $longFullName
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
