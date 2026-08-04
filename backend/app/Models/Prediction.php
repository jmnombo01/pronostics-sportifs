<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Prediction extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'competition',
        'country',
        'championship',
        'match_date',
        'match_time',
        'home_team',
        'away_team',
        'type',
        'odds',
        'selections_json',
        'confidence',
        'analysis',
        'status',
        'image_url',
        'is_published',
        'is_archived',
        'scheduled_at',
        'published_at',
    ];

    protected $casts = [
        'match_date' => 'date',
        'odds' => 'float',
        'selections_json' => 'array',
        'confidence' => 'integer',
        'is_published' => 'boolean',
        'is_archived' => 'boolean',
        'scheduled_at' => 'datetime',
        'published_at' => 'datetime',
    ];

    /**
     * Scope pour les pronostics publiés
     */
    public function scopePublished($query)
    {
        return $query->where('is_published', true)
                     ->where('is_archived', false);
    }

    /**
     * Scope par type (MONTANTE, COTE_5, COTE_10, COTE_50)
     */
    public function scopeOfType($query, $type)
    {
        if ($type) {
            return $query->where('type', $type);
        }
        return $query;
    }

    /**
     * Scope pour la recherche
     */
    public function scopeSearch($query, array $filters)
    {
        if (!empty($filters['championship'])) {
            $query->where('championship', 'like', '%' . $filters['championship'] . '%');
        }

        if (!empty($filters['team'])) {
            $query->where(function ($q) use ($filters) {
                $q->where('home_team', 'like', '%' . $filters['team'] . '%')
                  ->orWhere('away_team', 'like', '%' . $filters['team'] . '%');
            });
        }

        if (!empty($filters['match_date'])) {
            $query->whereDate('match_date', $filters['match_date']);
        }

        if (!empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        return $query;
    }
}
