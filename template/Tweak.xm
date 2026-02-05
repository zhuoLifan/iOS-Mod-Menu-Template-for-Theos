#import "Macros.h"
#import <mach-o/dyld.h>

// --- SENİN VERDİĞİN OFFSELER ---
#define OFF_W2VP    0x1638dd4
#define OFF_GMAIN   0x163a384
#define OFF_GTRANS  0x167f570
#define OFF_GPOS    0x1694170
#define OFF_TYPINFO 0x46ed358  // typinfoAddr offsetin
#define OFF_HEALTH  0x108      // Can değeri

// UnityFramework'ü bulma (getBase mantığı)
uintptr_t get_UnityFramework() {
    // Critical Ops'ta genelde UnityFramework image index'i değişebilir
    // Ama genelde 0 veya executable'dır.
    return (uintptr_t)_dyld_get_image_header(0);
}

// --- MENÜ ---
void setupMenu() {
    [menu setFrameworkName:"Anıl C-OPS"];
    [switches addSwitch:NSSENCRYPT("ESP Aktif") description:NSSENCRYPT("Düşmanları Gör")];
}

// --- SENİN ZİNCİR MANTIĞIN (Pointer Chain) ---
void RunLogic() {
    if(![switches isSwitchOn:NSSENCRYPT("ESP Aktif")]) return;

    uintptr_t base = get_UnityFramework();
    
    // 1. Adım: TypInfo Adresini bul
    uintptr_t typInfoAddr = base + OFF_TYPINFO;
    
    // 2. Adım: gameModuleInstance (Senin verdiğin mantık)
    void* gameModuleInstance = *(void**)(typInfoAddr);
    if (!gameModuleInstance) return;
    
    // 3. Adım: gameSystem (+0x30)
    void* gameSystem = *(void**)((uint64_t)gameModuleInstance + 0x30);
    if (!gameSystem) return;
    
    // 4. Adım: characters Listesi (+0xD0)
    void* charactersList = *(void**)((uint64_t)gameSystem + 0xD0);
    if (!charactersList) return;
    
    // Unity List yapısı: Size genelde 0x18'dedir, elemanlar 0x20'den başlar (Array pointer)
    int count = *(int*)((uint64_t)charactersList + 0x18);
    uintptr_t items = (uintptr_t)charactersList + 0x20; // Items array

    // Döngü
    for (int i = 0; i < count; i++) {
        // Her karakteri çek
        void* character = *(void**)(items + (i * 0x8));
        if (!character) continue;
        
        // 5. Adım: Can Değeri (+0x108)
        int health = *(int*)((uint64_t)character + OFF_HEALTH);
        
        // Canlıysa işlem yap (Burada çizim fonksiyonu çağrılır)
        if (health > 0 && health <= 1000) {
            // Düşman tespit edildi!
        }
    }
}

// --- HOOK (Oyunun içine sızma) ---
%hook PlayerAdapter
- (void)Update {
    %orig;      // Oyunun orijinal kodunu bozma
    RunLogic(); // Bizim kodumuzu çalıştır
}
%end

%ctor {
    setupMenu();
}
