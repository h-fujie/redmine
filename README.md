# Redmine

## メモ

* オフライン環境でRedmineサーバを構築する
* プラグインのマイグレーションもできるはず

### 資材

```
+ plugins
    + easy_gantt_pro-5-x.zip
    + redmine_agile-1_6_9-light.zip
+ source
    + redmine-5.1.5.tar.gz
    + ruby-3.2.6.tar.gz
```

### コマンド

```cmd
cd /d redmine
docker image build --tag fj_redmine:alpha .
cd ..
docker compose up -d
```

```cmd
docker image save fj_redmine:alpha > fj_redmine_alpha.tar
docker image save mysql:8.4.3 > mysql_8_4_3.tar
```
