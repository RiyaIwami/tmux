# ビュー設計ガイド

このドキュメントは、Laravelのビュー（Bladeテンプレート）に関する構造・記述ルールを定義します。

---

## 基本ルール
- **無駄なものは記述しない。現在必要ではないものは記述しないようにすること。**
- **不要なデフォルトファイルは削除すること**
  - `welcome.blade.php`などのLaravelデフォルトファイルで使用しないものは削除すること
  - 使用予定のないテンプレートファイルは作成・保持しないこと
- **blade内の不要な改行を削除すること**
  ```blade
  // ✅ 推奨：コンパクトな記述
  @extends('layouts.app')　// @extendsや@sectionディレクティブの前後には特別に改行を許可

  @section('title', 'タスク作成')
  
  @section('content')
    <div class="container">
      <div class="card"> //DOM同士の間には基本的に不要な改行を残さないように
  
  // ❌ 禁止：不要な改行
    <div class="container">

      <div class="card">
  ```
- **route()ヘルパーは必ず配列形式でパラメータを渡すこと。**パスパラメータが2つ以上の場合、配列で指定しないと動作しないため1つでも配列で統一させて下さい。
  ```blade
  // ✅ 推奨：配列形式でのパラメータ渡し
  <a href="{{ route('tasks.show', ['task' => $task]) }}">詳細</a>
  <a href="{{ route('tasks.edit', ['task' => $task]) }}">編集</a>
  <form action="{{ route('tasks.update', ['task' => $task]) }}" method="POST">
  
  // ❌ 禁止：オブジェクト直接渡し
  <a href="{{ route('tasks.show', $task) }}">詳細</a>
  <a href="{{ route('tasks.edit', $task) }}">編集</a>
  <form action="{{ route('tasks.update', $task) }}" method="POST">
  ```

## YAGNI原則の適用
- **現在使用していない機能の条件分岐は削除すること**
- **Laravelデフォルトテンプレートに含まれる不要な条件チェックは削除すること**
  ```blade
  // ❌ 禁止：使用していない機能の条件分岐
  @if (Route::has('password.request'))
      <a href="{{ route('password.request') }}">
          {{ __('Forgot Your Password?') }}
      </a>
  @endif
  
  // ✅ 推奨：必要な機能のみ記述
  <a href="{{ route('password.request') }}">
      {{ __('Forgot Your Password?') }}
  </a>
  ```
- **条件分岐削除の判断基準**
  - 機能を無効化する予定がない場合は条件チェック不要
  - プロジェクトで必ず使用する機能は直接記述する
  - 将来的に必要になる可能性が低い条件分岐は削除する
- **例外：設定によって機能が変わる場合のみ条件分岐を使用**
  ```blade
  // ✅ 許可：環境によって変わる機能
  @if (config('app.debug'))
      <div class="debug-info">デバッグ情報</div>
  @endif
  ```

## ファイル配置と命名
- 全ビューは `resources/views/` 以下に配置
- サブディレクトリでリソース単位にまとめる  
  ```plaintext
  resources/views/
  ├── layouts/
  │   └── app.blade.php
  ├── users/
  │   ├── index.blade.php
  │   └── show.blade.php
  └── tasks/
      ├── create.blade.php
      └── edit.blade.php
  ```
- **ファイル名はアクション名と一致させること**（index.blade.php, show.blade.php など）
- 基本的には`index`, `create`, `edit`, `show`のみを作成する。
- それでは表現出来ないもののみカスタムとして独自の名前を設定する。例:`complete.blade.php`、`confirm.blade.php`、`create_password_reset.blade.php`など

## レイアウトと継承
- ベースレイアウトとして共通部分（ヘッダー／フッター／ナビゲーション）は layouts/app.blade.php にまとめる。
- `@yield('content')`をlayouts/app.blade.phpに定義し、各画面は`@extends('layouts.app')`で継承し、`@section('content')`でコンテンツを埋めること。
- 管理画面とサービス画面でレイアウトを分離すること：
  * サービス画面：`layouts/app.blade.php`
  * 管理画面：`admin/layouts/app.blade.php`（AdminLTE使用）

