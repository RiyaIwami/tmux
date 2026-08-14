# 共通コーディング規約

本ドキュメントは、プロジェクト全体で共通して遵守すべきコーディング標準を定義します。

---
## 命名規則

### 変数名
- 変数の命名はLower Snake Caseで記述を行う
- 意味のある英語で命名すること（略語は避ける）
  - `$user`, `$registered_at`
- Eloquentから取得するデータは必ずModel名と一致させ、**複数**か**単体**かで複数形などで明確化する。
    ```php
    $task = Task::first();
    $task = Task::find($id);
    
    $tasks = Task::all();
    $tasks = Task::get(); 
    ```

### モデル名
- **パスカルケース（PascalCase）**
  - `User`, `UserSubscription`など
- 紐づいているテーブル名の単数形と一致させる
  - `users`テーブルの場合は`User`でモデルを作成する。

### クラス名
- **パスカルケース（PascalCase）**
  - `UserController`, `SubscriptionService`
- サービスクラスを作成する場合はどのデータを扱うのかを明確にするために`{モデル名}Service`や`{モデル名}{処理名}Serviec`と命名する。どのデータに属するか曖昧な場合は`{処理名}Service`とする

### 定数
- **全大文字＋アンダースコア（UPPER_SNAKE_CASE）**
  - `MAX_QUANTITY`, `CHUNK_SIZE`など
  
### ファイル名
- クラスと一致する名前をつける
  - `UserService.php`（中身も `class UserService`）

## 構造

### タイムゾーン・地域
- 日本語のサービスである為、バリデーションメッセージなども日本語化を行う。
- 必ず`config/app.php`の`timezone`を`Asia/Tokyo`に、`locale`を`ja`に変更すること。

### インデントと空白
- インデントは **スペース4つ**
- コントロール構文（`if`, `foreach`, `switch` など）には必ず **中括弧 `{}` を付ける**
- 視認性向上のためブロックの前後には1行空ける

### 名前空間のインポート
- **同一名前空間から複数クラスをインポートする場合は必ず `{}` でグループ化すること**
    
    ```php
    // ✅ 推奨：グループ化
    use App\Models\{
        Task,
        User
    };
    
    use Carbon\{
        CarbonImmutable,
        CarbonPeriod
    };
    
    // ❌ 禁止：個別インポート（同一名前空間の場合）
    use App\Models\Task;
    use App\Models\User;
    ```
- **グループ化時の記述ルール**
  - 開始の `{` の後で改行すること
  - 各クラス名は4スペースでインデントすること
  - 最後のクラス名の後にはカンマを付けないこと
  - 終了の `}` は独立した行に記述すること
