<?php

namespace App\Services;

use App\Events\TechnicianVerified;
use App\Models\AuditLog;
use App\Models\TechnicianProfile;
use App\Models\User;
use App\Models\VerificationDocument;
use Illuminate\Support\Facades\DB;

class VerificationService
{
    public const TYPES = [
        'government_id',
        'professional_certificate',
        'license',
        'experience_proof',
        'profile_photo',
        'other',
    ];

    public const ALLOWED_MIME = [
        'image/jpeg', 'image/png', 'image/webp', 'application/pdf',
    ];

    public const MAX_BYTES = 10 * 1024 * 1024;

    public function storeDocument(TechnicianProfile $profile, $file, string $type): VerificationDocument
    {
        abort_unless(in_array($type, self::TYPES, true), 422, 'Unknown document type.');
        abort_unless(in_array($file->getMimeType(), self::ALLOWED_MIME, true), 422, 'Unsupported file type.');
        abort_unless($file->getSize() <= self::MAX_BYTES, 422, 'Max file size is 10MB.');

        $ext = $file->guessExtension() ?? 'bin';
        $name = 'tech_'.$profile->id.'_'.uniqid('', true).'.'.$ext;
        // Private disk: local driver in dev, azure driver in prod (config only).
        $path = $file->storeAs('verification/'.$profile->id, $name, 'private');

        return $profile->documents()->create([
            'document_type' => $type,
            'file_path' => $path,
            'original_filename' => $file->getClientOriginalName(),
            'mime_type' => $file->getMimeType(),
            'file_size' => $file->getSize(),
            'status' => 'pending',
        ]);
    }

    public function approve(User $admin, TechnicianProfile $profile): TechnicianProfile
    {
        // Approval requires the submitted profile photo AND at least one
        // credential document — availability stays gated until this passes.
        abort_unless(
            $profile->documents()->where('document_type', 'profile_photo')->exists(),
            422,
            'Profile photo must be uploaded before approval.'
        );
        abort_unless(
            $profile->documents()
                ->where('document_type', '!=', 'profile_photo')
                ->exists(),
            422,
            'At least one credential document must be uploaded before approval.'
        );

        return DB::transaction(function () use ($admin, $profile) {
            $profile->update([
                'verification_status' => 'approved',
                'approved_at' => now(),
                'rejected_reason' => null,
            ]);
            $profile->documents()->update([
                'status' => 'approved',
                'reviewed_by' => $admin->id,
                'reviewed_at' => now(),
            ]);
            event(new TechnicianVerified($profile, true, null));
            AuditLog::record($admin, 'technician.approved', TechnicianProfile::class, $profile->id);

            return $profile->fresh();
        });
    }

    public function reject(User $admin, TechnicianProfile $profile, string $reason): TechnicianProfile
    {
        return DB::transaction(function () use ($admin, $profile, $reason) {
            $profile->update([
                'verification_status' => 'rejected',
                'rejected_reason' => $reason,
            ]);
            $profile->documents()->update([
                'status' => 'rejected',
                'reviewed_by' => $admin->id,
                'reviewed_at' => now(),
                'rejection_reason' => $reason,
            ]);
            event(new TechnicianVerified($profile, false, $reason));
            AuditLog::record($admin, 'technician.rejected', TechnicianProfile::class, $profile->id, ['reason' => $reason]);

            return $profile->fresh();
        });
    }

    public function requestResubmission(User $admin, TechnicianProfile $profile, string $reason): TechnicianProfile
    {
        $profile->update([
            'verification_status' => 'resubmission_required',
            'rejected_reason' => $reason,
        ]);
        event(new TechnicianVerified($profile, false, $reason));
        AuditLog::record($admin, 'technician.resubmission_required', TechnicianProfile::class, $profile->id, ['reason' => $reason]);

        return $profile->fresh();
    }
}
