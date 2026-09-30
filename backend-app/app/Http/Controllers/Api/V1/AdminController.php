<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use App\Models\Job;
use App\Models\Payment;
use App\Models\PlatformSetting;
use App\Models\TechnicianProfile;
use App\Models\User;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function dashboard()
    {
        return response()->json(['success' => true, 'message' => 'Dashboard.', 'data' => [
            'users' => User::count(),
            'customers' => User::where('role', 'customer')->count(),
            'technicians' => User::where('role', 'technician')->count(),
            'active_jobs' => Job::whereNotIn('status', ['completed', 'cancelled'])->count(),
            'completed_jobs' => Job::where('status', 'completed')->count(),
            'revenue' => (float) Payment::where('status', 'successful')->sum('amount'),
            'pending_verification' => TechnicianProfile::where('verification_status', 'pending')->count(),
            'open_complaints' => Complaint::where('status', 'open')->count(),
        ]]);
    }

    public function users(Request $request)
    {
        $rows = User::when($request->input('role'), fn ($q, $r) => $q->where('role', $r))
            ->when($request->input('q'), fn ($q, $term) => $q->where(fn ($w) => $w->where('name', 'like', "%{$term}%")->orWhere('email', 'like', "%{$term}%")))
            ->paginate(20);

        return response()->json(['success' => true, 'message' => 'Users.', 'data' => $rows->items(), 'meta' => ['total' => $rows->total()]]);
    }

    public function suspend(Request $request, int $id)
    {
        $user = User::findOrFail($id);
        abort_if($user->isRole('super_admin'), 403, 'Super admin cannot be suspended.');
        $user->update(['status' => $user->status === 'suspended' ? 'active' : 'suspended']);
        \App\Models\AuditLog::record($request->user(), 'user.'.$user->status, User::class, $user->id);

        return response()->json(['success' => true, 'message' => "User {$user->status}.", 'data' => []]);
    }

    public function jobs(Request $request)
    {
        $rows = Job::with(['customer:id,name', 'technician:id,name'])
            ->when($request->input('status'), fn ($q, $s) => $q->where('status', $s))
            ->latest()->paginate(20);

        return response()->json(['success' => true, 'message' => 'Jobs.', 'data' => $rows->items(), 'meta' => ['total' => $rows->total()]]);
    }

    public function payments(Request $request)
    {
        $rows = Payment::when($request->input('status'), fn ($q, $s) => $q->where('status', $s))
            ->latest()->paginate(20);

        return response()->json(['success' => true, 'message' => 'Payments.', 'data' => $rows->items(), 'meta' => ['total' => $rows->total()]]);
    }

    public function complaints(Request $request)
    {
        $rows = Complaint::with('reporter:id,name')
            ->when($request->input('status'), fn ($q, $s) => $q->where('status', $s))
            ->latest()->paginate(20);

        return response()->json(['success' => true, 'message' => 'Complaints.', 'data' => $rows->items(), 'meta' => ['total' => $rows->total()]]);
    }

    public function audit()
    {
        $rows = \App\Models\AuditLog::with('actor:id,name')->latest()->paginate(50);

        return response()->json(['success' => true, 'message' => 'Audit logs.', 'data' => $rows->items(), 'meta' => ['total' => $rows->total()]]);
    }

    public function settings(Request $request)
    {
        if ($request->isMethod('get')) {
            return response()->json(['success' => true, 'message' => 'Settings.', 'data' => PlatformSetting::all()]);
        }
        $request->validate(['key' => ['required', 'string'], 'value' => ['nullable', 'string']]);
        PlatformSetting::updateOrCreate(
            ['key' => $request->string('key')],
            ['value' => $request->input('value')]
        );

        return response()->json(['success' => true, 'message' => 'Setting saved.', 'data' => []]);
    }
}
