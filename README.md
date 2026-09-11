# COUNT YOUR FRIENDS

Gioco horror cooperativo per Roblox. In sviluppo.

> Quattro ragazzi entrano di notte in una scuola abbandonata per fotografarla.
> Uno di loro non e' uno di loro.

## Il gancio

Il mostro non insegue e non ruggisce. **Copia l'aspetto e il nome di uno dei
giocatori** e si mette in mezzo al gruppo. Uccide solo chi resta solo.

L'unico modo per accorgertene e' **contare**: sullo schermo c'e' scritto quanti
giocatori sono vivi. Se ne vedi uno in piu' di quel numero, ce l'hai davanti.

Il titolo del gioco e' la regola del gioco.

## A che punto siamo

| Fase | Cosa | Stato |
|---|---|---|
| 1 | Scuola generata a caso, buio, torcia | **fatta** — da provare in Studio |
| 2 | Macchina fotografica, 5 soggetti, tempo, furgone | da fare |
| 3 | Il sosia: copia faccia e nome, uccide chi e' solo | da fare |
| 4 | Conteggio, indizi, sedili del furgone | da fare |
| 5 | Suono, luci, morte | da fare |
| 6 | Icona, copertina, lancio | da fare |

## Com'e' organizzato

```
DESIGN.md    il progetto: cosa costruiamo e perche'
FASE-1.md    istruzioni passo-passo per far girare la fase 1
src/         il codice, nelle cartelle che corrispondono a Roblox Studio
```

I file dentro `src/` rispecchiano la struttura di Studio: `src/ReplicatedStorage/`
va in `ReplicatedStorage`, e cosi' via. L'estensione dice il tipo di script:

- `.luau` semplice → **ModuleScript**
- `.server.luau` → **Script** (gira sul server)
- `.client.luau` → **LocalScript** (gira sul dispositivo del giocatore)

## Come si prova

Serve **Roblox Studio** (Windows o Mac; non esiste per telefono).
Le istruzioni complete sono in [FASE-1.md](FASE-1.md).

Non serve saper modellare: l'edificio e' costruito dal codice con soli blocchi,
e cambia forma a ogni partita. Per modificarlo si cambia un numero in
`src/ReplicatedStorage/GameConfig.luau`.
