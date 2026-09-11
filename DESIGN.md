# COUNT YOUR FRIENDS

> Documento di progetto. Versione 1 — settembre 2026.
> Questo file descrive **cosa** costruiamo e **perche'**. Il codice arrivera' dopo,
> una fase alla volta. Ogni decisione qui dentro e' modificabile: se una cosa in
> prova non funziona, si cambia il documento, non si tiene per coerenza.

---

## 1. L'idea in una riga

Quattro ragazzi entrano di notte in un edificio abbandonato per fotografarlo.
Uno di loro non e' uno di loro.

## 2. Il gancio

Il mostro non insegue e non ruggisce. **Copia l'aspetto e il nome di uno dei
giocatori** e si mette in mezzo al gruppo. Uccide solo chi resta solo.

L'unico modo per accorgertene e' **contare**: sullo schermo c'e' scritto quanti
giocatori sono vivi. Se ne vedi uno in piu' di quel numero, ce l'hai davanti.

Il titolo del gioco e' la regola del gioco. Questo e' il punto piu' importante di
tutto il documento: chi legge "Count Your Friends" e poi si ritrova davvero a
contare, ha ricevuto quello che gli era stato promesso.

## 3. Perche' puo' funzionare

Tre ragioni concrete, non ottimismo:

- **L'horror e' il genere che i creator riprendono di piu'.** Nel 2026 i giochi
  che ottengono video spontanei nella prima settimana hanno cinque volte piu'
  probabilita' di mantenere giocatori dopo un mese. L'horror e' il genere con la
  copertura piu' alta.
- **Il buio nasconde il budget.** Stanze fatte di scatole grigie, illuminate male
  apposta, fanno paura. Le stesse stanze a luce piena fanno ridere. E' l'unico
  genere in cui partire da soli senza saper modellare non e' una condanna.
- **Il gancio si vede in cinque secondi di video.** "Ci sono due Marco" e' un clip
  che si spiega da solo, senza audio e senza contesto.

E una ragione per cui potrebbe non funzionare, che va tenuta sotto controllo:
**su Roblox il problema non e' costruire il gioco, e' farsi trovare.** Migliaia di
giochi tecnicamente validi restano a zero giocatori. Titolo, icona e copertina
contano quanto il codice, e vanno decisi prima del lancio, non dopo.

---

## 4. Come si svolge una partita

### 4.1 Il furgone (la sala d'attesa)

Non c'e' una lobby. C'e' un furgone che viaggia di notte verso il posto scelto.
I giocatori sono seduti dentro, si vedono, possono parlare. Si vota la
destinazione. Durata: **massimo 30 secondi**.

Due scelte tecniche non negoziabili:

- **Il furgone non si muove davvero.** Sta fermo, si muove il paesaggio intorno,
  con nebbia fitta a mascherare il trucco. I veicoli su Roblox causano giocatori
  che cadono fuori e posizioni disallineate: non vale il rischio per una scena
  che serve solo a dare atmosfera.
- **Il viaggio E' l'attesa fra una partita e l'altra.** Cosi' non esiste tempo
  morto: il momento in cui normalmente il giocatore si annoia e chiude, qui e'
  gia' gioco.

**Il furgone ha esattamente un sedile per giocatore.** Questo dettaglio non e'
decorativo: e' la condizione di vittoria (vedi 4.4).

### 4.2 L'arrivo

Il furgone si ferma davanti all'edificio e resta parcheggiato li' per tutta la
partita. E' il punto di riferimento: l'unico posto che i giocatori sanno
ritrovare al buio.

### 4.3 L'esplorazione

Ogni giocatore ha una **torcia** e una **macchina fotografica**.

Obiettivo: fotografare **5 soggetti** sparsi nell'edificio (il murale, la sala
operatoria, il registro di classe...). Il flash illumina la stanza per un
istante — ed e' li' che a volte si vede qualcosa che con la torcia non si vedeva.

Perche' fotografare invece di riparare qualcosa:

- e' la cosa che si fa davvero nell'urbex, quindi e' credibile;
- il flash e' uno strumento horror gratuito;
- i giocatori le foto se le scambiano. E' pubblicita' che si fa da sola.

**Il dilemma centrale del gioco sta qui.** I cinque soggetti sono lontani fra
loro. Restare uniti e' sicuro ma lentissimo, e il tempo scade. Dividersi e'
l'unico modo per farcela, ed e' esattamente quando si muore. Il mostro non e' la
fonte della tensione: e' lo strumento che rende letale una scelta che i giocatori
farebbero comunque.

### 4.4 Il ritorno

Fatte le 5 foto, si torna al furgone e ognuno si siede al proprio posto.

E i sedili sono contati.

### 4.5 Il sosia

Compare **a meta' partita**, non all'inizio: prima bisogna far abbassare la
guardia.

Copia l'aspetto e il nome del giocatore **piu' isolato in quel momento**. Cosi',
quando il gruppo si ricompatta, il vero proprietario di quella faccia arriva e ce
ne sono due.

**Uccide solo chi e' solo.** Se un altro giocatore lo sta vedendo, non fa niente.
Nessuno muore ingiustamente: si muore perche' ci si e' staccati.

