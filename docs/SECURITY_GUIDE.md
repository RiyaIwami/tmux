# セキュリティ設計ガイド

このドキュメントは、Laravelプロジェクトにおけるセキュリティ実装の指針を定めるものです。Claude Codeによるレビュー時にも本基準を準拠基準としてください。

---

## 認証

### Laravel標準認証の利用
- 認証を実装する場合は `Auth` 及び `Guard` を使用する。
    * Authを使用する際は、`auth()`ヘルパー関数で呼び出す。
- ガードによるログインの種別分けを必ず行う。一般ユーザーのproviderは`users`を使用すること。
- ログインや認証チェックを行う場合は必ず`guard()`でプロバイダーを指定すること。
- 認証トークンの生成と検証を実装する場合は、以下のパターンを使用すること：
  ```php
  // トークン生成（一意性確保）
  $token = bin2hex(random_bytes(32));
  while (UserAuthentication::where('token', $token)->exists()) {
      $token = bin2hex(random_bytes(32));
  }
  
  // トークン検証
  $user_authentication = UserAuthentication::query()
      ->where('token', $request->authentication_token)
      ->where('type', UserAuthenticationType::PASSWORD_RESET)
      ->where('expired_at', '>', now())
      ->where('is_completed', false)
      ->first();
  ```

## 認可


### 認証コントローラーのルール
- **Laravel Breezeは使用せず、独自で認証を構築すること**
- **バリデーションはFormRequestで行うこと**
- **バリデーションルールは必ず配列形式で改行とインデントを追加すること**
  ```php
  // ✅ 推奨：独自認証コントローラー
  class UserLoginHistoryController extends Controller
  {
        public function create(Request $request): View
        {
            return view('user_login_histories.create');
        }

        public function store(Request $request): RedirectResponse
        {
            if (Auth::guard('web')->attempt($request->only('email', 'password'))) {
                $request->session()->regenerate();
              
                UserLoginHistory::create([
                    'user_id' => auth()->guard('web')->id(),
                    'ip_address' => getIp(),
                    'user_agent' => $request->userAgent(),
                    'login_at' => now(),
                ]);
            }

            return to_route('tasks.index');
        }

        public function destroy(Request $request): RedirectResponse
        {
            auth()->guard('web')->logout();

            return to_route('user_login_histories.create');
        }
  }
  
  // ❌ 禁止：Laravel Breezeの使用
  // use Laravel\Breeze\Http\Controllers\Auth\AuthenticatedSessionController;
  ```

### ポリシー（Policy）クラスの利用
- モデルに対する権限制御はポリシーで集中管理
    * ポリシーは`ddev artisan make:policy {Model名}Policy --model={Model名}`で作成
- 呼び出しは各コントローラー内で`$this->authorize('update', $user);`などとして必要なアクションにのみ記述すること。
- **ログイン認証後の個人情報を扱うアクションかつ、ルートモデルバインディングを行なっているルート**では特に気をつけること。
- ポリシーの基本的な実装パターン：
  ```php
  // 基本的な所有権チェック
  public function view(User $user, PaymentHistory $payment_history): bool
  {
      return $user->id === $payment_history->user_id;
  }
  
  // 業務固有の認可ロジック
  public function canLottery(User $user, UserSubscription $user_subscription): Response|bool
  {
      if (!$user_subscription->is_enabled) {
          return Response::deny('サブスクリプションが無効です。');
      }
      
      return $user->id === $user_subscription->user_id;
  }
  ```

## ミドルウェアによるアクセス制御

### 認証チェック
- ログイン状態を確認する認証ミドルウェアなどを作成し、routeファイルで制御を行うこと。
- ガード別の認証ミドルウェアを実装すること：
  ```php
  // 一般ユーザー用認証ミドルウェア
  if (!auth()->guard('users')->check()) {
      return to_route('user_login_histories.create');
  }
  
  // 管理者用認証ミドルウェア
  if (!auth()->guard('admins')->check()) {
      return to_route('admin.admin_login_histories.create');
  }
  ```

### HTTPS接続の強制
- 本番環境では必ずHTTPS接続を強制するミドルウェアを実装すること：
  ```php
  public function handle(Request $request, Closure $next)
  {
      if (!$request->secure() && app()->environment('production')) {
          return redirect()->secure($request->getRequestUri());
      }
      
      return $next($request);
  }
  ```

