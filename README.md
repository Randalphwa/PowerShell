# PowerShell Repository

While these are primarily designed for my own use, you are welcome to copy and use them yourself.

# Modules

In the descriptions below, only the functions designed to be called from the PS command line are described. Module files may also contain common functions called by other modules and scripts.

## dir_module.psm1

This contains functions for dealing with folders and files

### delnode

Deletes a folder (does _not_ ask for confirmation) including all files and subfolders.

Sample output:
```powershell
Deleted: .\node_test\
  Folders deleted: 1
  Files deleted: 15
  Space freed: 2,376,443 (2.27 MB)
```

### driveinfo

Displays information about the current drive.

Sample output:
```powershell
Drive       : L
TotalGB     : 10.05
UsedGB      : 0.74
FreeGB      : 9.31
PercentFree : 92.7%
```

### ls (dir_module.psm1)

If you use this function, you will need to first remove the built-in ls alias so that this function takes precedence:

```PS
Remove-Item alias:ls -ErrorAction SilentlyContinue
```

This displays a multi-column, alphabetized list of folders and files, with some color-coding done for specific folders and filename extensions.

Sample output:
```
[.git]          [.vscode]       [modules]       [scripts]       .gitattributes  .gitignore      LICENSE         README.md
```

### lt (dir_module.psm1)

This displays a vertical list of folders and files sorted by modification time with the most recent appearing at the bottom. The second column displays the modification time, and the third column displays the size of the folder or file.

Sample output:
```powershell
[scripts]        2025-10-25 14:29:07        0
[modules]        2025-10-25 17:36:20   17,197
[.vscode]        2025-10-25 18:04:20    3,032
[.git]           2025-10-26 07:46:46   37,503
.gitattributes   2025-10-25 12:05:05       66
LICENSE          2025-10-25 12:05:05    1,087
.gitignore       2025-10-25 15:22:31        9
README.md        2025-10-26 18:21:51    2,833
```

### la (dir_module.psm1)

This displays a vertical list of alphabetically sorted folders and files. If the folder or file is a junction or symbolic-link, that will be indicated in parenthesis after the folder/file name. The second column displays the modification time, and the third column displays the size of the folder or file. At the end of the display will be the total number of folder, files, and size.

Sample output:
```powershell
[.git]           2025-10-26 07:46:46   37,503
[.vscode]        2025-10-25 18:04:20    3,032
[modules]        2025-10-25 17:36:20   17,145
[scripts]        2025-10-25 14:29:07        0
.gitattributes   2025-10-25 12:05:05       66
.gitignore       2025-10-25 15:22:31        9
LICENSE          2025-10-25 12:05:05    1,087
README.md        2025-10-26 18:19:54    2,406
--------------------
Folders: 4  Files: 4  Total size: 61,248```

# Scripts
