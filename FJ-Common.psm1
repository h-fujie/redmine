class FJCommon {
    static [string] $BaseDir = "$($Env:USERPROFILE)\.fj";

    static [string] CreateTemporaryDir() {
        $TemporaryDir = "$([FJCommon]::BaseDir)\$((Get-Date).ToString('yyyyMMddHHmmss'))";
        if (-not (Test-Path -Path $TemporaryDir)) {
            New-Item -Path $TemporaryDir -ItemType Directory -Force;
        }
        return $TemporaryDir;
    }
}
