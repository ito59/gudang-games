@extends('legal.layout')

@section('title', 'Ketentuan Layanan')

@section('content')
<p>
    Ketentuan ini mengatur penggunaan aplikasi {{ $legal['app_name'] }} dan layanannya, yang dikelola oleh
    <strong>{{ $legal['operator'] }}</strong> ("kami"). Dengan membuat akun, masuk, atau menggunakan
    {{ $legal['app_name'] }} dengan cara apa pun, Anda menyetujui ketentuan ini dan
    <a href="{{ route('legal.privacy', $keep) }}">Kebijakan Privasi</a> kami. Jika tidak
    setuju, jangan gunakan aplikasi ini.
</p>

<h2 id="eligibility">1. Siapa yang boleh menggunakan {{ $legal['app_name'] }}</h2>
<ul>
    <li>Anda harus berusia minimal {{ $legal['minimum_age'] }} tahun. Jika Anda belum dewasa menurut hukum di tempat Anda tinggal, Anda memerlukan izin orang tua atau wali, yang menyetujui ketentuan ini atas nama Anda.</li>
    <li>Anda tidak boleh menggunakan aplikasi jika sebelumnya telah kami blokir secara permanen, atau jika hukum melarang Anda.</li>
</ul>

<h2 id="account">2. Akun Anda</h2>
<ul>
    <li>Berikan informasi yang benar dan perbarui bila berubah. Jangan menyamar sebagai orang lain.</li>
    <li>Anda bertanggung jawab atas aktivitas di akun Anda. Jaga keamanan data masuk Anda dan beri tahu kami di <a href="mailto:{{ $contact }}">{{ $contact }}</a> jika Anda menduga akun Anda disalahgunakan.</li>
    <li>Satu orang, satu akun. Akun tidak boleh dijual atau dipindahtangankan.</li>
    <li>Anda dapat berhenti menggunakan aplikasi kapan saja dan meminta penghapusan akun seperti dijelaskan dalam <a href="{{ route('legal.privacy', $keep) }}#delete">Kebijakan Privasi</a>.</li>
</ul>

<h2 id="rules">3. Aturan komunitas</h2>
<p>
    {{ $legal['app_name'] }} adalah sebuah komunitas. <strong>Kami tidak menoleransi sama sekali konten
    yang tidak pantas maupun pengguna yang kasar.</strong> Anda dilarang memposting, mengirim, atau membagikan
    apa pun yang:
</p>
<ul>
    <li>melecehkan, merundung, mengancam, atau mengintimidasi siapa pun, atau mendorong orang lain melakukannya;</li>
    <li>mengandung kebencian atau diskriminasi berdasarkan suku, ras, agama, disabilitas, gender, orientasi seksual, atau karakteristik lain yang dilindungi;</li>
    <li>bermuatan seksual eksplisit, atau menyeksualisasi anak dalam bentuk apa pun;</li>
    <li>menampilkan atau mempromosikan kekerasan, menyakiti diri sendiri, terorisme, atau aktivitas berbahaya;</li>
    <li>melanggar hukum, mempromosikan kegiatan ilegal (termasuk judi, narkoba, atau jual beli senjata), atau melanggar hak kekayaan intelektual maupun privasi orang lain;</li>
    <li>menyebarkan data pribadi orang lain tanpa persetujuannya;</li>
    <li>berupa spam, penipuan, phishing, malware, atau iklan tanpa izin;</li>
    <li>sengaja menyesatkan orang lain, termasuk menyamar sebagai pengguna lain, staf, atau organisasi.</li>
</ul>
<p>Anda juga dilarang:</p>
<ul>
    <li>mengganggu layanan, mencoba mengakses akun atau data yang bukan milik Anda, atau mengakali moderasi, blokir, maupun batasan kami;</li>
    <li>menggunakan bot, scraper, atau cara otomatis untuk mengakses layanan tanpa izin kami;</li>
    <li>merekayasa balik aplikasi, kecuali sejauh diizinkan oleh hukum.</li>
</ul>

<h2 id="moderation">4. Pelaporan, pemblokiran, dan moderasi</h2>
<ul>
    <li><strong>Laporkan</strong> postingan, komentar, pesan, atau pengguna yang melanggar aturan ini melalui opsi laporan di aplikasi. Kami meninjau dan menindaklanjuti laporan, biasanya dalam 24 jam.</li>
    <li><strong>Blokir</strong> pengguna mana pun dari profilnya atau dari chat. Pengguna yang diblokir tidak dapat lagi mengirimi Anda pesan, dan Anda tidak akan melihat kontennya lagi. Akun yang diblokir dapat dikelola di aplikasi.</li>
    <li>Teks diperiksa otomatis dari kata kasar dan spam, dan dapat ditolak sebelum diterbitkan.</li>
    <li>Jika konten melanggar ketentuan ini, kami dapat menghapusnya dan memperingatkan, menangguhkan, atau memblokir permanen akun yang bertanggung jawab, tanpa pemberitahuan terlebih dahulu bila keadaan mengharuskan. Jika konten melanggar hukum atau membahayakan seseorang, kami dapat melaporkannya kepada pihak berwenang.</li>
    <li>Jika Anda merasa kami keliru, hubungi kami di <a href="mailto:{{ $contact }}">{{ $contact }}</a>.</li>
</ul>

