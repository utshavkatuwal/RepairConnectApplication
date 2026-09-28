<?php

return [
    'esewa' => [
        'merchant_id' => env('ESEWA_MERCHANT_ID'),
        'secret' => env('ESEWA_SECRET'),
        'endpoint' => env('ESEWA_ENDPOINT', 'https://rc.esewa.com.np/epay/main'),
    ],
    'khalti' => [
        'secret' => env('KHALTI_SECRET'),
        'endpoint' => env('KHALTI_ENDPOINT', 'https://khalti.com/api/v2'),
    ],
];
