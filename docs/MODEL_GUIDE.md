# モデル設計ガイド

このガイドでは、LaravelのEloquentモデルに関する設計・命名・記述ルールを定めます。

---

## モデルクラスのルール
- ホワイトリスト形式として、全てのアプリケーションカラムの`protected $fillable`を必ず定義すること。
- Enumを使用しているカラム,DATETIME型のカラムには`protected function casts(): array`にて、型変換を定義しておくこと。
  ```php
  protected function casts(): array
  {
      return [
          'gender' => Gender::class,
          'status' => PaymentStatus::class,
          'birthday' => 'date',
          'registered_at' => 'datetime',
      ];
  }
  ```
- **システムカラムとアプリケーションカラムの概念を取り入れ、システムカラム(```created_at```,```updated_at```)は使用しないように**
  ```php
  // ✅ 推奨：アプリケーションカラムの使用
  protected $fillable = [
    'title',
    'description',
    'is_completed',
    'registered_at'
  ];
  
  // ❌ 禁止：システムカラムの使用
  protected $fillable = ['title', 'description', 'is_completed']; // created_at, updated_atに依存
  ```
- **Userモデルに残っている不要なPHPDocコメントは削除すること**

## Eager Loadingの設定
- 常にEager Loadingが必要なリレーションは`protected $with`で定義すること。
  ```php
  protected $with = [
      'userPoints'
  ];
  ```
- N+1問題を回避するため、頻繁にアクセスされるリレーションは積極的に使用すること。

## プライマリキーの自動生成
- ランダムIDの生成は`boot`メソッドで実装すること。
  ```php
  protected static function boot()
  {
      parent::boot();
      
      static::creating(function ($user) {
          $ulid = (string)Str::random(rand(15, 50));
          while (User::where('account_id', $ulid)->exists()) {
              $ulid = (string)Str::random(rand(15, 50));
          }
          $user->account_id = $ulid;
      });
  }
  ```
- 重複チェックを必ず実装し、一意性を保証すること。

## セキュリティ設定
- パスワードなどの機密情報は`protected $hidden`で隠蔽すること。
  ```php
  protected $hidden = [
      'password',
      'remember_token',
  ];
  ```
  
## リレーションの設定
- マイグレーションファイルを確認して、リレーション関係にあるテーブルにはお互いにリレーションを定義すること。
- マイグレーションファイルの追加更新があった場合に、それに伴ったリレーションの更新も行うこと。
- 条件付きリレーションは明確な名前で定義すること。
  ```php
  // 基本のリレーション
  public function userAddresses()
  {
      return $this->hasMany(UserAddress::class);
  }
  
  // 条件付きリレーション
  public function defaultUserAddress()
  {
      return $this->hasOne(UserAddress::class)
          ->where('is_default', true);
  }
  
  public function enableUserSubscriptions()
  {
      return $this->hasMany(UserSubscription::class)
          ->where('is_enabled', true);
  }
  ```
- 中間テーブルを使用するリレーションは`belongsToMany`で定義すること。
  ```php
  public function userFavoriteLotteryTitles()
  {
      return $this->belongsToMany(LotteryTitle::class, 'user_favorites');
  }
  ```
- 複雑なリレーションでは`hasManyThrough`を活用すること。
  ```php
  public function playedLotteryTitles()
  {
      return $this->hasManyThrough(
          related: LotteryTitle::class,
          through: PaymentHistory::class,
          firstKey: 'user_id',
          secondKey: 'id',
          localKey: 'id',
          secondLocalKey: 'lottery_title_id'
      )
      ->where('payment_histories.status', PaymentStatus::ACTIVE)
      ->distinct();
  }
  ```

## アクセサ
- 必要がある場合に限り1つのデータに対して1つの```get{データ名}Attribute```を定義すること。
  * ```getFullAddressAttribute()```など
- **独自メソッドは絶対に作成しないこと。必ずアクセサ（get{名前}Attribute）として定義すること**
  ```php
  // ❌ 禁止：独自メソッド
  public function isOverdue(): bool
  {
      return $this->due_date->isPast();
  }
  
  // ✅ 推奨：アクセサとして定義
  public function getIsOverdueAttribute(): bool
  {
      if (is_null($this->due_date) || $this->is_completed) {
          return false;
      }
      return $this->due_date->isPast();
  }
  
  // 使用例: $task->is_overdue でアクセス可能
  ```
