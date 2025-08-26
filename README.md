# 📱 Keuanganku

**Keuanganku** adalah aplikasi pelacak pengeluaran pribadi berbasis **Flutter** dengan backend **Supabase**.  
Tujuannya membantu pengguna mengelola keuangan sehari-hari dengan tampilan modern, responsif, dan mudah digunakan.

---

## 📸 Screenshot
<p align="center">
  <img src="assets/readme/1.png" width="200"/>
  <img src="assets/readme/2.png" width="200"/>
  <img src="assets/readme/3.png" width="200"/>
</p>
<p align="center">
  <img src="assets/readme/4.png" width="200"/>
  <img src="assets/readme/5.png" width="200"/>
  <img src="assets/readme/6.png" width="200"/>
</p>

---

## ✨ Fitur Utama
- **Autentikasi Aman**  
  Login & register via Email/Password atau Google (Supabase Auth).  
  Navigasi otomatis sesuai status login.

- **Dashboard Modern**  
  - Ringkasan pengeluaran bulanan  
  - 3 transaksi terbaru  
  - Slider tips keuangan dinamis  

- **Manajemen Transaksi (CRUD)**  
  - Tambah, edit, hapus, dan lihat semua pengeluaran  
  - Swipe-to-delete & edit transaksi  

- **Laporan & Visualisasi Data**  
  - Grafik garis: tren pengeluaran harian  
  - Grafik pie: persentase kategori  
  - Filter bulan dengan navigasi panah  

- **Profil & Kategori**  
  - Ubah nama, kata sandi, dan foto profil  
  - Tambah/hapus kategori pengeluaran  

---

## 🚀 Cara Menjalankan Proyek

1. **Clone Repository**
   ```bash
   git clone https://github.com/skimatt/KeuanganKu.git
   cd KeuanganKu
Install Dependencies

bash
Salin
Edit
flutter pub get
Setup Supabase

Buka file .env (atau buat baru jika belum ada)

Tambahkan kode berikut dengan data dari Supabase Project:

env
Salin
Edit
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=your-anon-key
Jalankan Aplikasi

bash
Salin
Edit
flutter run
🛠️ Teknologi yang Digunakan
Flutter (Frontend, UI/UX)

Supabase (Auth, Database, Storage)

StreamBuilder (state real-time pada autentikasi & dashboard)

📖 Ringkasan
Proyek Keuanganku dirancang sebagai contoh aplikasi mobile modern:

UI/UX estetik

Backend realtime yang kuat

Fitur lengkap (auth, CRUD, laporan, profil)

Cukup clone repo, atur .env, lalu jalankan Flutter – dan aplikasi siap dipakai 🚀

📄 Lisensi
MIT License © 2025 Rahmat Mulia

