# drift_app

### drift: TodoのID, Contentをデータベースで管理
### shared_preferences: Todoの数（TodoCount）を管理
### Secure Storage: secureKeyを管理
Addボタンが押されたときに、セキュアストレージにsecureKeyというキーで「This is a secure value」という文字列が保存される。その後、_getSecureValueメソッドを使ってこの値を取得し、画面に表示している。

