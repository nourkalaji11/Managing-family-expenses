<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    /** فئة دخل: تظهر في تبويب الدخل ولا تُعرض حين يسجّل المستخدم مصروفاً. */
    public const TYPE_INCOME = 'income';

    /** فئة مصروف. القيمة الافتراضية، وما كانت عليه كل الصفوف قبل العمود. */
    public const TYPE_EXPENSE = 'expense';

    /** فئة دين — تبويب مستقل في شاشة الفئات. */
    public const TYPE_DEBT = 'debt';

    public const TYPES = [self::TYPE_INCOME, self::TYPE_EXPENSE, self::TYPE_DEBT];

    protected $fillable = ['name', 'type', 'parent_id', 'icon'];

    /**
     * المجموعة التي تنتمي إليها الفئة، وnull للمجموعات الرئيسية.
     */
    public function parent()
    {
        return $this->belongsTo(Category::class, 'parent_id');
    }

    /**
     * الفروع المدرجة تحت هذه المجموعة، مرتَّبة كما تُعرض.
     */
    public function children()
    {
        return $this->hasMany(Category::class, 'parent_id')->orderBy('id');
    }
 /**
     * علاقة التصنيف مع الميزانيات (التصنيف الواحد يمكن أن تُرصد له عدة ميزانيات عبر الزمن)
     */
    public function budgets()
    {
        return $this->hasMany(Budget::class);
    }

    /**
     * علاقة التصنيف مع العمليات (التصنيف الواحد يضم العديد من المصاريف والإيرادات)
     */
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
}
