# VetDoğum

**Makine öğrenmesi destekli hayvan doğum takip ve risk sınıflandırma prototipi.**

Bu çalışma, **TÜBİTAK 2209-A kapsamında desteklenmeye kabul edilen**, Kütahya Dumlupınar Üniversitesi Bilgisayar Mühendisliği bitirme projemdir. Projeyi ekip arkadaşımla birlikte geliştirdim.

Gerçek hayvan verilerine erişimin sınırlı olduğu geliştirme aşamasında sentetik fizyolojik ve davranışsal verilerle model deneyleri yapılmış; bu çalışma Flutter tabanlı bir takip uygulaması ve FastAPI servisiyle bir araya getirilmiştir. Gelecekte gerçek sensör verileriyle genişletilmesi hedeflenmektedir.

## Projenin Amacı

Hayvan sahipleri ve veteriner hekimler için hayvan kayıtlarını, gebelik takvimini ve sağlık gözlemlerini bir arada takip edebilecekleri bir prototip geliştirmek; sentetik veri üzerinde farklı makine öğrenmesi yöntemlerini karşılaştırmak.

## Mevcut Özellikler

- Firebase Authentication ile e-posta/şifre üzerinden kayıt ve giriş.
- Hayvan sahibi ve veteriner için ayrı arayüzler.
- Hayvan bilgileri ve gözlem kayıtlarının Firestore üzerinde tutulması.
- Çiftleşme tarihi ve türe özgü gebelik süresinden hesaplanan tahmini doğum takvimi.
- Kullanıcı ve veteriner ekranlarında tahmin sonuçlarını görüntüleme akışı.
- Yedi hayvan türü: sığır, koyun, keçi, at, domuz, köpek ve kedi.
- Random Forest, XGBoost, MLP ve LSTM modelleriyle sentetik veri deneyleri.

## Teknolojiler

| Katman | Teknolojiler |
| --- | --- |
| Mobil arayüz | Flutter, Dart |
| Kimlik doğrulama ve veritabanı | Firebase Authentication, Cloud Firestore |
| API | Python, FastAPI, Uvicorn |
| Model geliştirme | NumPy, Pandas, scikit-learn, XGBoost, TensorFlow/Keras |
| Analiz | Matplotlib, Seaborn, SHAP |
| Deney ortamı | Google Colab / Jupyter Notebook |

## Depo Yapısı

```text
vetdogum/
├── mobile/                         # Flutter uygulaması
├── backend/
│   ├── main.py                     # FastAPI tahmin servisi
│   ├── requirements.txt            # API bağımlılıkları
│   └── saved_models/               # Yerelde üretilecek model dosyaları
└── notebooks/
    └── vetdogum_model.ipynb        # Veri üretimi, eğitim ve değerlendirme
```

## Çalıştırma

### 1. Model dosyalarını üretme

`notebooks/vetdogum_model.ipynb` dosyasını Google Colab'a yükleyin ve hücreleri sırayla çalıştırın. Eğitim zaman ve işlem gücü gerektirir. Notebook sentetik veriyi üretir, modelleri eğitir ve `saved_models` dizinine kaydeder. Kayıtlı hücre çıktıları temizlenmiştir; bu depoda yeni bir eğitim çalıştırılmış değildir.

Notebook'un ürettiği `scaler.pkl`, `rf_model.pkl`, `xgb_model.pkl` ve `mlp_model.pkl` dosyalarını `backend/saved_models/` dizinine kopyalayın. Model dosyaları bu depoya dahil değildir. `backend/requirements.txt` API ortamını tanımlar; notebook'un bütün eğitim bağımlılıklarını kapsamaz. Eğitim ve API ortamlarındaki model kütüphanesi sürümlerini eşleştirin.

### 2. API'yi yerelde çalıştırma

```bash
cd backend
python -m venv .venv
```

Windows PowerShell:

```powershell
.venv\Scripts\Activate.ps1
```

macOS / Linux:

```bash
source .venv/bin/activate
```

Ardından:

