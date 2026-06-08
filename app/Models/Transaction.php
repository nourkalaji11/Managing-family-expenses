<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
  // الحقول المسموح بتعبئتها برمجياً داخل جدول العمليات المالية
  protected $fillable = [
    'amount', 
    'type', 
    'description', 
    'date', 
    'user_id', 
    'account_id', 
    'category_id'
];

/**
 * العملية المالية قام بها مستخدم واحد محدد
 */
public function user()
{
    return $this->belongsTo(User::class);
}

/**
 * العملية المالية تمت عبر حساب مالي واحد محدد (مثل: كاش أو بنك)
 */
public function account()
{
    return $this->belongsTo(Account::class);
}

/**
 * العملية المالية تتبع لتصنيف واحد محدد (مثل: طعام، مواصلات)
 */
public function category()
{
    return $this->belongsTo(Category::class);
}
}
