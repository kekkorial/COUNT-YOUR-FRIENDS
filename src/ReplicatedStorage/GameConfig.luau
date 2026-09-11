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
GameConfig.HoleChance    = 0.12 -- probabilita' che un pezzo di soffitto sia crollato

-- ============================================================
--  ARREDAMENTO
--  Sono tutti parallelepipedi: brutti da vicino, invisibili al buio.
--  Servono soprattutto a bloccare la vista, che nel nostro gioco e' meccanica.
-- ============================================================
GameConfig.DesksPerRoom   = 6
GameConfig.LockerChance   = 0.6   -- probabilita' di armadietti lungo un muro di corridoio
GameConfig.DebrisPerCell  = 2     -- calcinacci e cose rovesciate

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