## セクション定義の拡張
- 以下のセクションを標準的に定義すること：
  ```blade
  @section('title', 'ページタイトル')

  @section('page_class', 'page-specific-class')
  
  @section('head')
      <!-- 追加のCSS/JSファイル -->
  @endsection
  
  @section('js')
      <!-- ページ固有のJavaScript -->
  @endsection
  
  @section('seo')
      <!-- SEO関連のメタタグ -->
  @endsection
  ```

## SEO対策の実装
- SEO関連のメタタグは専用セクションで管理すること：
  ```blade
  @section('seo')
      <meta name="description" content="お問い合わせはこちらから。">
      <meta name="twitter:card" content="summary_large_image">
      <meta property="og:image" content="{{ asset('images/twitter-card.jpg') }}">
      <meta property="og:title" content="ほしくじ｜お問い合わせ">
      <meta property="og:url" content="{{ request()->url() }}">
      <link rel="canonical" href="{{ request()->url() }}">
  @endsection
  ```

## Bladeコンポーネント
- 作成コマンド
    ```shell
    ddev artisan make:component
    ```
- 単純かつ繰り返し使えるUIはBladeコンポーネントに切り分けること。但し、複雑なロジックの上で定義されている変数を使用する場合などはコンポーネント化は行わないように。
  * 例：`UserStatsuBagde`, `<x-user-status-badge :status="$user->status" />`など 

## Bladeコンポーネントの仮引数命名規則
- **Bladeコンポーネントの仮引数は2単語以上の場合、キャメルケースにしなければエラーになる。**
- **そのため、可能な限り1単語の仮引数名になるように心がけること。**
- 実装例：
  ```php
  // 推奨：1単語での命名
  public function __construct(
      private UserStatus $status,
      private User $user,
      private bool $bool
  )
  {
  }
  
  // 非推奨：スネークケースはエラーになる
  public function __construct(
      private UserStatus $user_status,  // エラー
      private User $target_user,        // エラー
      private bool $is_enabled         // エラー
  )
  {
  }
  ```
- 使用例：
  ```blade
  {{-- 1単語での使用（推奨） --}}
  <x-user-status-badge :status="$user->status" />
  <x-user-badge :user="$user" />
  ```

## ディレクティブ&ロジック
- 各ディレクティブと`()`の間に**は空白を設けないように**。
- `@section`, `@extends`には前後に改行を許可するが基本的に他では許可しない。以下のように`@if`ディレクティブなどでは不要な改行を残さずに連続させて記述する。インデントは設けること。
  ```blade
  @if(!is_null($task))
    <div>{{ $task->description }}</div>
  @endif
  ```
- 繰り返し処理では`@foreach()`ディレクティブを使用することを使用すること
  * Enumなどで繰り返し処理を行う場合、完全修飾クラス名（FQCN）でも可
- 条件式では`@if()`, `@else`ディレクティブを使用することで行うこと。条件が複数存在する場合やEnumでの条件分岐が可能な場合は`@switch()`, `@case()`, `@break`, `@default`ディレクティブを使用すること
  * Enumなどで条件分岐を行う場合、完全修飾クラス名（FQCN）でも可
- バリデーションエラーの確認は`@error()`ディレクティブを使用しエラーメッセージを表示すること。
- ログインしているかの条件などは`@auth`,`@guest`を使用すること。

## 認証関連の記述ルール
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
- **各ガードでの使用例**
  ```blade
  // ✅ 一般ユーザー（webガード）
  @if (auth()->guard('web')->check())
      <p>こんにちは、{{ auth()->guard('web')->user()->name }}さん</p>
  @endif
  
  // ✅ 管理者（adminガード）
  @if (auth()->guard('admin')->check())
      <p>管理者：{{ auth()->guard('admin')->user()->name }}</p>
  @endif
  ```
- **@authディレクティブでもガードを指定**
  ```blade
  // ✅ 推奨：ガード指定付きの@auth
  @auth('web')
      <li class="nav-item">
          <span>{{ auth()->guard('web')->user()->name }}</span>
      </li>
  @endauth
  
  @guest('web')
      <li class="nav-item">
          <a href="{{ route('login') }}">ログイン</a>
      </li>
  @endguest
  ```

