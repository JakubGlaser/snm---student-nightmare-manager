# SNM Balance Mechanics

## Mechaniky a dopad na game loop

| Mechanika | Trigger / pravidlo | Dopad na game loop | Dopad na pozornost studentu |
|---|---|---|---|
| Level timer | Level trva `120 s`. Po dobehnuti zacne dalsi level. | Hlavni tlak hry: prezit do konce levelu s co nejvice aktivnimi studenty. | Neprimo zvysuje tlak, protoze studenti behem levelu prubezne ztraceji pozornost. |
| Start noveho levelu | Pri startu hry a po dokonceni kazdeho levelu. | Resetuje levelove efekty, obnovi special ability a zvedne obtiznost pres decay. | Aktivnim studentum nastavi nahodnou pozornost `50-79 %`. |
| Klesani pozornosti | Bezi kazdy frame u aktivnich studentu, pokud neni decay pozastaveny. | Zakladni fail pressure: student pri `0 %` vypadne a snizi pocet prezivajicich. | Skaluje s levelem: `lerp(1.0, 3.2, t)` /s, kde `t = clamp((level-1)/9, 0, 1)`. Level 1: `-1.0/s`, od levelu 10 strop `-3.2/s`. |
| Skupinovy debuff | Aktivuje se, kdyz student ve stejne skupine (question zona: left=[0,1,2], center=[3,4,5], right=[6,7,8], tj. `index / 3`) prijde o pozornost. | Smrt jednoho zaka mirne uspisi pad jeho spoluzaku ve stejne zone -> kaskadovy tlak. | Kazdy mrtvy spoluzak ve skupine pridava prezivsim `+0.4/s` decay (max `+0.8/s` pri dvou mrtvych). Drzi se i pres levely. |
| Bonusova pozornost | Pouziva se u otazky pres `add_bonus_focus`. | Bonus se chova jako docasny naskok, ktery mizi rychleji nez normalni pozornost. | Bonusova cast klesa dvojnasobne: `efektivni decay * 2`. Pozornost je capnuta na `100 %`. |
| Smrt studenta | Student dosahne `0 %` pozornosti. | Student je neaktivni, dal nedostava efekty a zmensi se stamina counter; prepocita se radovy debuff. | Pozornost se nastavi na `0 %`; student uz se v dalsich levelech nerestartuje. |
| Joke minigame | Tlacitko Joke, cooldown `lerp(30, 14, t) s`; minihra pauzne strom. Sweet spot a rychlost kurzoru se s levelem zostruji. | Kratka skill check akce, level timer a decay stoji behem minihry. | Uspech: vsichni `lerp(20, 26, t) %` krat action multiplier. Fail: vsichni `lerp(-8, -16, t) %`. |
| Fun fact minigame | Tlacitko Fun Fact, cooldown `lerp(45, 20, t) s`; minihra pauzne strom. | Vyber spravne zajimave hlasky, level timer a decay stoji behem minihry. | Uspech: vsichni `lerp(15, 22, t) %` krat action multiplier. Fail: vsichni `lerp(-8, -16, t) %`. |
| Question | Tlacitko Question, vyber leve / stredni / prave skupiny. Cooldown `lerp(2.5, 5.0, t) s` po dokonceni. | Nepauzuje cely level timer, ale zastavi decay vsem studentum po dobu vyberu a QTE. | Vybrana skupina dostane bonus `lerp(30, 42, t) %` krat action multiplier; bonusova cast potom klesa 2x rychleji. |
| Question QTE | Po vyberu skupiny se nahodne zobrazuje pismeno na jednom studentovi ze skupiny. | QTE pokracuje, dokud hrac nesplete pismeno nebo nevyprsi cas. Reakcni okno `lerp(2.2, 0.85, t) s`. | Pri QTE je decay vsem pozastaveny; samotny QTE uspech uz dalsi pozornost nepridava. |
| Special wheel | 1x za level; minihra pauzne strom. | Jednorazovy silny zasah do levelu, po pouziti je special tlacitko vypnute do dalsiho levelu. | Efekt podle vysledku special ability. |
| Sadluck AI slop | Vysledek special wheel. | Okamzita zachrana / velky reset aktualni situace. | Vsem aktivnim studentum nastavi pozornost na `120 %`. |
| Josef's tobacco | Vysledek special wheel, trva do konce levelu. | Zesiluje pozitivni hracovy akce v aktualnim levelu. | Joke/Fun Fact uspechy a Question bonus se nasobi `2x`; negativni efekty se nenasobi. |
| Cenek's endless speech | Vysledek special wheel, trva do konce levelu. | Level bezi rychleji, ale studenti neztraceji pozornost. | Pozornost vsem prestane klesat; `Engine.time_scale = 4.0`. |
| DJ's failed calculation | Vysledek special wheel. | Risk/reward: aktualni level zhorsuje, dalsi level silne pomaha. | Ted vsichni `-20 %`; na zacatku dalsiho levelu vsichni aktivni studenti dostanou `120 %`. |
| Menu | Otevreni menu. | Pauzne hru a zablokuje gameplay tlacitka. | Decay stoji, protoze je pausnuty SceneTree. |
| Itemy | Na startu kazdeho levelu se prida 1 nahodny item, dokud inventar nema 5 itemu. Hover item vybere a zobrazi popis, klik zobrazi hlasku u ucitele a uvolni slot. | Nova narativni vrstva bez mechanickeho efektu; zatim nezasahuje do obtiznosti. | Zatim zadny efekt na pozornost. |

## Tabulka klesani pozornosti podle levelu

Vzorec: `decay = lerp(1.0, 3.2, t)`, kde `t = clamp((level-1)/9, 0, 1)`. Od levelu 10 plato.

| Level | Klesani pozornosti |
|---|---:|
| 1 | `-1.00/s` |
| 2 | `-1.24/s` |
| 3 | `-1.49/s` |
| 4 | `-1.73/s` |
| 5 | `-1.98/s` |
| 6 | `-2.22/s` |
| 7 | `-2.47/s` |
| 8 | `-2.71/s` |
| 9 | `-2.96/s` |
| 10+ | `-3.20/s` |

S radovym debuffem muze efektivni decay byt az `+0.8/s` vyssi (dva mrtvi spoluzaci v rade).

## Cooldowny akci podle levelu

Vzorce pouzivaji stejne `t = clamp((level-1)/9, 0, 1)`.

| Akce | Level 1 | Level 10+ |
|---|---:|---:|
| Joke | `30 s` | `14 s` |
| Fun Fact | `45 s` | `20 s` |
| Question | `2.5 s` | `5.0 s` |

## Itemy

| Item | Tema | Hlaska | Efekt ted |
|---|---|---|---|
| TV speech bubble | Marshall McLuhan | The Medium is the Boss Fight. | Zadne |
| Film database | Lev Manovich | Database First, Narrative Later. | Zadne |
| Network city | Manuel Castells | I Don't Have Friends, I Have Nodes. | Zadne |
| Remediation book/screen | Bolter-Grusin | New Media: Now Remaking Old Media Again. | Zadne |
| Typewriter skull | Friedrich Kittler | Your Hardware Has Already Decided. | Zadne |
| Cyborg companion | Donna Haraway | Cyborgs Don't Do Natural. | Zadne |
| Media ecology terrarium | Matthew Fuller | There Is No Escape from Media Ecology. | Zadne |
| Infosphere compass | Luciano Floridi | Welcome to the Infosphere. Please Update Your Ethics. | Zadne |
| Telegraph bits | Claude Shannon | Less Noise, More Bits. | Zadne |
