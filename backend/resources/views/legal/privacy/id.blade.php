@extends('legal.layout')

@section('title', 'Kebijakan Privasi')

@section('content')
<p>
    Kebijakan ini menjelaskan data pribadi apa yang dikumpulkan oleh aplikasi seluler
    {{ $legal['app_name'] }} (paket Android <code>{{ $legal['package'] }}</code>) beserta
    layanannya, untuk apa, dengan siapa dibagikan, dan pilihan yang Anda miliki.
    {{ $legal['app_name'] }} dikelola oleh <strong>{{ $legal['operator'] }}</strong>
    ("kami"), selaku pengendali data pribadi Anda menurut Undang-Undang Nomor 27 Tahun 2022
    tentang Pelindungan Data Pribadi (UU PDP).
</p>

<div class="summary">
    <h3>Ringkasnya</h3>
    <ul>
        <li>Kami mengumpulkan data yang Anda berikan (akun, profil, postingan, komentar, dan pesan) serta data yang dibutuhkan agar aplikasi berjalan (token masuk dan token notifikasi).</li>
        <li>Kami tidak menampilkan iklan, tidak menjual data Anda, dan tidak memakai pelacak analitik atau iklan pihak ketiga.</li>
        <li>Profil, postingan, dan komentar Anda dapat dilihat pengguna lain. Pesan pribadi hanya dapat dilihat oleh peserta percakapan, dengan tetap tunduk pada moderasi yang dijelaskan di bawah.</li>
        <li>Anda dapat meminta akun dan datanya dihapus kapan saja — lihat <a href="#delete">Menghapus akun</a>.</li>
    </ul>
</div>

<h2 id="collect">1. Data yang kami kumpulkan</h2>

<h3>Data yang Anda berikan</h3>
<ul>
    <li><strong>Data akun</strong> — nama, alamat email, dan kata sandi jika Anda masuk dengan email (hanya disimpan dalam bentuk hash satu arah).</li>
    <li><strong>Masuk dengan Google</strong> — jika Anda memilih "Continue with Google", Google membagikan nama, alamat email, ID akun Google, dan foto profil Anda kepada kami. Kami tidak menerima kata sandi Google atau akses ke data Google Anda yang lain.</li>
    <li><strong>Profil</strong> — username, bio, lokasi (kolom teks bebas yang Anda isi sendiri; kami tidak memakai lokasi perangkat), foto profil, warna aksen, dan game yang sedang Anda mainkan.</li>
    <li><strong>Konten</strong> — postingan, komentar, suka (like), permintaan pertemanan dan daftar teman, serta pesan yang Anda kirim di chat.</li>
    <li><strong>Foto</strong> — saat Anda memilih foto profil, aplikasi membuka kamera atau galeri atas permintaan Anda dan hanya mengunggah foto yang Anda pilih. Aplikasi tidak memiliki akses berkelanjutan ke foto Anda.</li>
    <li><strong>Laporan dan blokir</strong> — alasan dan catatan yang Anda kirim saat melaporkan konten atau pengguna, serta daftar pengguna yang Anda blokir.</li>
    <li><strong>Pengaturan</strong> — preferensi notifikasi Anda.</li>
</ul>

<h3>Data yang terkumpul secara otomatis</h3>
<ul>
    <li><strong>Token masuk</strong> — token yang membuat Anda tetap masuk, disimpan di perangkat dan di server kami, beserta waktu terakhir dipakai.</li>
    <li><strong>Token notifikasi</strong> — jika Anda mengizinkan notifikasi, Firebase Cloud Messaging memberikan token perangkat yang kami simpan bersama akun Anda untuk mengirim notifikasi chat dan berita. Token ini mengenali instalasi aplikasi, bukan diri Anda secara pribadi.</li>
    <li><strong>Aktivitas game</strong> — saat sebuah game dibuka, kami menambah penghitung jumlah main game tersebut. Penghitung ini tidak terhubung dengan akun Anda.</li>
    <li><strong>Log teknis</strong> — seperti layanan web pada umumnya, server kami mencatat alamat IP, waktu permintaan, dan detail galat untuk keamanan dan perbaikan masalah.</li>
    <li><strong>Di perangkat Anda</strong> — aplikasi menyimpan token masuk dan beberapa preferensi secara lokal agar Anda tetap masuk.</li>
</ul>

<p>Kami tidak mengumpulkan lokasi tepat maupun perkiraan, kontak, log panggilan, SMS, ID iklan, atau informasi pembayaran.</p>