## 条件式の記述ルール
- **値そのもので条件式を記述することは禁止。必ず明示的なboolean条件を使用すること**
- **Collectionの空判定は専用メソッドを使用すること**
  ```blade
  // ❌ 禁止：count()での空判定
  @if ($tasks->count() > 0)
      @foreach ($tasks as $task)
          <div>{{ $task->title }}</div>
      @endforeach
  @else
      <p>タスクがありません。</p>
  @endif
  
  @if ($tasks->count() === 0)
      <p>タスクがありません。</p>
  @endif
  
  // ✅ 推奨：isEmpty()とisNotEmpty()の使用
  @if ($tasks->isNotEmpty())
      @foreach ($tasks as $task)
          <div>{{ $task->title }}</div>
      @endforeach
  @else
      <p>タスクがありません。</p>
  @endif
  
  @if ($tasks->isEmpty())
      <p>タスクがありません。</p>
  @endif
  
  // ✅ 許可：実際の件数が必要な場合
  @if ($tasks->count() >= 10)
      <p>{{ $tasks->count() }}件のタスクがあります（10件以上）</p>
  @endif
  
  <p>合計: {{ $tasks->count() }}件</p>
  ```
- **Collectionメソッドの使用指針**
  - `->isEmpty()` - 空かどうかの判定
  - `->isNotEmpty()` - データが存在するかの判定
  - `->count()` - 実際の件数が必要な場合（件数表示、特定数以上の判定など）
  - `->count() > 0` や `->count() === 0` での空判定は禁止
  ```blade
  // ❌ 禁止：値そのもので条件判定
  @if (session('status'))
      <div class="alert alert-success">{{ session('status') }}</div>
  @endif
  
  @if (old('name'))
      value="{{ old('name') }}"
  @endif
  
  @if ($user->name)
      <p>{{ $user->name }}</p>
  @endif
  
  // ✅ 推奨：明示的なboolean条件
  @if (!is_null(session('status')))
      <div class="alert alert-success">{{ session('status') }}</div>
  @endif
  
  @if (!is_null(old('name')))
      value="{{ old('name') }}"
  @endif
  
  @if (!is_null($user->name))
      <p>{{ $user->name }}</p>
  @endif
  ```
- **boolean型の変数のみ直接条件式で使用可能**
  ```blade
  // ✅ 許可：boolean型は直接使用可能
  @if ($task->is_completed)
      <span class="badge bg-success">完了</span>
  @endif
  
  @if (!$user->is_enabled)
      <span class="text-muted">無効なユーザー</span>
  @endif
  ```
- **推奨する条件関数**
  - `is_null()` / `!is_null()` - null判定
  - `empty()` / `!empty()` - 空判定
  - `isset()` - 配列キー存在判定
  - `=== null` / `!== null` - 厳密null比較
- **日付・時刻の条件式は比較演算子を使用すること**
  ```blade
  // ❌ 禁止：日付の存在確認のような曖昧な条件
  @if ($task->expired_at)
      <p>期限: {{ $task->expired_at->format('Y-m-d') }}</p>
  @endif
  
  @if ($user->created_at)
      <p>登録日: {{ $user->created_at->format('Y-m-d') }}</p>
  @endif
  
  // ✅ 推奨：明確な比較条件
  @if (!is_null($task->expired_at))
      <p>期限: {{ $task->expired_at->format('Y-m-d') }}</p>
  @endif
  
  @if ($task->expired_at > now())
      <p class="text-success">期限まで余裕があります</p>
  @else
      <p class="text-danger">期限が過ぎています</p>
  @endif
  
  @if ($task->expired_at->isToday())
      <p class="text-warning">今日が期限です</p>
  @endif
  
  @if ($user->created_at > now()->subDays(30))
      <span class="badge bg-info">新規ユーザー</span>
  @endif
  ```
- **日付比較の推奨パターン**
  - `!is_null($date)` - 日付が設定されているか
  - `$date > now()` - 未来の日付か
  - `$date < now()` - 過去の日付か
  - `$date->isToday()` - 今日の日付か
  - `$date->isPast()` / `$date->isFuture()` - Carbonメソッドの活用
- バリデーションエラー時、リダイレクト時にSelectボックスでは`@selected()`を使用すること。必ずnullチェックも行うこと。
  * 例
    ```:blade
        <select name="user_status">
            <option></option>
            @foreach(\App\Enums\UserStatus::cases() as $user_status) 
            <option value={{ $user_status->value }} @selected(!is_null(old('user_status')) && $user_status->value === (int)old('user_status'))>{{ $user_status->label() }}</option>
        </select>
    ```
