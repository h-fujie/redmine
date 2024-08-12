using module ".\FJ-Security.psm1";

Add-Type -AssemblyName System.Web;

class FJAttachment {
    [int]    $AttachmentId;
    [string] $FileName;
    [string] $ContentType;
    [string] $ContentUrl;

    static [FJAttachment] Create([System.Xml.XmlElement] $Element) {
        $Attachment = New-Object FJAttachment;
        $Attachment.AttachmentId = $Element.id;
        $Attachment.FileName     = $Element.filename;
        $Attachment.ContentType  = $Element.content_type;
        $Attachment.ContentUrl   = $Element.content_url;
        return $Attachment;
    }
}

class FJIssue {
    [int] $IssueId;
    [int] $ProjectId;
    [int] $TrackerId;
    [int] $StatusId;
    [FJAttachment[]] $Attachments;

    static [FJIssue] Create([System.Xml.XmlElement] $Element) {
        $Issue = New-Object FJIssue;
        $Issue.IssueId   = $Element.id;
        $Issue.ProjectId = $Element.project.id;
        $Issue.TrackerId = $Element.tracker.id;
        $Issue.StatusId  = $Element.status.id;
        return $Issue;
    }
}

class FJRedmine {
    hidden [string] $BaseUrl;
    hidden [string] $Token;
    hidden [string] $User;
    hidden [string] $TemporaryDir = "$($Env:USERPROFILE)\.fj\redmine";

    FJRedmine([string] $BaseUrl, [string] $Token) {
        $this.BaseUrl = $BaseUrl;
        $this.Token   = $Token;
    }

    FJRedmine([string] $BaseUrl, [string] $Token, [string] $User) {
        $this.BaseUrl = $BaseUrl;
        $this.Token   = $Token;
        $this.User    = $User;
    }

    hidden [xml] InvokeGetRequest([string] $Path) {
        $Response = Invoke-WebRequest `
            -Uri "$($this.BaseUrl)$($Path)" `
            -Method "GET" `
            -Headers @{
                "X-Redmine-API-Key" = $this.Token
                "Accept"            = "application/xml"
            } `
            -Credential ([FJSecurity]::LoadCredential($this.User)) `
            -ErrorAction Stop;
        return [xml] $Response.Content;
    }

    hidden [xml] InvokePostRequest([string] $Path, [xml] $Body) {
        $Response = Invoke-WebRequest `
            -Uri "$($this.BaseUrl)$($Path)" `
            -Method "POST" `
            -Headers @{
                "X-Redmine-API-Key" = $this.Token
                "Content-Type"      = "application/xml"
                "Accept"            = "application/xml"
            } `
            -Body $Body `
            -Credential ([FJSecurity]::LoadCredential($this.User)) `
            -ErrorAction Stop;
        return [xml] $Response.Content;
    }

    hidden static [array] ToArray($Object) {
        if ($null -eq $Object) {
            return @();
        }
        if ("Array" -eq $Object.GetType().BaseType.Name) {
            return $Object;
        }
        return @($Object);
    }

    [void] SetTemporaryDir([string] $TemporaryDir) {
        $this.TemporaryDir = $TemporaryDir;
    }

    hidden static [string] GetIssueQuery([FJIssue] $Filter) {
        $Query = "";
        if (0 -ne $Filter.IssueId) {
            $Query += "&issue_id=$($Filter.IssueId)";
        }
        if (0 -ne $Filter.ProjectId) {
            $Query += "&project_id=$($Filter.ProjectId)";
        }
        if (0 -ne $Filter.TrackerId) {
            $Query += "&tracker_id=$($Filter.TrackerId)";
        }
        if (0 -ne $Filter.StatusId) {
            $Query += "&status_id=$($Filter.StatusId)";
        }
        return $Query;
    }

    [FJIssue[]] GetIssues() {
        return $this.GetIssues((New-Object FJIssue));
    }

    [FJIssue[]] GetIssues([FJIssue] $Filter) {
        $Issues = New-Object System.Collections.ArrayList;
        for ($offset, $total, $limit = 0, 1, 100; $offset -lt $total; $offset += $limit) {
            $Content = $this.InvokeGetRequest("/issues.xml?offset=$($offset)&limit=$($limit)&sort=issue_id$([FJRedmine]::GetIssueQuery($Filter))");
            $total = [int] $Content.issues.total_count;
            foreach ($Element in [FJRedmine]::ToArray($Content.issues.issue)) {
                [void] $Issues.Add([FJIssue]::Create($Element));
            }
        }
        return $Issues.ToArray();
    }

    [FJIssue] GetIssue([int] $IssueId) {
        $Content = $this.InvokeGetRequest("/issues/$($IssueId).xml?include=attachments");
        if ($null -eq $Content.issue) {
            return $null;
        }
        $Issue = [FJIssue]::Create($Content.issue);
        $Attachments = New-Object System.Collections.ArrayList;
        if ($null -ne $Content.issue.attachments) {
            foreach ($Element in [FJRedmine]::ToArray($Content.issue.attachments.attachment)) {
                [void] $Attachments.Add([FJAttachment]::Create($Element));
            }
        }
        $Issue.Attachments = $Attachments.ToArray();
        return $Issue;
    }

    [string] DownloadAttachment([FJAttachment] $Attachment) {
        if (-not (Test-Path -Path "$($this.TemporaryDir)")) {
            New-Item -Path "$($this.TemporaryDir)" -ItemType Directory -Force;
        }
        $DownloadPath = "$($this.TemporaryDir)\$((Get-Date).ToString('yyyyMMddHHmmss'))_$($Attachment.FileName)";
        Invoke-WebRequest `
            -Uri $Attachment.ContentUrl `
            -Method "GET" `
            -Headers @{
                "X-Redmine-API-Key" = $this.Token
                "Accept"            = $Attachment.ContentType
            } `
            -OutFile $DownloadPath `
            -Credential ([FJSecurity]::LoadCredential($this.User)) `
            -ErrorAction Stop;
        return $DownloadPath;
    }
}
