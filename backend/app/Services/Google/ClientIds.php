<?php

namespace App\Services\Google;

final class ClientIds
{
    /**
     * The audiences this server accepts.
     *
     * Derived from the clients it already hands out, because two settings that
     * must agree are two settings that can disagree — and a mismatch shows up
     * only as a rejected sign-in with no obvious cause.
     *
     * @return list<string>
     */
    public static function accepted(
        ?string $explicit,
        ?string $serverClientId,
        ?string $iosClientId,
    ): array {
        $ids = filled($explicit)
            ? array_map('trim', explode(',', $explicit))
            : [$serverClientId, $iosClientId];

        return array_values(array_unique(array_filter($ids, 'filled')));
    }
}
