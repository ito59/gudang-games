@extends('legal.layout')

@section('title', 'Terms of Service')

@section('content')
<p>
    These terms govern your use of the {{ $legal['app_name'] }} app and its services, operated by
    <strong>{{ $legal['operator'] }}</strong> ("we", "us"). By creating an account, signing in, or
    otherwise using {{ $legal['app_name'] }}, you agree to these terms and to our
    <a href="{{ route('legal.privacy', $keep) }}">Privacy Policy</a>. If you do not agree,
    do not use the app.
</p>

<h2 id="eligibility">1. Who can use {{ $legal['app_name'] }}</h2>
<ul>
    <li>You must be at least {{ $legal['minimum_age'] }} years old. If you are under the age of majority where you live, you need the permission of a parent or guardian, who accepts these terms on your behalf.</li>
    <li>You may not use the app if we have previously banned you, or if the law forbids you from doing so.</li>
</ul>

<h2 id="account">2. Your account</h2>
<ul>
    <li>Give accurate information and keep it up to date. Do not impersonate anyone.</li>
    <li>You are responsible for activity on your account. Keep your sign-in details secure and tell us at <a href="mailto:{{ $contact }}">{{ $contact }}</a> if you think your account has been compromised.</li>
    <li>One person, one account. Accounts may not be sold or transferred.</li>
    <li>You can stop using the app at any time and ask us to delete your account as described in the <a href="{{ route('legal.privacy', $keep) }}#delete">Privacy Policy</a>.</li>
</ul>

<h2 id="rules">3. Community rules</h2>
<p>
    {{ $legal['app_name'] }} is a community. <strong>We have zero tolerance for objectionable content
    and abusive users.</strong> You must not post, send or share anything that:
</p>
<ul>
    <li>harasses, bullies, threatens or intimidates anyone, or encourages others to do so;</li>
    <li>is hateful or discriminatory on the basis of race, ethnicity, religion, disability, gender, sexual orientation or any other protected characteristic;</li>
    <li>is sexually explicit, or sexualises minors in any way;</li>
    <li>depicts or promotes violence, self-harm, terrorism or dangerous activities;</li>
    <li>is illegal, promotes illegal activity (including gambling, drugs or weapons sales), or infringes someone else's intellectual property or privacy;</li>
    <li>shares another person's personal information without their consent;</li>
    <li>is spam, scams, phishing, malware, or unauthorised advertising;</li>
    <li>deliberately misleads others, including impersonating other users, staff or organisations.</li>
</ul>
<p>You must also not:</p>
<ul>
    <li>interfere with the service, try to access accounts or data that are not yours, or get around our moderation, blocks or limits;</li>
    <li>use bots, scrapers or automated means to access the service without our permission;</li>
    <li>reverse engineer the app except where the law allows it.</li>
</ul>

<h2 id="moderation">4. Reporting, blocking and moderation</h2>
<ul>
    <li><strong>Report</strong> any post, comment, message or user that breaks these rules using the report option in the app. We review reports and act on them, normally within 24 hours.</li>
    <li><strong>Block</strong> any user from their profile or from a chat. Blocked users can no longer message you, and you will no longer see their content. You can manage blocked accounts in the app.</li>
    <li>Text is checked automatically for abusive language and spam, and may be refused before it is published.</li>
    <li>When content breaks these terms, we may remove it and warn, suspend or permanently ban the account responsible, without prior notice where the situation requires it. Where content is illegal or puts someone in danger, we may report it to the authorities.</li>
    <li>If you believe we made a mistake, contact us at <a href="mailto:{{ $contact }}">{{ $contact }}</a>.</li>
</ul>

