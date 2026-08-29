<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens ,HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'role',
        'password',
        'spending_limit',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
    /**
     * الأدوار المعتبرة "ولي أمر".
     *
     * القيمتان موجودتان لأن الطرفين اختلفا: تطبيق الموبايل يرسل 'parent'
     * (AccountRole في data/constant/enums.dart) بينما الكود القديم في
     * DashboardController وsetSpendingLimit كان يفحص 'admin' حرفياً — فحساب
     * ولي أمر أُنشئ من التطبيق كان يُعامل كابن ولا يستطيع تحديد سقف السحب.
     *
     * التوحيد هنا وليس بترحيل البيانات، حتى لا تتعطل صفوف 'admin' الموجودة
     * أصلاً في قواعد بيانات الفريق.
     */
    public const PARENT_ROLES = ['admin', 'parent'];

    /**
     * هل هذا المستخدم ولي أمر؟ المرجع الوحيد لفحص الصلاحية في كل الكنترولرات.
     */
    public function isParent(): bool
    {
        return in_array(strtolower((string) $this->role), self::PARENT_ROLES, true);
    }

    /**
     * علاقة المستخدم مع حساباته المالية (كل مستخدم لديه عدة حسابات)
     */
    public function accounts()
    {
        return $this->hasMany(Account::class);
    }

    /**
     * إشعارات المستخدم، الأحدث أولاً.
     */
    public function notifications()
    {
        return $this->hasMany(AppNotification::class)->latest();
    }

    /**
     * علاقة المستخدم مع ميزانياته (كل مستخدم لديه عدة ميزانيات موضوعة)
     */
    public function budgets()
    {
        return $this->hasMany(Budget::class);
    }

    /**
     * علاقة المستخدم مع عملياته المالية (كل مستخدم يسجل عدة مصاريف وإيرادات)
     */
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
}
