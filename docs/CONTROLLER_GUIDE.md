# コントローラー設計ガイド

このドキュメントは、コントローラーに関する記述ルールと設計方針を示します。

---

## 基本ルール
- コントローラー1つにつき、対象リソース（モデル）は1つ
    - 例：`UserController` → ユーザー関連処理のみ
- 管理用・API用など、責務が異なる場合はコントローラーを分ける
    - 例：`Admin/UserController`, `Api/UserController`
- 各アクションには原則1つの責務を持たせる
- **全てのアクションメソッドには第一引数としてRequestパラメータを必ず追加すること**
  ```php
  // ✅ 推奨：全アクションにRequestパラメータを追加
  public function index(Request $request): View { /* 処理 */ }
  public function create(Request $request): View { /* 処理 */ }
  public function show(
        Request $request,
        Task $task
  ): View 
  {
    /* 処理 */ 
  }
  public function edit(
    Request $request,
    Task $task
  ): View 
  { 
    /* 処理 */
  }
  public function destroy(
    Request $request,
    Task $task
  ): RedirectResponse
  {
    /* 処理 */
  }
  
  // ❌ 禁止：Requestパラメータの省略
  public function create(): View { /* 処理 */ }
  public function show(Task $task): View { /* 処理 */ }
  public function destroy(
    Request $request,
    Task $task
  ): RedirectResponse {
    /* 処理 */
  }
  ```

## インポート文のフォーマット
- **use文でのグループ化インポートは必ず改行とインデントを使用すること**
  ```php
  // ✅ 推奨：改行とインデントを使用
  use Illuminate\Http\{
      RedirectResponse,
      Request
  };
  
  // ❌ 禁止：1行でのグループ化
  use Illuminate\Http\{RedirectResponse, Request};
  ```
- **インポート文の順序はEnums、Models、Requests、その他の順で記述すること**
  ```php
  // ✅ 推奨：正しい順序
  use App\Enums\TaskStatus;
  use App\Models\Task;
  use App\Http\Requests\Task{
      StoreRequest,
      UpdateRequest
  };
  use Illuminate\Http\{
      RedirectResponse,
      Request
  };
  
  // ❌ 禁止：順序が不適切
  use Illuminate\Http\{RedirectResponse, Request};
  use App\Models\Task;
  use App\Http\Requests\Task\StoreRequest;
  ```

## コントローラーの責務
- **モデル操作、ビジネス処理、ビュー返却** までをまとめて記述してもOK。ただし、処理が複雑な場合は **Serviceクラス** に切り出す。

## アクションの命名
### RESTfulを基本とする
|アクション名|説明|HTTPメソッド|
|--|--|--|
|index|一覧|GET|
|show|詳細|GET|
|create|作成フォーム|GET|
|store|登録|POST|
|edit|編集フォーム|GET|
|update|更新|PATCH|
|destroy|削除|DELETE|
### カスタムアクション
- RESTfulではバッティングする場合などは上記のアクション名の後に名詞などで定義を行うこと。`createPasswordReset`など。

## モデルの取得方法・ルール
- ルートモデルバインディングを積極的に使用すること。
- リクエストに`id`が含まれている場合は、`Model::find();`で取得すること。その他では`Model::where()->first();`で取得すること。
- **N+1を回避するために**、取得後のモデルに関しては`load()`メソッド、取得前のクエリでは`with()`メソッドを使用し、**Eager Logingを徹底する。**
- **モデル操作はEloquentを使用**し、クエリビルダ(DBファサード)は基本的に使用しない。
- よく使用される条件は独自スコープとして定義し、積極的に使用すること。
  ```php
  // モデルに独自スコープを定義
  public function scopeEnabled($query)
  {
      return $query->where('is_enabled', true);
  }
  
  // コントローラーで使用
  $user = User::query()
      ->where('email', $email)
      ->enabled()
      ->first();
  ```

## リクエストの扱い
- 各パラメーターは`$request->name`などで直接プロパティとして取得すること。
- **バリデーションは必ずFormRequestに責務を分割**すること。


