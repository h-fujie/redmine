using module ".\FJ-Common.psm1";

<#
 # モジュール読込前に参照DLLを読み込むこと
 # $NETPath = Get-ItemPropertyValue -LiteralPath 'HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name InstallPath;
 # [Reflection.Assembly]::LoadFile((Join-Path -Path $NETPath -ChildPath "System.IO.Compression.dll"));
 # [Reflection.Assembly]::LoadFile((Join-Path -Path $NETPath -ChildPath "System.IO.Compression.ZipFile.dll"));
 #>

class FJFileUtils {
    static [void] ArchiveFile([string] $Path, [string[]] $Entries) {
        if (Test-Path -Path $Path) {
            throw "アーカイブファイルがすでに存在します。 Path: '$($Path)'";
        }
        foreach ($Entry in $Entries) {
            if (-not (Test-Path -Path $Entry)) {
                throw "エントリが存在しません。 Entry: '$($Entry)";
            }
        }
        $ZipArchive = $null;
        try {
            $ZipArchive = [System.IO.Compression.ZipFile]::Open($Path, [System.IO.Compression.ZipArchiveMode]::Create);
            foreach ($Entry in $Entries) {
                $Item = Get-Item -Path $Entry;
                $ZipArchiveEntry = $ZipArchive.CreateEntry($Item.Name);
                $ZipArchiveEntry.LastWriteTime = $Item.LastWriteTime;
                $EntryWriter = $null;
                $EntryReader = $null;
                try {
                    $EntryReader = [System.IO.StreamReader]::new($Item.FullName);
                    $EntryWriter = [System.IO.StreamWriter]::new($ZipArchiveEntry.Open(), $EntryReader.CurrentEncoding);
                    while (-not $EntryReader.EndOfStream) {
                        $EntryWriter.WriteLine($EntryReader.ReadLine());
                    }
                } catch {
                    Write-Error "アーカイブエントリ作成に失敗しました。 Entry: '$($Entry)";
                    throw $_.Exception;
                } finally {
                    [FJCommon]::Dispose($EntryWriter);
                    [FJCommon]::Dispose($EntryReader);
                }
            }
        } catch {
            Write-Error "アーカイブファイル作成に失敗しました。 Path: '$($Path)";
            throw $_.Exception;
        } finally {
            [FJCommon]::Dispose($ZipArchive);
        }
    }
    static [bool] Exists([string] $Path) {
        if ([string]::IsNullOrEmpty($Path)) {
            return $false;
        }
        return Test-Path -Path $Path;
    }
    static [bool] IsFile([string] $Path) {
        if (-not ([FJFileUtils]::Exists($Path))) {
            return $false;
        }
        return -not (Get-Item -Path $Path).PSIsContainer;
    }
    static [bool] IsDirectory([string] $Path) {
        if (-not ([FJFileUtils]::Exists($Path))) {
            return $false;
        }
        return (Get-Item -Path $Path).PSIsContainer;
    }
    static [void] WriteNewFile([string] $FilePath, [string] $Text, [System.Text.Encoding] $Encoding) {
        $Writer = $null;
        try {
            $Writer = [System.IO.StreamWriter]::new($FilePath, $false, $Encoding);
            $Writer.Write($Text);
        }
        catch {
            throw $_.Exception;
        }
        finally {
            [FJCommon]::Dispose($Writer);
        }
    }
    static [string] Split([string] $Path, [int64] $Length) {
        return [FJFileUtils]::Split($Path, $Length, [System.Text.Encoding]::UTF8);
    }
    static [string] Split([string] $Path, [int64] $Length, [System.Text.Encoding] $Encoding) {
        if (-not ([FJFileUtils]::IsFile($Path))) {
            throw "ファイルを指定してください。 Path: '$($Path)'";
        }
        $Item = Get-Item -Path $Path;
        $Export = Join-Path -Path $Item.DirectoryName -ChildPath "$($Item.Name)_Export";
        if (-not ([FJFileUtils]::Exists($Export))) {
            New-Item -Path $Export -ItemType Directory -ErrorAction Stop;
        }
        return [FJFileUtils]::Split($Path, $Length, $Export, $Encoding);
    }
    static [string] Split([string] $Path, [int64] $Length, [string] $Export) {
        return [FJFileUtils]::Split($Path, $Length, $Export, [System.Text.Encoding]::UTF8);
    }
    static [string] Split([string] $Path, [int64] $Length, [string] $Export, [System.Text.Encoding] $Encoding) {
        if (-not ([FJFileUtils]::IsFile($Path))) {
            throw "ファイルを指定してください。 Path: '$($Path)'";
        }
        if (-not ([FJFileUtils]::IsDirectory($Export))) {
            throw "ディレクトリを指定してください。 Export: '$($Export)'";
        }
        $Reader = $null;
        try {
            $Item = Get-Item -Path $Path;
            $Count = 0;
            $Reader = [System.IO.StreamReader]::new($Item.FullName, $Encoding);
            $Txt = [System.Text.StringBuilder]::new();
            while (-not $Reader.EndOfStream) {
                [void] $Txt.Append([char] $Reader.Read());
                if ($Length -eq $Txt.Length -or $Reader.EndOfStream) {
                    $FilePath = Join-Path -Path $Export -ChildPath "$($Item.Name).$($Count)";
                    [FJFileUtils]::WriteNewFile($FilePath, $Txt.ToString(), $Encoding);
                    $Txt.Clear();
                    $Count++;
                }
            }
        } catch {
            throw $_.Exception;
        } finally {
            [FJCommon]::Dispose($Reader);
        }
        return $Export;
    }
    static [string] SplitByte([string] $Path, [int64] $Length) {
        return [FJFileUtils]::SplitByte($Path, $Length, [System.Text.Encoding]::UTF8);
    }
    static [string] SplitByte([string] $Path, [int64] $Length, [System.Text.Encoding] $Encoding) {
        if (-not ([FJFileUtils]::IsFile($Path))) {
            throw "ファイルを指定してください。 Path: '$($Path)'";
        }
        $Item = Get-Item -Path $Path;
        $Export = Join-Path -Path $Item.DirectoryName -ChildPath "$($Item.Name)_Export";
        if (-not ([FJFileUtils]::Exists($Export))) {
            New-Item -Path $Export -ItemType Directory -ErrorAction Stop;
        }
        return [FJFileUtils]::SplitByte($Path, $Length, $Export, $Encoding);
    }
    static [string] SplitByte([string] $Path, [int64] $Length, [string] $Export) {
        return [FJFileUtils]::SplitByte($Path, $Length, $Export, [System.Text.Encoding]::UTF8);
    }
    static [string] SplitByte([string] $Path, [int64] $Length, [string] $Export, [System.Text.Encoding] $Encoding) {
        if (-not ([FJFileUtils]::IsFile($Path))) {
            throw "ファイルを指定してください。 Path: '$($Path)'";
        }
        if (-not ([FJFileUtils]::IsDirectory($Export))) {
            throw "ディレクトリを指定してください。 Export: '$($Export)'";
        }
        $Reader = $null;
        try {
            $Item = Get-Item -Path $Path;
            $Count = 0;
            $Reader = [System.IO.StreamReader]::new($Item.FullName, $Encoding);
            $Txt = [System.Text.StringBuilder]::new();
            while (-not $Reader.EndOfStream) {
                $Ch = [char] $Reader.Read();
                $ByteCount = $Encoding.GetByteCount($Txt.ToString());
                $ChByteCount = $Encoding.GetByteCount($Ch);
                $BomByteCount = $Encoding.GetPreamble().Length;
                if ($Length -lt ($BomByteCount + $ByteCount + $ChByteCount)) {
                    $FilePath = Join-Path -Path $Export -ChildPath "$($Item.Name).$($Count)";
                    [FJFileUtils]::WriteNewFile($FilePath, $Txt.ToString(), $Encoding);
                    $Txt.Clear();
                    $Txt.Append($Ch);
                    $Count++;
                } else {
                    [void] $Txt.Append($Ch);
                }
            }
            if (0 -lt $Txt.Length) {
                $FilePath = Join-Path -Path $Export -ChildPath "$($Item.Name).$($Count)";
                [FJFileUtils]::WriteNewFile($FilePath, $Txt.ToString(), $Encoding);
            }
        } catch {
            throw $_.Exception;
        } finally {
            [FJCommon]::Dispose($Reader);
        }
        return $Export;
    }
}