<h2 id="use">2. Cara kami menggunakannya</h2>
<ul>
    <li>Untuk membuat dan menjalankan akun Anda serta memungkinkan Anda masuk.</li>
    <li>Untuk menampilkan profil, postingan, dan komentar Anda kepada pengguna lain, serta mengirimkan pesan Anda.</li>
    <li>Untuk mengirim notifikasi yang Anda aktifkan (pesan baru, berita). Anda dapat mematikannya di aplikasi atau di pengaturan perangkat.</li>
    <li>Untuk menjaga keamanan komunitas: teks yang Anda posting, komentari, atau kirim di chat diperiksa otomatis dari kata kasar dan spam sebelum diterbitkan, dan teks yang diblokir dicatat agar kami dapat mengevaluasi cara kerja filter. Konten yang dilaporkan ditinjau oleh moderator kami.</li>
    <li>Untuk mengamankan layanan, mencegah penyalahgunaan, memperbaiki masalah, dan mematuhi hukum.</li>
</ul>
<p>
    Dasar pemrosesan kami adalah pelaksanaan perjanjian dengan Anda (<a href="{{ route('legal.terms', $keep) }}">Ketentuan Layanan</a>),
    kepentingan sah kami untuk menjaga layanan tetap aman, persetujuan Anda (untuk notifikasi dan
    unggahan foto, yang dapat Anda tarik kapan saja), serta kewajiban hukum.
</p>

<h2 id="visible">3. Apa yang dapat dilihat pengguna lain</h2>
<ul>
    <li><strong>Publik bagi semua pengguna aplikasi</strong>, termasuk yang belum masuk: nama, username, bio, lokasi, foto profil, warna aksen, game yang sedang dimainkan, statistik game di profil, serta postingan, komentar, dan jumlah suka Anda.</li>
    <li><strong>Hanya peserta percakapan</strong>: pesan chat Anda dan status sudah dibaca.</li>
    <li><strong>Tidak pernah ditampilkan ke pengguna lain</strong>: alamat email, kata sandi, ID akun Google, token perangkat, pengaturan notifikasi, laporan yang Anda buat, dan daftar blokir Anda. Pengguna yang Anda blokir tidak diberi tahu bahwa ia diblokir.</li>
</ul>

<h2 id="share">4. Dengan siapa kami membagikannya</h2>
<p>Kami tidak menjual atau menyewakan data pribadi. Kami hanya membagikannya kepada:</p>
<div class="table-wrap">
<table>
    <tr><th>Penerima</th><th>Apa dan mengapa</th></tr>
    <tr>
        <td>Google (Masuk dengan Google)</td>
        <td>Jika Anda masuk dengan Google, Google menangani proses masuk dan memberikan profil dasar Anda kepada kami. <a href="https://policies.google.com/privacy?hl=id" rel="noopener">Kebijakan Privasi Google</a>.</td>
    </tr>
    <tr>
        <td>Google Firebase Cloud Messaging</td>
        <td>Mengirim notifikasi push. Layanan ini menerima token perangkat dan teks notifikasi (misalnya nama pengirim dan cuplikan pesan). <a href="https://firebase.google.com/support/privacy" rel="noopener">Informasi privasi Firebase</a>.</td>
    </tr>
    <tr>
        <td>Penyedia hosting dan infrastruktur</td>
        <td>Menyimpan dan menjalankan server, basis data, dan berkas kami atas nama kami, berdasarkan kontrak yang membatasi penggunaan data.</td>
    </tr>
    <tr>
        <td>Pihak berwenang</td>
        <td>Jika diwajibkan oleh hukum, atau bila perlu untuk melindungi keselamatan pengguna atau publik.</td>
    </tr>
    <tr>
        <td>Penerus usaha</td>
        <td>Jika {{ $legal['app_name'] }} digabungkan atau dialihkan, berdasarkan kebijakan ini atau kebijakan yang melindungi Anda setidaknya setara.</td>
    </tr>
</table>
</div>
<p>
    Sebagian penyedia tersebut memproses data di luar Indonesia. Dalam hal itu, kami mengandalkan
    perlindungan kontraktual dan teknis mereka untuk melindungi data sesuai hukum yang berlaku.
</p>

<h3>Game dan tautan pihak ketiga</h3>
<p>
    Sebagian game di katalog di-hosting oleh pengembangnya sendiri dan dibuka di dalam aplikasi.
    Game tersebut, dan tautan eksternal lainnya, tunduk pada kebijakan privasi masing-masing; kami
    tidak mengendalikan data yang mereka kumpulkan. Kami tidak meneruskan data akun Anda kepada mereka.
</p>

<h2 id="security">5. Keamanan</h2>
<p>
    Data antara aplikasi dan server kami dikirim melalui koneksi terenkripsi (HTTPS/TLS).
    Kata sandi disimpan sebagai hash satu arah, akses ke sistem produksi dibatasi hanya untuk staf
    yang membutuhkannya, dan berkas game yang diunggah disimpan di penyimpanan terlindungi. Pesan chat
    terenkripsi saat dikirim tetapi tidak terenkripsi end-to-end, sehingga pesan yang dilaporkan dapat
    ditinjau. Tidak ada sistem yang sepenuhnya aman; jika terjadi kebocoran yang memengaruhi data Anda,
    kami akan memberi tahu Anda dan pihak berwenang sesuai ketentuan hukum.
