#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>

// --- 1. AYARLAR VE OFSETLER (Senin Verdiğin Sayılar) ---
#define OFFSET_WorldToViewportPoint 0x1638dd4
#define OFFSET_get_main 0x163a384
#define OFFSET_get_transform 0x167f570
#define OFFSET_get_position 0x1694170
#define OFFSET_get_health 0x108 

// UnityFramework'ü bulma fonksiyonu
uintptr_t get_UnityFramework() {
    return (uintptr_t)_dyld_get_image_header(0);
}

// --- 2. GEREKLİ YAPILAR ---
struct Vector3 { float x, y, z; };

// --- 3. FONKSİYON TANIMLARI ---
void* (*Camera_get_main)();
Vector3 (*Transform_get_position)(void* transform);
void* (*Component_get_transform)(void* component);
Vector3 (*Camera_WorldToViewportPoint)(void* camera, Vector3 position);

// --- 4. ESP MANTIĞI (RADAR) ---
// Bu fonksiyon oyunun içinde sürekli çalışacak
void RunESP() {
    uintptr_t base = get_UnityFramework();
    
    // Senin verdiğin zincir (Chain)
    // NOT: 0x46ed358 statik bir adres, base'e eklenerek bulunur.
    uintptr_t typinfoAddr = base + 0x46ed358; 
    
    // Zinciri takip et
    void* gameModuleInstance = (void*)*(uintptr_t*)typinfoAddr; 
    if (!gameModuleInstance) return;

    auto gameSystem = *(void **)((uint64_t)gameModuleInstance + 0x30);
    if (!gameSystem) return;

    auto characterList = *(void **)((uint64_t)gameSystem + 0xD0);
    if (!characterList) return;

    int count = *(int*)((uint64_t)characterList + 0x18);
    void* mainCam = Camera_get_main();
    if (!mainCam) return;

    uintptr_t items = (uintptr_t)characterList + 0x20; 

    for (int i = 0; i < count; i++) {
        void* character = *(void**)(items + (i * 0x8)); 
        if (!character) continue;

        // Canı kontrol et (0x108)
        int health = *(int *)((uint64_t)character + 0x108);
        if (health <= 0 || health > 1000) continue; // Ölüleri veya hatalı verileri geç

        // Pozisyonu al
        void* transform = Component_get_transform(character);
        Vector3 pos = Transform_get_position(transform);
        
        // Ekrana yansıt (W2VP)
        Vector3 screenPos = Camera_WorldToViewportPoint(mainCam, pos);

        // --- ÇİZİM İŞLEMİ ---
        // Eğer düşman kameranın önündeyse (z > 0)
        if (screenPos.z > 0) {
            // BURASI ÖNEMLİ: Ekrana basit bir kırmızı kutu (UIView) ekleme mantığı
            // Normalde burada Menu'nun Draw fonksiyonu çağrılır.
            // Şimdilik sadece log atıyoruz (Crash olmasın diye)
            // NSLog(@"Düşman Görüldü: X:%f Y:%f", screenPos.x, screenPos.y);
        }
    }
}

// --- 5. HOOK (KONTAK ANAHTARI) ---
// Oyundaki "PlayerAdapter" sınıfının "Update" fonksiyonuna kanca atıyoruz.
// Oyun her karede bu fonksiyonu çalıştırır, biz de araya kendi kodumuzu sokarız.

%hook PlayerAdapter

// Update fonksiyonu her karede çalışır
- (void)Update {
    %orig; // Oyunun orijinal kodunu çalıştır (Bozulmasın)
    
    RunESP(); // BİZİM KODUMUZU ÇALIŞTIR
}

%end

// --- 6. BAŞLATMA (CTOR) ---
%ctor {
    uintptr_t base = get_UnityFramework();

    // Fonksiyon adreslerini hesapla
    Camera_get_main = (void* (*)()) (base + OFFSET_get_main);
    Transform_get_position = (Vector3 (*)(void*)) (base + OFFSET_get_position);
    Component_get_transform = (void* (*)(void*)) (base + OFFSET_get_transform);
    Camera_WorldToViewportPoint = (Vector3 (*)(void*, Vector3)) (base + OFFSET_WorldToViewportPoint);
}
