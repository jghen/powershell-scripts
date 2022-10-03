#Hvis noe ble feil: fjern 8 første tegn fra alle filnavn i en mappe. Fyll inn mappen du vil endre på.

$path = Read-Host ‘Lim inn lokasjonen på mappen du vil endre, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Åsveien skole] ‘
Set-Location $path
Get-Childitem | Where-Object {$_.Psiscontainer -eq $false} | Rename-Item -NewName {$_.Name.SubString(1)}

#Hvis du vil gjøre det samme også på undermapper:
$path = Read-Host ‘Lim inn lokasjonen på mappen du vil endre, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Åsveien skole] ‘
Set-Location $path
Get-Childitem -Recurse | Where-Object {$_.Psiscontainer -eq $false} | Rename-Item -NewName {$_.Name.SubString(1)}

#hvis filer har fått navn etter feil bygningsdel
#Fjerner 2 tegn fra plass nr 6 i filnavnet (index 5) og erstatter det med tallet 17:
$path = Read-Host ‘Lim inn lokasjonen på mappen du vil endre, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Åsveien skole] ‘
Set-Location $path
Get-Childitem -recurse | Where-Object {$_.Psiscontainer -eq $false} | Rename-Item -NewName {$_.Name.Remove(5,2).Insert(5,'17')}

#slette spesifikke bokstaver - erstatt "-" i mappenavn med " "
$path = Read-Host ‘Lim inn lokasjonen på mappen du vil endre, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Åsveien skole] ‘
Set-Location $path
Get-Childitem -Recurse | Where-Object {$_.Psiscontainer -eq $true} | Rename-Item -NewName { $_.name –replace("-"," ") }

#Hvis du vil ha på et ekstra prefiks før navnet
$path = Read-Host ‘Lim inn lokasjonen på mappen du vil endre, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Åsveien skole] ‘
Set-Location $path
Get-Childitem -Recurse  | Where-Object {$_.Psiscontainer -eq $true} | Rename-Item -NewName {"2021_17 " + $_.Name}

#insert
$path = Read-Host ‘Lim inn lokasjonen på mappen du vil endre, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Åsveien skole] ‘
Set-Location $path
Get-Childitem -recurse | Where-Object {$_.Psiscontainer -eq $false} | Rename-Item -NewName {$_.Name.Insert(7,' Gymsal - ')}

#filer får navn etter mappen over seg:
$path = Read-Host ‘Lim inn lokasjonen på mappen du vil endre, F. eks [U:\500000\FDV-dokumentasjon\Skoler\00 Åsveien skole] ‘
Set-Location $path
foreach ($file in Get-ChildItem -recurse -file) {
    $fileName = $file.Name
    $parentFolder = $file.Directory.Name

    $file | Rename-Item -NewName {$parentFolder + " " + $fileName}
}

#lag mapper mapper i hver mappe i get childitem (dvs der du står).
foreach($folder in (Get-ChildItem -directory)){
    new-item -ItemType directory -Path ($folder.fullname+"\module1") -verbose
    new-item -ItemType directory -Path ($folder.fullname+"\module2") -verbose
    new-item -ItemType directory -Path ($folder.fullname+"\module3") -verbose
    new-item -ItemType directory -Path ($folder.fullname+"\module4") -verbose
    new-item -ItemType directory -Path ($folder.fullname+"\course-assignement") -verbose
}
 


#test error message
$ers =@()
Set-Location 'C:\Users\7C4\Desktop'
try {
    asdf
} catch {
    $string_err = $_
}
$ers += $string_err

try {
    dddddd
} catch {
    $string_err = $_
}
$ers += $string_err


$ers | Format-Table -AutoSize | Out-File -Width 120 -FilePath 'C:\Users\7C4\Desktop\errorReportTest.txt' 
$errorReportTest = ".\errorReportTest.txt"
. $errorReportTest
