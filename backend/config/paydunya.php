<?php

return [
    'master_key' => env('PAYDUNYA_MASTER_KEY', 'default_master_key'),
    'private_key' => env('PAYDUNYA_PRIVATE_KEY', 'default_private_key_test'),
    'token' => env('PAYDUNYA_TOKEN', 'default_paydunya_token'),
    'mode' => env('PAYDUNYA_MODE', 'test'), // 'test' ou 'live'
    'ipn_url' => env('PAYDUNYA_IPN_URL', 'https://api.pronostics-sportifs.pro/api/v1/paydunya/ipn'),
    'return_url' => env('PAYDUNYA_RETURN_URL', 'https://api.pronostics-sportifs.pro/api/v1/paydunya/return'),
    'cancel_url' => env('PAYDUNYA_CANCEL_URL', 'https://api.pronostics-sportifs.pro/api/v1/paydunya/cancel'),
    'currency' => env('PAYDUNYA_CURRENCY', 'XOF'),
    'store_name' => 'Pronostics Sportifs VIP',
];