## 処理に関してのルール
- データ追加時は`create()`メソッドを使用すること。`insert()`メソッドを使用しない。
- データ更新時は`update()`メソッド内で配列を使用し、更新を行うこと。プロパティに代入して`save()`する方式は取らないように。
- **配列変数を作成せず、直接update()メソッドに配列を渡すこと**
- **例外的に**、boolean値やステータスの単純な更新など、1つのフィールドのみの更新時は直接代入＋save()パターンを使用してもよい。
  ```php
  // ✅ 推奨：直接update()メソッドに配列を渡す
  if ($request->has('is_completed')) {
      $task->update([
          'title' => $request->title,
          'description' => $request->description,
          'is_completed' => $request->is_completed,
          'completed_at' => $request->is_completed ? now() : null,
      ]);
  } else {
      $task->update([
          'title' => $request->title,
          'description' => $request->description,
      ]);
  }
  
  // ❌ 非推奨：配列変数を作成してからupdate()
  $updateData = [
      'title' => $request->title,
      'description' => $request->description,
  ];
  if ($request->has('is_completed')) {
      $updateData['is_completed'] = $request->is_completed;
  }
  $task->update($updateData);
  
  // 単一フィールドの更新（例外的に許可）
  $user->is_enabled = false;
  $user->save();
  ```

## ビューの返却方法
- **compact関数の使用を禁止すること**
  ```php
  // ✅ 推奨：配列形式での変数渡し
  return view('tasks.index', [
      'tasks' => $tasks
  ]);
  
  // ❌ 禁止：compact関数の使用
  return view('tasks.index', compact('tasks'));
  ```
- **システムカラム（created_at, updated_at）の使用を禁止すること**
  ```php
  // ✅ 推奨：アプリケーションカラムの使用
  $tasks = Task::orderBy('registered_at', 'desc')->paginate(20);
  
  // ❌ 禁止：システムカラムの使用
  $tasks = Task::orderBy('created_at', 'desc')->paginate(20);
  ```

## 検索・フィルタリング機能の実装
- 検索機能では`when`句を使用した条件分岐を使用すること。
  ```php
  $users = User::query()
      ->when(!is_null($request->name), function ($query) use ($request) {
          return $query->where('name', 'LIKE', "%{$request->name}%");
      })
      ->when(!is_null($request->is_enabled), function ($query) use ($request) {
          return $query->where('is_enabled', $request->is_enabled);
      })
      ->paginate(50);
  ```
- リレーション先での検索は`whereHas`を使用すること。
- ソート機能は`sortByRequest`スコープをモデルに定義し、使用すること。
- ページネーション数は管理画面では50、一般画面では適切な数値を設定すること。

## 集計・統計データの取得
- 関連データの件数取得は`withCount`メソッドを使用すること。
- 複雑な集計は`addSelect`と`selectRaw`を組み合わせて使用すること。
  ```php
  $clients = Client::query()
      ->withCount('lotteryTitles')
      ->addSelect([
          'available_lottery_titles_count' => function ($query) {
              return $query->selectRaw('COUNT(*)')
                  ->from('lottery_titles')
                  ->whereColumn('lottery_titles.client_id', 'clients.id')
                  ->where('available_at', '<=', now())
                  ->where('unavailable_at', '>=', now());
          }
      ])
      ->paginate(40);
  ```

## レスポンスの扱い
- **以下のルールに必ず従うこと。**
  - 画面返却：`return view();`を使用すること
   * また、Viewへは`compact`関数ではなく、連想配列を使用すること。
  - リダイレクト：`return to_route();`を使用すること
  - APIレスポンス：`return response()->json(...)`を使用すること

## フラッシュメッセージ・セッション管理
- フラッシュメッセージは`Toastr`ヘルパーを使用すること。
  ```php
  use App\Helpers\Toastr;
  
  Toastr::success('登録が完了しました。');
  Toastr::error('エラーが発生しました。');
  Toastr::info('情報を更新しました。');
  Toastr::warning('注意してください。');
  ```
- 完了画面への遷移では`session()->flash()`を使用し、完了画面ではセッションの確認を行うこと。
  ```php
  // 処理後
  return to_route('users.complete')
      ->with(['is_completed' => true]);
  
  // 完了画面
  public function complete(Request $request)
  {
      if (session('is_completed')) {
          return view('users.complete');
      }
      
      return to_route('home');
  }
  ```

## トランザクション管理
- 複数テーブルへの操作やメール送信を含む処理では必ずトランザクションを使用すること。
  ```php
  use Illuminate\Support\Facades\DB;
  
  DB::beginTransaction();
  try {
      // 複数の処理
      $user = User::create($userData);
      UserAddress::create($addressData);
      Mail::to($user->email)->send(new UserRegisterMail($user));
      
      DB::commit();
  } catch (\Exception $e) {
      DB::rollBack();
      // エラーハンドリング
  }
  ```