</p>

<h2 id="retention">6. Berapa lama kami menyimpannya</h2>
<ul>
    <li>Akun, profil, postingan, komentar, suka, pertemanan, dan pesan: selama akun Anda ada.</li>
    <li>Token notifikasi: sampai Anda keluar, token tidak berlaku lagi, atau akun Anda dihapus.</li>
    <li>Token masuk: sampai Anda keluar atau akun Anda dihapus.</li>
    <li>Laporan dan catatan moderasi: selama diperlukan untuk menjaga keamanan komunitas dan menangani sengketa. Saat akun dihapus, catatan ini dilepaskan dari akun tersebut.</li>
    <li>Log server: untuk jangka waktu terbatas demi keamanan, lalu dihapus.</li>
</ul>

<h2 id="delete">7. Menghapus akun</h2>
<p>
    Anda dapat meminta penghapusan akun {{ $legal['app_name'] }} beserta datanya kapan saja:
</p>
<ol>
    <li>Kirim email ke <a href="mailto:{{ $contact }}?subject={{ rawurlencode('Hapus akun '.$legal['app_name']) }}">{{ $contact }}</a> dari alamat email yang terhubung dengan akun Anda, dengan subjek "Hapus akun {{ $legal['app_name'] }}".</li>
    <li>Sertakan username Anda agar kami dapat menemukan akunnya. Kami mungkin meminta Anda mengonfirmasi permintaan tersebut.</li>
    <li>Kami menghapus akun dalam 30 hari dan mengonfirmasinya melalui email.</li>
</ol>
<p><strong>Yang dihapus:</strong> akun dan profil, foto profil, postingan, komentar, suka, pesan chat, pertemanan, daftar blokir, laporan yang Anda buat, pengaturan notifikasi, token perangkat, dan token masuk.</p>
<p><strong>Yang mungkin tetap disimpan:</strong> catatan moderasi dan laporan pengguna lain terhadap konten Anda, yang dilepaskan dari akun Anda, bila diperlukan untuk alasan keamanan atau hukum; serta data dalam cadangan terenkripsi sampai cadangan tersebut kedaluwarsa sesuai siklusnya. Jumlah main game yang anonim bukan data pribadi dan tidak terpengaruh.</p>
<p>Anda juga dapat meminta penghapusan data tertentu tanpa menghapus akun, melalui alamat yang sama.</p>

<h2 id="rights">8. Hak Anda</h2>
<p>
    Sesuai UU PDP dan hukum yang berlaku, Anda berhak memperoleh informasi tentang penggunaan data
    Anda, mengakses dan memperoleh salinannya, memperbaikinya, meminta penghapusan, menarik persetujuan,
    menolak atau membatasi pemrosesan tertentu, serta mengajukan pengaduan kepada otoritas yang berwenang.
    Sebagian besar profil dapat Anda ubah langsung di aplikasi. Untuk hal lainnya, hubungi kami di
    <a href="mailto:{{ $contact }}">{{ $contact }}</a>; kami akan menanggapi dalam jangka waktu yang ditentukan hukum.
</p>

<h2 id="children">9. Anak-anak</h2>
<p>
    {{ $legal['app_name'] }} tidak ditujukan untuk anak di bawah {{ $legal['minimum_age'] }} tahun, dan
    kami tidak dengan sengaja mengumpulkan data pribadi mereka. Jika Anda mengetahui anak di bawah
    {{ $legal['minimum_age'] }} tahun membuat akun, hubungi kami dan kami akan menghapusnya. Pengguna berusia
    {{ $legal['minimum_age'] }} tahun hingga belum dewasa menurut hukum negaranya harus menggunakan aplikasi
    dengan izin orang tua atau wali.
</p>

<h2 id="changes">10. Perubahan kebijakan</h2>
<p>
    Kami dapat memperbarui kebijakan ini. Tanggal di bagian atas menunjukkan kapan versi saat ini
    mulai berlaku. Jika perubahan secara material memengaruhi penggunaan data Anda, kami akan
    memberi tahu Anda melalui aplikasi atau email sebelum perubahan berlaku.
</p>

<h2 id="contact">11. Kontak</h2>
<p>
    {{ $legal['operator'] }}<br>
    Email: <a href="mailto:{{ $contact }}">{{ $contact }}</a><br>
    Situs web: <a href="{{ $legal['website'] }}" rel="noopener">{{ $legal['website'] }}</a>
</p>
<p>Jika terdapat perbedaan antara versi bahasa Indonesia dan versi bahasa Inggris, versi bahasa Indonesia yang berlaku.</p>
@endsection
