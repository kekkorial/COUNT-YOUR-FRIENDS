--[[
	GameConfig — tutti i numeri del gioco in un posto solo.

	Se vuoi cambiare com'e' fatta la scuola, cambia QUI e basta: non toccare gli
	altri script. Ogni valore ha scritto a cosa serve e cosa succede se lo alzi.

	Dove va in Studio:  ReplicatedStorage > GameConfig   (ModuleScript)
	("ModuleScript" = un foglio di codice che non fa niente da solo, ma che gli
	 altri script possono leggere. Serve appunto a tenere i numeri in un posto solo.)
--]]

local GameConfig = {}

-- ============================================================
--  FORMA DELL'EDIFICIO
--  L'edificio e' una griglia di caselle. Alcune file e alcune colonne sono
--  corridoi (strette), tutte le altre caselle diventano aule (larghe).
-- ============================================================
GameConfig.GridWidth     = 9    -- quante caselle in larghezza
GameConfig.GridDepth     = 8    -- quante caselle in profondita'
GameConfig.CorridorEvery = 3    -- ogni quante caselle passa un corridoio

GameConfig.RoomSize      = 26   -- lato di un'aula, in "studs" (l'unita' di Roblox: un giocatore e' alto ~5)
GameConfig.CorridorWidth = 14   -- larghezza di un corridoio
GameConfig.WallHeight    = 14   -- altezza dei muri
GameConfig.WallThickness = 1

GameConfig.DoorWidth     = 8    -- larghezza dei vani porta
GameConfig.DoorHeight    = 10

GameConfig.MergeChance   = 0.55 -- probabilita' che due aule vicine diventino un'aula sola (piu' alto = stanze piu' grandi e irregolari)

-- ============================================================
--  IL CONTROSOFFITTO CROLLATO
--  Sono due strati: in alto la soletta vera, scura, con le travi; sotto i
--  pannelli chiari appesi a un'orditura metallica. Dove i pannelli sono caduti
--  si vede il buio della struttura — ed e' quello il colpo d'occhio.
-- ============================================================
GameConfig.PlenumHeight     = 4.5  -- quanto e' alta la cavita' fra i pannelli e la soletta
GameConfig.CeilingTile      = 8    -- lato di un pannello

GameConfig.CeilingCollapses = 7    -- quante ZONE di crollo. Non pannelli sparsi: chiazze
GameConfig.CollapseRadius   = 34   -- quanto sono larghe. Piu' grande = squarci piu' lunghi
GameConfig.StrayHoleChance  = 0.05 -- pannelli mancanti isolati, fuori dalle chiazze

GameConfig.HangingPanels  = 0.16 -- pannelli staccati da un lato che pendono, sul bordo dei crolli
GameConfig.HangerChance   = 0.22 -- fili di sostegno rimasti appesi nel vuoto
GameConfig.DanglingCables = 0.3  -- cavi che penzolano dai corridoi
GameConfig.RoofHoles      = 4    -- buchi nella soletta VERA: da li' entra la luna

-- ============================================================
--  ARREDAMENTO
--  Sono tutti parallelepipedi: brutti da vicino, invisibili al buio.
--  Servono soprattutto a bloccare la vista, che nel nostro gioco e' meccanica.
-- ============================================================
GameConfig.DesksPerRoom   = 6
GameConfig.LockerChance   = 0.6   -- probabilita' di armadietti lungo un muro di corridoio
GameConfig.DebrisPerCell  = 2     -- calcinacci e cose rovesciate

-- ============================================================
--  ESTETICA
--  Nessuno di questi cambia il gioco: cambiano solo com'e' fatto l'ambiente.
--  Sono le cose che trasformano "scatole grigie" in "scuola abbandonata".
--  Se il gioco ti va a scatti sul telefono, e' qui che si taglia.
-- ============================================================
GameConfig.ColorJitter = 0.16  -- quanto varia il colore fra un pezzo e l'altro. A 0 tutto identico: e' cio' che fa sembrare tutto plastica

GameConfig.Baseboard       = true  -- la fascia dipinta in basso ai muri: il dettaglio che rende di piu' in assoluto
GameConfig.BaseboardHeight = 5

GameConfig.DoorFrames = true   -- stipiti attorno ai vani porta

GameConfig.WindowChance = 0.5  -- probabilita' che un tratto di muro esterno sia una finestra
GameConfig.BrokenGlass  = 0.4  -- di quelle, quante hanno il vetro rotto (aperte)
GameConfig.MoonLight    = 1.1  -- quanta luce lunare entra da finestre e buchi nel soffitto
GameConfig.MaxFillLights = 16  -- tetto alle luci lunari: oltre una certa soglia Roblox ne scarta alcune a caso e le vedi sparire mentre cammini

GameConfig.PipeChance   = 0.45 -- tubi sotto il soffitto dei corridoi
GameConfig.PuddleChance = 0.3  -- pozze d'acqua: riflettono la torcia
GameConfig.PapersPerCell = 3   -- fogli sparsi per terra
GameConfig.OverturnedDesks = 0.28 -- quota di banchi rovesciati
GameConfig.ChairChance  = 0.5  -- probabilita' che un banco abbia la sedia

-- ============================================================
--  LUCI SUPERSTITI
--  Quasi tutti i neon sono morti. Quelli vivi sfarfallano: e' quello che
--  da' l'atmosfera, molto piu' dei modelli.
-- ============================================================
GameConfig.WorkingLights  = 7     -- quanti neon funzionano in tutto l'edificio
GameConfig.FlickerChance  = 0.5   -- quanti di quelli, tra i vivi, sfarfallano

-- ============================================================
--  TORCIA
-- ============================================================
GameConfig.TorchAngle      = 50    -- ampiezza del fascio in gradi (piu' basso = fascio stretto e piu' angosciante)
GameConfig.TorchRange      = 70    -- quanto lontano arriva la luce
GameConfig.TorchBrightness = 4

-- ============================================================
--  SEME CASUALE
--  Se lo lasci a 0, la scuola e' diversa ogni volta.
--  Se ci metti un numero (es. 12345), esce sempre la stessa: utile mentre
--  facciamo le prove, cosi' cambiamo una cosa alla volta e vediamo l'effetto.
-- ============================================================
GameConfig.Seed = 0

return GameConfig
