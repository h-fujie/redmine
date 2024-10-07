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
        $ArchiveFile = Join-Path -Path ([FJCommon]::CreateTemporaryDir()) -ChildPath "$($Date.ToString('yyyyMMdd')).zip";
        return [FJLogUtils]::ArchiveLogFiles($Path, $Date, $ArchiveFile);
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
        [FJFileUtils]::ArchiveFile($ArchiveFile, $Target.FullName);
        return $ArchiveFile;
    }
}