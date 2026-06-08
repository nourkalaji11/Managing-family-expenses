<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Budget extends Model
{
  // الحقول المسموح بتعبئتها برمجياً داخل جدول الميزانيات
  protected $fillable = [
    'limit_amount', 
    'current_spending', 
    'start_date', 
    'end_date', 
    'user_id', 
    'category_id'
];

/**
 * الميزانية تتبع لمستخدم واحد محدد
 */
public function user()
{
    return $this->belongsTo(User::class);
}

/**
 * الميزانية تُرصد لتصنيف مصروف واحد محدد (مثل: ميزانية الطعام)
 */
public function category()
{
    return $this->belongsTo(Category::class);
}
}
