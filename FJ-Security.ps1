class FJSecurity {
    hidden static [string] $BasePath = "$($Env:USERPROFILE)\.fj";
    hidden static [string] $CredentialsPath = "$([FJSecurity]::BasePath)\credentials";

    hidden static [string] CreateEncryptString() {
        return Read-Host -Prompt "Enter Password" -MaskInput | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString;
    }

    hidden static [hashtable] ReadCredentials() {
        if (-not (Test-Path -Path "$([FJSecurity]::BasePath)")) {
            New-Item -Path "$([FJSecurity]::BasePath)" -ItemType Directory -Force;
        }
        if (-not (Test-Path -Path "$([FJSecurity]::CredentialsPath)")) {
            Set-Content -Path "$([FJSecurity]::CredentialsPath)" -Value "" -Encoding Default;
        }
        return (Get-Content -Path "$([FJSecurity]::CredentialsPath)" -Raw | ConvertFrom-StringData);
    }

    hidden static [void] WriteCredentials([hashtable] $Credentials) {
        try {
            Move-Item -Path "$([FJSecurity]::CredentialsPath)" -Destination "$([FJSecurity]::CredentialsPath).old" -Force;
            foreach ($Key in $Credentials.Keys) {
                Add-Content -Path "$([FJSecurity]::CredentialsPath)" -Value "$($Key)=$($Credentials[$Key])" -Encoding Default;
            }
        } catch {
            Write-Error "Credentialの保存に失敗しました。";
            throw $_.Exception;
        }
    }

    static [pscredential] LoadCredential([string] $User) {
        $Credentials = [FJSecurity]::ReadCredentials();
        if (-not $Credentials.Contains($User)) {
            Write-Warning "Credentialが保存されていません。 User: $($User)";
            return $null;
        }
        return New-Object System.Management.Automation.PSCredential $User,(ConvertTo-SecureString -String $Credentials[$User]);
    }

    static [void] SaveCredential([string] $User) {
        $Credentials = [FJSecurity]::ReadCredentials();
        if ($Credentials.Contains($User)) {
            Write-Warning "Credentialが既に保存されているため上書きします。 User: $($User)";
            $Credentials[$User] = [FJSecurity]::CreateEncryptString();
        } else {
            $Credentials.Add($User, [FJSecurity]::CreateEncryptString());
        }
        [FJSecurity]::WriteCredentials($Credentials);
    }

    static [void] RemoveCredential([string] $User) {
        $Credentials = [FJSecurity]::ReadCredentials();
        if ($Credentials.Contains($User)) {
            $Credentials.Remove($User);
        } else {
            Write-Warning "Credentialが保存されていないためスキップします。 User: $($User)";
        }
        [FJSecurity]::WriteCredentials($Credentials);
    }

}