<h2 id="content">5. Konten Anda</h2>
<ul>
    <li>Anda tetap memiliki postingan, komentar, pesan, dan foto yang Anda bagikan ("konten Anda").</li>
    <li>Dengan membagikannya, Anda memberi kami lisensi non-eksklusif, bebas royalti, dan berlaku di seluruh dunia untuk menyimpan, menggandakan, menampilkan, dan mendistribusikan konten Anda untuk keperluan menjalankan dan mengembangkan {{ $legal['app_name'] }}. Lisensi ini berakhir saat konten atau akun Anda dihapus, kecuali salinan yang disimpan sebagaimana dijelaskan dalam Kebijakan Privasi.</li>
    <li>Anda bertanggung jawab atas konten Anda dan menjamin bahwa Anda berhak membagikannya.</li>
    <li>Profil, postingan, dan komentar dapat dilihat pengguna lain. Jangan membagikan apa pun yang ingin Anda rahasiakan.</li>
</ul>

<h2 id="games">6. Game dan konten pihak ketiga</h2>
<p>
    {{ $legal['app_name'] }} memungkinkan Anda menemukan dan memainkan game, sebagian di antaranya dibuat
    dan di-hosting oleh pihak ketiga. Game tersebut milik pengembangnya dan dapat memiliki ketentuan serta
    kebijakan privasi sendiri. Kami tidak bertanggung jawab atas game, situs web, atau layanan pihak ketiga,
    dan penggunaannya menjadi risiko Anda sendiri. Nama, gambar, dan merek dagang game adalah milik pemiliknya masing-masing.
</p>

<h2 id="ours">7. Aplikasi kami</h2>
<p>
    Aplikasi, desain, perangkat lunak, dan konten yang kami sediakan (tidak termasuk konten Anda dan game
    pihak ketiga) adalah milik {{ $legal['operator'] }} atau pemberi lisensinya. Kami memberi Anda lisensi
    pribadi, non-eksklusif, tidak dapat dialihkan, dan dapat dicabut untuk menggunakan aplikasi sesuai
    tujuannya, berdasarkan ketentuan ini dan ketentuan Google Play tempat Anda mengunduhnya.
</p>

<h2 id="availability">8. Perubahan dan ketersediaan</h2>
<p>
    Kami dapat mengubah, menangguhkan, atau menghentikan bagian mana pun dari {{ $legal['app_name'] }}
    kapan saja. Kami berupaya menjaga layanan tetap berjalan, tetapi tidak menjamin layanan selalu tersedia,
    tanpa gangguan, atau bebas galat. Aplikasi ini saat ini gratis; jika kami menambahkan fitur berbayar,
    kami akan memberi tahu harganya sebelum Anda membayar.
</p>

<h2 id="termination">9. Pengakhiran</h2>
<p>
    Anda dapat berhenti menggunakan aplikasi kapan saja. Kami dapat menangguhkan atau mengakhiri akses Anda
    jika Anda melanggar ketentuan ini, jika diwajibkan hukum, atau jika penggunaan Anda membahayakan pengguna
    lain atau kami. Bagian yang menurut sifatnya tetap berlaku setelah pengakhiran — termasuk bagian 5, 7, 10,
    dan 11 — tetap berlaku.
</p>

<h2 id="liability">10. Penafian dan batasan tanggung jawab</h2>
<p>
    {{ $legal['app_name'] }} disediakan "sebagaimana adanya" dan "sebagaimana tersedia". Sejauh diizinkan
    hukum, kami tidak memberikan jaminan apa pun, dan kami tidak bertanggung jawab atas kerugian tidak langsung,
    insidental, atau konsekuensial, maupun atas konten yang diposting oleh pengguna atau pihak ketiga. Tidak ada
    bagian dari ketentuan ini yang membatasi tanggung jawab yang menurut hukum tidak dapat dibatasi.
</p>

<h2 id="law">11. Hukum yang berlaku</h2>
<p>
    Ketentuan ini diatur oleh hukum Negara Republik Indonesia. Kami akan terlebih dahulu berupaya menyelesaikan
    setiap sengketa secara musyawarah; hubungi kami di <a href="mailto:{{ $contact }}">{{ $contact }}</a>.
    Jika tidak selesai dalam 30 hari, sengketa diselesaikan melalui pengadilan yang berwenang di Indonesia,
    tanpa mengurangi hak konsumen yang wajib berlaku di tempat Anda tinggal.
</p>

<h2 id="changes">12. Perubahan ketentuan</h2>
<p>
    Kami dapat memperbarui ketentuan ini. Tanggal di bagian atas menunjukkan kapan versi saat ini mulai berlaku.
    Jika perubahannya material, kami akan memberi tahu Anda melalui aplikasi atau email sebelum berlaku. Dengan
    tetap menggunakan aplikasi setelahnya, Anda menyetujui ketentuan yang diperbarui.
</p>

<h2 id="contact">13. Kontak</h2>
<p>
    {{ $legal['operator'] }}<br>
    Email: <a href="mailto:{{ $contact }}">{{ $contact }}</a><br>
    Situs web: <a href="{{ $legal['website'] }}" rel="noopener">{{ $legal['website'] }}</a>
</p>
<p>Jika terdapat perbedaan antara versi bahasa Indonesia dan versi bahasa Inggris, versi bahasa Indonesia yang berlaku.</p>
@endsection