### CSRF対策
- 決済関連のAPIエンドポイントなど、外部からのコールバックを受け取るルートは適切に除外すること：
  ```php
  protected $except = [
      'payment/each/complete/*',
      'payment/each/error/*',
      'payment/each/cancel/*',
  ];
  ```

### 業務固有のアクセス制御
- サブスクリプションの有効性チェックなど、業務固有の条件は専用ミドルウェアで実装すること：
  ```php
  public function handle(Request $request, Closure $next)
  {
      $user = auth()->guard('users')->user();
      
      if (!$user->userSubscriptions()->where('is_enabled', true)->exists()) {
          return to_route('subscription_payment_courses.index');
      }
      
      return $next($request);
  }
  ```

## パスワード・個人情報のハッシュ化
- パスワード保存時は必ずハッシュ化。テーブルに保存する際もハッシュ化したパスワードを保存するように。
- ハッシュの検証、ハッシュ化には`Hash`ファサードを使用するように。
- 実装例：
  ```php
  // パスワードのハッシュ化
  $user = User::create([
      'password' => Hash::make($request->password),
      // その他のフィールド
  ]);
  
  // パスワードの検証
  if (!Hash::check($request->current_password, $user->password)) {
    // 処理
  }
  ```

## 暗号化処理
- 機密情報の暗号化には`Crypt`ファサードを使用すること：
  ```php
  // 暗号化
  $encrypted = Crypt::encryptString($user->id);
  
  // 復号化
  $decrypted = Crypt::decryptString($encrypted);
  ```
- Cookie暗号化の除外設定：
  ```php
  protected $except = [
      'stripe_session_id',
      'amazon_pay_session_id',
  ];
  ```

## 入力の検証とバリデーション
- すべての入力に対してサーバーサイドのバリデーションを必ず実施
- FormRequestクラスで入力チェックを一元化
    * 命名は`{Model名}/{Model名}{アクション名}Request`で定義すること。
    * 漏れの内容にバリデーションを行うこと。文字数、データ型、最小値など網羅すること。
- バリデーションメッセージには日本語を設定すること。**またlangディレクトリに日本語のバリデーションメッセージファイルを作成し、それを使用すること。基本的にmessages()はオーバーライドしないこと。**
- 実装例：
  ```php
  public function rules(): array
  {
      return [
          'email' => [
              'required',
              'email:rfc,dns',
              'unique:users,email',
              'max:255'
          ],
          'password' => [
              'required',
              'string',
              'min:8',
              'max:255',
              'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/'
          ],
          'nick_name' => [
              'required',
              'string',
              'max:50'
          ],
      ];
  }
  
  public function attributes(): array
  {
      return [
          'email' => 'メールアドレス',
          'password' => 'パスワード',
          'nick_name' => 'ニックネーム',
      ];
  }
  ```

## IPアドレスの取得
- セキュリティログやアクセス制御でIPアドレスを取得する場合は、プロキシ対応の実装をすること：
  ```php
  // app/helpers.php
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

## セッションとCookie
- HTTPS環境では SESSION_SECURE_COOKIE=trueを.envに指定
- Cookieに値を入れる場合はハッシュ化を行うように
- Sessionは複数インスタンスでも稼働するようにdatabaseで管理を行う。
- Sessionも暗号化するため、`config/session.php`内の`'encrypt'`は`true`にすること。
- セッション設定例：
  ```php
  // config/session.php
  return [
      'driver' => 'database',
      'encrypt' => true,
      'secure' => env('SESSION_SECURE_COOKIE', true),
      'http_only' => true,
      'same_site' => 'lax',
  ];
  ```

## ログ収集とセキュリティ監査
- セキュリティに関わる操作は必ずログを収集すること：
  ```php
  // ログイン試行のログ
  Log::channel('portal.portal_user_login_histories')->info('ログイン試行', [
      'email' => $request->email,
      'ip_address' => getIp(),
      'user_agent' => $request->userAgent(),
      'success' => $success,
  ]);
  
  // 管理者操作のログ
  Log::channel('admin.users')->info('ユーザー情報変更', [
      'admin_id' => auth()->guard('admins')->id(),
      'target_user_id' => $user->id,
      'action' => 'update_is_test',
      'ip_address' => getIp(),
  ]);
  ```