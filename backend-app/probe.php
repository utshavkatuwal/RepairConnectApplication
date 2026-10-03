<?php
$p = new PDO('sqlite:' . __DIR__ . '/database/database.sqlite');
echo "PROFILE: ";
foreach ($p->query("SELECT tp.id, tp.user_id, s.name, tp.verification_status, tp.experience_years, tp.latitude, tp.longitude FROM technician_profiles tp LEFT JOIN specialties s ON s.id = tp.specialty_id WHERE tp.user_id = 9") as $r) {
    echo implode(' | ', [$r['id'], $r['user_id'], $r['name'], $r['verification_status'], $r['experience_years'], $r['latitude'], $r['longitude']]) . PHP_EOL;
}
echo "DOCS: ";
foreach ($p->query("SELECT id, technician_id, document_type, original_filename, status FROM verification_documents ORDER BY id DESC LIMIT 6") as $r) {
    echo implode(' | ', [$r['id'], $r['technician_id'], $r['document_type'], $r['original_filename'], $r['status']]) . ' ; ';
}
echo PHP_EOL;
