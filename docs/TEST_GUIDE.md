# テスト設計ガイド

このドキュメントは、Laravelプロジェクトにおけるテスト記述の統一ルールおよび品質基準を定義します。

---

## テストの分類と目的

| テスト種別       | 対象範囲                           | 目的                                     |
|------------------|------------------------------------|------------------------------------------|
| Unitテスト       | 単体クラス・関数（Model, Service） | ロジック単位の正確性                    |
| Featureテスト    | HTTP層〜DBを含む処理全体           | リクエスト・レスポンスの正当性、また正常に通信ができているかを検証 |
| Requestテスト    | フォームバリデーション             | バリデーションルールの正当性            |

---

## 命名規則

### 2.1 テストファイル

- `〇〇Test.php`（PascalCase + Test）で命名
- `tests/Feature/`, `tests/Unit/`, `tests/Requests/`, `tests/Dusks` に分類

例：
```plaintext
tests/
├── Feature/
│   └── TaskControllerTest.php
├── Unit/
│   └── UserModelTest.php
└── Requests/
    └── UserStoreRequestTest.php
```

### メソッド名
 - 属性構文`#[Test]`を付与して、何のテストなのかメソッド名を日本語で命名すること。
    * 例：```test_task_fillable_attributes()```ではなく```Taskモデルのfillable属性を正しく設定しているか()```と命名

## 基本ルール
- **`RefreshDatabase`は絶対に使用しないこと。必ず`DatabaseTransactions`を使用すること**
- **Feature、Unit、Request全てのテストでDatabaseTransactionsを使用する**
  ```php
  // ✅ 推奨：DatabaseTransactionsを使用
  use Tests\TestCase;
  use Illuminate\Foundation\Testing\DatabaseTransactions;
  
  class TaskControllerTest extends TestCase
  {
      use DatabaseTransactions;
  }
  
  // ❌ 禁止：RefreshDatabaseの使用
  use Illuminate\Foundation\Testing\RefreshDatabase;
  
  class TaskControllerTest extends TestCase
  {
      use RefreshDatabase; // これは禁止
  }
  ```
- `.env.testing`を作成し、SQLiteで行うこと
- 1つのテストケースには 1つの期待結果 を記述
  * 仮に1つのname属性にバリデーションルールが5個ある場合、それぞれのバリデーションルールに対して各ケースを単一で記述していくこと。
- テストデータはFactoryを使用し、データベーストランザクションでテストの独立性を保つこと
- **人が目視で確認する場合のSeederも必ず作成しておくこと。** テスト用ユーザーのログイン情報などはREADME.mdファイルに記述しておくこと。
- **エラーが起きた際には、テストが通過するまでエラー内容を修正し続けること。**
- **全てのテストが100%通過するまで再帰的にテスト実行と修正を繰り返すこと。**
- テーブルにカラムを追加したり、既存機能に追加機能が加わった際は、既存のテストコードも修正すること。
- **テスト環境では必ず`.env.testing`を使用し、SQLite in-memoryデータベースを使用すること。**

## テストデータの準備
- **Factoryを使用した効率的なテストデータ生成**
  ```php
  // UserFactory.php
  public function definition(): array
  {
      return [
          'account_id' => fake()->unique()->uuid(),
          'email' => fake()->unique()->safeEmail(),
          'password' => Hash::make('password'),
          'nick_name' => fake()->userName(),
          'registered_at' => now(),
          'is_enabled' => true,
      ];
  }
  ```
- **状態別のFactoryを定義**
  ```php
  public function disabled(): Factory
  {
      return $this->state(fn() => ['is_enabled' => false]);
  }
  
  public function testUser(): Factory
  {
      return $this->state(fn() => ['is_test_user' => true]);
  }
  ```
- **関連データを含むFactoryの作成**
  ```php
  public function withSubscription(): Factory
  {
      return $this->afterCreating(function (User $user) {
          UserSubscription::factory()
              ->for($user)
              ->create();
      });
  }
  ```

## ビュー表示テストの必須実装
- **全てのビューページが正常に表示されることを確認するテストを必須で実装すること**
- **実際にサイトが表示されるかを保証するため、ビューテストは最優先で実装すること**