- チェックボックスでは`@checked()`を使用すること
- いついかなる場合でも`@php`ディレクティブは使用しないこと。必要であればバックエンド側で処理を記述すること。

## 完全修飾クラス名（FQCN）の使用
- Enumを使用する場合は完全修飾クラス名で記述すること：
  ```blade
  @if($user->gender === \App\Enums\Gender::MALE)
      男性です
  @endif
  
  @foreach(\App\Enums\Prefecture::asSelectArray() as $value => $description)
      <option value="{{ $value }}">{{ $description }}</option>
  @endforeach
  ```

## 型変換を伴う値の比較
- old()やrequest()の値を比較する場合は型変換を忘れずに行うこと：
  ```blade
  @selected(!is_null(old('prefecture')) && (int)old('prefecture') === $value)
  @checked(!is_null(old('gender')) && (int)old('gender') === \App\Enums\Gender::MALE)
  ```

## 複合条件での値の再表示
- 編集画面などで既存データとold()値を併用する場合：
  ```blade
  <input value="{{ $inquiry->name ?? old('name') }}">
  
  <option @selected(!is_null($inquiry->category) ? $inquiry->category->value === $value : !is_null(old('category')) && old('category') === $value)>
  ```

## 入力値の再表示
- **POSTフォーム内の全ての入力フィールドに`old()`による値の再表示を必須とする**
- **バリデーションエラー時のUI/UX向上のため、パスワード以外は必ず`old()`を設定すること**
  ```blade
  // ❌ 禁止：old()がない入力フィールド
  <input type="text" name="title" class="form-control" required>
  <input type="email" name="email" class="form-control" required>
  <textarea name="description" class="form-control"></textarea>
  
  // ✅ 推奨：old()による値の再表示
  <input type="text" name="title" class="form-control" value="{{ old('title') }}" required>
  <input type="email" name="email" class="form-control" value="{{ old('email') }}" required>
  <textarea name="description" class="form-control">{{ old('description') }}</textarea>
  ```
- **編集フォームでは既存データとold()の併用**
  ```blade
  // ✅ 推奨：編集フォームでの値設定
  <input type="text" name="title" class="form-control" value="{{ old('title', $task->title) }}" required>
  <input type="email" name="email" class="form-control" value="{{ old('email', $user->email) }}" required>
  <textarea name="description" class="form-control">{{ old('description', $task->description) }}</textarea>
  ```
- **セレクトボックスでの再表示**
  ```blade
  // ✅ 推奨：セレクトボックスでの@selected使用
  <select name="priority" class="form-control" required>
      <option value="1" @selected(old('priority') == '1')>低</option>
      <option value="2" @selected(old('priority') == '2')>中</option>
      <option value="3" @selected(old('priority') == '3')>高</option>
  </select>
  
  // ✅ 編集時のセレクトボックス
  <select name="priority" class="form-control" required>
      <option value="1" @selected(old('priority', $task->priority) == 1)>低</option>
      <option value="2" @selected(old('priority', $task->priority) == 2)>中</option>
      <option value="3" @selected(old('priority', $task->priority) == 3)>高</option>
  </select>
  ```
- **チェックボックス・ラジオボタンでの再表示**
  ```blade
  // ✅ 推奨：チェックボックスでの@checked使用
  <input type="checkbox" name="is_completed" value="1" @checked(old('is_completed') == '1')>
  
  // ✅ 編集時のチェックボックス
  <input type="checkbox" name="is_completed" value="1" @checked(old('is_completed', $task->is_completed) == true)>
  ```
- **パスワードフィールドは例外的に再表示しない**
  ```blade
  // ✅ 推奨：パスワードは再表示しない
  <input type="password" name="password" class="form-control" required>
  <input type="password" name="password_confirmation" class="form-control" required>
  ```
- 同一ルートへのリダイレクト時(検索など)の場合には`{{ request()->name }}`や`@selected(!is_null(request()->name) && request()->name === $name)`と記述し、値の再表示を行うこと。ただし**パスワードは再表示しない**

## 属性に関して
- 属性が複数、または横スクロールが必要なくらい長い記述になった場合は以下のように属性ごとに改行すること。
  ```
    <button
        class="btn"
        type="submit"
        id="button"
        formaction="/"
        formmethod="GET"
        data-id="1"
    >
        送信
    </button>
  ```
