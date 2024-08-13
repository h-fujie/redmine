using module ".\FJ-Common.psm1";
using module ".\FJ-Security.psm1";

Add-Type -AssemblyName System.Web;

class FJAttachment {
    [int]    $AttachmentId;
    [string] $FileName;
    [string] $ContentType;
    [string] $ContentUrl;

    FJAttachment([System.Xml.XmlElement] $Element) {
        $this.AttachmentId = $Element.id;
        $this.FileName     = $Element.filename;
        $this.ContentType  = $Element.content_type;
        $this.ContentUrl   = $Element.content_url;
    }
}

class FJIdNamePair {
    [int]    $Id;
    [string] $Name;

    FJIdNamePair([System.Xml.XmlElement] $Element) {
        $this.Id   = $Element.id;
        $this.Name = $Element.name;
    }
}

class FJProject : FJIdNamePair { FJProject([System.Xml.XmlElement] $Element) : base($Element) {} }
class FJTracker : FJIdNamePair { FJTracker([System.Xml.XmlElement] $Element) : base($Element) {} }
class FJStatus : FJIdNamePair { FJStatus([System.Xml.XmlElement] $Element) : base($Element) {} }
class FJCustomField : FJIdNamePair {
    [string] $Value;

    FJCustomField([System.Xml.XmlElement] $Element) : base($Element) {
        $this.Value = $Element.value;
    }
}

class FJIssue {
    [int]             $IssueId;
    [FJProject]       $Project;
    [FJTracker]       $Tracker;
    [FJStatus]        $Status;
    [string]          $Subject;
    [string]          $Description;
    [FJCustomField[]] $CustomFields;
    [FJAttachment[]]  $Attachments;

    FJIssue([System.Xml.XmlElement] $Element) {
        $this.IssueId = $Element.id;
        $this.Project = New-Object FJProject($Element.project);
        $this.Tracker = New-Object FJTracker($Element.tracker);
        $this.Status  = New-Object FJStatus($Element.status);
        $this.Subject     = $Element.subject;
        $this.Description = $Element.description;
        $Fields = New-Object System.Collections.ArrayList;
        if ($null -ne $Element.custom_fields) {
            foreach ($Field in [FJRedmine]::ToArray($Element.custom_fields.custom_field)) {
                [void] $Fields.Add((New-Object FJCustomField($Field)));
            }
        }
        $this.CustomFields = $Fields.ToArray();
    }
}

class FJIssueFilter {
    [int] $IssueId;
    [int] $ProjectId;
    [int] $TrackerId;
    [int] $StatusId;
}

class FJRedmine {
    hidden static [string] $TemporaryDir = "$([FJCommon]::BaseDir)\redmine";

    hidden [string] $BaseUrl;
    hidden [string] $Token;
    hidden [string] $User;

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

    hidden [xml] InvokeUpdateRequest([string] $Path, [xml] $Body, [string] $Method) {
        $Response = Invoke-WebRequest `
            -Uri "$($this.BaseUrl)$($Path)" `
            -Method $Method `
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

    hidden [xml] InvokePostRequest([string] $Path, [xml] $Body) {
        return $this.InvokeUpdateRequest($Path, $Body, "POST");
    }

    hidden [xml] InvokePutRequest([string] $Path, [xml] $Body) {
        return $this.InvokeUpdateRequest($Path, $Body, "PUT");
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

    hidden static [string] GetIssueQuery([FJIssueFilter] $Filter) {
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
        return $this.GetIssues((New-Object FJIssueFilter));
    }

    [FJIssue[]] GetIssues([FJIssueFilter] $Filter) {
        $Issues = New-Object System.Collections.ArrayList;
        for ($offset, $total, $limit = 0, 1, 100; $offset -lt $total; $offset += $limit) {
            $Content = $this.InvokeGetRequest("/issues.xml?offset=$($offset)&limit=$($limit)&sort=issue_id$([FJRedmine]::GetIssueQuery($Filter))");
            $total = [int] $Content.issues.total_count;
            foreach ($Element in [FJRedmine]::ToArray($Content.issues.issue)) {
                [void] $Issues.Add((New-Object FJIssue($Element)));
            }
        }
        return $Issues.ToArray();
    }

    [FJIssue] GetIssue([int] $IssueId) {
        $Content = $this.InvokeGetRequest("/issues/$($IssueId).xml?include=attachments");
        if ($null -eq $Content.issue) {
            return $null;
        }
        $Issue = New-Object FJIssue($Content.issue);
        $Attachments = New-Object System.Collections.ArrayList;
        if ($null -ne $Content.issue.attachments) {
            foreach ($Element in [FJRedmine]::ToArray($Content.issue.attachments.attachment)) {
                [void] $Attachments.Add((New-Object FJAttachment($Element)));
            }
        }
        $Issue.Attachments = $Attachments.ToArray();
        return $Issue;
    }

    [void] UpdateIssue([FJIssue] $Issue) {
        # 初版はステータスのみ
        $Body = [xml] "<issue><status_id>$($Issue.Status.Id)</status_id></issue>";
        $this.InvokePutRequest("/issues/$($Issue.IssueId).xml", $Body);
    }

    [string] DownloadAttachment([FJAttachment] $Attachment) {
        if (-not (Test-Path -Path $([FJRedmine]::TemporaryDir))) {
            New-Item -Path $([FJRedmine]::TemporaryDir) -ItemType Directory -Force;
        }
        $DownloadPath = "$([FJRedmine]::TemporaryDir)\$((Get-Date).ToString('yyyyMMddHHmmss'))_$($Attachment.FileName)";
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
