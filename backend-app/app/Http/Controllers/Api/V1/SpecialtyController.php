<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Specialty;
use Illuminate\Http\Request;

class SpecialtyController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'name' => ['required', 'string', 'max:120', 'unique:specialties,name'],
            'description' => ['nullable', 'string'],
            'icon' => ['nullable', 'string', 'max:120'],
        ]);

        return response()->json([
            'success' => true, 'message' => 'Specialty created.',
            'data' => Specialty::create($request->only('name', 'description', 'icon')),
        ], 201);
    }

    public function update(Request $request, int $id)
    {
        $specialty = Specialty::findOrFail($id);
        $request->validate([
            'name' => ['sometimes', 'string', 'max:120', "unique:specialties,name,{$id}"],
            'description' => ['nullable', 'string'],
            'icon' => ['nullable', 'string', 'max:120'],
            'status' => ['sometimes', 'in:active,inactive'],
        ]);
        $specialty->update($request->only('name', 'description', 'icon', 'status'));

        return response()->json(['success' => true, 'message' => 'Specialty updated.', 'data' => $specialty]);
    }

    public function destroy(int $id)
    {
        $specialty = Specialty::findOrFail($id);
        abort_if($specialty->technicians()->exists(), 409, 'Specialty is in use.');
        $specialty->delete();

        return response()->json(['success' => true, 'message' => 'Specialty removed.', 'data' => []]);
    }
}
