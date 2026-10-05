<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Category extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'slug', 'icon', 'sort_order'];

    protected static function booted(): void
    {
        static::saving(function (Category $category) {
            $category->slug = $category->slug ?: Str::slug($category->name);
        });
    }

    public function games(): HasMany
    {
        return $this->hasMany(Game::class);
    }
}
