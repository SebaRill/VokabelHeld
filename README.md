# 🦸 Vokabelheld

Offline-Vokabeltrainer für Kinder (8–12 Jahre), Englisch ⇄ Deutsch.
Flutter · Material 3 · Provider · SQLite · Google ML Kit (lokale OCR).

**Komplett offline:** keine Cloud, keine Konten, keine Werbung, keine Kosten.
Alle Daten liegen in einer SQLite-Datei im App-Speicher des Tablets.

## Funktionen

| # | Funktion | Wo im Code |
|---|----------|-----------|
| 1 | Lektionen anlegen / umbenennen / löschen, Wortanzahl | `lessons_screen.dart`, `lesson_provider.dart` |
| 2 | Foto aufnehmen oder aus Galerie wählen | `import_screen.dart`, `import_provider.dart` |
| 3 | OCR (ML Kit, on-device) | `services/ocr_service.dart`, `ocr_layout.dart` |
| 4 | Parser mit mehreren Regelsätzen | `domain/vocabulary_parser.dart` |
| 5 | Korrekturansicht (z. B. `h0use` → `house`) | `import_screen.dart`, `domain/ocr_corrector.dart` |
| 6 | Lokale Speicherung (SQLite) | `data/` |
| 7 | Lernmodus (Karteikarten, EN→DE / DE→EN, ✔/✖) | `flashcard_screen.dart`, `study_provider.dart` |
| 8 | Multiple Choice (4 gemischte Antworten) | `quiz_screen.dart` |
| 9 | Lernlevel 0–4 + gewichtete Zufallsauswahl | `study_provider.dart`, `domain/weighted_selector.dart` |
| 10 | Statistik pro Lektion | `widgets/stats_card.dart`, `lesson.dart` |

## Projektstruktur

```
lib/
├─ main.dart                  Einstieg, Dependency Injection (MultiProvider)
├─ app.dart                   MaterialApp (Material 3, deutsch)
├─ core/                      Theme, Konstanten (Level 0–4), Formatierer
├─ data/                      DATENHALTUNG
│  ├─ models/                 Lesson, LessonStats, VocabularyEntry
│  ├─ database/               SQLite-Schema (sqflite)
│  └─ repositories/           LessonRepository, VocabularyRepository
├─ domain/                    BUSINESS-LOGIK (reines Dart, testbar)
│  ├─ vocabulary_parser.dart  OCR-Text → Vokabelpaare
│  ├─ ocr_corrector.dart      Korrekturvorschläge
│  └─ weighted_selector.dart  gewichtete Zufallsauswahl
├─ services/                  OCR (ML Kit) + Zeilen-/Spaltenerkennung
├─ providers/                 ZUSTAND (ChangeNotifier)
└─ ui/                        OBERFLÄCHE
   ├─ screens/                Lektionen, Detail, Lernen, Quiz, Foto-Import
   └─ widgets/                Dialoge, Statistik-Karte, Level-Chip, ...
test/                         Unit-Tests für Parser und Auswahl
```

Schichten: **UI → Provider → Repository → SQLite**. Die UI kennt keine SQL-Befehle,
die Repositories kennen keine Widgets.

## Datenmodell

```
lessons     (id, name, created_at)
vocabulary  (id, lesson_id → lessons.id ON DELETE CASCADE, english_word,
             german_word, correct_count, wrong_count, level 0..4, last_asked)
```

## Lernalgorithmus

* Level: 0 Neu · 1 Unsicher · 2 Bekannt · 3 Gut · 4 Beherrscht
* Richtig: Level +1, falsch: Level −1 (begrenzt auf 0..4)
* Gewichtete Auswahl: Gewicht je Level `[10, 7, 4, 2, 1]` – ein neues Wort kommt
  ca. 10× so oft dran wie ein beherrschtes. Dasselbe Wort kommt nie zweimal
  direkt hintereinander (außer die Lektion hat nur ein Wort).
* Lernfortschritt = Summe aller Level ÷ (Wörter × 4)
* Fehlerquote = falsche Antworten ÷ alle Antworten
* Beherrscht = Wörter auf Level 4

## Parser-Regeln (Reihenfolge)

1. Tab-Spalten (aus der OCR-Zeilenerkennung), auch 2 Paare pro Zeile
2. Führende Nummer entfernen (`1 dog Hund`, `2. cat Katze`)
3. Trenner ` - `, ` – `, `=`, `:`, `|`, `;`
4. Beginnt mit `to / a / an / the` → die ersten zwei Wörter sind Englisch
5. Erstes großgeschriebenes Wort nach klein geschriebenen = Anfang des deutschen Nomens (`ice cream Eis`)
6. Genau zwei Wörter → links Englisch, rechts Deutsch
7. Notlösung (als ⚠️ „unsicher“ markiert)

Unsichere Einträge (Ziffern/Sonderzeichen im Wort, leere Seite, Notlösung) werden in
der Korrekturansicht orange hervorgehoben, mit Vorschlag zum Übernehmen.

---

## Installation unter Windows

### 1. Voraussetzungen
1. **Flutter SDK** (stable) von <https://docs.flutter.dev/get-started/install/windows/mobile>
   herunterladen, z. B. nach `C:\src\flutter` entpacken (kein Pfad mit Leerzeichen,
   nicht unter `C:\Program Files`).
2. `C:\src\flutter\bin` zur Umgebungsvariable **Path** hinzufügen
   (Windows-Suche → „Umgebungsvariablen bearbeiten“ → Path → Neu).
