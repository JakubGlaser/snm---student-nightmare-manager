# SNM Balance Mechanics

## Mechaniky a dopad na game loop

| Mechanika | Trigger / pravidlo | Dopad na game loop | Dopad na pozornost studentu |
|---|---|---|---|
| Level timer | Level trva `120 s`. Po dobehnuti zacne dalsi level. | Hlavni tlak hry: prezit do konce levelu s co nejvice aktivnimi studenty. | Neprimo zvysuje tlak, protoze studenti behem levelu prubezne ztraceji pozornost. |
| Start noveho levelu | Pri startu hry a po dokonceni kazdeho levelu. | Resetuje levelove efekty, obnovi special ability a zvedne obtiznost pres decay. | Aktivnim studentum nastavi nahodnou pozornost `50-79 %`. |
| Klesani pozornosti | Bezi kazdy frame u aktivnich studentu, pokud neni decay pozastaveny. | Zakladni fail pressure: student pri `0 %` vypadne a snizi pocet prezivajicich. | Level 1: `-1.0/s`; kazdy level `+0.5/s`; strop od levelu 12: `-6.5/s`. |
| Bonusova pozornost | Pouziva se u otazky pres `add_bonus_focus`. | Bonus se chova jako docasny naskok, ktery mizi rychleji nez normalni pozornost. | Bonusova cast klesa dvojnasobne: `focus_decay_rate * 2`. Pozornost je capnuta na `100 %`. |
| Smrt studenta | Student dosahne `0 %` pozornosti. | Student je neaktivni, dal nedostava efekty a zmensi se stamina counter. | Pozornost se nastavi na `0 %`; student uz se v dalsich levelech nerestartuje. |
| Joke minigame | Tlacitko Joke, cooldown `30 s`; minihra pauzne strom. | Kratka skill check akce, level timer a decay stoji behem minihry. | Uspech: vsichni `+20 %` krat action multiplier. Fail: vsichni `-10 %`. |
| Fun fact minigame | Tlacitko Fun Fact, cooldown `45 s`; minihra pauzne strom. | Vyber spravne zajimave hlasky, level timer a decay stoji behem minihry. | Uspech: vsichni `+15 %` krat action multiplier. Fail: vsichni `-10 %`. |
| Question | Tlacitko Question, vyber leve / stredni / prave skupiny. | Nepauzuje cely level timer, ale zastavi decay vsem studentum po dobu vyberu a QTE. | Vybrana skupina dostane bonus `+30 %` krat action multiplier; bonusova cast potom klesa 2x rychleji. |
| Question QTE | Po vyberu skupiny se nahodne zobrazuje pismeno na jednom studentovi ze skupiny. | QTE pokracuje, dokud hrac nesplete pismeno nebo nevyprsi cas. | Pri QTE je decay vsem pozastaveny; samotny QTE uspech uz dalsi pozornost nepridava. |
| Special wheel | 1x za level; minihra pauzne strom. | Jednorazovy silny zasah do levelu, po pouziti je special tlacitko vypnute do dalsiho levelu. | Efekt podle vysledku special ability. |
| Sadluck AI slop | Vysledek special wheel. | Okamzita zachrana / velky reset aktualni situace. | Vsem aktivnim studentum nastavi pozornost na `120 %`. |
| Josef's tobacco | Vysledek special wheel, trva do konce levelu. | Zesiluje pozitivni hracovy akce v aktualnim levelu. | Joke/Fun Fact uspechy a Question bonus se nasobi `2x`; negativni efekty se nenasobi. |
| Cenek's endless speech | Vysledek special wheel, trva do konce levelu. | Level bezi rychleji, ale studenti neztraceji pozornost. | Pozornost vsem prestane klesat; `Engine.time_scale = 4.0`. |
| DJ's failed calculation | Vysledek special wheel. | Risk/reward: aktualni level zhorsuje, dalsi level silne pomaha. | Ted vsichni `-20 %`; na zacatku dalsiho levelu vsichni aktivni studenti dostanou `120 %`. |
| Menu | Otevreni menu. | Pauzne hru a zablokuje gameplay tlacitka. | Decay stoji, protoze je pausnuty SceneTree. |
| Itemy | Na startu kazdeho levelu se prida 1 nahodny item, dokud inventar nema 5 itemu. Hover item vybere a zobrazi popis, klik zobrazi hlasku u ucitele a uvolni slot. | Nova narativni vrstva bez mechanickeho efektu; zatim nezasahuje do obtiznosti. | Zatim zadny efekt na pozornost. |

## Tabulka klesani pozornosti podle levelu

| Level | Klesani pozornosti |
|---|---:|
| 1 | `-1.0/s` |
| 2 | `-1.5/s` |
| 3 | `-2.0/s` |
| 4 | `-2.5/s` |
| 5 | `-3.0/s` |
| 6 | `-3.5/s` |
| 7 | `-4.0/s` |
| 8 | `-4.5/s` |
| 9 | `-5.0/s` |
| 10 | `-5.5/s` |
| 11 | `-6.0/s` |
| 12+ | `-6.5/s` |

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
