using module ".\FJ-Common.psm1";
using module ".\FJ-Security.psm1";
using module ".\FJ-FileUtils.psm1";

<#
 # モジュール読込前に参照DLLを読み込むこと
 # $NETPath = Get-ItemPropertyValue -LiteralPath 'HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name InstallPath;
 # [Reflection.Assembly]::LoadFile((Join-Path -Path $NETPath -ChildPath "System.IO.Compression.dll"));
 # [Reflection.Assembly]::LoadFile((Join-Path -Path $NETPath -ChildPath "System.IO.Compression.FileSystem.dll"));
 #>

class FJLogUtils {
    static [string] ArchiveLogFiles([string] $Path) {
        $Date = (Get-Date).AddDays(-1);
        return [FJLogUtils]::ArchiveLogFiles($Path, $Date);
    }
    static [string] ArchiveLogFiles([string] $Path, [datetime] $Date) {
        $TempDir = [FJCommon]::CreateTemporaryDir();
        $ArchiveFile = [FJLogUtils]::ArchiveLogFiles($Path, $Date, (Join-Path -Path $TempDir -ChildPath "$($Date.ToString('yyyyMMdd')).zip"));
        if ([string]::IsNullOrEmpty($ArchiveFile)) {
            Remove-Item -Path $TempDir -Force;
        }
        return $ArchiveFile;
    }
    static [string] ArchiveLogFiles([string] $Path, [datetime] $Date, [string] $ArchiveFile) {
        if ([string]::IsNullOrEmpty($Path)) {
            throw "圧縮対象が指定されていません。"
        }
        if ($null -eq $Date) {
            throw "日付が指定されていません。";
        }
        if ([string]::IsNullOrEmpty($ArchiveFile)) {
            throw "圧縮ファイルパスが指定されていません。";
        }
        $Start = Get-Date -Date $Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0;
        $From = (Get-Date -Date $Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0).AddDays(1);
        $Target = Get-ChildItem -Path $Path -File -Force | Where-Object { $_.CreationTime -ge $Start -and $_.CreationTime -lt $From };
        if (0 -eq $Target.Count) {
            Write-Warning "圧縮対象のファイルが見つかりませんでした。";
            return "";
        }
        [FJFileUtils]::ArchiveFiles($ArchiveFile, $Target.FullName);
        return $ArchiveFile;
    }
    static [void] DeleteLogFiles([string] $Path) {
        $Date = (Get-Date).AddDays(-2);
        [FJLogUtils]::DeleteLogFiles($Path, $Date);
    }
    static [void] DeleteLogFiles([string] $Path, [datetime] $Date) {
        if ([string]::IsNullOrEmpty($Path)) {
            throw "削除対象が指定されていません。"
        }
        if ($null -eq $Date) {
            throw "日付が指定されていません。";
        }
        $Start = Get-Date -Date $Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0;
        $From = (Get-Date -Date $Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0).AddDays(1);
        $Target = Get-ChildItem -Path $Path -File -Force | Where-Object { $_.CreationTime -ge $Start -and $_.CreationTime -lt $From };
        if (0 -eq $Target.Count) {
            Write-Warning "削除対象のファイルが見つかりませんでした。";
            return;
        }
        Remove-Item -Path $Target.FullName -Force;
    }
}