- 文字列結合系アクセサの実装例：
  ```php
  public function getFullAddressAttribute()
  {
      return $this->prefecture->description
          . $this->city
          . $this->street
          . $this->building;
  }
  
  public function getFullNameAttribute()
  {
      return "{$this->last_name} {$this->first_name}";
  }
  ```
- 集計系アクセサの実装例：
  ```php
  public function getRemainingPointAttribute()
  {
      return $this->userPoints
          ->where('expired_at', '>', now())
          ->sum('remaining_point');
  }
  
  public function getTotalPaymentAmountAttribute()
  {
      return $this->paymentHistories
          ->where('status', PaymentStatus::ACTIVE)
          ->sum('including_tax_total_paid_amount');
  }
  ```
- アクセサを使用する場合は、必要に応じて事前にEager Loadingを行うこと。

## スコープ
- **複雑なクエリのみスコープとして定義すること**
- **単純な1行のクエリ（`where('column', value)`程度）はスコープにせず、使用時に直接記述すること**
  ```php
  // ❌ 禁止：単純すぎるスコープ
  public function scopeCompleted($query)
  {
      return $query->where('is_completed', true);
  }
  
  // ✅ 推奨：使用時に直接記述
  $tasks = Task::where('is_completed', true)->get();
  ```
- **スコープ作成基準**
  - 複数の条件を組み合わせている場合
  - 複雑なサブクエリやJOINを含む場合
  - 日付計算やロジックを含む場合
  - 再利用性が高く、可読性が向上する場合
- **スコープが必要な複雑なクエリの例：**
  ```php
  // ✅ 推奨：本当に複雑なクエリのみスコープ化
  public function scopeAvailableForUser($query, $userId, $now)
  {
      return $query->where('display_started_at', '<=', $now)
          ->where(function ($query) use ($now) {
              return $query->where('display_ended_at', '>=', $now)
                  ->orWhereNull('display_ended_at');
          })
          ->where('setting_status', LotteryTitleSettingStatus::COMPLETE)
          ->whereHas('permissions', function ($query) use ($userId) {
              $query->where('user_id', $userId)
                  ->where('is_accessible', true);
          });
  }
  
  // ❌ 削除対象：単純な条件の組み合わせ
  public function scopeOverdue($query)
  {
      return $query->where('expired_at', '<', now()->startOfDay())
          ->where('is_completed', false);
  }
  ```
- **直接記述すべきクエリの例：**
  ```php
  // ✅ 推奨：直接記述
  $overdueTask = Task::query()
      ->where('expired_at', '<', now()->startOfDay())
      ->where('is_completed', false)
      ->get();
      
  $dueTodayTasks = Task::query()
      ->whereDate('expired_at', now()->toDateString())
      ->where('is_completed', false)
      ->get();
  ```
- リクエストベースソートの標準実装：
  ```php
  public function scopeSortByRequest($query, $request)
  {
      return $query->when(!is_null($request->sort), function ($query) use ($request) {
          switch ($request->sort) {
              case UserSort::REGISTERED_AT_ASC:
                  return $query->orderBy('registered_at', 'ASC');
              case UserSort::REGISTERED_AT_DESC:
                  return $query->orderBy('registered_at', 'DESC');
              default:
                  return $query->orderBy('id', 'DESC');
          }
      }, function ($query) {
          return $query->orderBy('id', 'DESC');
      });
  }
  ```
- スコープはメソッドチェーンで使用できるように設計すること。

## ソフトデリートトレイトに関して
- SoftDeletesトレイトを使用することでEloquentメソッドの挙動が変わる為、使用しない方針。

## モデルの利用に関して
- 取得する際はN+1に注意し、取得済みモデルには```load()```で、取得前には```with()```で**Eager Lodingを徹底すること**
- リレーション先での条件の指定は`leftJoin`ではなく、`whereHas`を使用すること。
  * `whereHas()`を使用する際、リレーション先が1つだけのデータで連続していて指定を省略できる場合はリレーションを省略すること。
    - 例：`whereHas('paymentHistory.user', function())`