- **インポート順序**
  - `App\Enums\`, `App\Models\`, `App\Http\`の順で宣言すること
  - 同一グループ内ではアルファベット順で記述すること
  - それ以外の名前空間は順不同で記述すること
  - **一つ上の階層が同じ場合のみグループ化し、異なる階層は分離すること**
  - **インポート時は必ず改行とインデントを追加すること**
  - **バリデーションルールは必ず配列形式で改行とインデントを追加すること**
- 処理の変更などで不要になった名前空間のインポートは必ず削除すること
- **使用するクラスはBladeファイル以外では完全修飾クラス名(FQCN)を使用せず、必ず名前空間でインポートすること**
  ```php
  // ✅ 推奨：インポートを使用
  use App\Http\Controllers\HomeController;
  Route::get('/home', [HomeController::class, 'index']);
  
  // ❌ 禁止：FQCNの直接使用
  Route::get('/home', [App\Http\Controllers\HomeController::class, 'index']);
  ```

### NULLチェック
- 条件式の中で変数のみで判断せず、変数には`is_null()`を使用し、連想配列には`isset()`を使用する。boolean型のみ条件式に変数単体で使用していいものとする。
- **Requestオブジェクトの値チェックには`has()`ではなく`!is_null()`を使用すること**
  ```php
  // ✅ 推奨：!is_null()を使用
  if (!is_null($request->is_completed) && $request->is_completed) {
      // 処理
  }
  
  // ❌ 禁止：has()の使用
  if ($request->has('is_completed') && $request->is_completed) {
      // 処理
  }
  ```

### 条件式
- 必ず```===```で条件式を記述すること。
- HTTPリクエストでは文字列に変換されてしまう為、`(int)`などでキャストを行うこと。

### その他の記述ルール
- 文字列は変数展開を除き、シングルクォートで定義すること。
- 2つ以上のメソッドチェーンでは、1つ目のメソッド以外を改行した上でインデントを4スペース開け記述すること。
  ```
    User::query()
        ->where('status', UserStatus::ACTIVE)
        ->first();
  ```
- **不要なコメント（PHPDoc等）は削除すること。特に単純なメソッドには不要**
- **Laravel Breezeを使用せず、独自で認証を構築すること**
- **バリデーションメッセージは`lang/ja/validation.php`で管理し、`attributes()`メソッドで属性名を定義すること**
- **Controller.phpなどのLaravelデフォルトファイルは変更しないこと**
- 不要なファイルは必ず削除すること


### 可読性
- `if`, `foreach`などのネストは2段階までに抑える。
- `else`が必要ないように記述。
    ```php
    if (is_null($user)) {
        abort('404');
    }

    return to_route('home');
    ```
- クロージャーをラムダ式で記述せず、`function () use () {}`で記述する。
- 連想配列では、KeyValueごとに改行を行う。また連想配列の中に連想配列が入る場合はインデントを設ける。

### クラス設計
- メソッド、フィールド変数は必要がない限り`private`で実装すること。
- 仮引数が2個以上になった場合は改行を行うこと。
    
    ```php
    public function store(
    	Request $request,
    	User $user
    ): RedirectResponse
    {
    
    }
    ```
- 戻り値、仮引数、フィールド変数は型宣言を行うこと。その際の型も完全修飾クラス名(FQCN)を使用せず、名前空間でインポートすること。
- 不完全なインスタンスの生成を避けるために`setter`ではなくコンストラクタ内でフィールド変数を初期化できるように定義する。

### プロジェクト進行
- 現在のタスクとは関係のない機能の実装はしないこと。

### 開発環境
- DDEVを使用すること。その為、```php```コマンドは```ddev```に切り替えて実行すること。

## Laravel機能の使用制限

### 認証関連の記述ルール
- **`Auth::`ファサードではなく`auth()`ヘルパー関数を使用すること**
- **ガードを必ず明示的に指定すること**
  ```blade
  // ❌ 禁止：Authファサードの使用
  {{ Auth::user()->name }}
  {{ Auth::check() }}
  {{ Auth::id() }}
  
  // ✅ 推奨：auth()ヘルパー＋ガード指定
  {{ auth()->guard('web')->user()->name }}
  {{ auth()->guard('web')->check() }}
  {{ auth()->guard('web')->id() }}
  ```

### 禁止するLaravel機能・パッケージ
- **Laravel/UI の使用禁止**
  - `composer require laravel/ui` の使用禁止
  - `php artisan ui bootstrap` などのコマンド使用禁止
- **認証エコシステムの使用禁止**
  - `Auth::routes()` の使用禁止
  - Laravel Breezeの使用禁止
  - Laravel Jetstream の使用禁止
  - Laravel Fortify の使用禁止
- **Viteの使用禁止**
  - `@vite()` ディレクティブの使用禁止
  - `vite.config.js` の使用禁止
  - npm/yarn でのフロントエンドビルド禁止

### 推奨する独自実装
- **認証機能は独自実装すること**
  ```php
  // ✅ 推奨：独自認証ルート定義
  Route::get('/login', [UserLoginHistoryController::class, 'create'])->name('login');
  Route::delete('/logout', [UserLoginHistoryController::class, 'destroy'])->name('logout');
  
  // ❌ 禁止：Laravel/UIの認証ルート
  Auth::routes();
  ```
- **フロントエンドは独自実装すること**
  ```blade
  // ✅ 推奨：CDNからの直接読み込み
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
  
  // ❌ 禁止：Viteの使用
  @vite(['resources/sass/app.scss', 'resources/js/app.js'])
  ```
- **独自実装の利点**
  - プロジェクト要件に最適化された実装
  - 不要な機能が含まれない軽量な実装
  - カスタマイズの自由度が高い
  - 学習効果の向上

## Enumクラスの実装パターン

### 基本設計
- 定数値は`case`で定義し、`UPPER_SNAKE_CASE`で命名する
- 必ず`getDescription()`メソッドを実装し、日本語説明を提供すること
- ファイル名は`{モデル名}{カラム名}.php`形式で命名すること

### 実装例
```php
<?php declare(strict_types=1);

