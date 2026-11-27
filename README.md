# Monstereiland

Loop naar een monster en praat ermee. Kies een antwoord met de stick of met W en S. Druk op SR, A of de spatiebalk om te antwoorden. Je kunt ook op een antwoord klikken. Je mag rustig nadenken en opnieuw proberen.

| Monster | Gebied | Vriendenproef | Schat |
| --- | --- | --- | --- |
| Flamelingo | Vuurweide | Plus en min | Telraam |
| AquaPouch | Watervalplas | Dieren | Parelschelp |
| BlazeGlyph | Lavakloof | Ruimte | Ringplaneet |
| CycloVolt | Zonnekaap | Keer en deel | Gouden dobbelsteen |
| SpiralButterfly | Vlindertuin | Vlaggen | Reisvlag |

Elk gebied heeft vier bewoners. Niveau 1 begint eenvoudig. Bij niveau 4 ontmoet je een glinsterend monster. Voor een gewone vriend beantwoord je drie vragen goed, voor een glinsterende vijf. In het [vragenboek voor ouders](Vragenboek.html) staan de vragen, antwoorden en rekenregels per bewoner. Het spel leest de [vragenbank](game/data/vragen.json) bij het opstarten. Na wijzigingen maak je het boek opnieuw met `python3 tools/vragenboek.py`.

## Build

```
godot --headless --path game --export-release Web ../docs/index.html
```

## Spelen

Open `game/project.godot` in Godot 4.5.1 of 4.7.2 en druk op F5. Houd een losse linker-Joy-Con dwars met de stick links en de SL- en SR-knoppen boven.

| Actie | Losse linker-Joy-Con | Twee Joy-Cons | Toetsenbord |
| --- | --- | --- | --- |
| Lopen | Stick | Linkerstick | WASD |
| Rondkijken | Vier knoppen op de voorkant | Rechterstick | Sleep met de rechtermuisknop |
| Praten, antwoorden of iets uitproberen | SR | A | Spatie |
| Rennen | Houd SL vast | Houd L vast | Houd Ctrl vast |
| Springen | Druk op de stick, of houd SL vast en tik op SR | B | Shift |
| Eilandboek openen of sluiten | Min | Menu | Tab |
| Kaart in het boek | Druk op de stick | B | Shift |
| Opnieuw oefenen met een vriend in het boek | SL | L | Ctrl |

Blader in het boek naar een gebied en kies een vriend die mee mag. Je kunt vijf vrienden tegelijk meenemen. Elke nieuwe vriendschap, schat en stempel wordt meteen bewaard. Loop naar de mat bij het huisje om ook de laatste veranderingen in je team te bewaren. De volgende keer begin je bij het huisje. Gebruik voor de browserversie dezelfde browser en hetzelfde adres.

Zoek op de kaart de vijf ontdekplekjes. Probeer iets uit voor een stempel. Bij vijf stempels hangt er een gouden kompas bij het huisje. Volg de keitjes naar de Sterrenheuvel. Met de kijker kun je acht planeten zien. Met de springknop of een klik op **Sterren tekenen** open je het sterrenboek. Verbind de sterren op volgorde voor de Steelpan, Cassiopeia en een eigen ruimteraket. Je tekeningen worden automatisch bewaard. Heb je alle vijf de schatten, kijk dan nog eens naar de hemel.

Zijn alle vier de bewoners van een gebied je vriend? Dan krijgt je huisje een vaantje met hun portret. Met alle twintig vrienden is het feest bij het huisje.

Op het Schildpadstrand liggen drie gespikkelde eitjes. Kijk wie eruit komt en loop samen langs de sporen naar zee.

Tussen het huisje en de Watervalplas glinstert iets in het gras. Richt het licht van drie kristallen op de steen in de bron. In de wei langs het pad naar de Sterrenheuvel hangt een vlieger met een kapotte staart. Zoek de drie strikken en ga terug naar de paal. Je eerste meelopende monster mag de vlieger dragen. Bij de paal kun je hem weer inhalen. Elke vondst wordt bewaard.

In het **Echobos**, tussen het huisje en de Vlindertuin, speel je een bel en zweeft je monster naar de trommel om antwoord te geven. Bij elke nieuwe klank komt er een vogel bij. Bij de **Vogelpost** op weg naar de Lavakloof draagt je vriend twee brieven, één per tocht. Volg de gele stenen naar het Zonnehuis of de blauwe naar het Maanhuis. Geef onder het juiste vogelhuisje een seintje en je vriend vliegt naar de hoge brievenbus.

## Emberflame Island

Volg de oostkust van Vareneiland naar de houten steiger. Aan het eind stap je met de praatknop op de veerboot. Je team vaart mee. Op de eilandkaart staat de terugreis aangegeven. Vanaf de steiger zie je de twee vulkanen aan de overkant.

Emberflame heeft vijf soorten: Sylvendra in Emberwood Forest, Voltaris op Fire Ridge, Voltarium in Ignis Grotto, Aurelon aan Sunflame Shores en Gyralune in Flarefell Marsh. Elk gebied heeft één bewoner per niveau. Alleen niveau 4 is shiny. In Emberwood Forest krijg je vragen over eten, op Fire Ridge ontdek je hoe vulkanen werken, in Ignis Grotto verken je de Nederlandse geschiedenis, aan Sunflame Shores oefen je aardrijkskunde en in Flarefell Marsh speel je een sportquiz. In het eilandboek zie je de bewoners en ontdekkingen van je huidige eiland. Open de kaart met Shift en kies de knop onderaan (of druk op de praatknop) om met je team naar de andere aanlegsteiger te reizen. De teller bovenin telt de vrienden van het eiland waar je loopt.

Een nieuw spel in de editor begint aan de steiger op Emberflame. Een nieuw spel in de geëxporteerde versie begint op Vareneiland. Na het laden van een bewaard spel begin je op het laatst bezochte eiland. Om tijdens de ontwikkeling direct met je bestaande team op Emberflame te beginnen, gebruik je `godot --path game -- --emberflame`.

## In de browser

Installeer via **Editor → Manage Export Templates** de exportsjablonen die precies bij je Godot-versie passen. Het Web-profiel gebruikt WebGL 2 en WebAssembly zonder extra threads. Voer in de hoofdmap uit:

```sh
mkdir -p build/web
godot --headless --editor --path game --import
godot --headless --path game --export-release Web ../build/web/index.html
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

Open [het spel](http://127.0.0.1:8765/). Druk bij een controller na het laden eerst op een knop. Om het spel te delen zet je de hele inhoud van `build/web/` op een statische HTTPS-website die wasm-bestanden serveert als `application/wasm`.

## Testen

Met `godot --headless --fixed-fps 60 --path game --script res://tests/playthrough.gd` speel je het eiland automatisch door met een afzonderlijk testbestand. Haal voor schermafbeeldingen `--headless` weg en voeg `-- --captures=/absoluut/pad/naar/bestaande/map` toe. De oorspronkelijke tekeningen staan in `assets/`.
