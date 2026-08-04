<?php

use Illuminate\Support\Facades\Schedule;

/*
|--------------------------------------------------------------------------
| Console Routes & Command Scheduling - Laravel 12
|--------------------------------------------------------------------------
| Configuration des tâches récurrentes pour la maintenance des abonnements
*/

// Planifier la vérification automatique des essais gratuits 48h et des abonnements chaque heure
Schedule::command('check:subscriptions')->hourly();