namespace App\Enums;

enum UserPointType: string
{
    case NORMAL = 'normal';
    case ADMIN  = 'admin';

    public function description(): string
    {
        return match($this) {
            self::NORMAL => '通常ポイント',
            self::ADMIN  => '付与ポイント',
        };
    }
}
```

## ヘルパー関数の実装パターン

### 基本ルール
- グローバルヘルパー関数は`app/helpers.php`に定義すること
- 関数名は`camelCase`で記述すること
- 関数の存在チェックを`function_exists()`で実施すること
- 戻り値の型を明確に定義すること

### 実装例
```php
<?php declare(strict_types=1);

if (!function_exists('getIp')) {
    function getIp(): string
    {
        $headers = [
            'HTTP_CF_CONNECTING_IP',
            'HTTP_X_FORWARDED_FOR',
            'HTTP_X_REAL_IP',
            'REMOTE_ADDR'
        ];

        foreach ($headers as $header) {
            if (!empty($_SERVER[$header])) {
                $ip = $_SERVER[$header];
                if (strpos($ip, ',') !== false) {
                    $ip = explode(',', $ip)[0];
                }
                return trim($ip);
            }
        }
        
        return '0.0.0.0';
    }
}
```

## 通知システムの実装パターン

### Toastrヘルパークラス
- 通知メッセージは専用のヘルパークラスで管理すること
- セッションを使用してメッセージを格納すること
- 種類別（success, info, warning, error）にメソッドを分離すること

### 実装例
```php
<?php declare(strict_types=1);

namespace App\Helpers;

class Toastr
{
    public static function success(string $message): void
    {
        session()->flash('toastr_success', $message);
    }

    public static function info(string $message): void
    {
        session()->flash('toastr_info', $message);
    }

    public static function warning(string $message): void
    {
        session()->flash('toastr_warning', $message);
    }

    public static function error(string $message): void
    {
        session()->flash('toastr_error', $message);
    }
}
```

## FormRequestの実装パターン

### バリデーション前の前処理
- `prepareForValidation()`でデータの整形・統合を実施すること
- 複数フィールドからの値の結合処理を行うこと
- 日付・時刻の処理はCarbonを使用すること

### 実装例
```php
protected function prepareForValidation(): void
{
    if ($this->filled(['year', 'month', 'day']) && checkdate($this->month, $this->day, $this->year)) {
        $birthday = Carbon::createFromDate($this->year, $this->month, $this->day);
        $this->merge([
            'birthday' => $birthday,
        ]);
    }

    if ($this->filled(['first_phone_number', 'middle_phone_number', 'last_phone_number'])) {
        $this->merge([
            'phone_number' => $this->first_phone_number . $this->middle_phone_number . $this->last_phone_number
        ]);
    }
}
```

## 定数の管理パターン

### クラス定数での管理
- 定数は関連するクラス内で`const`で定義すること
- 定数名は`UPPER_SNAKE_CASE`で命名すること
- 時間やサイズなどの設定値は定数として管理すること

### 実装例
```php
class UserService
{
    const CACHE_LIFETIME = 60 * 60 * 24; // 24時間
    const MAX_LOGIN_ATTEMPTS = 5;
    const PASSWORD_RESET_EXPIRE = 30; // 30分
    
    public function processUser(): void
    {
        Cache::remember('users', self::CACHE_LIFETIME, function () {
            return User::all();
        });
    }
}
```

## 例外処理の実装パターン

### トランザクション処理
- データベース操作を伴う処理は`DB::beginTransaction()`で囲むこと
- 例外発生時のロールバック処理を適切に実装すること
- エラーログは適切なレベルで出力すること

### 実装例
```php
public function createUser(array $data): User
{
    DB::beginTransaction();
    try {
        $user = User::create($data);    
        $user->profile()->create($data['profile']);
        
        DB::commit();
        return $user;
    } catch (Exception $e) {
        Log::error('ユーザー作成エラー', [
            'error' => $e->getMessage(),
            'data' => $data
        ]);
        DB::rollback();
        throw $e;
    }
}
```