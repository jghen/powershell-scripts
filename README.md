# powershell-scripts
powershell script for altering filenames

1. Prompts for path 
2. Counts files to be moved 
3. Moves files up one folder if parent dir starts with 2 numbers -Force is used to avoid duplicates.
4. Repeats (3.) until all files are moved to correct folder.
5. Renames all files.
6. Searches for, and deletes empty folders.
7. Displays status - files moved, filenames altered, folders deleted.

# How to use
paste it into powershell and press enter. \
Or, you can make it into a desktop app: \
See [Microsoft documentation](https://docs.microsoft.com/en-us/answers/questions/318610/convert-powershell-to-exe.html) for info on how to convert .ps1 files to .exe
