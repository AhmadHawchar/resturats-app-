# 🍔 FoodApp — Multi-Role Food Ordering App

A cross-platform mobile food-ordering application built with **Flutter** and a real-time **Firebase** backend. It supports three distinct user roles — **customers**, **restaurant owners**, and a **platform admin** — each with its own tailored interface and permissions.

<p align="left">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.29-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.6-0175C2?logo=dart&logoColor=white">
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black">
  <img alt="Platform" src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey">
</p>

> The Flutter project lives in the [`foodapp-master/`](foodapp-master/) directory.

---

## ✨ Features

- **Role-based authentication** (customer / restaurant / owner) via Firebase Auth, with a dedicated onboarding and dashboard for each role.
- **Browse & order** — explore restaurants and menus by category, view food details, and place orders in real time.
- **Restaurant management** — owners add and edit menu items (with image upload), manage opening hours, and process incoming orders.
- **Favourites** — customers save and revisit their favourite dishes.
- **Order tracking** — customers and restaurants both see live order status backed by Cloud Firestore.
- **Location & maps** — set and visualise a delivery address using interactive maps (OpenStreetMap), GPS geolocation, and reverse geocoding.
- **Direct WhatsApp ordering** — deep-link to a restaurant's WhatsApp to confirm an order.
- **Commission system** — each order automatically credits a configurable platform-owner account.
- **Polished UX** — cached network images, shimmer loading placeholders, custom page transitions, and Lottie animations.

---

## 🛠️ Tech Stack

| Area | Technology |
|------|------------|
| Framework | Flutter (Dart 3.6+) |
| Auth | `firebase_auth` |
| Database | `cloud_firestore` (real-time) |
| Maps / Location | `flutter_map`, `geolocator`, `geocoding`, `latlong2` |
| Media | `image_picker`, `cached_network_image`, ImgBB hosting |
| Config | `flutter_dotenv` (secrets in a gitignored `.env`) |
| UI polish | `google_fonts`, `shimmer`, `lottie`, `animate_do`, `circle_nav_bar` |

---

## 📁 Project Structure

```
foodapp-master/lib/
├── main.dart                 # App entry — loads .env, initialises Firebase
└── pages/
    ├── auth/                 # Role-based auth flows
    │   ├── client/           #   customer login / signup / profile setup
    │   ├── owner/            #   owner login + dashboard
    │   └── restaurant/       #   restaurant login / signup / admin panel
    ├── navbar_pages/         # Home, restaurants, favourites, orders, profile
    ├── food_info.dart        # Dish details + order placement
    └── splash_screen.dart
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.29+ (Dart 3.6+)
- A Firebase project (Authentication + Cloud Firestore enabled)
- An [ImgBB](https://api.imgbb.com/) API key (for image uploads)

### Setup

```bash
# 1. Clone and enter the Flutter project
git clone https://github.com/AhmadHawchar/resturats-app-.git
cd resturats-app-/foodapp-master

# 2. Install dependencies
flutter pub get

# 3. Configure secrets
cp .env.example .env
#   then open .env and fill in your Firebase + ImgBB values

# 4. Run
flutter run
```

### Environment variables
All secrets and deploy-specific config are loaded from a **gitignored** `.env` file (see [`.env.example`](foodapp-master/.env.example)):

| Key | Description |
|-----|-------------|
| `FIREBASE_API_KEY` … `FIREBASE_STORAGE_BUCKET` | Firebase project configuration |
| `IMGBB_API_KEY` | ImgBB image-hosting key |
| `PLATFORM_OWNER_ID` | Firestore doc id of the owner account that receives commissions |

---

## 📸 Screenshots

_Add screenshots or a short demo GIF here._

| Home | Restaurant | Order |
|------|------------|-------|
| _coming soon_ | _coming soon_ | _coming soon_ |

---

## 📄 License

This project is available under the MIT License.
