<?php
$db = new PDO('sqlite:C:\Projects\repairconnect\backend-app\database\database.sqlite');
foreach ($db->query('SELECT id, email, role, status FROM users ORDER BY id') as $r) {
    echo implode('|', [$r['id'], $r['email'], $r['role'], $r['status']]).PHP_EOL;
}
