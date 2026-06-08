<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Account extends Model
{
 // الحقول المسموح بتعبئتها برمجياً داخل جدول الحسابات
 protected $fillable = ['name', 'balance', 'user_id'];

 /**
  * الحساب يتبع لمستخدم واحد محدد (العلاقة العكسية)
  */
 public function user()
 {
     return $this->belongsTo(User::class);
 }

 /**
  * الحساب المالي الواحد يمكن أن تُسجل عليه عمليات مالية كثيرة
  */
 public function transactions()
 {
     return $this->hasMany(Transaction::class);
 }
}
