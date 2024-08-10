Add-Type -AssemblyName System.Web;

class FJAttachment {
    [int]    $AttachmentId;
    [string] $FileName;
    [string] $ContentType;
    [string] $ContentUrl;
}

class FJIssue {
    [int]    $IssueId;
    [int]    $ProjectId;
    [int]    $TrackerId;
    [int]    $StatusId;
    [FJAttachment[]] $Attachments;
}

class FJRedmine {
    hidden [string] $BaseUrl;
    hidden [string] $Token;
    hidden [string] $TemporaryDir = "$($Env:USERPROFILE)\develop\redmine\temp";

    FJRedmine([string] $BaseUrl, [string] $Token) {
        $this.BaseUrl = $BaseUrl;
        $this.Token   = $Token;
    }

    hidden [xml] InvokeGetRequest([string] $Path) {
        $Response = Invoke-WebRequest `
            -Uri "$($this.BaseUrl)$($Path)" `
            -Method "GET" `
            -Headers @{
                "X-Redmine-API-Key" = $this.Token
                "Accept"            = "application/xml"
            } `
            -ErrorAction Stop;
        return [xml] $Response.Content;
    }

    hidden [xml] InvokePostRequest([string] $Path, [hashtable] $Body) {
        $Response = Invoke-WebRequest `
            -Uri "$($this.BaseUrl)$($Path)" `
            -Method "POST" `
            -Headers @{
                "X-Redmine-API-Key" = $this.Token
                "Content-Type"      = "application/xml"
                "Accept"            = "application/xml"
            } `
            -Body $Body `
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

    [FJIssue[]] GetIssues([hashtable] $Filter) {
        $Issues = New-Object System.Collections.ArrayList;
        $Query = "";
        foreach ($Key in $Filter.Keys) {
            if (0 -ne $Query.Length) {
                $Query += "&";
            }
            $Query += "$([System.Web.HttpUtility]::UrlEncode($Key))=$([System.Web.HttpUtility]::UrlEncode($Filter[$Key]))";
        }
        $offset = 0;
        $limit = 100;
        while ($true) {
            $Content = $this.InvokeGetRequest("/issues.xml?offset=$($offset)&limit=$($limit)&sort=issue_id&$($Query)");
            if ($null -eq $Content.issues.issue) {
                break;
            }
            foreach ($Element in [FJRedmine]::ToArray($Content.issues.issue)) {
                $Issue = New-Object FJIssue;
                $Issue.IssueId   = [int] $Element.id;
                $Issue.ProjectId = [int] $Element.project.id;
                $Issue.TrackerId = [int] $Element.tracker.id;
                $Issue.StatusId  = [int] $Element.status.id;
                [void] $Issues.Add($Issue);
            }
            $offset += $limit;
        }
        return $Issues.ToArray();
    }

    [FJIssue] GetIssue([int] $IssueId) {
        $Content = $this.InvokeGetRequest("/issues/$($IssueId).xml?include=attachments");
        if ($null -eq $Content.issue) {
            return $null;
        }
        $Issue = New-Object FJIssue;
        $Issue.IssueId   = [int] $Content.issue.id;
        $Issue.ProjectId = [int] $Content.issue.project.id;
        $Issue.TrackerId = [int] $Content.issue.tracker.id;
        $Issue.StatusId  = [int] $Content.issue.status.id;
        $Attachments = New-Object System.Collections.ArrayList;
        if ($null -ne $Content.issue.attachments) {
            foreach ($Element in [FJRedmine]::ToArray($Content.issue.attachments.attachment)) {
                [void] $Attachments.Add($this.GetAttachment($Element));
            }
        }
        $Issue.Attachments = $Attachments.ToArray();
        return $Issue;
    }

    [FJAttachment] GetAttachment([System.Xml.XmlElement] $Element) {
        $Attachment = New-Object FJAttachment;
        $Attachment.AttachmentId = $Element.id;
        $Attachment.FileName     = $Element.filename;
        $Attachment.ContentType  = $Element.content_type;
        $Attachment.ContentUrl   = $Element.content_url;
        return $Attachment;
    }

    [string] DownloadAttachment([FJAttachment] $Attachment) {
        $DownloadPath = "$($this.TemporaryDir)\$((Get-Date).ToString('yyyyMMddHHmmss'))_$($Attachment.FileName)";
        Invoke-WebRequest `
            -Uri $Attachment.ContentUrl `
            -Method "GET" `
            -Headers @{
                "X-Redmine-API-Key" = $this.Token
                "Accept"            = $Attachment.ContentType
            } `
            -OutFile $DownloadPath `
            -ErrorAction Stop;
        return $DownloadPath;
    }
}
