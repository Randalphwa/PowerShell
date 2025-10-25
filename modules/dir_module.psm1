# Helper function to determine item color based on priority
function Get-ItemColor {
    param([string]$itemName, [bool]$isFolder, [object]$itemObj)

    # Priority 1: Read-only
    if ($itemObj.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
        return "Red"  # Bright red
    }

    # Priority 2: Hidden
    if ($itemObj.Attributes -band [System.IO.FileAttributes]::Hidden) {
        return "DarkGray"  # Grey
    }

    if ($isFolder) {
        # Priority 3: Folders starting with a dot
        if ($itemName.StartsWith(".")) {
            return "Blue"
        }
        # Priority 4: Regular folders
        return "Yellow"  # Bright yellow
    }
    else {
        # Priority 5: File extensions
        $ext = [System.IO.Path]::GetExtension($itemName).ToLower()

        # Map ANSI codes to PowerShell colors
        $colorMap = @{
            "`e[35m" = "Magenta"    # Bright magenta for .exe
            "`e[36m" = "Cyan"       # Bright cyan for .h*, .rc*
            "`e[33m" = "Yellow"     # Yellow for .txt, .md, .rtf
            "`e[93m" = "Yellow"     # Bright yellow for .chm
            "`e[37m" = "White"      # White for .bak, .tmp
            "`e[92m" = "Green"      # Green for .cmd, .bat, .ps1, etc.
            "`e[94m" = "Blue"       # Blue for .sln
        }

        if ($PSStyle.FileInfo.Extension.ContainsKey($ext)) {
            $ansiCode = $PSStyle.FileInfo.Extension[$ext]
            if ($colorMap.ContainsKey($ansiCode)) {
                return $colorMap[$ansiCode]
            }
        }

        # Default for files
        return "Green"
    }
}

# Helper function to calculate folder size recursively
function Get-FolderSize {
    param([string]$folderPath)
    try {
        $size = 0
        $items = Get-ChildItem -Path $folderPath -Recurse -File -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $size += $item.Length
        }
        return $size
    }
    catch {
        return 0
    }
}

# Helper function to format size with appropriate suffix
function Format-Size {
    param([long]$size)
    $sizeStr = $size.ToString("N0")
    if ($size -gt 1GB) {
        $gbSize = [math]::Round($size / 1GB, 2)
        $sizeStr += " ($($gbSize.ToString("N2")) GB)"
    }
    elseif ($size -gt 1MB) {
        $mbSize = [math]::Round($size / 1MB, 2)
        $sizeStr += " ($($mbSize.ToString("N2")) MB)"
    }
    return $sizeStr
}

#### Command-line functions ####

# Function to delete all files and subdirectories in a specified directory
function delnode {
    if ($args.Count -eq 0) {
        Write-Host "Usage: delnode <directory>"
        Write-Host "This command will recursively delete all files and subdirectories in the specified directory."
        return
    }

    foreach ($path in $args) {
        if (Test-Path $path -PathType Container) {
            # Get initial size and counts
            $size = Get-FolderSize -folderPath $path
            $allItems = @(Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue)
            $fileCount = @($allItems | Where-Object { -not $_.PSIsContainer }).Count
            $folderCount = @($allItems | Where-Object { $_.PSIsContainer }).Count

            # Delete all files and subdirectories
            Get-ChildItem $path -File -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue

            # Output results
            $sizeStr = Format-Size -size $size
            Write-Host "Deleted: $path"
            Write-Host "  Folders deleted: $folderCount"
            Write-Host "  Files deleted: $fileCount"
            Write-Host "  Space freed: $sizeStr"
        }
        else {
            Write-Host "Error: '$path' is not a valid directory or does not exist."
        }
    }
}

# Function to display drive information for the current drive
function driveinfo {
    # Get the drive where the current location resides
    $currentDrive = (Get-Location).Drive.Name

    # Pull size info for that drive
    $info = Get-PSDrive -Name $currentDrive

    # Calculate used space
    $used = $info.Used   # already in bytes
    $free = $info.Free   # already in bytes
    $total = $used + $free

    # Show nicely formatted output
    [pscustomobject]@{
        Drive       = $currentDrive
        TotalGB     = "{0:N2}" -f ($total / 1GB)
        UsedGB      = "{0:N2}" -f ($used / 1GB)
        FreeGB      = "{0:N2}" -f ($free / 1GB)
        PercentFree = "{0:P1}" -f ($free / $total)
    }
}

