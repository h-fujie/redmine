using module ".\FJ-Common.psm1";

Add-Type -AssemblyName System.IO.Compression.FileSystem;

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

}