# Count Your Friends

Gioco horror cooperativo per Roblox. Il progetto e' descritto in `DESIGN.md`:
leggerlo prima di proporre modifiche al gioco.

## Con chi stai parlando

L'utente **non ha esperienza di programmazione** e non sa modellare in 3D.
Ha Roblox Studio su un computer, ma spesso scrive dal telefono.

Ne discendono tre regole:

- **Spiegazioni in italiano**, con i termini tecnici definiti la prima volta che
  compaiono. Conciso non vuol dire oscuro.
- **Niente lavoro manuale in Studio** se si puo' evitare: l'ambiente si costruisce
  da codice. Se una cosa richiede per forza di trascinare oggetti col mouse, va
  detto chiaramente e ridotto al minimo.
- **Istruzioni sempre complete**: dove va un file, di che tipo, con che nome
  esatto. "Crea uno script" non basta.

## Roblox non gira in questo ambiente

Il codice non si puo' eseguire da qui. Quindi:

- **Mai dire che una cosa funziona** se e' stata solo scritta. Si dice cosa e'
  stato verificato e cosa no.
- Quello che **si puo'** verificare va verificato davvero:
  - sintassi: scaricare `luau-compile` dalle release di `luau-lang/luau` e
    compilare ogni file;
  - logica di generazione (piante, percorsi, connettivita'): riscriverla in
    Python e simularla su molti semi. Ha gia' trovato difetti veri.
- Aspetto, illuminazione, ritmo e "fa paura?" li puo' giudicare solo l'utente.
  Vanno posti come domande, non dati per buoni.

## Come si costruisce

Una fase alla volta, e **ogni fase deve finire con qualcosa di giocabile**, non
con un pezzo pronto. Serve ad accorgersi subito se una cosa non e' divertente.

Il momento della verita' e' la fine della fase 2: se camminare al buio con un
obiettivo non e' teso *senza* mostro, il mostro non lo salvera'.

## Onesta'

Se una scelta e' rischiosa (un genere saturo, un'idea gia' fatta da altri, un
lavoro sproporzionato al risultato) va detto prima, non dopo. Su Roblox il
problema non e' costruire il gioco, e' farsi trovare: le valutazioni sul
potenziale di un'idea vanno date con questa consapevolezza, non per compiacere.

Le costanti di gioco (velocita', distanze, tempi) stanno tutte in
`src/ReplicatedStorage/GameConfig.luau`. Si cambiano una alla volta, sapendo
cosa si sta cercando — non a tentativi finche' "sembra giusto".

## Codice

- Luau, commentato **in italiano**: l'utente lo leggera'.
- I commenti spiegano **perche'**, non cosa: chi legge non conosce il linguaggio,
  ma capisce il ragionamento.
- Ogni numero regolabile va in `GameConfig`, mai sparso nel codice.
- Attenzione alle prestazioni su telefono: la maggior parte del pubblico Roblox
  gioca da li'. Niente mesh pesanti, niente cicli per fotogramma inutili.
