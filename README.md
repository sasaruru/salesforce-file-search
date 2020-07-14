# salesforce-file-search

## 概要
ファイルの中身を検索し、結果をオブジェクトと一緒に表示する.
検索対象の親オブジェクトは選択可能とする.

## 処理内容
1. SOSLを使用して入力されたキーワードからContentVersionを検索する
2. SOQLで1で取得したContentVersionのContentDocumentIdを条件にContentDocumentLinkを検索する
3. SOQLで2で取得したContentDocumentLinkのLinkedEntityIdを条件に対象オブジェクトを検索する
4. 結果を画面に表示する.

### 注意点
画面に表示さえるのは「取得したファイルのとその親オブジェクト」となり、１つの親オブジェクトに対して複数のファイルがヒットした場合すべて表示させる必要がある.  
JOIできない関係上、データを取得してから改めて画面表示用のデータを作成している.

## インストール方法（多分)
1. クローンする
 `git clone git@github.com:sasaruru/salesforce-file-search.git`
2. salesforce 組織に接続
 develop
 `sfdx force:auth:web:login --setalias {UserName} --instanceurl https://login.salesforce.com` 
 sandbox
 `sfdx force:auth:web:login --setalias {UserName} --instanceurl https://test.salesforce.com` 
3. 各組織にpush
 `sfdx force:source:push -u {UserName}`