Comportamento: quando qualcuno lo guarda, **sta fermo**. Non insegue, non corre,
non parla. Il mostro piu' inquietante qui e' il piu' stupido — una sagoma
immobile con la faccia del tuo amico, che aspetta.

Questo non e' pigrizia, e' progettazione: l'IA non deve reggere una conversazione,
deve reggere **due secondi a venti metri al buio**. Per quello basta molto poco, e
la versione minimale e' anche la piu' spaventosa.

### 4.6 Come si smaschera

Tre indizi, in ordine di difficolta':

1. **Il numero.** In alto sullo schermo: quanti giocatori sono vivi. Se ne conti
   uno in piu', ce l'hai davanti.
2. **Il nome doppio.** Due giocatori con lo stesso nome nella stessa stanza. E' il
   momento da clip, ed e' il motivo per cui verso la fine il gruppo si ricompatta.
3. **Non lavora.** Fermo davanti a un soggetto che non viene mai fotografato.

### 4.7 Il colpo di scena

Il giocatore che viene copiato riceve un messaggio privato:
**"qualcosa sta indossando la tua faccia"**.

Da quel momento e' lui il primo sospettato dagli altri e deve dimostrare di essere
quello vero. Costa pochissimo da programmare e vale meta' del divertimento.

### 4.8 L'unica arma

Nessuna votazione, nessuna assemblea: rallentano l'horror e sono molta interfaccia
da costruire.

**Una sola scansione a partita.** Punti la torcia addosso a qualcuno e scopri se e'
reale. Una sola, per tutta la partita. Puntarla sulla persona sbagliata e' la cosa
peggiore che ti possa capitare — ed e' ottimo materiale da video.

---

## 5. Le mappe

**Una sola mappa al lancio, fatta bene.** Quattro mappe mediocri valgono meno di
una buona.

Ma il sistema va costruito fin da subito cosi': la mappa non si disegna a mano,
**si compone**. Si costruiscono una decina di **moduli** (un'aula, un corridoio, un
bagno, una palestra) e il codice li assembla a caso a ogni partita.

Due vantaggi:

- la mappa non e' mai identica: e' il motivo per rigiocare;
- **una mappa nuova = un set nuovo di moduli**, non un progetto da capo. Ed e'
  esattamente la cadenza di aggiornamenti che riporta i creator a rifare un video.

Mappe previste, in ordine: **scuola abbandonata** (la prima: e' il posto che il
pubblico riconosce meglio, e i corridoi con le porte in fila sono la cosa piu'
semplice da generare), poi ospedale dismesso, centro commerciale chiuso, rifugio
sotterraneo.

---

## 6. Ordine di costruzione

Ogni fase deve finire con **qualcosa di giocabile**, non con "un pezzo pronto".
Serve ad accorgersi subito se una cosa non e' divertente, invece che alla fine.

| Fase | Cosa | Risultato |
|---|---|---|
| 0 | Studio installato, esperienza creata su Roblox | c'e' un posto dove pubblicare |
| 1 | Mappa composta a caso + buio + torcia | si cammina al buio, e fa gia' paura |
| 2 | Macchina fotografica + 5 soggetti + tempo + furgone | un gioco cooperativo completo, senza mostro |
| 3 | Il sosia: copia faccia e nome, uccide chi e' solo | il gioco vero |
| 4 | Conteggio, indizi, messaggio "indossa la tua faccia", sedili | il gancio e' completo |
| 5 | Suono, luci, morte | fa paura sul serio |
| 6 | Icona, copertina, titolo, descrizione, lancio | si esce |

**Il momento della verita' e' alla fine della fase 2.** Se camminare al buio con un
obiettivo non e' gia' teso *senza* mostro, il mostro non lo salvera'. Se a quel
punto non funziona, si cambia il gioco, non si aggiungono cose sopra.

---

## 7. Monetizzazione

Da decidere alla fase 6, ma la direzione e' questa.

In un gioco dove conta l'equita', **vendere vantaggi e' rischioso**: scansioni
extra o torce migliori spostano l'esito della partita e fanno arrabbiare chi non
paga. Meglio evitarlo almeno al lancio.

Le leve buone:

- **Server privati.** Roblox li lascia vendere senza scrivere una riga di codice, e
  un horror a quattro giocatori e' esattamente il gioco che gli amici vogliono
  giocare per conto loro. E' la leva migliore che hai.
- **Estetica.** Colori della torcia, aspetto della macchina fotografica, skin.
  Nessun effetto sul gioco.

---

## 8. Decisioni ancora aperte

- Quanti giocatori per server (l'ipotesi e' 4-6; sopra i 6 il conteggio diventa
  difficile da tenere a mente, ed e' il cuore del gioco)
- Cosa succede a chi muore: spettatore o rientro alla partita dopo
- Se il sosia debba poter parlare in chat (per ora: no, il silenzio e' un indizio)
- La "foto di gruppo finale con una persona in piu'" sarebbe il manifesto del
  gioco, ma richiede di disegnare davvero un'immagine: rimandata, non al lancio
