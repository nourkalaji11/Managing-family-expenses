<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * الجلسات المتوازية على الحساب نفسه.
 *
 * ---------------------------------------------------------------------------
 * كان login يبدأ بـ $user->tokens()->delete()، فيُبطل توكنات كل الأجهزة قبل
 * إنشاء توكنه. النتيجة أن دخول أي جهاز ثانٍ بالحساب نفسه يُخرج الأول فوراً —
 * وهو ما بلّغ عنه المستخدم: "لما 2 عم يدخلو نفس الحساب من جهازين عم يصير
 * logout من عند حدا".
 *
 * الاختباران الأولان يفشلان على الكود السابق. الباقي يحرس ما لا يجب أن ينكسر
 * بإزالة الحذف الشامل: تسجيل الخروج يبقى محلياً بجهازه، وتغيير كلمة المرور
 * يبقى مُخرِجاً لبقية الأجهزة، وعدد التوكنات لا ينمو بلا حد.
 * ---------------------------------------------------------------------------
 */
class ConcurrentSessionsTest extends TestCase
{
    use RefreshDatabase;

    private const PASSWORD = 'password123';

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::create([
            'name' => 'Parent',
            'email' => 'parent@test.local',
            'password' => Hash::make(self::PASSWORD),
            'role' => 'parent',
        ]);
    }

    /** يسجّل الدخول ويعيد التوكن النصي. */
    private function login(?string $device = null): string
    {
        $payload = [
            'email' => $this->user->email,
            'password' => self::PASSWORD,
        ];
        if ($device !== null) {
            $payload['device_name'] = $device;
        }

        $response = $this->postJson('/api/login', $payload);
        $response->assertStatus(200);

        return $response->json('access_token');
    }

    private function meWith(string $token)
    {
        // Laravel's auth manager caches the user it resolved for a guard, and
        // that cache survives between requests inside one test — so a token
        // revoked by the previous request would still appear to authenticate.
        // Real clients get a fresh container per request; this reproduces that.
        $this->app['auth']->forgetGuards();

        return $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/profile');
    }

    public function test_logging_in_from_a_second_device_keeps_the_first_signed_in(): void
    {
        $first = $this->login('phone');
        $second = $this->login('tablet');

        $this->assertNotSame($first, $second);

        // الجوهر: الجهاز الأول ما زال يعمل بعد دخول الثاني.
        $this->meWith($first)->assertStatus(200);
        $this->meWith($second)->assertStatus(200);
    }

    public function test_both_devices_keep_working_after_several_logins(): void
    {
        $first = $this->login('phone');
        $this->login('tablet');
        $this->login('laptop');

        $this->meWith($first)->assertStatus(200);
    }

    public function test_logout_ends_only_the_device_that_asked(): void
    {
        $phone = $this->login('phone');
        $tablet = $this->login('tablet');

        $this->withHeader('Authorization', "Bearer {$phone}")
            ->postJson('/api/logout')
            ->assertStatus(200);

        $this->meWith($phone)->assertStatus(401);
        $this->meWith($tablet)->assertStatus(200);
    }

    public function test_changing_the_password_signs_out_the_other_devices(): void
    {
        $phone = $this->login('phone');
        $tablet = $this->login('tablet');

        $this->withHeader('Authorization', "Bearer {$phone}")
            ->putJson('/api/profile', [
                'password' => 'newpassword456',
                'password_confirmation' => 'newpassword456',
                'current_password' => self::PASSWORD,
            ])
            ->assertStatus(200);

        // الجهاز الذي غيّر كلمة المرور يبقى داخلاً؛ الباقي يخرج.
        $this->meWith($phone)->assertStatus(200);
        $this->meWith($tablet)->assertStatus(401);
    }

    public function test_editing_the_profile_without_a_password_keeps_other_devices(): void
    {
        $phone = $this->login('phone');
        $tablet = $this->login('tablet');

        $this->withHeader('Authorization', "Bearer {$phone}")
            ->putJson('/api/profile', ['name' => 'Parent Renamed'])
            ->assertStatus(200);

        $this->meWith($tablet)->assertStatus(200);
    }

    public function test_sessions_are_capped_and_the_oldest_is_dropped_first(): void
    {
        $oldest = $this->login('device-0');
        for ($i = 1; $i <= 5; $i++) {
            $newest = $this->login("device-{$i}");
        }

        $this->assertSame(5, $this->user->tokens()->count());
        $this->meWith($oldest)->assertStatus(401);
        $this->meWith($newest)->assertStatus(200);
    }

    public function test_device_name_is_recorded_and_optional(): void
    {
        $this->login('Nour phone');
        $this->login();

        $names = $this->user->tokens()->pluck('name')->all();
        $this->assertContains('Nour phone', $names);
        $this->assertContains('auth_token', $names);
    }

    public function test_wrong_password_creates_no_session(): void
    {
        $this->postJson('/api/login', [
            'email' => $this->user->email,
            'password' => 'wrong-password',
        ])->assertStatus(401);

        $this->assertSame(0, $this->user->tokens()->count());
    }
}
