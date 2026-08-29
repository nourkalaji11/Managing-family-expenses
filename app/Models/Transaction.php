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
    'category_id',
    // يربط طرفَي التحويل الواحد. null في العمليات العادية — انظر TransferController.
    'transfer_group_id',
];

/**
 * هل هذا الصف أحد طرفَي تحويل بين حسابين؟
 *
 * يستعمله العميل لاستثنائه من مجاميع الدخل والمصاريف: نقل المال بين حسابَي
 * العائلة ليس دخلاً ولا إنفاقاً.
 */
public function getIsTransferAttribute(): bool
{
    return $this->transfer_group_id !== null;
}

/**
 * يُضاف is_transfer إلى كل استجابة JSON، حتى لا يضطر العميل إلى فحص
 * transfer_group_id بنفسه في كل موضع.
 */
protected $appends = ['is_transfer'];

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
