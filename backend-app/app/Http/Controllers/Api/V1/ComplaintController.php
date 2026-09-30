<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use Illuminate\Http\Request;

class ComplaintController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'job_id' => ['nullable', 'exists:jobs,id'],
            'body' => ['required', 'string', 'min:5', 'max:2000'],
        ]);
        $c = Complaint::create([
            'job_id' => $request->input('job_id'),
            'reporter_id' => $request->user()->id,
            'body' => $request->string('body'),
        ]);

        return response()->json(['success' => true, 'message' => 'Complaint filed.', 'data' => $c], 201);
    }

    public function resolve(Request $request, int $id)
    {
        $request->validate(['resolution' => ['required', 'string', 'min:5']]);
        $c = Complaint::findOrFail($id);
        $c->update([
            'status' => 'resolved',
            'assignee_id' => $request->user()->id,
            'resolution' => $request->string('resolution'),
        ]);
        \App\Models\AuditLog::record($request->user(), 'complaint.resolved', Complaint::class, $c->id);

        return response()->json(['success' => true, 'message' => 'Complaint resolved.', 'data' => $c]);
    }
}
