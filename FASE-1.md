# Fase 1 — camminare al buio

Obiettivo di questa fase: premi Play e ti ritrovi davanti a una scuola
abbandonata, al buio, con una torcia in mano. Niente mostro, niente obiettivi.

**Serve a rispondere a una domanda sola: fa gia' un po' paura?**
Se la risposta e' si', il resto del gioco ha senso. Se e' no, e' molto meglio
scoprirlo adesso che dopo trenta ore di lavoro.

Non devi costruire né disegnare niente. La scuola la costruisce il codice, ed e'
diversa a ogni partita.

---

## Prima di tutto: i due pannelli

In Studio, scheda **View** in alto. Accendi:

- **Explorer** — l'elenco di tutto quello che c'e' nel gioco. E' la cosa con cui
  lavorerai sempre.
- **Properties** — le proprieta' dell'oggetto selezionato nell'Explorer.

---

## Passo 1 — l'interruttore piu' importante

Questo cambia l'aspetto del gioco piu' di qualsiasi altra cosa farai oggi, ed e'
l'unica che il codice non puo' fare da solo.

1. Nell'**Explorer**, clicca su **Lighting**.
2. Nel **Properties**, cerca **Technology**.
3. Mettilo su **Future**.

E' il motore di illuminazione moderno: senza, le torce non proiettano ombre vere
e l'atmosfera non arriva.

---

## Passo 2 — creare i quattro fogli di codice

Ogni pezzo di codice va in un posto preciso e deve essere di un **tipo** preciso.
Il tipo conta: un `Script` gira sul server (il computer di Roblox), un
`LocalScript` gira sul dispositivo del giocatore, un `ModuleScript` non gira mai
da solo ma viene letto dagli altri.

Per crearli: nell'**Explorer**, passa il mouse sull'oggetto che deve contenerlo,
compare un **+**, cliccalo e cerca il tipo. Poi rinominalo (doppio clic sul nome).

| Dove | Tipo | Nome | Cosa incollarci |
|---|---|---|---|
| `ReplicatedStorage` | **ModuleScript** | `GameConfig` | `src/ReplicatedStorage/GameConfig.luau` |
| `ServerScriptService` | **ModuleScript** | `MapGenerator` | `src/ServerScriptService/MapGenerator.luau` |
| `ServerScriptService` | **Script** | `Main` | `src/ServerScriptService/Main.server.luau` |
| `StarterPlayer` > `StarterPlayerScripts` | **LocalScript** | `Torch` | `src/StarterPlayerScripts/Torch.client.luau` |

> I nomi devono essere **esattamente** questi, maiuscole comprese: gli script si
> cercano per nome, e `gameconfig` non e' `GameConfig`.

Per ognuno: apri il file corrispondente qui nella cartella, copia **tutto**,
apri il foglio in Studio, **cancella quello che c'e' dentro** (Studio ci mette
sempre una riga di esempio) e incolla.

---

## Passo 3 — Play

Premi il tasto **Play** (il triangolo in alto).

Dovresti trovarti fuori dall'ingresso, al buio. Premi **F** per la torcia e
entra.

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

**Non succede niente / resta il pavimento grigio di prova**
Guarda la finestra **Output** (scheda View > Output): se c'e' scritto in rosso
`Main is not a valid member`, hai sbagliato un nome. Se c'e' `attempt to index
nil`, probabilmente un ModuleScript e' stato creato come Script.

**Buio assoluto, non vedo niente nemmeno con la torcia**
Controlla il passo 1 (`Technology` = `Future`). Se e' giusto, alza
`TorchBrightness` in `GameConfig`.

**La torcia non si accende con F**
`Torch` deve essere un **LocalScript** e stare dentro `StarterPlayerScripts`,
non altrove. Se e' un `Script` normale non parte.

**Passo attraverso i muri / cado nel vuoto**
Segnalamelo con quello che leggi nell'Output: e' un difetto del generatore, non
tuo.

---

## Poi

Quando questa fase ti convince, si passa alla **fase 2**: macchina fotografica,
i cinque soggetti da fotografare, il tempo che scade e il furgone.

Il mostro arriva alla fase 3. Prima deve funzionare il gioco senza.