### ビューテストの基本パターン
```php
#[Test]
public function ホーム画面が正常に表示される()
{
    $user = User::factory()->create();
    
    $this->actingAs($user, 'web')
        ->get(route('home'))
        ->assertStatus(200)
        ->assertSee('ダッシュボード')
        ->assertViewIs('home');
}

#[Test] 
public function タスク一覧画面が正常に表示される()
{
    $user = User::factory()->create();
    $tasks = Task::factory(3)->for($user)->create();
    
    $this->actingAs($user, 'web')
        ->get(route('tasks.index'))
        ->assertStatus(200)
        ->assertSee('タスク一覧')
        ->assertViewIs('tasks.index')
        ->assertViewHas('tasks');
}

#[Test]
public function タスク作成画面が正常に表示される()
{
    $user = User::factory()->create();
    
    $this->actingAs($user, 'web')
        ->get(route('tasks.create'))
        ->assertStatus(200)
        ->assertSee('タスク作成')
        ->assertSee('タイトル')
        ->assertSee('説明')
        ->assertViewIs('tasks.create');
}

#[Test]
public function ログイン画面が正常に表示される()
{
    $this->get(route('login'))
        ->assertStatus(200)
        ->assertSee('ログイン')
        ->assertSee('メールアドレス')
        ->assertSee('パスワード')
        ->assertViewIs('auth.login');
}
```

### ビューテストで確認すべき項目
- **ステータスコード200の確認**
- **期待するテキストの表示確認**
- **正しいビューファイルの使用確認**
- **変数の受け渡し確認**
- **認証が必要な画面での認証確認**

### エラー画面のテスト
```php
#[Test]
public function 存在しないタスクにアクセスすると404が表示される()
{
    $user = User::factory()->create();
    
    $this->actingAs($user, 'web')
        ->get(route('tasks.show', 99999))
        ->assertStatus(404);
}

#[Test]
public function 未認証でタスク一覧にアクセスするとログイン画面にリダイレクトされる()
{
    $this->get(route('tasks.index'))
        ->assertRedirect(route('login'));
}
```

## 一般的なテスト設計パターン

### 認証・認可のテスト
- **ガード別の認証テスト**
  ```php
  #[Test]
  public function 一般ユーザーでログインできる()
  {
      $user = User::factory()->create();
      
      $this->actingAs($user, 'users')
          ->get(route('users.index'))
          ->assertStatus(200);
  }
  
  #[Test]
  public function 管理者でログインできる()
  {
      $admin = Admin::factory()->create();
      
      $this->actingAs($admin, 'admins')
          ->get(route('admin.users.index'))
          ->assertStatus(200);
  }
  ```

### 外部API連携のテスト
- **外部APIのモック**
  ```php
  #[Test]
  public function 外部API処理が正常に完了する()
  {
      $user = User::factory()->create();
      
      // 外部APIのモック
      Http::fake([
          'api.example.com/*' => Http::response([
              'status' => 'success',
              'data' => ['id' => 12345]
          ], 200)
      ]);
      
      $this->actingAs($user, 'users')
          ->post(route('api.process'))
          ->assertRedirect();
      
      $this->assertDatabaseHas('processing_histories', [
          'user_id' => $user->id,
          'status' => ProcessingStatus::COMPLETED,
      ]);
  }
  ```

### ビジネスロジックのテスト
- **複雑なロジックのテスト**
  ```php
  #[Test]
  public function 計算ロジックが正しく動作する()
  {
      $product = Product::factory()->create(['price' => 1000]);
      $user = User::factory()->create(['discount_rate' => 0.1]);
      
      $service = new CalculationService();
      $result = $service->calculateFinalPrice($product, $user);
      
      $this->assertEquals(900, $result);
  }
  ```

### メール送信のテスト
- **メール送信のテスト**
  ```php
  #[Test]
  public function 登録完了メールが送信される()
  {
      Mail::fake();
      
      $this->post(route('users.store'), [
          'email' => 'test@example.com',
          'password' => 'Password123!',
          'name' => 'testuser',
      ]);
      
      Mail::assertSent(UserRegistrationMail::class);
  }
  ```