- 同一formタグ内に2つ以上の分岐する繊維がある場合は各buttonに`formaction`属性と`formmethod`属性を追加すること。
- 実装例：
  ```blade
  <form method="POST">
      @csrf
      <!-- フォーム内容 -->
      <button class="form__btn btn" formaction="{{ route('users.store') }}" formmethod="POST">
          登録する
      </button>
      <button class="form__btn btn btn_outline" formaction="{{ route('users.mypage') }}" formmethod="GET">
          キャンセル
      </button>
  </form>
  ```

## JavaScript連携とセキュリティ
- 二重クリック防止はdata属性で実装すること：
  ```blade
  <button class="form__btn btn" data-prevent-double-click>確認する</button>
  <x-prevent-double-click />
  ```
- JavaScriptとの連携にはdata属性を使用すること：
  ```blade
  <button data-toggle="modal" data-target="#modal" data-url="{{ route('admin.users.login', ['user' => $user]) }}">
      ログイン
  </button>
  ```

## 外部ライブラリの使用
- 郵便番号自動補完などの外部ライブラリを使用する場合：
  ```blade
  @section('js')
      <script src="https://yubinbango.github.io/yubinbango/yubinbango.js"></script>
  @endsection
  ```

## ファイルアップロード機能
- ファイルアップロード機能の実装：
  ```blade
  <input type="file" id="fileInput" accept=".jpg, .jpeg, .png" name="images[]" multiple>
  ```

## 値の表示方法
- `{{  }}`内で変数、または変数内の値を取得すること。
  * その際は空白スペース1つを初めと最後に用意すること。例：`{{ $name }}`
- **aタグのhref, formタグのaction, buttonタグのformactionなどでルートを呼び出す際は`route()`ヘルパー関数で名前付きルートを呼び出すこと**
- **`url()`ヘルパー関数は絶対に使用禁止**
  ```blade
  // ❌ 禁止：url()ヘルパーの使用
  <a href="{{ url('/') }}">ホーム</a>
  <a href="{{ url('/tasks') }}">タスク一覧</a>
  <form action="{{ url('/login') }}" method="POST">
  
  // ✅ 推奨：route()ヘルパーで名前付きルート
  <a href="{{ route('home') }}">ホーム</a>
  <a href="{{ route('tasks.index') }}">タスク一覧</a>
  <form action="{{ route('login') }}" method="POST">
  ```
- **全てのリンクとフォームアクションは名前付きルートで統一すること**
  ```blade
  // ✅ 推奨：名前付きルートの使用例
  <a href="{{ route('tasks.create') }}">新規作成</a>
  <a href="{{ route('tasks.show', $task) }}">詳細</a>
  <a href="{{ route('tasks.edit', $task) }}">編集</a>
  <form action="{{ route('tasks.update', $task) }}" method="POST">
  <button formaction="{{ route('tasks.destroy', $task) }}" formmethod="DELETE">削除</button>
  ```

## 言語・文字列の記述ルール
- **日本語のサービスであるため、Bladeテンプレートは日本語ベースで記述すること**
- **文字列は日本語でベタ書きすること。多言語化ヘルパー関数`__()`は使用しないこと**
  ```blade
  // ❌ 禁止：多言語化ヘルパーの使用
  <h1>{{ __('Dashboard') }}</h1>
  <p>{{ __('You are logged in!') }}</p>
  <button>{{ __('Login') }}</button>
  <a href="#">{{ __('Forgot Your Password?') }}</a>
  
  // ✅ 推奨：日本語ベタ書き
  <h1>ダッシュボード</h1>
  <p>ログインしています！</p>
  <button>ログイン</button>
  <a href="#">パスワードをお忘れですか？</a>
  ```
- **フォームラベルやボタンテキストも日本語で記述**
  ```blade
  // ✅ 推奨：日本語でのフォーム記述
  <label for="email">メールアドレス</label>
  <label for="password">パスワード</label>
  <button type="submit" class="btn btn-primary">ログイン</button>
  <button type="submit" class="btn btn-success">登録</button>
  ```
- **エラーメッセージやアラート表示も日本語**
  ```blade
  // ✅ 推奨：日本語でのメッセージ表示
  @if (!is_null(session('status')))
      <div class="alert alert-success">{{ session('status') }}</div>
  @endif
  
  <div class="alert alert-danger">
      <strong>エラー！</strong> 入力内容を確認してください。
  </div>
  ```