3. **Git for Windows** installieren (<https://git-scm.com/download/win>).
4. **Android Studio** installieren, beim ersten Start den Setup-Assistenten
   durchlaufen (installiert Android SDK). Dann in Android Studio:
   *Settings → Languages & Frameworks → Android SDK → Tab „SDK Tools“* →
   **Android SDK Command-line Tools (latest)** aktivieren → Apply.
5. Eingabeaufforderung / PowerShell öffnen:
   ```
   flutter doctor --android-licenses
   flutter doctor
   ```
   Bei „Android toolchain“ muss ein Haken sein. (Visual Studio wird für Android **nicht** benötigt.)
6. Optional: **VS Code** mit der Erweiterung „Flutter“.

### 2. Projekt einrichten
Diese ZIP-Datei enthält nur `lib/`, `test/`, `pubspec.yaml` usw.; der Android-Ordner
wird von Flutter erzeugt:

```
cd C:\dev
flutter create --org de.vokabelheld --project-name vokabelheld --platforms android vokabelheld
```

Danach den **Inhalt dieses Pakets** in den neuen Ordner `C:\dev\vokabelheld` kopieren
und alle Dateien **überschreiben** (`lib\`, `test\`, `pubspec.yaml`, `analysis_options.yaml`, `README.md`).
Lösche außerdem `test\widget_test.dart`, falls sie noch existiert.

### 3. Android-Einstellung (wichtig für ML Kit)
In `android\app\build.gradle.kts` (oder `build.gradle`) bei `defaultConfig`:

```kotlin
minSdk = 21        // Groovy-Variante: minSdkVersion 21
```

### 4. Abhängigkeiten laden und testen
```
cd C:\dev\vokabelheld
flutter pub get
flutter test
flutter analyze
```

### 5. Auf dem Tablet ausprobieren
Tablet per USB anschließen (siehe unten, USB-Debugging), dann:
```
flutter devices
flutter run
```

## Build für das Amazon Fire Tablet

### APK bauen
```
flutter build apk --release
```
Ergebnis: `build\app\outputs\flutter-apk\app-release.apk`

Hinweis: Viele Fire-Tablets nutzen ein 32-Bit-Android (armeabi-v7a), obwohl die CPU
64-Bit kann. Der normale `flutter build apk` enthält beide Varianten und läuft daher
überall. Nicht `--split-per-abi` verwenden, solange du die Architektur nicht kennst.

Die Release-APK wird ohne eigenen Schlüssel mit dem Debug-Schlüssel signiert. Für die
private Nutzung per Sideload reicht das. (Für einen Store bräuchte man ein eigenes Keystore.)

### Auf dem Fire-Tablet installieren

**Variante A – Datei kopieren (einfach)**
1. Fire-Tablet: *Einstellungen → Sicherheit (bzw. „Sicherheit & Datenschutz“) →
   „Apps unbekannter Herkunft“* für den Datei-Manager bzw. Silk-Browser erlauben
   (Menüname je nach Fire-OS-Version leicht unterschiedlich).
2. Tablet per USB an den PC anschließen, `app-release.apk` in den Ordner
   „Dokumente“/„Downloads“ kopieren.
3. Auf dem Tablet mit der Dateien-App/Docs-App öffnen → *Installieren*.

**Variante B – per ADB (für Entwickler)**
1. Fire-Tablet: *Einstellungen → Geräteoptionen → Über das Fire-Tablet* →
   7× auf „Seriennummer“ tippen → *Entwickleroptionen → USB-Debugging* einschalten.
2. Tablet per USB anschließen, Debugging-Abfrage bestätigen.
3. ```
   adb devices
   adb install -r build\app\outputs\flutter-apk\app-release.apk
   ```
   (`adb` liegt in `%LOCALAPPDATA%\Android\Sdk\platform-tools`, ggf. zum Path hinzufügen.)

## OCR-Hinweise

* Es wird die **gebündelte** ML-Kit-Texterkennung (Latin) verwendet. Sie läuft lokal
  und benötigt keine Internetverbindung. Wenn ein Fire-Tablet die Texterkennung
  dennoch verweigert, bitte die Fehlermeldung in der App ansehen.
* Beste Ergebnisse: gutes Licht, Seite gerade, nur die Wörterliste im Bild,
  keine Schatten. Zwei-Spalten-Tabellen (Englisch | Deutsch) werden über die
  Zeilenhöhe zu Paaren zusammengeführt.
* OCR ist nie perfekt – deshalb gibt es immer die Korrekturansicht vor dem Speichern.

## Fehlerbehebung

| Problem | Lösung |
|---|---|
| `flutter doctor` meldet fehlende Lizenzen | `flutter doctor --android-licenses` und alles mit `y` bestätigen |
| „minSdkVersion 16 cannot be smaller than 21“ | `minSdk = 21` in `build.gradle.kts` setzen (Schritt 3) |
| Kamera öffnet sich nicht | Prüfen, ob das Gerät eine Kamera-App hat; alternativ „Aus Galerie wählen“ |
| `flutter test` bricht bei `widget_test.dart` ab | Datei `test\widget_test.dart` löschen |
| Gradle-Download hängt | Erstes Bauen lädt viel (ca. 1 GB), einmalig Internet nötig |

Die **App selbst** braucht nie Internet. Nur das Bauen (Pakete, Gradle) benötigt es einmalig.
