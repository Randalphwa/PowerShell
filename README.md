# PowerShell Repository

While these are primarily designed for my own use, you are welcome to copy and use them yourself.

# Modules

In the descriptions below, only the functions designed to be called from the PS command line are described. Module files may also contain common functions called by other modules and scripts.

## dir_module.psm1

This contains functions for dealing with folders and files

### delnode

Deletes a folder (does _not_ ask for confirmation) including all files and subfolders.

Sample output:
```
Deleted: .\node_test\
  Folders deleted: 1
  Files deleted: 15
  Space freed: 2,376,443 (2.27 MB)
```

### driveinfo

Displays information about the current drive.

Sample output:
```
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
```
[.vscode]         2025-10-25 12:09:13      2,097
[scripts]         2025-10-25 14:29:07      0
[modules]         2025-10-25 14:29:16      10,751
.gitattributes    2025-10-25 12:05:05      66
LICENSE           2025-10-25 12:05:05      1,087
.gitignore        2025-10-25 15:22:31      9
README.md         2025-10-25 15:25:39      1,087
```

# Scripts