- 中間テーブルの操作では、直接モデルを操作するのではなく、`update()`メソッドを使用すること。
  ```php
  // 中間テーブルの更新
  SocialAccount::query()
      ->where('id', session()->pull('social_account_id'))
      ->update([
          'user_id' => $user->id
      ]);
  ```
- 条件に合致しないデータや無効なリクエストに対しては`abort()`関数を使用すること。
  ```php
  // データが存在しない場合
  if (is_null($user_authentication)) {
      abort(404);
  }
  
  // アクセス権限がない場合
  if ($user->userSubscriptions->where('is_enabled', true)->isNotEmpty()) {
      abort(403);
  }
  
  // サーバーエラーの場合
  if ($processingFailed) {
      abort(500);
  }
  ```

## 認証・認可の実装
- **認証が必要なルートは必ずroutes/web.phpでmiddleware('auth')をグループ化すること**
  ```php
  Route::middleware('auth')->group(function () {
      Route::resource('tasks', TaskController::class);
  });
  ```
- **コントローラーのコンストラクタでmiddlewareを設定してはいけない**
- **認可処理は必ずPolicyを使用すること。手動での認証チェックは禁止**
  ```php
  // ✅ 推奨：Policyを使用
  $this->authorize('view', $task);
  
  // ❌ 禁止：手動での認証チェック
  if ($task->user_id !== auth()->id()) {
      abort(403);
  }
  ```
- **Enumを使用してハードコーディングを避けること**
  ```php
  // ✅ 推奨：Enumを使用
  if ($request->status === TaskStatus::COMPLETED) {
      return $query->completed();
  }
  
  // ❌ 禁止：ハードコーディング
  if ($request->status === 'completed') {
      return $query->completed();
  }
  ```
- 認証チェックは`auth()->guard('guard_name')`を使用してガードを明示的に指定すること。
  ```php
  // 認証チェック
  if (auth()->guard('users')->check()) {
      $user = auth()->guard('users')->user();
  }
  
  // ログイン処理
  auth()->guard('users')->login($user);
  
  // ログアウト処理
  auth()->guard('users')->logout();
  ```
- **認証が必要なルートでは、`auth()->user()`を使わずAuthenticatable型で受け取ることを推奨する**
  ```php
  use Illuminate\Contracts\Auth\Authenticatable;
  
  // ✅ 推奨：Authenticatable型で受け取り
  public function index(
      Request $request,
      Authenticatable $user
  ): View {
      $tasks = $user->tasks()->get();
  }
  
  // ❌ 非推奨：auth()->user()の多用
  public function index(Request $request): View {
      $tasks = auth()->user()->tasks()->get();
  }
  ```
- `auth()->user()`を使用する場合は、明示的にガードを指定すること
  ```php
  // ✅ ガードを明示
  $user = auth()->guard('web')->user();
  
  // ❌ デフォルトガードに依存
  $user = auth()->user();
  ```
- 署名付きURLが必要な場合は`URL::temporarySignedRoute`を使用すること。
  ```php
  use Illuminate\Support\Facades\URL;
  
  return redirect()->away(
      URL::temporarySignedRoute(
          'users.admin_login',
          now()->addMinute(),
          ['encripted_user_id' => Crypt::encryptString($user->id)]
      )
  );
  ```

## 管理画面コントローラーの特別ルール
- 管理画面用コントローラーは`Admin`名前空間内に配置すること。
- 管理画面では検索・フィルタリング機能を標準実装すること。
- 管理画面専用のアクションには明確な命名を行うこと（`reJoin`, `updateIsTest`など）。
- 管理画面のページネーション数は50件で統一すること。
- 管理画面でのステータス変更などの処理後は、必ず`Toastr`でメッセージを表示すること。
  ```php
  use App\Helpers\Toastr;
  
  public function destroy(UserDestroyRequest $request, User $user)
  {
      $user->is_enabled = false;
      $user->save();
      
      Toastr::error("会員{$user->account_id}を退会させました。");
      
      return to_route('admin.users.show', [
          'user' => $user,
          'type' => UserShowActionType::CHANGE_STATUS
      ]);
  }
  ```

## FatController回避指針
以下のような兆候がある場合は、Service クラスなどへの処理の切り出しを検討：
- 1アクションが100行を超える
- 複数の役割を持つ（例：DB操作＋外部API通信＋ファイル生成）
- 複数モデルが密結合している