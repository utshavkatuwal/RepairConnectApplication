<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\Role;
use App\Events\TechnicianRegistered;
use App\Http\Controllers\Controller;
use App\Http\Requests\ApiRequests\LoginRequest;
use App\Http\Requests\ApiRequests\RegisterRequest;
use App\Http\Resources\ApiResources\UserResource;
use App\Models\CustomerProfile;
use App\Models\OtpCode;
use App\Models\TechnicianProfile;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Password;

class AuthController extends Controller
{
    public function register(RegisterRequest $request)
    {
        $user = DB::transaction(function () use ($request) {
            $user = User::create([
                'name' => $request->string('name'),
                'email' => strtolower(trim($request->string('email'))),
                'phone' => $request->input('phone'),
                'password' => $request->string('password'),
                'role' => $request->string('role'),
                'status' => 'active',
            ]);
            if ($user->role === Role::Customer->value) {
                CustomerProfile::create(['user_id' => $user->id]);
            } else {
                $profile = TechnicianProfile::create(['user_id' => $user->id]);
                event(new TechnicianRegistered($profile));
            }

            return $user;
        });

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registered.',
            'data' => [
                'token' => $token,
                'user' => new UserResource($user->fresh()),
            ],
        ], 201);
    }

    public function login(LoginRequest $request)
    {
        if (! Auth::attempt($request->only('email', 'password'))) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials.',
            ], 401);
        }
        $user = $request->user();
        abort_unless($user->status === 'active', 403, 'Account is not active.');

        return response()->json([
            'success' => true,
            'message' => 'Logged in.',
            'data' => [
                'token' => $user->createToken('mobile')->plainTextToken,
                'user' => new UserResource($user),
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['success' => true, 'message' => 'Logged out.', 'data' => []]);
    }

    public function me(Request $request)
    {
        return response()->json([
            'success' => true,
            'message' => 'Profile.',
            'data' => new UserResource($request->user()->loadMissing('technicianProfile')),
        ]);
    }

    public function forgot(Request $request)
    {
        $request->validate(['email' => ['required', 'email:rfc']]);
        Password::sendResetLink($request->only('email'));

        return response()->json([
            'success' => true,
            'message' => 'If the account exists, a reset link was sent.',
            'data' => [],
        ]);
    }

    public function reset(Request $request)
    {
        $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'email:rfc'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);
        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            fn (User $user, string $password) => $user->update(['password' => $password])
        );

        return $status === Password::PASSWORD_RESET
            ? response()->json(['success' => true, 'message' => 'Password reset.', 'data' => []])
            : response()->json(['success' => false, 'message' => 'Invalid token.'], 422);
    }

    /**
     * Sliding session: revoke the calling token, issue a fresh one.
     * Used by clients on 401 instead of forcing a full re-login.
     */
    public function refresh(Request $request)
    {
        $user = $request->user();
        $request->user()->currentAccessToken()->delete();
        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Token refreshed.',
            'data' => ['token' => $token, 'user' => new UserResource($user)],
        ]);
    }

    /**
     * Email OTP: 6 digits, bcrypt-hashed at rest, 10-minute expiry,
     * 5 attempts, single use. Code is mailed in production; in local
     * debug it is also returned so the flow is testable without mail.
     */
    public function sendCode(Request $request)
    {
        $request->validate(['email' => ['required', 'email:rfc']]);
        $email = strtolower(trim($request->string('email')));

        OtpCode::where('email', $email)->whereNull('consumed_at')->update([
            'consumed_at' => now(),
        ]);

        $code = (string) random_int(100000, 999999);
        OtpCode::create([
            'email' => $email,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes(10),
        ]);

        Mail::raw(
            "Your RepairConnect code is: {$code}. It expires in 10 minutes.",
            fn ($m) => $m->to($email)->subject('Verification code')
        );

        return response()->json([
            'success' => true,
            'message' => 'If the account exists, a code was sent.',
            'data' => config('app.debug') ? ['debug_code' => $code] : [],
        ]);
    }

    public function verify(Request $request)
    {
        $request->validate([
            'email' => ['required', 'email:rfc'],
            'code' => ['required', 'digits:6'],
        ]);
        $email = strtolower(trim($request->string('email')));

        $otp = OtpCode::where('email', $email)
            ->whereNull('consumed_at')
            ->latest()
            ->first();
        abort_unless($otp?->usable(), 422, 'Code expired. Request a new one.');

        if (! Hash::check($request->string('code'), $otp->code_hash)) {
            $otp->increment('attempts');

            return response()->json(['success' => false, 'message' => 'Invalid code.'], 422);
        }

        $otp->update(['consumed_at' => now()]);
        $user = User::where('email', $email)->first();
        if ($user && is_null($user->email_verified_at)) {
            $user->update(['email_verified_at' => now()]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Verified.',
            'data' => $user ? new UserResource($user) : [],
        ]);
    }
}
