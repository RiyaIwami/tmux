# ルーティング設計ガイド

本ドキュメントは、プロジェクトにおけるルーティング命名・構成・責務の設計方針を定めます。Claude Codeを含むレビュー時の判断基準とします。

---

## 命名規則

### ルート名（name属性）
- **名前付きルートは必ずすべてに定義すること**
- 命名形式はドット記法（resource.action）とする
  - 例：`users.index`, `tasks.store`
- 基本的にアクション名と一致させて定義すること
- 2単語以上が連なるアクションの場合、スネーク記法で定義すること
  - `users.create_password_reset`など
- URIのprefixは複数形で行うこと。また操作するデータをプレフィックスに使用すること。例として`User`モデルを扱う`UserController`の場合、`users`とprefixを宣言。

## HTTPメソッドとアクションの対応

URLやコントローラーアクションはRESTFULアーキテクチャのリソースの概念に合わせて作成して欲しい。可能な限りBlade名も**この原則から離れないように**。

|HTTPメソッド|URI|アクション名|ルート名|内容|Blade名|
|--|--|--|--|--|--|
|GET|`/`|`index`|`{モデル名}.index`|一覧表示|`index.blade.php`|
|GET|`/create`|`create`|`{モデル名}.create`|作成画面表示|`create.blade.php`|
|POST|`/`|`store`|`{モデル名}.store`|登録処理||
|GET|`/{id}`|`show`|`{モデル名}.show`|詳細表示|`show.blade.php`|
|GET|`/edit/{id}}`|`edit`|`{モデル名}.edit`|編集画面表示|`edit.blade.php`|
|PATCH|`edit/{id}`|`update`|`{モデル名}.update`|更新処理||
|DELETE|`/{id}`|`destroy`|`{モデル名}.destroy`|削除||
- ルートの命名・アクションは**RESTful** を厳守し、リソースベースで定義すること
- ホームなどのどれにも属さないアクションは`home`等と定義してよい。


## ルーティング構成（Routing Structure）

- **柔軟性、可読性を持たせるために、`Route::resource`は使用せず、明示的にルートを定義すること**
  * `Route::resource`を使用するとルートが何個存在するのか分からなくなる為、明示的にルートを定義する
- **Route::controllerを使用してコントローラーでグループ化し、可読性を向上させること**
- **認証が必要なルートは必ずroutes/web.phpでmiddleware('auth')をグループ化すること**
- **コントローラーのコンストラクタでmiddlewareを設定してはいけない**
- Middrewareの使用はルーティングファイル内で行い、`Route::middleware()`メソッドで定義した後、`group()`メソッドでグループ化すること。
- 同一Controller内のルートは`Route::controller()`メソッドで定義し、`group()`メソッドでグループ化すること。またルート名も`as()`を使用し、グループ化すること。URIも必要ではない場合を除いて`prefix()`でグループ化すること
- 単体のControllerのルートは配列で定義する。ただし、**ルートが新たに追加され、同一コントローラーのアクションが2つ以上かつmiddlewareによる区別も不要な場合は必ずグループ化を行う。**
- **必要に応じてModelバインディングを行うこと**

### 推奨ルート実装例
```php
// ✅ 推奨：Route::controllerでグループ化
Route::middleware('auth')->group(function () {
    Route::controller(TaskController::class)->prefix('tasks')->as('tasks.')->group(function () {
        Route::get('/', 'index')->name('index');
        Route::get('/create', 'create')->name('create');
        Route::post('/', 'store')->name('store');
        Route::get('/{task}', 'show')->name('show');
        Route::get('/{task}/edit', 'edit')->name('edit');
        Route::patch('/{task}', 'update')->name('update');
        Route::delete('/{task}', 'destroy')->name('destroy');
    });
});

// ❌ 禁止：Route::resourceの使用
Route::middleware('auth')->group(function () {
    Route::resource('tasks', TaskController::class); // これは禁止
});

// ❌ 禁止：コントローラーのコンストラクタでmiddleware設定
class TaskController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth'); // これは禁止
    }
}
```

### 名前空間インポートの実装例
```php
// ✅ 推奨：FQCNを避けてインポートを使用
use App\Http\Controllers\HomeController;
Route::get('/home', [HomeController::class, 'index'])->name('home');

// ❌ 禁止：FQCNの直接使用
Route::get('/home', [App\Http\Controllers\HomeController::class, 'index'])->name('home');
```

## マルチドメインシステムの実装
- 管理者用のルートは別ドメインで分離し、一般ユーザー用のルートと明確に分ける。
- `RouteServiceProvider`で以下のように設定すること：
  ```php
  // 一般ユーザー用
  Route::middleware('web')
      ->domain(config('app.url'))
      ->group(base_path('routes/web.php'));
  
  // 管理者用
  Route::middleware('admin')
      ->domain(config('app.admin_domain'))
      ->group(base_path('routes/admin.php'));
  ```
- 管理者用ルートは必ず`admin.`プレフィックスを付けること。
  ```php
  Route::as('admin.')->group(function () {
      // 管理者用のルート定義
  });
  ```

