# Fase 1 — camminare al buio

Obiettivo di questa fase: premi Play e ti ritrovi davanti a una scuola
abbandonata, al buio, con una torcia in mano. Niente mostro, niente obiettivi.

**Serve a rispondere a una domanda sola: fa gia' un po' paura?**
Se la risposta e' si', il resto del gioco ha senso. Se e' no, e' molto meglio
scoprirlo adesso che dopo trenta ore di lavoro.

Non devi costruire né disegnare niente. La scuola la costruisce il codice, ed e'
diversa a ogni partita.

---

## Prima di iniziare

**Una trappola in cui cascano tutti la prima volta:** quando premi Play, Studio
entra in modalita' prova. Se modifichi qualcosa mentre sei li' dentro, quelle
modifiche vengono **buttate via** quando premi Stop. Quindi: prima si incolla
tutto, poi si prova.

### I due pannelli

In alto c'e' una fila di schede (`Home`, `Model`, `Test`, `View`...). Clicca
**`View`** e accendi:

- **Explorer** — l'elenco di tutto cio' che esiste nel gioco. E' l'attrezzo
  principale, lo userai sempre.
- **Properties** — le proprieta' dell'oggetto selezionato nell'Explorer.

Di solito si piazzano a destra, uno sopra l'altro.

---

## Passo 1 — l'interruttore della luce

Questo il codice non puo' farlo: Roblox non lo permette agli script. Ed e' la
cosa che cambia di piu' l'aspetto del gioco.

1. Nell'**Explorer**, clic singolo su **`Lighting`**
2. Nel **Properties** scorri fino alla riga **`Technology`**
3. Clicca il valore accanto, si apre un menu': scegli **`Future`**

E' il motore di illuminazione moderno: senza, le torce non proiettano ombre vere
e l'atmosfera non arriva.

---

## Passo 2 — GameConfig

1. Nell'**Explorer**, cerca la riga **`ReplicatedStorage`**
2. **Passaci sopra col mouse**: a destra della riga compare un **`+`** in un cerchio
3. Clicca il `+`, si apre una casella di ricerca
4. Scrivi **`ModuleScript`** e clicca il risultato
5. Appare un oggetto nuovo dentro `ReplicatedStorage`, col nome gia' evidenziato:
   scrivi **`GameConfig`** e premi Invio
   *(se il nome non e' evidenziato: selezionalo e premi **F2**)*
6. **Doppio clic sull'oggetto**: si apre l'editor di testo al centro
7. Studio ci ha gia' messo una riga di esempio. **Cancellala**: clicca
   nell'editor, poi `Ctrl+A` (`Cmd+A` su Mac) e `Canc`
8. Apri `src/ReplicatedStorage/GameConfig.luau` su GitHub. In alto a destra del
   riquadro del codice c'e' l'icona **"Copy raw file"** (due quadratini
   sovrapposti): cliccala
9. Torna in Studio, clicca dentro l'editor vuoto, `Ctrl+V`

---

## Passo 3 — MapGenerator

Identico al passo 2, ma:

- contenitore: **`ServerScriptService`**
- tipo: **`ModuleScript`**
- nome: **`MapGenerator`**
- codice: `src/ServerScriptService/MapGenerator.luau`

---

## Passo 4 — Main

Stesso contenitore del passo 3, **ma attenzione al tipo**:

- contenitore: **`ServerScriptService`**
- tipo: **`Script`** — non `ModuleScript`, non `LocalScript`
- nome: **`Main`**
- codice: `src/ServerScriptService/Main.server.luau`

> Il `.server` nel nome del file e' una convenzione per ricordare il tipo.
> **In Studio l'oggetto si chiama solo `Main`.**

---

## Passo 5 — Torch

Qui c'e' un passaggio in piu', perche' il contenitore e' annidato.

1. Nell'**Explorer** trova **`StarterPlayer`**
2. Alla sua **sinistra** c'e' una piccola freccia. Cliccala per aprirlo
3. Dentro compaiono `StarterCharacterScripts` e **`StarterPlayerScripts`**
4. Passa il mouse su **`StarterPlayerScripts`**, poi `+`
5. Tipo: **`LocalScript`** — un `Script` normale, qui, non parte
6. Nome: **`Torch`**
7. Codice: `src/StarterPlayerScripts/Torch.client.luau`

---

## Passo 6 — controlla, salva, prova

Nell'Explorer devi vedere esattamente questo:

```
ReplicatedStorage
 └── GameConfig          (ModuleScript)
ServerScriptService
 ├── MapGenerator        (ModuleScript)
 └── Main                (Script)
StarterPlayer
 └── StarterPlayerScripts
      └── Torch          (LocalScript)
```

I nomi devono essere identici, **maiuscole comprese**: gli script si cercano per
nome, e `gameconfig` non e' `GameConfig`.

Poi `Ctrl+S` per salvare, e premi **Play** (il triangolo in alto). Per uscire,
il quadrato **Stop**.

Dovresti trovarti fuori dall'ingresso, al buio. Premi **F** per la torcia ed entra.

---

## Cosa guardare

Non guardare se e' bello — non lo e', sono scatole grigie. Guarda queste cose:

- **Ci si perde?** Serve che ci si perda un po', ma non troppo.
- **Il fascio della torcia e' giusto?** Troppo largo e vedi tutto, troppo stretto
  e diventa fastidioso.
- **I corridoi sono troppo lunghi? Le stanze troppe?**
- **E soprattutto: cammineresti volentieri in questo posto?**

Tutto si aggiusta cambiando un numero in `GameConfig`, senza toccare altro. I piu'
utili:

| Se vuoi... | Cambia |
|---|---|
| una scuola piu' grande | `GridWidth`, `GridDepth` |
| un fascio piu' stretto e angosciante | `TorchAngle` (prova 35) |
| vedere piu' lontano | `TorchRange` |
| piu' buio | `WorkingLights` (prova 3) |
| meno nebbia | in `Main`, `atmosphere.Density` |
| la stessa scuola a ogni prova | `Seed` (metti un numero qualsiasi) |

---

## Se qualcosa non va

Apri **`View` > `Output`**: e' la finestra dove il gioco scrive gli errori, in rosso.

| Cosa leggi | Cosa significa |
|---|---|
| `... is not a valid member of ...` | un nome sbagliato, o un oggetto nel contenitore sbagliato |
| `attempt to call a nil value` / `attempt to index nil` | un `ModuleScript` creato come `Script`, o viceversa |
| niente in rosso, ma resta il pavimento grigio di prova | `Main` non sta girando: dev'essere uno `Script` dentro `ServerScriptService` |
| tutto nero, non si vede niente nemmeno con la torcia | manca il passo 1 (`Technology` = `Future`). Se e' gia' giusto, alza `TorchBrightness` |
| `F` non accende la torcia | `Torch` dev'essere un `LocalScript` dentro `StarterPlayerScripts` |
| si passa attraverso i muri, o si cade nel vuoto | e' un difetto del generatore: segnalalo con quello che leggi nell'Output |

Se esce un errore che non e' in questa tabella, copialo e chiedi: si traduce.

## Poi

Quando questa fase ti convince, si passa alla **fase 2**: macchina fotografica,
i cinque soggetti da fotografare, il tempo che scade e il furgone.

Il mostro arriva alla fase 3. Prima deve funzionare il gioco senza.
