<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    protected $fillable = ['name'];
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
