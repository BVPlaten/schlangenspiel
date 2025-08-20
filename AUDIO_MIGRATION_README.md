# Audio-System Migration zu OOP-Ansatz

## Übersicht

Das Musiksteuerungssystem wurde von einem prozeduralen Ansatz zu einem objektorientierten Design migriert. Die neue Struktur bietet bessere Erweiterbarkeit, Wiederverwendbarkeit und klare Trennung der Verantwortlichkeiten.

## Neue Klassen

### 1. AudioManager (AudioManager.gd)
**Hauptklasse für Audio-Steuerung**

- **OOP-Design**: Nutzt eine interne `AudioCategory`-Klasse
- **Erweiterbar**: Neue Audio-Kategorien können einfach hinzugefügt werden
- **Signal-basiert**: Emitted `volume_changed` Signale bei Änderungen
- **Persistent**: Speichert Einstellungen automatisch

**Verwendung:**
```gdscript
# AudioManager ist als Singleton verfügbar
var audio_manager = get_tree().get_root().get_node("AudioManager")

# Standard-Methoden
audio_manager.set_music_volume(8)
audio_manager.set_sfx_volume(5)

# Erweiterte Methoden
audio_manager.add_category("Ambient", 7)
audio_manager.set_volume("Ambient", 3)
```

### 2. AudioCategory (interne Klasse)
**Repräsentiert eine Audio-Kategorie**

- Kapselt alle Eigenschaften einer Audio-Kategorie
- Berechnet automatisch dB-Werte aus normalisierter Lautstärke
- Unterstützt individuelle Min/Max-Werte pro Kategorie

### 3. GlobalSettingsAdapter (GlobalSettingsAdapter.gd)
**Rückwärtskompatibler Adapter**

- Ermöglicht sanfte Migration ohne Code-Änderungen
- Lädt alte Einstellungen automatisch
- Bietet neue erweiterte Funktionen

## Migrationsschritte

### 1. Automatische Migration
- Alte `settings.json` wird automatisch in `audio_settings.json` konvertiert
- Backup wird als `settings_backup.json` erstellt
- Keine manuellen Eingriffe erforderlich

### 2. Neue Struktur
```
Alte Struktur:
├── tools/GlobalSettings.gd (Singleton)
├── Prozedurale Methoden
└── Feste Music/SFX Busse

Neue Struktur:
├── AudioManager.gd (Singleton)
├── AudioCategory (OOP-Klasse)
├── Erweiterbare Kategorien
└── Signal-basierte Kommunikation
```

## Vorteile des neuen Systems

### 1. Erweiterbarkeit
```gdscript
# Neue Kategorie hinzufügen
audio_manager.add_category("VoiceChat", 8, 10, 0)

# Mehrere Kategorien verwalten
var categories = ["Music", "SFX", "Ambient", "VoiceChat"]
for cat in categories:
    audio_manager.set_volume(cat, 5)
```

### 2. Wiederverwendbarkeit
- Die `AudioCategory`-Klasse kann in anderen Projekten verwendet werden
- Konfigurierbare Min/Max-Werte pro Kategorie
- Automatische dB-Berechnung

### 3. Klare Verantwortlichkeiten
- **AudioManager**: Verwaltet alle Kategorien und Persistenz
- **AudioCategory**: Kapselt Kategorie-spezifische Logik
- **GlobalSettingsAdapter**: Sorgt für Kompatibilität

## API-Referenz

### AudioManager Methoden
```gdscript
# Basis-Methoden
set_volume(category_name: String, volume: int) -> bool
get_volume(category_name: String) -> int
add_category(category_name: String, default_volume: int = 10, max_volume: int = 10, min_volume: int = 0) -> bool

# Komfort-Methoden
set_music_volume(volume: int) -> bool
set_sfx_volume(volume: int) -> bool
get_music_volume() -> int
get_sfx_volume() -> int

# Verwaltung
apply_all_volumes()
apply_volume(category_name: String) -> bool
```

### Signal
```gdscript
# Verbinden mit Volumenänderungen
audio_manager.volume_changed.connect(_on_volume_changed)

func _on_volume_changed(category_name: String, new_volume: int):
    print("Volume changed: %
