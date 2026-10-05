@extends('legal.layout')

@section('title', 'Privacy Policy')

@section('content')
<p>
    This policy explains what personal data the {{ $legal['app_name'] }} mobile app
    (Android package <code>{{ $legal['package'] }}</code>) and its services collect,
    why, who it is shared with, and the choices you have. {{ $legal['app_name'] }}
    is operated by <strong>{{ $legal['operator'] }}</strong> ("we", "us"), which is
    the controller of your personal data under Indonesia's Personal Data Protection
    Law (Law No. 27 of 2022).
</p>

<div class="summary">
    <h3>In short</h3>
    <ul>
        <li>We collect what you give us (your account, profile, posts, comments and messages) and what the app needs to work (sign-in tokens and a push notification token).</li>
        <li>We do not show ads, sell your data, or use third-party analytics or advertising trackers.</li>
        <li>Your profile, posts and comments are public to other users. Your private messages are visible only to the people in the conversation, subject to the moderation described below.</li>
        <li>You can ask us to delete your account and its data at any time — see <a href="#delete">Deleting your account</a>.</li>
    </ul>
</div>

<h2 id="collect">1. Data we collect</h2>

<h3>Information you give us</h3>
<ul>
    <li><strong>Account details</strong> — your name, email address and, if you sign in with an email address, a password (stored only as a one-way hash).</li>
    <li><strong>Google Sign-In</strong> — if you choose "Continue with Google", Google shares your name, email address, Google account identifier and profile picture with us. We do not receive your Google password or access to your other Google data.</li>
    <li><strong>Profile</strong> — username, bio, location (a free-text field you fill in yourself; we do not use your device's location), profile photo, accent colour and the game you are currently playing.</li>
    <li><strong>Content</strong> — posts, comments, likes, friend requests and friends list, and messages you send in chat.</li>
    <li><strong>Photos</strong> — when you choose to set a profile photo, the app opens your camera or photo gallery at your request and uploads only the photo you pick. The app has no ongoing access to your photos.</li>
    <li><strong>Reports and blocks</strong> — the reason and note you submit when reporting content or a user, and the list of users you have blocked.</li>
    <li><strong>Settings</strong> — your notification preferences.</li>
</ul>

<h3>Information collected automatically</h3>
<ul>
    <li><strong>Sign-in tokens</strong> — a token that keeps you signed in, stored on your device and on our server, with the time it was last used.</li>
    <li><strong>Push notification token</strong> — if you allow notifications, Firebase Cloud Messaging gives the app a device token which we store with your account so we can deliver chat and news notifications. It identifies the app installation, not you personally.</li>
    <li><strong>Game activity</strong> — when a game is opened we increase that game's public play counter. This counter is not linked to your account.</li>
    <li><strong>Technical logs</strong> — like any web service, our servers record IP addresses, request times and error details in logs used for security and troubleshooting.</li>
    <li><strong>On your device</strong> — the app stores your sign-in token and a few preferences locally so you stay signed in.</li>
</ul>

<p>We do not collect your precise or approximate location, contacts, call logs, SMS, advertising ID, or payment information.</p>

<h2 id="use">2. How we use it</h2>
<ul>
    <li>To create and run your account and let you sign in.</li>
    <li>To show your profile, posts and comments to other users, and deliver your messages.</li>
    <li>To send the notifications you have switched on (new messages, news). You can turn these off in the app or in your device settings.</li>
    <li>To keep the community safe: text you post, comment or send in chat is automatically checked for abusive language and spam before it is published, and blocked text is logged so we can review how the filter behaves. Reported content is reviewed by our moderators.</li>
    <li>To secure the service, prevent abuse, fix problems and comply with the law.</li>
</ul>
<p>
    Our legal bases are performing our agreement with you (the <a href="{{ route('legal.terms', $keep) }}">Terms of Service</a>),
    our legitimate interest in keeping the service secure and safe, your consent (for notifications and
    photo uploads, which you can withdraw at any time), and legal obligations.
</p>

<h2 id="visible">3. What other users can see</h2>
<ul>
    <li><strong>Public to everyone using the app</strong>, including people who are not signed in: your name, username, bio, location, profile photo, accent colour, the game you are playing, game statistics on your profile, and your posts, comments and like counts.</li>
    <li><strong>Visible only to conversation participants</strong>: your chat messages and whether you have read them.</li>
    <li><strong>Never shown to other users</strong>: your email address, password, Google account identifier, device tokens, notification settings, reports you make, and your block list. A blocked user is not told that you blocked them.</li>
</ul>

<h2 id="share">4. Who we share it with</h2>
<p>We do not sell or rent personal data. We share it only with:</p>
<div class="table-wrap">
<table>
    <tr><th>Recipient</th><th>What and why</th></tr>
    <tr>
        <td>Google (Google Sign-In)</td>
        <td>If you use Google to sign in, Google handles the sign-in and gives us your basic profile. <a href="https://policies.google.com/privacy" rel="noopener">Google Privacy Policy</a>.</td>
    </tr>
    <tr>
        <td>Google Firebase Cloud Messaging</td>
        <td>Delivers push notifications. It receives your device token and the notification text (for example, the sender's name and a preview of a message). <a href="https://firebase.google.com/support/privacy" rel="noopener">Firebase privacy information</a>.</td>
    </tr>
    <tr>
        <td>Hosting and infrastructure providers</td>
        <td>Store and serve our servers, database and files on our behalf, under contracts that limit their use of the data.</td>
    </tr>
    <tr>
        <td>Authorities</td>
        <td>When required by law, or when necessary to protect the safety of our users or the public.</td>
    </tr>
    <tr>
        <td>A successor</td>
        <td>If {{ $legal['app_name'] }} is merged or transferred, under this policy or one that protects you at least as well.</td>
    </tr>
</table>
</div>
<p>
    Some of these providers process data outside Indonesia. Where they do, we rely on
    their contractual and technical safeguards to protect it as required by applicable law.
</p>

<h3>Games and links from third parties</h3>
<p>
    Some games in the catalogue are hosted by their own developers and open inside the app.
    Those games, and any external links, are governed by their own privacy policies; we do not
    control what they collect. We do not pass your account details to them.
</p>

<h2 id="security">5. Security</h2>
<p>
    Data between the app and our servers is sent over encrypted connections (HTTPS/TLS).
    Passwords are stored as one-way hashes, access to production systems is restricted to staff
    who need it, and uploaded game files are kept in protected storage. Chat messages are
    encrypted in transit but are not end-to-end encrypted, which is what allows reported
    messages to be reviewed. No system is perfectly secure; if a breach affects your data we
    will notify you and the authorities as the law requires.
</p>

<h2 id="retention">6. How long we keep it</h2>
<ul>
    <li>Account, profile, posts, comments, likes, friendships and messages: for as long as your account exists.</li>
    <li>Push notification tokens: until you sign out, the token stops working, or your account is deleted.</li>
    <li>Sign-in tokens: until you sign out or your account is deleted.</li>
    <li>Reports and moderation records: for as long as needed to keep the community safe and handle disputes. When an account is deleted, these records are detached from it.</li>
    <li>Server logs: for a limited period for security, then deleted.</li>
</ul>

<h2 id="delete">7. Deleting your account</h2>
<p>
    You can ask us to delete your {{ $legal['app_name'] }} account and its associated data at any time:
</p>
<ol>
    <li>Email <a href="mailto:{{ $contact }}?subject={{ rawurlencode($legal['app_name'].' account deletion') }}">{{ $contact }}</a> from the email address linked to your account, with the subject "{{ $legal['app_name'] }} account deletion".</li>
    <li>Include your username so we can find the account. We may ask you to confirm the request.</li>
    <li>We delete the account within 30 days and confirm by email.</li>
</ol>
<p><strong>What is deleted:</strong> your account and profile, profile photo, posts, comments, likes, chat messages, friendships, block list, reports you made, notification settings, device tokens and sign-in tokens.</p>
<p><strong>What may be kept:</strong> moderation records and reports that other users made about your content, detached from your account, where needed for safety or legal reasons; and data in encrypted backups until those backups expire in their normal cycle. Anonymous game play counts are not personal data and are not affected.</p>
<p>You can also ask us to delete specific data without deleting your account, using the same address.</p>

<h2 id="rights">8. Your rights</h2>
<p>
    Subject to applicable law, you have the right to be informed about how we use your data, to
    access and obtain a copy of it, to correct it, to have it deleted, to withdraw consent, to
    object to or restrict certain processing, and to lodge a complaint with the relevant authority.
    You can edit most of your profile directly in the app. For anything else, contact us at
    <a href="mailto:{{ $contact }}">{{ $contact }}</a>; we reply within the time the law allows.
</p>

<h2 id="children">9. Children</h2>
<p>
    {{ $legal['app_name'] }} is not intended for children under {{ $legal['minimum_age'] }}, and we do
    not knowingly collect personal data from them. If you believe a child under
    {{ $legal['minimum_age'] }} has created an account, contact us and we will delete it. Users between
    {{ $legal['minimum_age'] }} and the age of majority in their country should use the app with the
    permission of a parent or guardian.
</p>

<h2 id="changes">10. Changes to this policy</h2>
<p>
    We may update this policy. The date at the top shows when the current version took effect.
    If a change materially affects how we use your data, we will notify you in the app or by email
    before it applies.
</p>

<h2 id="contact">11. Contact</h2>
<p>
    {{ $legal['operator'] }}<br>
    Email: <a href="mailto:{{ $contact }}">{{ $contact }}</a><br>
    Website: <a href="{{ $legal['website'] }}" rel="noopener">{{ $legal['website'] }}</a>
</p>
<p>If this policy and its Indonesian version differ, the Indonesian version prevails.</p>
@endsection
