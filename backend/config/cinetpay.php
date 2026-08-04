<?php

return [
    'api_key' => env('CINETPAY_API_KEY', '1234567890.abcdefg'),
    'site_id' => env('CINETPAY_SITE_ID', '654321'),
    'secret_key' => env('CINETPAY_SECRET_KEY', 'secret_key_cinetpay_example'),
    'notify_url' => env('CINETPAY_NOTIFY_URL', 'https://api.pronostics-sportifs.pro/api/v1/cinetpay/webhook'),
    'return_url' => env('CINETPAY_RETURN_URL', 'https://api.pronostics-sportifs.pro/api/v1/cinetpay/return'),
    'currency' => env('CINETPAY_CURRENCY', 'XOF'),
    'channels' => 'ALL', // MOBILE_MONEY, CREDIT_CARD, ALL
];
