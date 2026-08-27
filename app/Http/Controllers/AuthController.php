<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // 1. إنشاء حساب جديد (Register)
    public function register(Request $request)
    {
        $validatedData = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'role'     =>  'nullable|string',
        ]);

        $user = User::create([
            'name'     => $validatedData['name'],
            'email'    => $validatedData['email'],
            'password' => Hash::make($validatedData['password']),
            'role'     => $validatedData['role']?? 'member',
        ]);

        // إنشاء Token للمستخدم الجديد
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message'      => 'User registered successfully',
            'access_token' => $token,
            'token_type'   => 'Bearer',
            'user'         => $user
        ], 201);
    }

    // 2. تسجيل الدخول (Login)
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Invalid login credentials'
            ], 401);
        }

        // إبطال أي توكنات قديمة وإنشاء توكن جديد
        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message'      => 'Login successful',
            'access_token' => $token,
            'token_type'   => 'Bearer',
            'user'         => $user
        ], 200);
    }

    // 3. تسجيل الخروج (Logout)
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully'
        ], 200);
    }

    // 4. جلب بيانات المستخدم الحالي (Profile)
    public function me(Request $request)
    {
        return response()->json([
            'user' => $request->user()
        ], 200);
    }
    // 5. تحديد حد السحب المالي للابن (خاص بالأب)
    public function setSpendingLimit(Request $request, $id)
    {
        if (auth()->user()->role !== 'admin') {
            return response()->json(['message' => 'غير مصرح لك بتحديد الحدود المالية.'], 403);
        }

        $request->validate([
            'spending_limit' => 'required|numeric|min:0',
        ]);

        $user = User::findOrFail($id);
        $user->spending_limit = $request->spending_limit;
        $user->save();

        return response()->json([
            'message' => 'تم تحديث سقف السحب للابن بنجاح.',
            'user' => $user
        ], 200);
    }
};