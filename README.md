# Powershell script for FDV
powershell script for å endre filnavn og opprydding i FDV

# Hvordan bruke det
1. Åpne powershell (trykk windows-knapp og skriv powershell, trykk enter).
2. Lim inn scriptet i powershell trykk enter.
3. Følg instruksjonene.

# Hva gjør scriptet?
1. Spør etter sti
2. Lager en ny mappe (00 FDV MainManager) og kopierer alt dit. 
3. Scriptet kjøres deretter på den nye mappen. Originalfilene blir bevart som de er.
4. Scriptet endrer mapper som starter på "80 " til 17 branndokumentasjon
5. Pakker ut zip-filer.
6. Flytter filer hvis det ikke ligger i 2- eller 3-siffer FDV-mappe.
7. Gjentar (4.) til alle filene er flyttet til riktig mappe. Filer som ligger utenfor struktur flyttes til øverste nivå.
8. Endrer til korrekt navn på alle filer (yyyy_bb Filnavn).
9. Sletter tomme overflødige mapper.
10. Genererer rapport og åpner den nye mappen med FDV.
