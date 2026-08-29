<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * إشعار داخل التطبيق.
 *
 * يُسمّى AppNotification وليس Notification تفادياً للالتباس مع
 * Illuminate\Notifications\Notification، ولأن الجدول app_notifications.
 */
class AppNotification extends Model
{
    protected $table = 'app_notifications';

    protected $fillable = [
        'user_id',
        'type',
        'title',
        'message',
        'data',
        'seen',
    ];

    /**
     * data يُخزَّن JSON ويُقرأ مصفوفة؛ seen يُقرأ bool وليس 0/1، حتى لا يضطر
     * تطبيق الموبايل إلى تخمين شكل الحقل.
     */
    protected function casts(): array
    {
        return [
            'data' => 'array',
            'seen' => 'boolean',
        ];
    }

    // -------------------------------------------------------------------------
    // أنواع الإشعارات. ثوابت وليست نصوصاً متناثرة، حتى يبقى للواجهة عقد واحد
    // تعرفه: كل نوع هنا له أيقونة ولون في NotificationVisuals بتطبيق الموبايل.
    // -------------------------------------------------------------------------

    /** ابن تجاوز ميزانية فئة — يذهب لولي الأمر. */
    public const TYPE_BUDGET_EXCEEDED = 'budget_exceeded';

    /** ابن حاول صرف مبلغ يتجاوز سقف سحبه — يذهب لولي الأمر وللابن. */
    public const TYPE_LIMIT_BLOCKED = 'limit_blocked';

    /** ابن سجّل مصروفاً — يذهب لولي الأمر. */
    public const TYPE_MEMBER_SPENT = 'member_spent';

    /** ولي الأمر عدّل سقف سحب ابن — يذهب للابن. */
    public const TYPE_LIMIT_UPDATED = 'limit_updated';

    /**
     * اقترب الابن من نهاية مصروفه، ولم يتجاوزه بعد.
     *
     * الفرق عن TYPE_LIMIT_BLOCKED جوهري: هذا تحذير مسبق يصل قبل أن تُرفض أي
     * عملية، وهو ما يتيح لولي الأمر أن يرفع السقف أو يسأل قبل أن يجد الابن
     * نفسه عاجزاً عن الدفع. الرفض إشعار بما فات؛ هذا إشعار بما هو آتٍ.
     */
    public const TYPE_LIMIT_APPROACHING = 'limit_approaching';

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
