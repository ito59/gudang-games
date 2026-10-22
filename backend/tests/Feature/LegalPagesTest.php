<?php

namespace Tests\Feature;

use Tests\TestCase;

/**
 * Play Console links to these pages, and a reviewer reads them logged out, in
 * whatever language their browser asks for.
 */
class LegalPagesTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config([
            'legal.operator' => 'PT Example',
            'legal.contact_email' => 'privacy@example.test',
        ]);
    }

    public function test_the_privacy_policy_is_public_in_both_languages(): void
    {
        $this->get('/policy?lang=en')->assertOk()
            ->assertSee('Privacy Policy')
            ->assertSee('PT Example')
            ->assertSee('privacy@example.test')
            ->assertSee('id.co.ki89.gudanggames')
            ->assertSee('id="delete"', false);

        $this->get('/policy?lang=id')->assertOk()
            ->assertSee('Kebijakan Privasi')
            ->assertSee('Menghapus akun');
    }

    public function test_the_terms_are_public_in_both_languages(): void
    {
        $this->get('/terms?lang=en')->assertOk()
            ->assertSee('Terms of Service')
            ->assertSee('zero tolerance');

        $this->get('/terms?lang=id')->assertOk()
            ->assertSee('Ketentuan Layanan');
    }

    public function test_the_browser_language_picks_the_version_when_none_is_asked_for(): void
    {
        $this->get('/terms', ['Accept-Language' => 'id-ID,id;q=0.9'])
            ->assertSee('Ketentuan Layanan');

        $this->get('/terms', ['Accept-Language' => 'fr-FR'])
            ->assertSee('Terms of Service');
    }

    public function test_an_unknown_language_falls_back_rather_than_failing(): void
    {
        $this->get('/policy?lang=../../welcome')->assertOk();
    }

    public function test_privacy_is_an_alias_for_the_policy(): void
    {
        $this->get('/privacy')->assertRedirect('/policy');
    }

    public function test_the_app_can_ask_for_the_dark_page_and_its_links_keep_it(): void
    {
        $dark = $this->get('/policy?lang=id&theme=dark')->assertOk()
            ->assertSee('/terms?lang=id&amp;theme=dark', false)
            ->getContent();
        $this->assertMatchesRegularExpression('/<html[^>]*data-theme="dark"/', $dark);

        // The stylesheet names the attribute either way; the root tag is what counts.
        $light = $this->get('/terms?lang=en')->assertOk()->getContent();
        $this->assertDoesNotMatchRegularExpression('/<html[^>]*data-theme/', $light);
    }

    public function test_the_contact_address_is_kept_out_of_cloudflare_obfuscation(): void
    {
        // Cloudflare rewrites addresses into "[email protected]" and undoes it
        // with JavaScript, which the app's WebView does not run.
        $this->get('/policy')->assertSee('<!--email_off-->', false)->assertSee('privacy@example.test');
    }
}