## エラーページの実装
- エラーページは統一されたデザインで実装すること：
  ```blade
  @extends('layouts.app')
  @section('title', 'Not Found')
  @section('main')
  <main class="page__container">
      <div class="error">
          <p class="error__main-txt">404</p>
          <p class="error__sub-txt">Not Found</p>
      </div>
  </main>
  @endsection
  ```

## ページネーションの実装
- **ページネーションでは必ず`withQueryString()`でクエリパラメータを保持すること**
  ```blade
  // ❌ 禁止：クエリパラメータが失われる
  {{ $tasks->links() }}
  {{ $users->links() }}
  
  // ✅ 推奨：クエリパラメータを保持
  {{ $tasks->withQueryString()->links() }}
  {{ $users->withQueryString()->links() }}
  ```
- **検索・フィルタ条件を維持したページネーション**
  ```blade
  // ✅ 推奨：検索条件やソート条件を保持
  {{ $tasks->withQueryString()->links() }}
  // ?search=タスク&status=completed&sort=expired_at_asc のようなパラメータが保持される
  
  // ✅ カスタムビューを使用する場合
  {{ $tasks->withQueryString()->links('custom.pagination') }}
  ```
- **ページネーション実装時の注意点**
  - 検索フォームがある場合は必須
  - フィルタ機能がある場合は必須
  - ソート機能がある場合は必須
  - ユーザーが設定した条件が失われないよう配慮すること

## メール用テンプレートの実装
- メール用テンプレートは`resources/views/mails/`配下に配置すること
- メール用の専用レイアウトを使用すること

## 管理画面専用コンポーネント
- 管理画面専用のコンポーネントを使用すること：
  ```blade
  <x-admin.toastr></x-admin.toastr>
  <x-admin.user-status-badge :status="$user->status" />
  ```

## コードフォーマットルール

### 改行の禁止
- **`@extends`と`@section`ディレクティブ間の改行は許可**
- **`@section`ディレクティブ内のHTML要素間での不要な改行は一切禁止**
- **各div要素間での改行は禁止（連続したHTML要素はコンパクトに記述）**
- **textareaタグ内のold()値は改行せず同一行に記述すること**
- **4スペースのインデントで整形し、コンパクトに記述すること**

### インデントルール
- **`@section`ディレクティブには適切なインデントを追加すること**
- **HTMLタグの開始・終了タグの位置を合わせ、一貫した4スペースインデントを使用すること**
- **input、textarea、select要素の開始・終了タグは適切にインデントされること**

### 推奨フォーマット例
```blade
// ✅ 推奨：適切な改行とインデント
@extends('layouts.app')

@section('title', 'ページタイトル')

@section('content')
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header">タイトル</div>
                    <div class="card-body">
                        <form method="POST" action="{{ route('example.store') }}">
                            @csrf
                            <div class="form-group mb-3">
                                <label for="title">タイトル</label>
                                <input type="text" class="form-control" id="title" name="title" required>
                            </div>
                            <div class="form-group mb-3">
                                <label for="description">説明</label>
                                <textarea class="form-control" name="description">{{ old('description') }}</textarea>
                            </div>
                            <button type="submit" class="btn btn-primary">送信</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection

// ❌ 禁止：不要な改行が多い記述
@extends('layouts.app')

@section('content')
    <div class="container">
        
        <div class="row justify-content-center">
            <div class="col-md-8">
                
                <div class="card">
                    <div class="card-header">タイトル</div>
                    
                    <div class="card-body">
                        <form method="POST" action="{{ route('example.store') }}">
                            @csrf
                            
                            <div class="form-group mb-3">
                                <label for="title">タイトル</label>
                                <input type="text" class="form-control" id="title" name="title" required>
                            </div>
                            
                            <div class="form-group mb-3">
                                <label for="description">説明</label>
                                <textarea class="form-control" name="description">
                                    {{ old('description') }}
                                </textarea>
                            </div>
                            
                            <button type="submit" class="btn btn-primary">送信</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection
```

## その他
- 必要に応じてJavaScriptで2重クリックを防ぐこと。
- Bootstrap5で記述すること
- コメントを残さないこと。