# DeepChem MolAI Frontend (Flutter Web)

Flutter Web フロントエンドのソースコードです。
セットアップ手順はリポジトリルートの [README.md](../README.md) を参照してください。

## API URL の変更

`lib/config/app_config.dart` を編集してから再ビルドする:

```dart
static const String apiBaseUrl = 'http://localhost:8282';
```

## ビルド

```bash
flutter pub get
flutter build web --release
# → build/web/ に出力される
```