### 権限管理のテスト
- **アクセス制御のテスト**
  ```php
  #[Test]
  public function 権限のないユーザーはアクセスできない()
  {
      $user = User::factory()->create(['role' => 'user']);
      $resource = Resource::factory()->create();
      
      $this->actingAs($user, 'users')
          ->get(route('resources.show', $resource))
          ->assertStatus(403);
  }
  ```

### 管理画面のテスト
- **管理者機能のテスト**
  ```php
  #[Test]
  public function 管理者はリソースを操作できる()
  {
      $admin = Admin::factory()->create();
      $resource = Resource::factory()->create();
      
      $this->actingAs($admin, 'admins')
          ->patch(route('admin.resources.update', $resource), [
              'name' => 'Updated Name',
              'status' => 'active'
          ])
          ->assertRedirect();
      
      $this->assertDatabaseHas('resources', [
          'id' => $resource->id,
          'name' => 'Updated Name',
          'status' => 'active'
      ]);
  }
  ```

### セキュリティテスト
- **認証・認可のテスト**
  ```php
  #[Test]
  public function 他のユーザーのデータにアクセスできない()
  {
      $user1 = User::factory()->create();
      $user2 = User::factory()->create();
      $resource = Resource::factory()->for($user2)->create();
      
      $this->actingAs($user1, 'users')
          ->get(route('resources.show', $resource))
          ->assertStatus(403);
  }
  
  #[Test]
  public function 署名付きURLの有効期限が切れるとアクセスできない()
  {
      $resource = Resource::factory()->create();
      
      // 期限切れのURL
      $expiredUrl = URL::temporarySignedRoute(
          'resources.preview',
          now()->subMinutes(10),
          ['resource' => $resource]
      );
      
      $this->get($expiredUrl)
          ->assertStatus(403);
  }
  ```

## テスト観点
 ### ハッピーパス（正常系）
 - 想定通りの入力をして正常動作が行われることを確認
 - 必須観点
    * ステータスコード（200, 302など）
    * DBへの保存
    * レスポンス本文／リダイレクト先
    * 成功メッセージ／通知の表示
  
 ### アンハッピーパス（異常系）
 - 入力ミスや不正操作など、異常時の動作を確認
 - エラー表示や処理キャンセルが適切かを検証

 ### 境界値テスト
 - 制限値に近い値でテストを行う（最大255文字、最小1文字など）
 - 主に文字数・数値・日付の前後で発生するエラーを検出

 ### 同値クラステスト
 - 有効値／無効値の「グループ」単位で代表ケースを抽出してテスト
 - 例:メールアドレス → 有効形式、空、全角、存在しないドメインなど

 ### レイアウトの確認
 - ページネーションのレイアウトが崩れていることがあった為、レイアウトの崩れなども検知するテストケースの作成を行なってください

 ### エラーパスや例外系の確認
 - 例外が投げられること、ログに出力されること、適切にcatchされることを確認
 - 500系エラーを見逃さない

## バリデーションテストの設計
- **FormRequestのテスト**
  ```php
  #[Test]
  public function メールアドレスが必須である()
  {
      $request = new UserRegisterRequest();
      $validator = Validator::make([], $request->rules());
      
      $this->assertTrue($validator->fails());
      $this->assertArrayHasKey('email', $validator->errors()->toArray());
  }
  
  #[Test]
  public function パスワードは8文字以上である()
  {
      $request = new UserRegisterRequest();
      $validator = Validator::make([
          'password' => 'short'
      ], $request->rules());
      
      $this->assertTrue($validator->fails());
      $this->assertArrayHasKey('password', $validator->errors()->toArray());
  }
  ```

## パフォーマンステスト
- **大量データでのテスト**
  ```php
  #[Test]
  public function 大量ユーザーでもページネーションが正常に動作する()
  {
      User::factory(1000)->create();
      
      $admin = Admin::factory()->create();
      
      $response = $this->actingAs($admin, 'admins')
          ->get(route('admin.users.index'));
      
      $response->assertStatus(200);
      $response->assertSee('1000'); // 総件数表示
  }
  ```

