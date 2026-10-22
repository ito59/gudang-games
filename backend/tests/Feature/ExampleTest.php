<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    use RefreshDatabase;

    /** The root is the public landing page; the panel stays at /admin. */
    public function test_the_root_is_the_landing_page(): void
    {
        $this->get('/')->assertOk()->assertSee('GudangGames');
    }

    public function test_the_landing_page_speaks_both_languages_and_links_the_legal_pages(): void
    {
        $this->get('/?lang=id')->assertOk()
            ->assertSee('Segera hadir di Google Play')
            ->assertSee('/policy?lang=id', false)
            ->assertSee('/terms?lang=id', false);

        $this->get('/?lang=en')->assertOk()->assertSee('Everything between matches');
    }

    public function test_the_download_button_waits_for_a_public_listing(): void
    {
        config(['legal.play_store_url' => null]);
        $this->get('/?lang=en')->assertSee('Coming soon to Google Play');

        config(['legal.play_store_url' => 'https://play.google.com/store/apps/details?id=id.co.ki89.gudanggames']);
        $this->get('/?lang=en')
            ->assertSee('Get it on Google Play')
            ->assertSee('details?id=id.co.ki89.gudanggames', false);
    }
}
