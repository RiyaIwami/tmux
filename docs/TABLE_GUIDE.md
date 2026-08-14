# テーブル設計ルールガイド

本ドキュメントは、Laravelプロジェクトにおけるテーブル設計の共通ルールを「マイグレーションファイル視点」と「論理設計視点」の両面から定義します。

Claude Codeは、両者に準拠したマイグレーション・モデルを自動でレビュー可能です。
---

## マイグレーションファイルベースの設計ルール

### 命名規則

| 種別           | 命名規則                     | 例                              |
|----------------|------------------------------|---------------------------------|
| テーブル名     | 複数形・スネークケース        | `users`, `company_users`        |
| 中間テーブル   | テーブル名同士を連結させ、前の方は単数系、後に連結した方を複数形にして命名する。どちらを前後にするかは主流な命名規則に合う方を採用してください。 | `books`と`geres`の中間テーブルなら`book_genres`, `clients`と`services`なら`client_services` |
| マイグレーション名 | `create_xxx_table` 形式     | `create_tasks_table`            |
| 外部キー       | `**_id`                      | `user_id`, `task_id`            |
|boolean型カラム|`is_**`, `has_**`, `can_**`などで命名。`flag`という命名は禁止|`is_enabled`, `has_subscription`|
|datetime型カラム|時刻までを扱うデータなら`**_at`, 日付までを扱うデータなら`**_on`|`available_on`, `registered_at`, `expired_at`|
|状態を扱うカラム|`type`や`status`と命名。アプリケーション側で`{Model名}{カラム名}.php`と命名したEnumを作成し、アプリケーション側でEnumを使用し、データを管理する。　|`users.type`, `users_verifications.status`|

## テーブル定義ルール
- 不可算名詞でテーブルを命名しない。別の単語で命名すること。
- あるデータとセットのようなデータは同じ単語から始めて統一すること。`users`

## カラム定義ルール
- **TIMESTAMP型の使用を禁止する。timestamps()メソッドを使用しないこと**
  ```php
  // ✅ 推奨：アプリケーションカラムの使用
  $table->dateTime('registered_at')->index();
  
  // ❌ 禁止：システムカラムの使用
  $table->timestamps(); // created_at, updated_atの使用は禁止
  ```
- 金額・数値データは`integer`型を使用する。
- 文字列データは`string`型を使用し、必要に応じて長さを指定する。
- 長文テキストは`text`型を使用する。
- 日時データは`dateTime`型を使用する。
- 論理値データは`boolean`型を使用する。
- **JSONカラムは基本的に作成しない。**データベースだから構造化データとして管理する。
- JSONカラムを追加するくらいなら、適切なテーブルを作成して正規化すること。

## インデックス設計ルール
- 検索・ソート・結合で使用されるカラムには必ず`index()`を設定する。
  ```php
  $table->string('email')->nullable()->index();
  $table->string('last_name')->index();
  $table->dateTime('registered_at')->index()->comment('会員登録日');
  ```
- **外部キーカラムには`index()`を設定しない。**外部キー制約により自動的にインデックスが付与される。
- 一意制約が必要な場合は`unique()`を使用する。
  ```php
  $table->string('account_id')->unique();
  ```
- 時系列データのカラム（`**_at`）には`index()`を設定する。
- **検索で使用されるカラムには必ずindex()を付与すること**
- **status等のカーディナリティが低いカラムにはindex()を付与しないこと**

## 外部キー制約設計ルール
- 外部キーには`foreignId()`と`constrained()`メソッドを使用する。
  ```php
  $table->foreignId('user_id')->constrained();
  $table->foreignId('lottery_title_id')->constrained();
  ```
- 親レコード削除時の動作を明確に定義する。
  - 削除連携が必要な場合：`onDelete('cascade')`
  - 削除を禁止する場合：`onDelete('restrict')`
  - NULLに設定する場合：`onDelete('set null')`

## コメント記述ルール
- 複雑なビジネスロジックを含むカラムにはコメントを追加する。
  ```php
  $table->boolean('can_news_notify')->comment('お知らせの通知を許可するか');
  $table->integer('including_tax_amount')->comment('単価列');
  $table->integer('excluding_tax_amount')->comment('10％商品小計列');
  ```
- 金額計算に関連するカラムには税込・税抜の区別を明記する。
- 外部システムとの連携項目には詳細なコメントを記述する。