## 統合テストの設計
- **エンドツーエンドのテスト**
  ```php
  #[Test]
  public function 会員登録からくじ引きまでの一連の流れが正常に動作する()
  {
      // 1. 会員登録
      $userAuth = UserAuthentication::factory()
          ->create(['type' => UserAuthenticationType::USER_REGISTER]);
      
      $response = $this->post(route('users.store'), [
          'authentication_token' => $userAuth->token,
          'password' => 'Password123!',
          'nick_name' => 'testuser',
          // その他必要なフィールド
      ]);
      
      $user = User::where('email', $userAuth->email)->first();
      
      // 2. サブスクリプション登録
      $subscription = UserSubscription::factory()
          ->for($user)
          ->create(['is_enabled' => true]);
      
      // 3. くじ引き実行
      $lotteryTitle = LotteryTitle::factory()->create();
      $tier = LotteryTier::factory()->for($lotteryTitle)->create();
      
      $this->actingAs($user, 'users')
          ->post(route('lottery_title_courses.begin', $lotteryTitle))
          ->assertRedirect();
      
      // 4. 結果確認
      $this->assertDatabaseHas('user_play_histories', [
          'user_id' => $user->id,
          'lottery_title_id' => $lotteryTitle->id,
      ]);
  }
  ```

## モックとスタブの活用
- **外部サービスのモック**
  ```php
  #[Test]
  public function 外部メールサービスが停止していても処理が継続される()
  {
      // メール送信をモック
      Mail::shouldReceive('send')
          ->once()
          ->andThrow(new Exception('Mail service unavailable'));
      
      // ログをモック
      Log::shouldReceive('error')
          ->once()
          ->with('メール送信に失敗しました');
      
      $user = User::factory()->create();
      
      // 処理は継続されるべき
      $this->post(route('users.store'), [
          // 必要なデータ
      ])->assertRedirect();
  }
  ```

## テストの実行と継続的インテグレーション
- **テスト実行コマンド**
  ```bash
  # 全テスト実行
  ddev artisan test
  
  # 特定のテストファイル実行
  ddev artisan test tests/Feature/TaskControllerTest.php
  
  # カバレッジレポート生成
  ddev artisan test --coverage
  ```

## 再帰的テスト修正の手順
- **テスト失敗時の対応フロー**
  1. `ddev artisan test` でテスト実行
  2. エラーが発生した場合、エラー内容を詳細に確認
  3. エラー原因を特定し、コードを修正
  4. 再度 `ddev artisan test` を実行
  5. **全てのテストが通過するまで2-4を繰り返す**
  6. 全テスト通過後、機能が正常に動作することを手動確認

### 典型的なビューテストエラーと対処法
```php
// エラー例1: ビューファイルが見つからない
// ViewException: View [tasks.index] not found.
// → resources/views/tasks/index.blade.php を作成

// エラー例2: ルートが見つからない  
// RouteNotFoundException: Route [tasks.index] not found.
// → routes/web.php にルート定義を追加

// エラー例3: 変数が未定義
// Undefined variable $tasks
// → コントローラーでビューに変数を渡すよう修正

// エラー例4: 認証エラー
// Unauthenticated.
// → テスト内で適切に認証を行う
```

### テスト修正の優先順位
1. **ビューテスト（画面表示の確認）**
2. **機能テスト（フォーム送信、データ操作）**  
3. **バリデーションテスト**
4. **認証・認可テスト**
5. **例外・エラーテスト**

# 確認観点
 - ハッピーパスとアンハッピーパス両方が書かれているか？
 - 境界値・同値分析が考慮されているか？
 - テストメソッドが1ケース1主張になっているか？
 - テスト漏れのコントローラーアクションがないか？
 - バリデーションの全ケースがカバーされているか？
 - **プロジェクト固有の機能（くじ引き、決済、サブスクリプション）のテストが網羅されているか？**
 - **セキュリティテスト（認証・認可・署名付きURL）が実装されているか？**
 - **外部サービスのモック・スタブが適切に使用されているか？**