# Function to display folders and files in multiple columns
function ls {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$paths
    )

    # If no arguments provided, use current directory
    if ($paths.Count -eq 0 -or [string]::IsNullOrWhiteSpace($paths[0])) {
        $paths = @((Get-Location).Path)
    }

    # Validate that all paths are valid directories
    $validPaths = @()
    foreach ($path in $paths) {
        if (Test-Path -Path $path -PathType Container) {
            $validPaths += $path
        }
        else {
            Write-Host "Warning: '$path' is not a valid folder" -ForegroundColor Yellow
        }
    }

    if ($validPaths.Count -eq 0) {
        Write-Host "No valid directories to list" -ForegroundColor Red
        return
    }

    # Process each directory
    foreach ($dir in $validPaths) {
        # Get all items and separate folders from files
        $items = @(Get-ChildItem -Path $dir -Force)
        $folders = @($items | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty Name | Sort-Object)
        $files = @($items | Where-Object { -not $_.PSIsContainer } | Select-Object -ExpandProperty Name | Sort-Object)

        # Combine folders first, then files
        $all = $folders + $files

        if ($all.Count -eq 0) {
            Write-Host "Directory is empty: $dir" -ForegroundColor Gray
            continue
        }

        # Calculate number of columns and rows needed
        # Determine reasonable column width and number of columns
        $maxNameLength = ($all | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
        $colWidth = [Math]::Min($maxNameLength + 2, 30)
        $windowWidth = $Host.UI.RawUI.WindowSize.Width - 1  # Account for window edge
        $numCols = [Math]::Max(1, [int]($windowWidth / $colWidth))

        # Calculate rows needed
        $numRows = [Math]::Ceiling($all.Count / $numCols)

        # Create output grid
        for ($row = 0; $row -lt $numRows; $row++) {
            for ($col = 0; $col -lt $numCols; $col++) {
                $index = $col * $numRows + $row
                if ($index -lt $all.Count) {
                    $itemName = $all[$index]
                    $isFolder = $folders -contains $itemName
                    $itemObj = $items | Where-Object { $_.Name -eq $itemName } | Select-Object -First 1

                    # Add brackets around folder names
                    $displayName = if ($isFolder) { "[$itemName]" } else { $itemName }

                    # Don't pad the last column to avoid trailing spaces
                    $isLastCol = ($col -eq ($numCols - 1))
                    $displayItem = if ($isLastCol) { $displayName } else { $displayName.PadRight($colWidth) }

                    # Determine color based on priority
                    $color = Get-ItemColor -itemName $itemName -isFolder $isFolder -itemObj $itemObj

                    Write-Host $displayItem -ForegroundColor $color -NoNewline
                }
            }
            Write-Host ""  # Newline at end of row
        }
        Write-Host ""  # Blank line between directories
    }
}

# This displays a vertical list of folders and files sorted by modification time with the most
# recent appearing at the bottom. The second column displayes the modification time, and the third
# column displays the size of the folder or file.

function lt {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Paths
    )

    # If no paths provided, use current directory
    if ($Paths.Count -eq 0) {
        $Paths = @(".")
    }

    foreach ($path in $Paths) {
        # Validate that the path is a valid folder
        if (-not (Test-Path -Path $path -PathType Container)) {
            Write-Host "Error: '$path' is not a valid folder" -ForegroundColor Red
            continue
        }

        $resolvedPath = Resolve-Path $path

        # Get all items and sort by modification time (oldest first)
        $items = @()

        # Get directories first
        $dirs = Get-ChildItem -Path $resolvedPath -Directory -ErrorAction SilentlyContinue | Sort-Object -Property LastWriteTime
        foreach ($dir in $dirs) {
            $items += $dir
        }

        # Get files
        $files = Get-ChildItem -Path $resolvedPath -File -ErrorAction SilentlyContinue | Sort-Object -Property LastWriteTime
        foreach ($file in $files) {
            $items += $file
        }

        # Calculate the maximum width needed for the first column
        $maxNameLength = 0
        foreach ($item in $items) {
            if ($item -is [System.IO.DirectoryInfo]) {
                $displayName = "[$($item.Name)]"
            }
            else {
                $displayName = $item.Name
            }
            $length = $displayName.Length
            if ($length -gt $maxNameLength) {
                $maxNameLength = $length
            }
        }

        # Add two spaces for padding
        $columnWidth = $maxNameLength + 2

        # Display the items
        foreach ($item in $items) {
            $lastWriteTime = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            $isFolder = $item -is [System.IO.DirectoryInfo]

            # Calculate size
            if ($isFolder) {
                $displayName = "[$($item.Name)]"
                $size = Get-FolderSize -folderPath $item.FullName
                $sizeStr = Format-Size -size $size
            }
            else {
                $displayName = $item.Name
                $size = $item.Length
                $sizeStr = Format-Size -size $size
            }

            # Get the color for this item
            $color = Get-ItemColor -itemName $item.Name -isFolder $isFolder -itemObj $item

            # Display the name with appropriate color
            Write-Host "$displayName".PadRight($columnWidth) -ForegroundColor $color -NoNewline

            # Display time and size in their original colors
            Write-Host "  $lastWriteTime".PadRight(25) -NoNewline
            Write-Host "  $sizeStr" -ForegroundColor Yellow
        }

        Write-Host ""
    }
}
