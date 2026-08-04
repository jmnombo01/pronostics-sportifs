<?php

return [
    'project_id' => env('FCM_PROJECT_ID', 'pronostics-sportifs-app'),
    'credentials_path' => env('FCM_CREDENTIALS_PATH', 'storage/app/firebase_credentials.json'),
    'default_topic_all' => 'topic_all',
    'default_topic_vip' => 'topic_vip',
    'default_topic_montante' => 'topic_montante',
];