```bash
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

API belgeleri: `http://localhost:8000/docs`. Modeller yüklenmeden tahmin endpoint'i kullanılamaz. Önce `/health` yanıtındaki `scaler_loaded` ve `models_loaded` alanlarını kontrol edin; yalnızca HTTP 200 yanıtı modellerin hazır olduğunu göstermez.

### 3. Firebase yapılandırması

Bu depo kişisel Firebase proje ayarlarını içermez. Kendi test projenizi kullanın:

1. Firebase projesi oluşturun; Authentication bölümünde e-posta/şifre girişini ve Cloud Firestore'u etkinleştirin.
2. Flutter SDK'yı kurun. Projenin Dart SDK gereksinimi `^3.11.4` değeridir.
3. Firebase CLI ve FlutterFire CLI kurulumunu tamamlayıp kendi hesabınızla giriş yapın.
4. `mobile` dizininde aşağıdaki komutları çalıştırın:

```bash
flutter pub get
flutterfire configure
```

`flutterfire configure` ile kendi `lib/firebase_options.dart` dosyanızı ve seçtiğiniz platformların Firebase ayarlarını oluşturun. Android uygulama kimliği mevcut projede `com.example.veteriner_app` olarak tanımlıdır.

Firestore koleksiyonları: `users`, `animals`, `observations`, `predictions`. Bu depoda dağıtıma hazır Firestore güvenlik kuralları bulunmaz. Rol ve sahiplik kontrollerini güvenlik kurallarıyla tanımlamadan gerçek kullanıcı verileri kullanmayın.

### 4. Flutter uygulamasını başlatma

Web üzerinde yerel API ile:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Android emülatöründe bilgisayarınızdaki API adresi için `http://10.0.2.2:8000` kullanılır. Fiziksel cihazda bilgisayarınızın erişilebilir ağ adresini kullanın. Android'de yerel HTTP denemeleri için geliştirme ağ ayarları gerekebilir; dağıtımda HTTPS kullanın. Uygulama API adresini `API_BASE_URL` derleme parametresinden alır.

## Model Çalışması

Notebook 10.000 sentetik örnek ve 30 özellik üzerinden deneyler yapar; eğitim/doğrulama/test ayrımı %70/%15/%15'tir. SMOTE, hiperparametre arama, model karşılaştırma ve SHAP analizi içerir.

Tahmini doğum tarihi uygulamada takvim hesabıyla elde edilir. ML modeli ise sentetik `successful_birth` etiketini sınıflandırır; bağımsız bir doğum tarihi regresyon modeli değildir. Notebook'taki dört modelli deneyin aksine mevcut API üç modeli eşit ağırlıkla kullanır.

## Projenin Durumu

- Önceki canlı API hizmeti şu an aktif değildir; kaynak kod yerel kurulum için paylaşılmıştır.
- Çalışma bir araştırma prototipidir; gerçek sensör verileriyle doğrulanmış klinik bir ürün değildir.
- Canlı izleme ekranı geliştirme aşamasındadır. Push bildirimleri tamamlanmış özellikler arasında değildir.
- Eğitim, API ve mobil katman arasındaki alan ölçeklerinin ve sonuç şemasının uyumlandırılması geliştirme kapsamındadır.
- Model değerlendirme yönteminin iyileştirilmesi, rol yetkilendirmesi ve davranış testlerinin eklenmesi planlanmaktadır. Mevcut örnek test uygulama davranışını doğrulamaz.

## Gelecek Çalışmalar

- Gerçek sensör verileri ve gerçekleşen doğum sonuçlarıyla yeni veri seti oluşturma.
- Modelleri gerçek verilerle yeniden eğitme ve bağımsız olarak değerlendirme.
- Hayvan bazlı zaman serileriyle takip ve canlı izleme.
- Bildirim akışlarının tamamlanması.
- API sözleşme testleri ve Firebase erişim kurallarının test edilmesi.

## Geliştirme

**Duygu Erdoğan — ekip arkadaşımla birlikte geliştirilmiştir.**

Bu depo bitirme projesinin kaynak kodunu ve araştırma kapsamını portföy amacıyla sunar.
