# redmine

## ざっくり使い方

### 事前準備

1. Redmineの個人設定でAPIアクセスキーを発行する
2. 資格情報を登録する ※認証が必要な場合のみ

    ```powershell
    using module .\FJ-Security.psm1;
    [FJSecurity]::SaveCredential("h-fujie");
    ```

### チケット一覧取得

`GetIssues`

#### 認証情報が不要な場合

```powershell
using module .\FJ-Redmine.psm1;
# 第1引数：RedmineのベースURL
# 第2引数：APIアクセスキー
$Redmine = New-Object FJRedmine("http://localhost:8080", "token");
$Issues = $Redmine.GetIssues();
```

#### 認証情報が必要な場合

```powershell
using module .\FJ-Redmine.psm1;
# 第1引数：RedmineのベースURL
# 第2引数：APIアクセスキー
# 第3引数：資格情報登録したユーザID
$Redmine = New-Object FJRedmine("http://localhost:8080", "token", "h-fujie");
$Issues = $Redmine.GetIssues();
```

### チケット取得

`GetIssue`

### チケット更新

`UpdateIssue`

### 添付ファイル取得

`DownloadAttachment`

## その他

RedBull飲みたいナー