## nullable設定ルール
- 必須項目には`nullable()`を設定しない。
- 任意項目には`nullable()`を設定する。
- 外部キーで親レコードが存在しない場合があるものは`nullable()`を設定する。
  ```php
  $table->string('email')->nullable()->index();
  $table->integer('gender');
  ```

## デフォルト値設定ルール
- boolean型は明確なデフォルト値を設定する。
  ```php
  $table->boolean('is_enabled')->default(true);
  $table->boolean('is_test_user')->default(false);
  $table->boolean('has_birthday_changed')->default(false);
  ```
- 整数型で初期値が必要な場合は`default(0)`を設定する。
- **デフォルト値はbooleanではない場合。必ずEnumで管理すること**
  ```php
  // ✅ 推奨：Enumを使用したデフォルト値
  $table->string('status')->default(TaskStatus::PENDING->value);
  
  // ❌ 禁止：文字列直接指定
  $table->string('status')->default('pending');
  ```

## システムカラムの統一ルール
- 本プロジェクトでは`created_at`, `updated_at`を使用せず、`datetimes()`メソッドを使用する。
  ```php
  $table->datetimes();
  ```
- `users`テーブルの`timestamps()`はよく放置されるが、`datetimes()`に修正すること。
- `datetimes()`は`timestamps()`を`datetimes()`に変更したもので、同じ`created_at`, `updated_at`カラムを作成する。
- 時刻まで入れるカラムは`**_at`、日時のみは`**_on`形式で統一する。
- 有効/無効フラグは`is_enabled`で統一する。

### Laravelデフォルトマイグレーション修正ルール
- **Laravelデフォルトのusersテーブルマイグレーションファイルの`timestamps()`は必ず`datetimes()`に修正すること**
- **新規プロジェクト作成時の必須作業**
  ```php
  // ❌ Laravelデフォルト
  $table->timestamps();
  
  // ✅ 修正後
  $table->datetimes();
  ```
- **不要なPHPDocコメントも同時に削除すること**
  ```php
  // ❌ デフォルト
  /**
   * Run the migrations.
   */
  public function up(): void
  
  // ✅ 修正後
  public function up(): void
  ```

## マイグレーションファイル生成
- 基本的にマイグレーションファイルが作成されると同時にモデルも作られた方がいい為、Modelをベースに-msオプションでマイグレーションファイルとSeederファイルを作成する。
    ```bash
        ddev artisan make:model -ms User
    ```

## マイグレーションファイル記述ルール
- カラム追加時は`after()`メソッドを使用してカラムの位置を指定する。
  ```php
  $table->boolean('is_test_user')->default(false)->after('is_enabled');
  ```
- 削除するカラムは`dropColumn()`で配列形式で指定する。
  ```php
  $table->dropColumn([
      'including_tax_amount',
      'tax_amount',
      'including_tax_delivery_amount'
  ]);
  ```
- マイグレーションファイルは時系列順に作成する。
- 既存テーブルの構造を壊さないよう注意する。

## 履歴テーブルの設計原則
- 履歴系テーブルは必ず`**_histories`形式で命名する。
- 履歴テーブルには処理日時カラム（`**_at`）を必ず含める。
- 操作者を記録するためのユーザーIDカラムを含める。
- 操作内容を記録するためのtypeカラムを含める。

## 中間テーブルの設計ルール
- 中間テーブルでも`datetimes()`メソッドを使用する。
- 関連テーブルの外部キーには適切な制約を設定する。
- 削除時の動作（cascade, restrict等）を明確に定義する。

## シーダーについて
- 本番環境でも使用されるマスターデータのシーダーを作成すること。
- テスト用のシーダーと本番用のシーダーを分けて作成すること。
- シーダーの実行順序を考慮し、外部キー制約を満たすよう依存関係を整理すること。
- シーダーファイルの命名規則：
  ```bash
  {Model名}Seeder.php
  ```
- 実装例：
  ```php
  public function run(): void
  {
      // 本番環境でも使用されるマスターデータ
      Genre::create([
        'name' => 'アニメ',
        'display_order' => 1
      ]);
      Genre::create([
        'name' => 'ゲーム',
        'display_order' => 2
      ]);
      
      // テスト用データ（条件分岐で制御）
      if (app()->environment('local', 'testing')) {
          User::factory(10)->create();
      }
  }
  ```
- `DatabaseSeeder.php`では適切な順序でシーダーを呼び出すこと。
- 大量データを投入する場合は、メモリ効率を考慮してchunkやバッチ処理を使用すること。
- **Seederの中身が空の場合は適切な実装を行うこと**