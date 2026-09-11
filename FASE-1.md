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

### Se hai Studio in italiano

I nomi degli oggetti restano in inglese in **qualsiasi** lingua, perche' non sono
parole ma identificatori del programma: `ReplicatedStorage`, `ServerScriptService`,
`StarterPlayer`, `Lighting`, `ModuleScript`, `Script`, `LocalScript`, `Technology`,
`Future`. Tutto l'albero dell'Explorer e tutti i nomi nel pannello delle proprieta'
sono quindi identici a quelli scritti qui.

Cambiano solo le etichette in alto: la scheda `View` si chiama `Visualizza` e
`Properties` diventa `Proprieta'`. Se non ritrovi un pannello col nome giusto,
vai per icona: dentro `Visualizza` sono i primi pulsanti a sinistra, uno con un
albero di elementi e uno con un elenco di proprieta'.

Quasi tutte le guide e i video su Roblox sono pero' in inglese. Se in futuro ti
stufa tradurre i nomi dei pulsanti, la lingua si cambia da **File > Studio
Settings** (`Alt+S`).

---

## Regola numero uno

**In alto deve esserci il triangolo Play.** Se c'e' un quadrato Stop, premilo.

Tutto cio' che crei *mentre il gioco e' in esecuzione* viene **cancellato**
quando esci dalla prova. Si scrive col gioco fermo, si prova col gioco in moto,
mai il contrario. E' la trappola in cui cascano tutti la prima volta.

---

## Le due manovre che ripeterai

Imparale una volta, poi le usi quattro volte.

### A — come si da' il nome

Il doppio clic su uno script apre l'editor invece di rinominare, quindi il nome
si mette dal pannello delle proprieta':

1. Clicca **una volta** sull'oggetto nell'**Explorer** (se si apre l'editor, ignoralo)
2. Guarda il pannello **Proprieta'**
3. Prima riga dell'elenco: a sinistra c'e' scritto **`Name`**
4. Clicca **sulla casella a destra** di `Name`
5. `Ctrl+A`, scrivi il nome, **Invio**

Nell'Explorer il nome cambia subito, e cambia anche la linguetta dell'editor:
quella e' la conferma.

### B — come si mette il codice

1. **Doppio clic** sull'oggetto: si apre l'editor al centro
2. Clicca **dentro** l'editor, poi `Ctrl+A` e `Canc` (deve restare vuoto)
3. Apri il file su GitHub, tasto **Copy raw file** in alto a destra del riquadro
4. Torna in Studio, clicca dentro l'editor, `Ctrl+V`

---

## I quattro oggetti

Per crearli: **clic destro** sul contenitore nell'Explorer, poi `Insert Object`,
poi il tipo. (C'e' anche un `+` che compare passando il mouse sulla riga: fa la
stessa cosa.)

### 1. GameConfig

- contenitore: **`ReplicatedStorage`**
- tipo: **`ModuleScript`**
- nome (manovra A): **`GameConfig`**
- codice (manovra B): `src/ReplicatedStorage/GameConfig.luau`

### 2. MapGenerator

- contenitore: **`ServerScriptService`**
- tipo: **`ModuleScript`**
- nome: **`MapGenerator`**
- codice: `src/ServerScriptService/MapGenerator.luau`

### 3. Main

- contenitore: **`ServerScriptService`**
- tipo: **`Script`** — non `ModuleScript`
- nome: **`Main`**
- codice: `src/ServerScriptService/Main.server.luau`

### 4. Torch

- contenitore: **`StarterPlayer`** > **`StarterPlayerScripts`**
  (apri prima la freccia di `StarterPlayer`)
- tipo: **`LocalScript`**
- nome: **`Torch`**
- codice: `src/StarterPlayerScripts/Torch.client.luau`

---

## I nomi: quali contano e quali no

Non e' un capriccio, e la differenza e' importante:

| Oggetto | Il nome conta? | Perche' |
|---|---|---|
| `GameConfig` | **si', obbligatorio** | `Main` lo cerca per nome |
| `MapGenerator` | **si', obbligatorio** | idem |
| `Main` | no | nessuno lo cerca |
| `Torch` | no | nessuno lo cerca |

Se `GameConfig` o `MapGenerator` hanno il nome sbagliato, `Main` si blocca ad
aspettarli e non succede niente — **senza errori in rosso**. Nell'Output compare
una riga arancione `Infinite yield possible on ...` che dice quale oggetto sta
aspettando.

Il nome dev'essere identico, maiuscole comprese: `gameconfig` non e' `GameConfig`.
Niente estensione `.luau`, niente spazi in fondo.

---

## Verifica

Apri tutte le frecce. Deve essere **esattamente** cosi', ne' piu' ne' meno —
quattro oggetti in tutto:

```
ReplicatedStorage
 └── GameConfig

ServerScriptService
 ├── MapGenerator
 └── Main

StarterPlayer
 └── StarterPlayerScripts
      └── Torch
```

Se ne trovi di piu' (capita rifacendo i passaggi), **cancella i doppioni**:
clic sull'oggetto, tasto `Canc`. Un doppione si riconosce anche dall'Output,
dove ogni messaggio compare due volte.

---

## Salva e prova

`Ctrl+S`, poi il tasto **Play**. Per uscire, il quadrato **Stop**.

Apri `Visualizza` > `Output` e cerca questa riga:

```
[Count Your Friends] Scuola costruita: ... oggetti.
```

Se c'e', la scuola e' stata costruita davvero. Compari **fuori** dall'ingresso,
sul piazzale, sotto una lampada che sfarfalla. Premi **F** per la torcia ed entra.

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
| tutto nero, non si vede niente nemmeno con la torcia | alza `TorchBrightness` in `GameConfig`. Se nell'Output c'e' un avviso sull'illuminazione, segui quello che dice |
| `F` non accende la torcia | `Torch` dev'essere un `LocalScript` dentro `StarterPlayerScripts` |
| si passa attraverso i muri, o si cade nel vuoto | e' un difetto del generatore: segnalalo con quello che leggi nell'Output |

Se esce un errore che non e' in questa tabella, copialo e chiedi: si traduce.

## Poi

Quando questa fase ti convince, si passa alla **fase 2**: macchina fotografica,
i cinque soggetti da fotografare, il tempo che scade e il furgone.

Il mostro arriva alla fase 3. Prima deve funzionare il gioco senza.
