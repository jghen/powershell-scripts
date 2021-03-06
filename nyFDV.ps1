'<------------------------Endre navn på ny FDV-------------------------->
 
Versjon: 4.07
Dato: 18.01.2022
 
Nytt i denne versjonen:
1. ekskluder mapper 200-210, 300-310 .. etc. Dette er ikke FDV-mapper.
2. kan velge å legge inn prosjektnavn i alle filnavn etter yyyy_bb
3. fikset problem med omdøping av 80-mappe
 
<----------------------------------------------------------------------->
'
 
#inputs
$oldPath = Read-Host 'Lim inn stien til FDV-mappen:'
Set-Location $oldPath
$year_built = Read-Host 'Skriv inn byggeår [yyyy] '
$project = Read-Host 'Kort prosjektnavn [hvis ikke - trykk Enter] '

if ($project.Length -gt 0) {
    $projectName = " " + $project + " - "
} else {
    $projectName = $project
}

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
 
$children = Get-ChildItem -Exclude ('10 Originaldokumentasjon', '11 Revisjoner', '00 FDV MainManager - StatusRapport.txt')

#tell windows API to disable string parsing - allows long file names
$longPath = '\\?\' + $path
 
foreach ($item in $children) {
    if ($item.Name -ne $newMainFolder) {
        $itemLong = '\\?\' + $item.FullName
        Write-Host ('Copying item: ' + $item.Name)
        Write-Host ('Copying to: ' + $longPath)
        $itemLong | Copy-Item -Force -Recurse -Destination $longPath
    }
}
 
Write-Host ('Copy complete')
 
Set-Location $longPath
 
#failsafe 3 - alle mapper som starter på 80 må starte på 17 - men ikke hvis de ligger under f. eks 20.
foreach ($folder in (Get-ChildItem -Recurse -Directory)) {
    if ( ($folder.Name.Length -gt 2) -And ($folder.Name.substring(0,3) -eq '80 ') -And (($folder.Parent.Name -eq $newMainFolder) -Or ($folder.Parent.Parent.Name -eq $newMainFolder)) ) {
        Write-Host ('Renaming folder: ' + $folder.Name)
        $folder | Rename-Item -Verbose -Force -NewName {"17 - " + $folder.Name}
    }
}

foreach ($file in (Get-ChildItem -Filter 'desktop.ini' -Recurse)) {
    $file | Remove-Item
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
    }
    return $false
}
function checkSpaceAtIndex {
    param (
        $String,
        $index
    )
    if ($String.substring($index,1) -eq " ") {
        return $true
    }
    return $false
}
function stringIsOnlyNumbers {
    param (
        $String
    )
    if ($String -match '^\d+$') {
        return $true
    }
    return $false
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
    }
    return $false
}

#ekskluder 200-210, 300-310 .. etc.
function isNotGeneralFolder {
    param (
        $FolderDigits
    )
    for ($i = 2; $i -lt 8; $i++) {
        for ($j = 0; $j -lt 11; $j++) {
            $k = $i*100 + $j
            if ($FolderDigits -eq $k) {
                return $false
            }
        }
    }
    return $true 
}

function match3DigitFdvDir{
    param (
        $ParentDir
    )
    if ($ParentDir.Length -lt 4) {return $false}
 
    $fourthCharIsSpace = checkSpaceAtIndex $ParentDir 3
    $first3DigitsAreNumbers = stringIsOnlyNumbers $ParentDir.substring(0, 3)
    $matchFdvFolder3Digits = ($ParentDir.substring(0, 3) -gt 210) -And ($ParentDir.substring(0, 3) -lt 790)
    $isNotGeneralFolder = isNotGeneralFolder $ParentDir.substring(0,3)
 
    if ($first3DigitsAreNumbers -And $fourthCharIsSpace -And $matchFdvFolder3Digits -And $isNotGeneralFolder) {
        return $true
    }
    return $false
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
    $file2DigitsMatchDir2Digits = ($fileName.Length -ge 2) -And ($fileName.Substring(0,2) -eq $parentFolder.Substring(0,2))
    $file3DigitsMAtchDir3Digits =($fileName.Length -ge 3) -And ($fileName.Substring(0,3) -eq $parentFolder.Substring(0,3))
    $fileNameIndex2IsSpace = ($fileName.Length -gt 2) -And (checkSpaceAtIndex $fileName 2)
    $fileNameIndex3IsSpace = ($fileName.Length -gt 3) -And (checkSpaceAtIndex $fileName 3)
 
    if ($is2DigitFolder) {
        if ($file2DigitsMatchDir2Digits -And $fileNameIndex2IsSpace) {
            $file | Rename-Item -NewName {$year_built + ”_” + $projectName + $fileName}
            $counterRenamed++
        }
        else {
            $file | Rename-Item -NewName {$year_built + ”_” + $parentFolder.substring(0, 2) + ” ” + $projectName + $fileName}
            $counterRenamed++
        }
    }
    elseif ($is3DigitFolder) {
        if ($file3DigitsMAtchDir3Digits -And $fileNameIndex3IsSpace) {
            $file | Rename-Item -NewName {$year_built + ”_” + $projectName + $fileName}
            $counterRenamed++
        }
        else {
            $file | Rename-Item -NewName {$year_built + ”_” + $parentFolder.substring(0, 3) + ” ” + $projectName + $fileName}
            $counterRenamed++
        }
    }
    else {
        $counterNotRenamed++
    }
    Write-Host ("File renamed: " + $file.Name)
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
<----------------------------- ZIP-FILER slettes -------------------------->
'
foreach ($zip in (Get-ChildItem -Path $path -Filter *.zip -Recurse)) {
    Write-Host ("Deleting zip: " + $zip.Name)
    $zip | Remove-Item
}
Write-Host ('zips removed')

#inputs til StatusRapport
$header = "------------------------------- STATUS --------------------------------"
$flyttet = "   Filer flyttet: " + $countMovedTot.ToString()
$ikkeFlyttet = "   Filer ikke flyttet: " + $countNotMovedTot.ToString()
$mapperSlettet ="   Tomme mapper slettet: " + $countRemovedFolders.ToString()
$omdopt = "   Filer omdøpt: " + $counterRenamed.ToString()
$ikkeOmdopt = "   Filer ikke omdøpt: " + $counterNotRenamed.ToString()
$footer = "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
$filesInTheWrongPlace = (Get-ChildItem -Path $path | where-Object {!$_.PSIsContainer}).Count
$underOverskrift = "   " + $filesInTheWrongPlace.ToString() + " filer lå utenfor 2- og 3-siffer FDV-mappe: "

function composeFileList {
    $fileNumber = 0
    $list = @()
    foreach ($file in Get-ChildItem -Path $path -File) {
        $fileNumber++
        $list += "   " +$fileNumber.tostring() + " " + $file.Name
    }
    return $list
}
$fileList = composeFileList

#Lag StatusRapport
$StatusRapport = $oldPath + '\00 FDV MainManager - StatusRapport.txt'
("") | Out-File -FilePath $StatusRapport

function addToReport {
    param (
        $Report,
        $InputObject
        )
    $InputObject | Out-File $Report -Append
}

addToReport $StatusRapport ($header, "", $flyttet, $ikkeFlyttet, $mapperSlettet, $omdopt, $ikkeOmdopt,"",$footer,"", $underOverskrift,"")
addToReport $StatusRapport $fileList
addToReport $StatusRapport ("", $footer, "")

Get-Content -Path $StatusRapport

. $StatusRapport

Invoke-Item -Path $path

Get-ChildItem -Path $path