<h2 id="content">5. Your content</h2>
<ul>
    <li>You keep ownership of the posts, comments, messages and photos you share ("your content").</li>
    <li>By sharing it, you give us a non-exclusive, royalty-free, worldwide licence to host, store, reproduce, display and distribute your content for the purpose of operating and improving {{ $legal['app_name'] }}. This licence ends when your content or account is deleted, except for copies kept as described in the Privacy Policy.</li>
    <li>You are responsible for your content and confirm that you have the rights to share it.</li>
    <li>Profiles, posts and comments are visible to other users. Do not share anything you want to keep private.</li>
</ul>

<h2 id="games">6. Games and third-party content</h2>
<p>
    {{ $legal['app_name'] }} lets you discover and play games, some of which are made and hosted by
    third parties. Those games belong to their developers and may have their own terms and privacy
    policies. We are not responsible for third-party games, websites or services, and your use of them
    is at your own risk. Game names, images and trademarks belong to their respective owners.
</p>

<h3 id="casino">Casino-style games</h3>
<p>
    Some games, such as slots, blackjack, roulette, bingo and video poker, imitate casino games.
    They are <strong>simulations for entertainment only</strong>:
</p>
<ul>
    <li>there is no betting with real money, and no money, prizes or anything of real-world value can be won;</li>
    <li>coins, chips or credits inside a game cannot be bought, sold, exchanged or cashed out, and have no value outside the game;</li>
    <li>success in these games does not imply future success at real gambling.</li>
</ul>
<p>
    {{ $legal['app_name'] }} does not offer, promote or link to gambling services. If you feel your playing
    habits are getting in the way of your life, take a break and seek help.
</p>

<h2 id="ours">7. Our app</h2>
<p>
    The app, its design, software and content that we provide (excluding your content and third-party
    games) belong to {{ $legal['operator'] }} or its licensors. We give you a personal, non-exclusive,
    non-transferable, revocable licence to use the app for its intended purpose, in accordance with these
    terms and the Google Play terms under which you downloaded it.
</p>

<h2 id="availability">8. Changes and availability</h2>
<p>
    We may change, suspend or discontinue any part of {{ $legal['app_name'] }} at any time. We try to keep
    the service running but do not guarantee that it will always be available, uninterrupted or error-free.
    The app is currently free; if we introduce paid features, we will tell you the price before you pay.
</p>

<h2 id="termination">9. Ending your use</h2>
<p>
    You may stop using the app at any time. We may suspend or terminate your access if you break these
    terms, if the law requires it, or if your use puts other users or us at risk. Sections that by their
    nature should survive termination — including 5, 7, 10 and 11 — continue to apply.
</p>

<h2 id="liability">10. Disclaimer and limitation of liability</h2>
<p>
    {{ $legal['app_name'] }} is provided "as is" and "as available". To the fullest extent permitted by law,
    we make no warranties of any kind, and we are not liable for any indirect, incidental or consequential
    loss, or for content posted by users or third parties. Nothing in these terms limits liability that
    cannot be limited under applicable law.
</p>

<h2 id="law">11. Governing law</h2>
<p>
    These terms are governed by the laws of the Republic of Indonesia. We will first try to resolve any
    dispute with you informally; contact us at <a href="mailto:{{ $contact }}">{{ $contact }}</a>. If it
    cannot be resolved within 30 days, it will be settled by the competent courts of Indonesia, without
    affecting any mandatory consumer rights you have where you live.
</p>

<h2 id="changes">12. Changes to these terms</h2>
<p>
    We may update these terms. The date at the top shows when the current version took effect. If a change
    is material, we will notify you in the app or by email before it applies. Continuing to use the app
    after that means you accept the updated terms.
</p>

<h2 id="contact">13. Contact</h2>
<p>
    {{ $legal['operator'] }}<br>
    Email: <a href="mailto:{{ $contact }}">{{ $contact }}</a><br>
    Website: <a href="{{ $legal['website'] }}" rel="noopener">{{ $legal['website'] }}</a>
</p>
<p>If these terms and their Indonesian version differ, the Indonesian version prevails.</p>
@endsection