## ルートファイルの分離
- `routes/web.php`：一般ユーザー向けの機能
- `routes/admin.php`：管理者向けの機能
- `routes/api.php`：API用のルート（必要に応じて）
- 各ファイルは責務を明確に分けて管理すること。

## 実装例

### 一般ユーザー用ルート（web.php）
```php
Route::middleware(['pending_redirect'])->group(function () {
    Route::get('/', [HomeController::class, 'index'])->name('home');
    
    Route::controller(UserController::class)->as('users.')->prefix('user')->group(function () {
        Route::get('mypage', 'myPage')->name('mypage');
        Route::get('/create/{authentication_token}', 'create')->name('create');
        Route::post('/', 'store')->name('store');
    });
});

Route::middleware(['verify.login'])->group(function () {
    Route::controller(UserController::class)->as('users.')->group(function () {
        Route::get('account', 'account')->name('account');
        Route::get('edit', 'edit')->name('edit');
        Route::patch('edit-password', 'editPassword')->name('edit_password');
    });
});
```

### 管理者用ルート（admin.php）
```php
Route::as('admin.')->group(function () {
    Route::controller(AdminLoginHistoryController::class)->as('admin_login_histories.')->group(function () {
        Route::get('/create', 'create')->name('create');
        Route::post('/', 'store')->name('store');
    });
    
    Route::middleware('verify.admin_login')->group(function () {
        Route::controller(UserController::class)->prefix('users')->as('users.')->group(function () {
            Route::get('/', 'index')->name('index');
            Route::get('/{user}', 'show')->name('show');
            Route::delete('/{user}', 'destroy')->name('destroy');
        });
    });
});
```

## 署名付きURLの実装
- 時間制限付きのアクセスが必要な場合は署名付きURLを使用すること。
  ```php
  // ルート定義
  Route::get('/preview/{lottery_title}', 'preview')
      ->name('preview')
      ->middleware('signed');
  
  // 署名付きURL生成
  $url = URL::temporarySignedRoute(
      'lottery_titles.preview',
      now()->addMinutes(30),
      ['lottery_title' => $lottery_title]
  );
  ```
- 署名付きURLは必ず`signed`ミドルウェアを適用すること。

## カスタムミドルウェアの活用
- 特定の条件でのみアクセスを許可する場合は、カスタムミドルウェアを作成してルートに適用すること。
  ```php
  // カスタムミドルウェアの適用例
  Route::middleware('lottery_title.update_setting_status')->group(function () {
      Route::controller(LotteryTierController::class)->prefix('lottery-tiers')->as('lottery_tiers.')->group(function () {
          Route::get('/{lottery_title}/create', 'create')->name('create');
          Route::post('/{lottery_title}', 'store')->name('store');
      });
  });
  ```

## URIパターンの統一
- 編集系のURIは統一したパターンで定義すること。
  ```php
  // 推奨パターン
  Route::get('/{model}/edit', 'edit')->name('edit');
  Route::patch('/{model}/edit', 'update')->name('update');
  
  // 複数単語の場合はケバブケース
  Route::prefix('user-addresses')->group(function () {
      Route::get('/edit', 'edit')->name('edit');
      Route::patch('/edit/{user_address}', 'update')->name('update');
  });
  ```

## 決済系ルートの特別な実装
- 外部決済サービスからのコールバックルートは適切に定義すること。
  ```php
  // 決済完了・エラー・キャンセルの3パターンを必ず定義
  Route::controller(EachPaymentCourseController::class)->prefix('payment/each')->as('each_payment_courses.')->group(function () {
      Route::post('/complete/{payment_history}/{account_id}', 'complete')->name('complete');
      Route::post('/error/{payment_history}/{account_id}', 'errorUrl')->name('error');
      Route::post('/cancel/{payment_history}/{account_id}', 'cancel')->name('cancel');
  });
  ```

## ルートパス（'/'）の設定ルール
- **ルートパス（'/'）には適切なリダイレクト処理を必ず設定すること**
- **アクセス不可状態を避けるため、認証状態に応じたリダイレクトを実装すること**
  ```php
  // ✅ 推奨：認証状態に応じたリダイレクト
  Route::get('/', function () {
      return auth()->guard('web')->check() 
          ? redirect()->route('tasks.index')
          : redirect()->route('login');
  })->name('home');
  
  // ❌ 禁止：アクセス不可状態
  // Route::get('/', function () {
  //     return abort(404);
  // });
  ```
- **リダイレクト先は以下の原則に従うこと**
  - **認証済みユーザー**: メイン機能（一覧画面等）へリダイレクト
  - **未認証ユーザー**: ログイン画面へリダイレクト
  - **管理者系**: 管理画面のダッシュボードへリダイレクト
- **ルートパスにも必ず名前付きルート（`name()`）を設定すること**
  ```php
  // ✅ 推奨：名前付きルートの設定
  Route::get('/', function () {
    return to_route('user_login_histories.create');
  })->name('home');
  ```

## その他
- クロージャーは原則禁止する。
- ルートの可読性を保つため、長すぎるURIは避けること。
- 必要に応じて適切なHTTPメソッドを使用すること（GET, POST, PATCH, DELETE）。