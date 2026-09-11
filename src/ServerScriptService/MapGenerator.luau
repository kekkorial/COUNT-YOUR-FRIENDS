--[[
	MapGenerator — costruisce la scuola abbandonata.

	Nessun modello 3D: tutto e' fatto di parallelepipedi ("Part") creati dal
	codice. Il trucco per non farli sembrare scatole non e' aggiungere pezzi
	complicati, ma quattro cose semplici ripetute ovunque:

	  - il COLORE varia leggermente su ogni pezzo (l'uniformita' e' cio' che fa
	    sembrare tutto plastica);
	  - i muri hanno una ZOCCOLATURA, la fascia dipinta in basso: e' il dettaglio
	    che da solo fa leggere un muro grigio come un corridoio di scuola;
	  - le porte hanno gli STIPITI, cosi' sono architettura e non buchi;
	  - la luce entra da FINESTRE e BUCHI nel soffitto, azzurra, in contrasto col
	    giallo della torcia.

	Come ragiona la pianta:
	  1. divide l'edificio in una griglia di caselle;
	  2. alcune file/colonne diventano corridoi (stretti), le altre aule (larghe);
	  3. le aule vicine a volte si fondono, cosi' non sono tutte uguali;
	  4. mette un muro fra due caselle solo se appartengono a stanze diverse;
	  5. ogni aula riceve UNA porta verso un corridoio;
	  6. arreda, sporca e illumina.

	Dove va in Studio:  ServerScriptService > MapGenerator   (ModuleScript)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local MapGenerator = {}

-- ------------------------------------------------------------
--  Tavolozza
-- ------------------------------------------------------------
local C_WALL   = Color3.fromRGB(178, 174, 164)   -- intonaco chiaro. Muri pallidi su pavimento scuro: e' il rapporto che regge la foto di riferimento
local C_TRIM   = Color3.fromRGB(64, 84, 78)      -- verde istituzionale della zoccolatura
local C_FRAME  = Color3.fromRGB(104, 96, 82)     -- stipiti
local C_FLOOR  = Color3.fromRGB(60, 58, 55)      -- il pavimento resta scuro: e' il contrasto coi muri a dare profondita'
local C_CEIL   = Color3.fromRGB(98, 96, 90)
local C_METAL  = Color3.fromRGB(76, 82, 80)
local C_WOOD   = Color3.fromRGB(94, 72, 50)
local C_BOARD  = Color3.fromRGB(34, 44, 40)
local C_GLASS  = Color3.fromRGB(150, 175, 190)
local C_PAPER  = Color3.fromRGB(196, 190, 172)
local C_MOON   = Color3.fromRGB(126, 158, 210)   -- la luce da fuori: fredda, per contrasto con la torcia
local C_PANEL  = Color3.fromRGB(198, 196, 188)   -- pannelli del controsoffitto: chiari, quasi bianchi
local C_DECK   = Color3.fromRGB(26, 26, 28)      -- la soletta vera sopra: quasi nera. E' il contrasto che fa la foto
local C_BEAM   = Color3.fromRGB(42, 40, 38)
local C_TBAR   = Color3.fromRGB(152, 150, 144)   -- l'orditura metallica che regge i pannelli
local C_CABLE  = Color3.fromRGB(24, 24, 26)
local C_DAMAGE = Color3.fromRGB(132, 104, 88)    -- il mattone che si scopre dove l'intonaco e' caduto
local C_LOCKER = Color3.fromRGB(72, 88, 94)      -- lamiera verniciata degli armadietti

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.Concrete
	p.Color = C_WALL
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	-- I pezzi sottili non proiettano ombra. Sono centinaia — modanature,
	-- fogli, schegge, fili — l'ombra di una lamina di mezzo centimetro non si
	-- vede, e su geometria che si compenetra le ombre dinamiche producono
	-- artefatti: proprio quelle sbavature che sembrano difetti grafici.
	if props.CastShadow == nil then
		local s = p.Size
		if math.min(s.X, s.Y, s.Z) < 0.6 then
			p.CastShadow = false
		end
	end
	p.Parent = parent
	return p
end

-- Frasi di gesso sulle lavagne. Le piu' inquietanti sono quelle normali:
-- una data, dei compiti. Dicono che qui dentro la vita si e' interrotta.
local LAVAGNA = {
	"COMPITI PER DOMANI", "VERIFICA VENERDI'", "12 SETTEMBRE",
	"ASSEMBLEA ORE 10", "NON CANCELLARE", "ULTIMO GIORNO",
	"CI SIAMO DIVERTITI", "3 B", "BUONE VACANZE",
}

-- ------------------------------------------------------------
--  Costruzione
-- ------------------------------------------------------------
function MapGenerator.build(parent)
	local cfg = GameConfig
	local rng = Random.new(cfg.Seed ~= 0 and cfg.Seed or math.floor(os.clock() * 1e6))

	-- Sposta un colore di un soffio, a caso. Ripetuto su ogni pezzo, e' quello
	-- che toglie l'aria di "tutto uguale, tutto finto".
	local function tinta(color, a)
		local h, s, v = color:ToHSV()
		v = math.clamp(v + (rng:NextNumber() - 0.5) * a, 0, 1)
		s = math.clamp(s + (rng:NextNumber() - 0.5) * a * 0.5, 0, 1)
		return Color3.fromHSV(h, s, v)
	end

	-- Per gli oggetti sparsi: variare parecchio toglie l'aria di plastica.
	local function jc(color) return tinta(color, cfg.ColorJitter) end

	-- Per le SUPERFICI CONTINUE (muri, pannelli, soletta, armadietti) la stessa
	-- variazione e' un difetto invece che un pregio: una parete lunga e' fatta
	-- di molti tratti, e se ognuno ha una tonalita' diversa si vede a chiazze,
	-- come una texture rotta. Qui la variazione dev'essere appena percettibile.
	local function jw(color) return tinta(color, cfg.ColorJitter * 0.22) end

	local W, D = cfg.GridWidth, cfg.GridDepth
	local T, H = cfg.WallThickness, cfg.WallHeight
	-- H e' la quota del controsoffitto, cioe' il "soffitto" che vede il
	-- giocatore. I muri pero' devono salire piu' su, fino alla soletta vera:
	-- altrimenti, dove i pannelli sono caduti, si vedrebbe da una stanza
	-- all'altra passando sopra i muri.
	local EPS = cfg.SeamOverlap
	local PLEN = cfg.PlenumHeight
	local HW = H + PLEN

	-- --- 1. quali file e colonne sono corridoi ---
	local corridorCol, corridorRow = {}, {}
	for x = 2, W, cfg.CorridorEvery do corridorCol[x] = true end
	for y = 2, D, cfg.CorridorEvery do corridorRow[y] = true end

	local function isCorridor(x, y)
		return corridorCol[x] == true or corridorRow[y] == true
	end

	-- --- 2. bordi delle caselle ---
	-- I corridoi sono piu' stretti delle aule, quindi le caselle non sono tutte
	-- uguali: qui calcoliamo dove cade ogni linea della griglia.
	local xEdge, zEdge = {0}, {0}
	for x = 1, W do
		xEdge[x + 1] = xEdge[x] + (corridorCol[x] and cfg.CorridorWidth or cfg.RoomSize)
	end
	for y = 1, D do
		zEdge[y + 1] = zEdge[y] + (corridorRow[y] and cfg.CorridorWidth or cfg.RoomSize)
	end
	local totalX, totalZ = xEdge[W + 1], zEdge[D + 1]

	-- --- 3. raggruppa le caselle in stanze ---
	local space = {}
	for x = 1, W do space[x] = {} end
	for y = 1, D do
		for x = 1, W do
			if isCorridor(x, y) then space[x][y] = 0 end -- 0 = corridoio
		end
	end

	local function free(x, y)
		return x >= 1 and x <= W and y >= 1 and y <= D
			and not isCorridor(x, y) and space[x][y] == nil
	end

	local nextId = 0
	for y = 1, D do
		for x = 1, W do
			if free(x, y) then
				nextId += 1
				local w = (free(x + 1, y) and rng:NextNumber() < cfg.MergeChance) and 2 or 1
				local h = 1
				if free(x, y + 1) and (w == 1 or free(x + 1, y + 1))
					and rng:NextNumber() < cfg.MergeChance then
					h = 2
				end
				for dx = 0, w - 1 do
					for dy = 0, h - 1 do
						space[x + dx][y + dy] = nextId
					end
				end
			end
		end
	end

	-- --- 4. una porta per ogni aula ---
	local candidates = {}
	local function addCandidate(id, edge)
		if id and id > 0 then
			candidates[id] = candidates[id] or {}
			table.insert(candidates[id], edge)
		end
	end

	local edges = {}
	for y = 1, D do
		for x = 1, W - 1 do
			local a, b = space[x][y], space[x + 1][y]
			if a ~= b then
				local e = { axis = "Z", fixed = xEdge[x + 1], from = zEdge[y], to = zEdge[y + 1], mode = "solid" }
				table.insert(edges, e)
				if a == 0 then addCandidate(b, e) elseif b == 0 then addCandidate(a, e) end
			end
		end
	end
	for y = 1, D - 1 do
		for x = 1, W do
			local a, b = space[x][y], space[x][y + 1]
			if a ~= b then
				local e = { axis = "X", fixed = zEdge[y + 1], from = xEdge[x], to = xEdge[x + 1], mode = "solid" }
				table.insert(edges, e)
				if a == 0 then addCandidate(b, e) elseif b == 0 then addCandidate(a, e) end
			end
		end
	end

	for _, list in pairs(candidates) do
		list[rng:NextInteger(1, #list)].mode = "door"
	end

	-- --- 5. muri esterni, con l'ingresso e le finestre ---
	local entranceCol
	for x = 1, W do
		if corridorCol[x] then entranceCol = x end
	end
	entranceCol = entranceCol or math.ceil(W / 2)

	local function exterior(axis, fixed, from, to, isEntrance)
		local mode = "solid"
		if isEntrance then
			mode = "door"
		elseif rng:NextNumber() < cfg.WindowChance then
			mode = "window"
		end
		table.insert(edges, { axis = axis, fixed = fixed, from = from, to = to, mode = mode })
	end

	for x = 1, W do
		exterior("X", 0, xEdge[x], xEdge[x + 1], false)
		exterior("X", totalZ, xEdge[x], xEdge[x + 1], x == entranceCol)
	end
	for y = 1, D do
		exterior("Z", 0, zEdge[y], zEdge[y + 1], false)
		exterior("Z", totalX, zEdge[y], zEdge[y + 1], false)
	end

	-- --- 6. tira su i muri ---
	local walls = Instance.new("Folder")
	walls.Name = "Muri"
	walls.Parent = parent

	-- Posizioni dove potrebbe entrare luce da fuori (finestre e buchi nel
	-- soffitto). Le raccogliamo tutte e alla fine ne accendiamo solo alcune.
	local fillCandidates = {}

	-- Un tratto di muro: il muro vero piu', se tocca terra, la zoccolatura.
	local function segment(axis, fixed, from, to, height, yBottom)
		if to - from < 0.05 then return end

		-- LA CORREZIONE PIU' IMPORTANTE DI QUESTO FILE.
		-- Due tratti di muro che combaciano esatti lasciano passare una riga di
		-- luce lungo la congiunzione: il motore non chiude perfettamente il
		-- contatto fra due facce coincidenti, e quelle righe chiare lungo ogni
		-- giunzione sono cio' che si vede come "parete glitchata". Facendoli
		-- sovrapporre di sei centesimi il problema sparisce, e sei centesimi
		-- non si vedono.
		local a, b = from - EPS, to + EPS
		local len = b - a
		local mid = (a + b) / 2

		if axis == "X" then
			part(walls, {
				Size = Vector3.new(len, height, T),
				CFrame = CFrame.new(mid, yBottom + height / 2, fixed),
				Color = jw(C_WALL),
			})
		else
			part(walls, {
				Size = Vector3.new(T, height, len),
				CFrame = CFrame.new(fixed, yBottom + height / 2, mid),
				Color = jw(C_WALL),
			})
		end

		-- La modanatura orizzontale a meta' parete. Nei corridoi degli edifici
		-- pubblici c'e' quasi sempre. Serve a due cose: rompe la parete piatta,
		-- e da' una linea orizzontale che segue la prospettiva — che e' proprio
		-- cio' che rende leggibile un corridoio lungo.
		if cfg.PictureRail and yBottom < 0.1 and height > 12 and len > 4 then
			local ry = cfg.BaseboardHeight + 4.5
			part(walls, {
				Size = (axis == "X") and Vector3.new(len, 0.5, T + 0.5)
					or Vector3.new(T + 0.5, 0.5, len),
				CFrame = (axis == "X") and CFrame.new(mid, ry, fixed)
					or CFrame.new(fixed, ry, mid),
				Color = jw(C_TRIM),
			})
		end

		-- Intonaco caduto, col mattone sotto. E' l'unico modo che ho per
		-- simulare una superficie rovinata senza usare immagini: una toppa di
		-- colore e materiale diversi, appiccicata al muro.
		if len > 6 and rng:NextNumber() < cfg.WallDamage then
			local pw = math.min(len * 0.5, rng:NextNumber() * 9 + 3)
			local ph = math.min(height * 0.6, rng:NextNumber() * 6 + 2)
			local px = from + pw / 2 + rng:NextNumber() * (len - pw)
			local py = yBottom + ph / 2 + rng:NextNumber() * (height - ph)
			local lato = rng:NextNumber() < 0.5 and 1 or -1
			if axis == "X" then
				part(walls, {
					Size = Vector3.new(pw, ph, 0.4),
					CFrame = CFrame.new(px, py, fixed + lato * (T / 2 + 0.1)),
					Color = jc(C_DAMAGE), Material = Enum.Material.Brick, CanCollide = false,
				})
			else
				part(walls, {
					Size = Vector3.new(0.4, ph, pw),
					CFrame = CFrame.new(fixed + lato * (T / 2 + 0.1), py, px),
					Color = jc(C_DAMAGE), Material = Enum.Material.Brick, CanCollide = false,
				})
			end
		end

		-- La fascia dipinta in basso. Sporge di poco dal muro: e' quel gradino
		-- che l'occhio legge come "edificio vero" invece che "scatola".
		if cfg.Baseboard and yBottom < 0.1 then
			local bh = cfg.BaseboardHeight
			if axis == "X" then
				part(walls, {
					Size = Vector3.new(len, bh, T + 0.35),
					CFrame = CFrame.new(mid, bh / 2, fixed),
					Color = jw(C_TRIM),
				})
			else
				part(walls, {
					Size = Vector3.new(T + 0.35, bh, len),
					CFrame = CFrame.new(fixed, bh / 2, mid),
					Color = jw(C_TRIM),
				})
			end
		end
	end

	-- Cornice attorno a un vano: due montanti, un traverso sopra e, per le
	-- finestre, il davanzale sotto. "yBottom" e' da dove parte: 0 per le porte,
	-- l'altezza del davanzale per le finestre.
	local function frame(axis, fixed, mid, width, yBottom, height)
		if not cfg.DoorFrames then return end
		local half = width / 2
		local t = 0.7

		local function pezzo(w, h, d, py, pOff)
			local size = (axis == "X") and Vector3.new(w, h, d) or Vector3.new(d, h, w)
			local pos = (axis == "X")
				and Vector3.new(mid + pOff, py, fixed)
				or Vector3.new(fixed, py, mid + pOff)
			part(walls, {
				Size = size, CFrame = CFrame.new(pos),
				Color = jw(C_FRAME), Material = Enum.Material.WoodPlanks,
			})
		end

		for _, side in ipairs({ -1, 1 }) do
			pezzo(t, height, T + 0.5, yBottom + height / 2, side * half)
		end
		pezzo(width + t, t, T + 0.5, yBottom + height, 0)
		if yBottom > 0.1 then
			pezzo(width + t, t, T + 1.2, yBottom, 0)   -- il davanzale sporge di piu'
		end
	end

	-- PILASTRINI AGLI INCROCI DEI MURI.
	-- Fanno due lavori insieme. Coprono lo spigolo dove due tratti di muro si
	-- incontrano, che e' il punto dove ogni difetto si vede di piu'. E sono
	-- architettura vera: i pilastri che nei corridoi lunghi scandiscono la
	-- parete e danno il ritmo alla prospettiva.
	if cfg.CornerPosts then
		local nodi = {}
		local function nodo(px, pz)
			local k = string.format("%.2f:%.2f", px, pz)
			nodi[k] = (nodi[k] or 0) + 1
		end
		for _, e in ipairs(edges) do
			if e.axis == "X" then
				nodo(e.from, e.fixed); nodo(e.to, e.fixed)
			else
				nodo(e.fixed, e.from); nodo(e.fixed, e.to)
			end
		end
		for chiave, quanti in pairs(nodi) do
			-- uno solo vuol dire un muro che finisce nel nulla: li' non c'e'
			-- nessuno spigolo da coprire
			if quanti >= 2 then
				local sx2, sz2 = string.match(chiave, "([^:]+):([^:]+)")
				part(walls, {
					Size = Vector3.new(T + 0.7, HW, T + 0.7),
					CFrame = CFrame.new(tonumber(sx2), HW / 2, tonumber(sz2)),
					Color = jw(C_WALL),
				})
			end
		end
	end

	local SILL, HEAD = 4, 10.5   -- altezza del davanzale e della sommita' delle finestre

	for _, e in ipairs(edges) do
		local mid = (e.from + e.to) / 2

		if e.mode == "door" then
			local half = cfg.DoorWidth / 2
			segment(e.axis, e.fixed, e.from, mid - half, HW, 0)
			segment(e.axis, e.fixed, mid + half, e.to, HW, 0)
			local lintel = HW - cfg.DoorHeight
			if lintel > 0.05 then
				segment(e.axis, e.fixed, mid - half, mid + half, lintel, cfg.DoorHeight)
			end
			frame(e.axis, e.fixed, mid, cfg.DoorWidth, 0, cfg.DoorHeight)

			-- L'anta, spalancata. Un vano vuoto sembra un buco nel muro; una
			-- porta aperta di traverso dice che qualcuno e' passato di qui.
			-- Non fa collisione: se l'angolo la mettesse di traverso nel
			-- passaggio, non deve poter intrappolare nessuno.
			if rng:NextNumber() < cfg.DoorSlabs then
				local dw, dh = cfg.DoorWidth - 0.6, cfg.DoorHeight - 0.4
				local lato = rng:NextNumber() < 0.5 and 1 or -1
				local cardine = mid + lato * (cfg.DoorWidth / 2)
				local ang = math.rad(rng:NextInteger(35, 100)) * (rng:NextNumber() < 0.5 and 1 or -1)
				local base = (e.axis == "X")
					and CFrame.new(cardine, dh / 2 + 0.2, e.fixed)
					or CFrame.new(e.fixed, dh / 2 + 0.2, cardine)
				local yaw = (e.axis == "X") and 0 or math.rad(90)
				part(walls, {
					Size = Vector3.new(dw, dh, 0.4),
					CFrame = base * CFrame.Angles(0, yaw + ang, 0) * CFrame.new(-lato * dw / 2, 0, 0),
					Color = jw(C_FRAME), Material = Enum.Material.WoodPlanks,
					CanCollide = false,
				})
			end

		elseif e.mode == "window" then
			local wWidth = math.min(cfg.DoorWidth + 4, (e.to - e.from) - 6)
			if wWidth < 4 then
				segment(e.axis, e.fixed, e.from, e.to, HW, 0)
			else
				local half = wWidth / 2
				-- muro pieno ai lati, sotto il davanzale e sopra la finestra
				segment(e.axis, e.fixed, e.from, mid - half, HW, 0)
				segment(e.axis, e.fixed, mid + half, e.to, HW, 0)
				segment(e.axis, e.fixed, mid - half, mid + half, SILL, 0)
				segment(e.axis, e.fixed, mid - half, mid + half, HW - HEAD, HEAD)
				frame(e.axis, e.fixed, mid, wWidth, SILL, HEAD - SILL)

				local gh = HEAD - SILL
				local centro = (e.axis == "X")
					and Vector3.new(mid, SILL + gh / 2, e.fixed)
					or Vector3.new(e.fixed, SILL + gh / 2, mid)

				-- I traversi restano anche quando il vetro non c'e' piu'.
				-- Senza, l'apertura e' un rettangolo vuoto e si vede che e' finta.
				local function traverso(size)
					part(walls, {
						Size = size, CFrame = CFrame.new(centro),
						Color = jw(C_FRAME), Material = Enum.Material.WoodPlanks,
						CanCollide = false,
					})
				end
				if e.axis == "X" then
					traverso(Vector3.new(0.45, gh, T * 0.5))
					traverso(Vector3.new(wWidth, 0.45, T * 0.5))
				else
					traverso(Vector3.new(T * 0.5, gh, 0.45))
					traverso(Vector3.new(T * 0.5, 0.45, wWidth))
				end

				if rng:NextNumber() > cfg.BrokenGlass then
					part(walls, {
						Name = "Vetro",
						Size = (e.axis == "X") and Vector3.new(wWidth, gh, 0.3)
							or Vector3.new(0.3, gh, wWidth),
						CFrame = CFrame.new(centro),
						Color = C_GLASS, Material = Enum.Material.Glass,
						Transparency = 0.65, Reflectance = 0.08,
					})
				else
					-- il vetro rotto e' finito per terra, dentro
					local verso = (e.axis == "X")
						and (e.fixed < totalZ / 2 and 1 or -1)
						or (e.fixed < totalX / 2 and 1 or -1)
					for _ = 1, rng:NextInteger(4, 8) do
						local lungo = (rng:NextNumber() - 0.5) * wWidth * 1.3
						local dentro = verso * (rng:NextNumber() * 6 + 1)
						part(walls, {
							Size = Vector3.new(rng:NextNumber() * 1.3 + 0.3, 0.06,
								rng:NextNumber() * 1.3 + 0.3),
							CFrame = CFrame.new(
								(e.axis == "X") and mid + lungo or e.fixed + dentro, 0.06,
								(e.axis == "X") and e.fixed + dentro or mid + lungo)
								* CFrame.Angles(0, rng:NextNumber() * 6.28, 0),
							Color = C_GLASS, Material = Enum.Material.Glass,
							Transparency = 0.4, Reflectance = 0.15, CanCollide = false,
						})
					end
				end

				-- La luce lunare che entra. E' fredda apposta: contro il giallo
				-- della torcia si capisce a colpo d'occhio da dove viene la luce,
				-- e le finestre diventano punti di orientamento.
				-- Qui segniamo solo la posizione: quali accendere si decide dopo.
				table.insert(fillCandidates, {
					pos = (e.axis == "X")
						and Vector3.new(mid, (SILL + HEAD) / 2, e.fixed)
						or Vector3.new(e.fixed, (SILL + HEAD) / 2, mid),
					range = 30, brightness = cfg.MoonLight,
				})
			end

		else
			segment(e.axis, e.fixed, e.from, e.to, HW, 0)
		end
	end

	-- --- 7. pavimento, piazzale, soffitto ---
	part(parent, {
		Name = "Pavimento",
		Size = Vector3.new(totalX, 2, totalZ),
		CFrame = CFrame.new(totalX / 2, -1, totalZ / 2),
		Color = C_FLOOR, Material = Enum.Material.Slate,
	})

	-- Piazzale esterno. Senza, chi compare fuori o esce dalla porta cade nel
	-- vuoto: il pavimento di sopra copre solo l'interno dell'edificio.
	local margine = 70
	part(parent, {
		Name = "Piazzale",
		Size = Vector3.new(totalX + margine * 2, 2, totalZ + margine * 2),
		CFrame = CFrame.new(totalX / 2, -1.15, totalZ / 2),
		Color = Color3.fromRGB(54, 54, 52), Material = Enum.Material.Asphalt,
	})

	-- =========================================================
	--  IL CONTROSOFFITTO CROLLATO
	--
	--  Due strati sovrapposti:
	--    quota HW = H + PLEN : la soletta vera, scura, con le travi
	--    quota H             : i pannelli chiari, appesi a un'orditura
	--
	--  Dove i pannelli sono caduti si apre il buio della struttura, ed e'
	--  quel contrasto — chiaro sotto, nero sopra — a fare tutto il lavoro.
	-- =========================================================
	local ceilings = Instance.new("Folder")
	ceilings.Name = "Controsoffitto"
	ceilings.Parent = parent

	-- Le ZONE di crollo. E' il punto che distingue un crollo credibile da uno
	-- finto: il soffitto non cade a pannelli sparsi, cade a chiazze. Scegliendo
	-- pannello per pannello a caso verrebbe una grattugia, non uno squarcio.
	local centers = {}
	for _ = 1, cfg.CeilingCollapses do
		table.insert(centers, {
			x = rng:NextNumber() * totalX,
			z = rng:NextNumber() * totalZ,
			r = cfg.CollapseRadius * (0.55 + rng:NextNumber() * 0.9),
		})
	end

	-- Dove manca la soletta vera, sotto e' per forza crollato tutto.
	local roofHole = {}
	for _ = 1, cfg.RoofHoles do
		local hx, hz = rng:NextInteger(1, W), rng:NextInteger(1, D)
		roofHole[hx .. ":" .. hz] = true
		table.insert(centers, {
			x = (xEdge[hx] + xEdge[hx + 1]) / 2,
			z = (zEdge[hz] + zEdge[hz + 1]) / 2,
			r = cfg.CollapseRadius * 0.75,
		})
	end

	-- Un pannello e' caduto? Al centro di una chiazza sempre, verso il bordo
	-- sempre meno: e' il bordo sfumato che fa sembrare un crollo invece di un
	-- ritaglio col righello.
	local function caduto(px, pz)
		for _, c in ipairs(centers) do
			local dx, dz = px - c.x, pz - c.z
			local t = math.sqrt(dx * dx + dz * dz) / c.r
			if t < 1 and rng:NextNumber() > t * t then return true end
		end
		return rng:NextNumber() < cfg.StrayHoleChance
	end

	for y = 1, D do
		for x = 1, W do
			local x0, x1 = xEdge[x], xEdge[x + 1]
			local z0, z1 = zEdge[y], zEdge[y + 1]
			local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2

			-- --- la soletta vera ---
			if roofHole[x .. ":" .. y] then
				table.insert(fillCandidates, {
					pos = Vector3.new(cx, HW - 1.5, cz),
					range = 42, brightness = cfg.MoonLight * 1.5,
				})
			else
				part(ceilings, {
					Size = Vector3.new(x1 - x0, 1, z1 - z0),
					CFrame = CFrame.new(cx, HW + 0.5, cz),
					Color = jw(C_DECK),
				})
			end

			-- --- quali pannelli sono caduti ---
			local nx = math.max(1, math.floor((x1 - x0) / cfg.CeilingTile))
			local nz = math.max(1, math.floor((z1 - z0) / cfg.CeilingTile))
			local tw, td = (x1 - x0) / nx, (z1 - z0) / nz

			local buco, quanti = {}, 0
			for i = 1, nx do
				buco[i] = {}
				for j = 1, nz do
					local h = caduto(x0 + (i - 0.5) * tw, z0 + (j - 0.5) * td)
					buco[i][j] = h
					if h then quanti += 1 end
				end
			end
			local frazione = quanti / (nx * nz)

			-- --- i pannelli rimasti ---
			-- Accorpati per file: una fila di pannelli intatti diventa UN pezzo
			-- invece di sei. A vedersi e' identico, e costa un quarto.
			for j = 1, nz do
				local inizio = nil
				for i = 1, nx + 1 do
					local intatto = (i <= nx) and not buco[i][j]
					if intatto then
						inizio = inizio or i
					elseif inizio then
						local a = x0 + (inizio - 1) * tw
						local b = x0 + (i - 1) * tw
						part(ceilings, {
							Size = Vector3.new(b - a, 0.4, td),
							CFrame = CFrame.new((a + b) / 2, H, z0 + (j - 0.5) * td),
							Color = jw(C_PANEL), Material = Enum.Material.Sandstone,
						})
						inizio = nil
					end
				end
			end

			-- --- l'orditura metallica ---
			-- Solo dove il crollo e' parziale: se non e' caduto niente non si
			-- vede comunque, e se e' caduto tutto e' venuta giu' anche lei.
			if frazione > 0.15 and frazione < 0.9 then
				for i = 0, nx do
					part(ceilings, {
						Size = Vector3.new(0.25, 0.3, z1 - z0),
						CFrame = CFrame.new(x0 + i * tw, H + 0.35, cz),
						Color = jc(C_TBAR), Material = Enum.Material.Metal,
						CanCollide = false,
					})
				end
				for j = 0, nz do
					part(ceilings, {
						Size = Vector3.new(x1 - x0, 0.3, 0.25),
						CFrame = CFrame.new(cx, H + 0.35, z0 + j * td),
						Color = jc(C_TBAR), Material = Enum.Material.Metal,
						CanCollide = false,
					})
				end
			end

			-- --- fili appesi nel vuoto, e pannelli che pendono ---
			for i = 1, nx do
				for j = 1, nz do
					if buco[i][j] then
						local px = x0 + (i - 0.5) * tw
						local pz = z0 + (j - 0.5) * td

						-- il filo che reggeva il pannello, rimasto li'
						if rng:NextNumber() < cfg.HangerChance then
							part(ceilings, {
								Size = Vector3.new(0.14, PLEN, 0.14),
								CFrame = CFrame.new(px, H + PLEN / 2, pz),
								Color = jc(C_TBAR), Material = Enum.Material.Metal,
								CanCollide = false,
							})
						end

						-- Un pannello staccato da un lato che pende. Ha senso
						-- solo sul BORDO di uno squarcio: in mezzo al vuoto
						-- sarebbe appeso a niente.
						local bordo = (i > 1 and not buco[i - 1][j])
							or (i < nx and not buco[i + 1][j])
							or (j > 1 and not buco[i][j - 1])
							or (j < nz and not buco[i][j + 1])
						if bordo and rng:NextNumber() < cfg.HangingPanels then
							part(ceilings, {
								Size = Vector3.new(tw * 0.85, 0.4, td * 0.85),
								CFrame = CFrame.new(px, H - 1.4, pz)
									* CFrame.Angles(
										math.rad(rng:NextInteger(28, 62)),
										rng:NextNumber() * 6.28, 0),
								Color = jw(C_PANEL), Material = Enum.Material.Sandstone,
								CanCollide = false,
							})
						end
					end
				end
			end

			-- --- cavi che penzolano ---
			-- Nella foto di riferimento e' il dettaglio che dice "qui dentro
			-- qualcosa si e' rotto e nessuno l'ha aggiustato".
			if isCorridor(x, y) and rng:NextNumber() < cfg.DanglingCables then
				local len = rng:NextNumber() * 4 + 2.5
				part(ceilings, {
					Size = Vector3.new(0.18, len, 0.18),
					CFrame = CFrame.new(
						cx + (rng:NextNumber() - 0.5) * 6,
						H - len / 2 + 0.4,
						cz + (rng:NextNumber() - 0.5) * 6)
						* CFrame.Angles(math.rad(rng:NextInteger(-15, 15)), 0,
							math.rad(rng:NextInteger(-15, 15))),
					Color = C_CABLE, Material = Enum.Material.SmoothPlastic,
					CanCollide = false,
				})
			end
		end
	end

	-- --- le travi della soletta ---
	-- Attraversano tutto l'edificio invece di essere spezzate stanza per
	-- stanza: cosi' sono 20 pezzi invece di 200, e dove il controsoffitto e'
	-- caduto si vede la struttura proseguire nel buio.
	local passoTravi = 9
	local b = passoTravi / 2
	while b < totalZ do
		part(ceilings, {
			Size = Vector3.new(totalX, 1.1, 0.9),
			CFrame = CFrame.new(totalX / 2, HW - 0.7, b),
			Color = jc(C_BEAM), Material = Enum.Material.Metal,
			CanCollide = false,
		})
		b += passoTravi
	end

	-- --- 7b. accendi la luna, ma con giudizio ---
	-- Le luci dinamiche costano, e oltre una certa soglia Roblox ne scarta
	-- alcune a caso: si vedrebbero sparire mentre cammini. Meglio sceglierne
	-- noi un numero fisso. Le mescoliamo prima, altrimenti prenderemmo sempre
	-- quelle di un angolo solo: la mappa si costruisce riga per riga.
	local moonFolder = Instance.new("Folder")
	moonFolder.Name = "Luna"
	moonFolder.Parent = parent

	for i = #fillCandidates, 2, -1 do
		local j = rng:NextInteger(1, i)
		fillCandidates[i], fillCandidates[j] = fillCandidates[j], fillCandidates[i]
	end

	for i = 1, math.min(cfg.MaxFillLights, #fillCandidates) do
		local spot = fillCandidates[i]
		local moon = Instance.new("PointLight")
		moon.Range      = spot.range
		moon.Brightness = spot.brightness
		moon.Color      = C_MOON
		moon.Shadows    = false   -- riempimento: le ombre qui costerebbero e non si noterebbero
		moon.Parent = part(moonFolder, {
			Size = Vector3.new(0.2, 0.2, 0.2),
			CFrame = CFrame.new(spot.pos),
			Transparency = 1, CanCollide = false, CanQuery = false,
		})
	end

	-- --- 8. arredamento e sporcizia ---
	local props = Instance.new("Folder")
	props.Name = "Arredamento"
	props.Parent = parent

	local seen = {}
	for y = 1, D do
		for x = 1, W do
			local id = space[x][y]
			local cx = (xEdge[x] + xEdge[x + 1]) / 2
			local cz = (zEdge[y] + zEdge[y + 1]) / 2
			local sx = xEdge[x + 1] - xEdge[x]
			local sz = zEdge[y + 1] - zEdge[y]
			local along = corridorRow[y] == true   -- il corridoio corre lungo X?

			if id == 0 then
				-- ARMADIETTI: una fila CONTINUA contro un muro.
				-- Un armadietto isolato in mezzo a un corridoio non esiste: quello
				-- che l'occhio riconosce e' la teoria di ante uguali di fila, con
				-- le fughe verticali fra l'una e l'altra. Prima ne mettevo quattro
				-- staccati, e infatti sembravano quattro scatole.
				local lungoAsse = along and sx or sz
				local perpAsse  = along and sz or sx
				-- La fila sta in una meta' sola della casella: al centro del muro
				-- cade il vano porta, e murare un'aula sarebbe un difetto grave.
				local estensione = lungoAsse / 2 - cfg.DoorWidth / 2 - 2

				if estensione >= 4 and rng:NextNumber() < cfg.LockerChance then
					local lato = rng:NextNumber() < 0.5 and -1 or 1
					local verso = rng:NextNumber() < 0.5 and -1 or 1
					local DEPTH, HEIGHT = 2.6, 8.5
					local centroFila = (along and cx or cz)
						+ verso * (cfg.DoorWidth / 2 + 1 + estensione / 2)
					local muro = (along and cz or cx)
						+ lato * (perpAsse / 2 - DEPTH / 2 - T / 2 - 0.2)

					-- un pezzo della fila, orientato secondo il corridoio
					local function pezzo(lungo, alto, prof, lungoPos, altoPos, col, mat)
						part(props, {
							Size = along and Vector3.new(lungo, alto, prof)
								or Vector3.new(prof, alto, lungo),
							CFrame = CFrame.new(
								along and lungoPos or muro, altoPos,
								along and muro or lungoPos),
							Color = col or jw(C_LOCKER),
							Material = mat or Enum.Material.DiamondPlate,
						})
					end

					pezzo(estensione, HEIGHT, DEPTH, centroFila, 0.8 + HEIGHT / 2)
					pezzo(estensione + 0.5, 0.8, DEPTH + 0.5, centroFila, 0.4)              -- zoccolo
					pezzo(estensione + 0.5, 0.7, DEPTH + 0.6, centroFila, 0.8 + HEIGHT)     -- cimasa

					-- Le fughe fra un'anta e l'altra. Sono il dettaglio che fa
					-- leggere "armadietti" invece che "parallelepipedo grigio".
					local ante = math.max(2, math.floor(estensione / 3))
					local passo = estensione / ante
					for k = 0, ante do
						pezzo(0.2, HEIGHT - 1, DEPTH + 0.3,
							centroFila - estensione / 2 + k * passo, 0.8 + HEIGHT / 2,
							Color3.fromRGB(28, 30, 31), Enum.Material.Metal)
					end

					-- Un'anta spalancata, perpendicolare alla fila. La tengo a 90
					-- gradi esatti invece che a un angolo casuale: cosi' non c'e'
					-- modo che finisca dentro il muro.
					if rng:NextNumber() < 0.5 then
						local k = rng:NextInteger(0, ante - 1)
						local cardine = centroFila - estensione / 2 + (k + 0.05) * passo
						local fuori = muro - lato * (DEPTH / 2 + passo * 0.46)
						part(props, {
							Size = along and Vector3.new(0.2, HEIGHT - 1.4, passo * 0.92)
								or Vector3.new(passo * 0.92, HEIGHT - 1.4, 0.2),
							CFrame = CFrame.new(
								along and cardine or fuori, 0.8 + HEIGHT / 2,
								along and fuori or cardine),
							Color = jw(C_LOCKER), Material = Enum.Material.CorrodedMetal,
							CanCollide = false,
						})
					end
				end

				-- tubi sotto il soffitto
				if rng:NextNumber() < cfg.PipeChance then
					local off = (rng:NextNumber() - 0.5) * (along and sz or sx) * 0.5
					part(props, {
						Size = along and Vector3.new(sx, 0.8, 0.8) or Vector3.new(0.8, 0.8, sz),
						CFrame = CFrame.new(along and cx or cx + off, H + PLEN * 0.55, along and cz + off or cz),
						Color = jc(C_METAL), Material = Enum.Material.CorrodedMetal,
						CanCollide = false,
					})
				end

				-- pozze: riflettono il fascio della torcia
				if rng:NextNumber() < cfg.PuddleChance then
					local r = rng:NextNumber() * 6 + 3
					part(props, {
						Size = Vector3.new(r, 0.08, r * 0.7),
						CFrame = CFrame.new(
							cx + (rng:NextNumber() - 0.5) * (sx - 6), 0.04,
							cz + (rng:NextNumber() - 0.5) * (sz - 6)
						) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0),
						Color = Color3.fromRGB(22, 24, 26),
						Material = Enum.Material.SmoothPlastic,
						Reflectance = 0.22, CanCollide = false,
					})
				end

			elseif not seen[id] then
				-- l'aula si arreda una volta sola, alla prima casella che incontriamo
				seen[id] = true
				for _ = 1, cfg.DesksPerRoom do
					local px = cx + (rng:NextNumber() - 0.5) * (sx - 8)
					local pz = cz + (rng:NextNumber() - 0.5) * (sz - 8)
					local yaw = rng:NextNumber() * 6.28

					if rng:NextNumber() < cfg.OverturnedDesks then
						-- banco rovesciato su un fianco
						part(props, {
							Size = Vector3.new(4, 0.4, 2.5),
							CFrame = CFrame.new(px, 1.3, pz)
								* CFrame.Angles(0, yaw, math.rad(88)),
							Color = jc(C_WOOD), Material = Enum.Material.WoodPlanks,
						})
					else
						local desk = part(props, {
							Size = Vector3.new(4, 0.4, 2.5),
							CFrame = CFrame.new(px, 3, pz) * CFrame.Angles(0, yaw, 0),
							Color = jc(C_WOOD), Material = Enum.Material.WoodPlanks,
						})
						part(props, {
							Size = Vector3.new(0.6, 3, 0.6),
							CFrame = desk.CFrame * CFrame.new(0, -1.5, 0),
							Color = jc(C_METAL),
						})
						if rng:NextNumber() < cfg.ChairChance then
							local seat = part(props, {
								Size = Vector3.new(1.8, 0.3, 1.8),
								CFrame = desk.CFrame * CFrame.new(0, -1, 2.6),
								Color = jc(C_WOOD), Material = Enum.Material.WoodPlanks,
							})
							part(props, {
								Size = Vector3.new(1.8, 1.8, 0.3),
								CFrame = seat.CFrame * CFrame.new(0, 1, 0.75),
								Color = jc(C_WOOD), Material = Enum.Material.WoodPlanks,
							})
						end
					end
				end

				-- lavagna, col gesso ancora sopra
				local board = part(props, {
					Size = Vector3.new(sx * 0.5, 5, 0.4),
					CFrame = CFrame.new(cx, 7, zEdge[y] + 0.9),
					Color = C_BOARD, Material = Enum.Material.Slate,
					CanCollide = false,   -- se il muro dietro ha una porta, non deve tapparla
				})

				local gui = Instance.new("SurfaceGui")
				gui.Face = Enum.NormalId.Back      -- la faccia rivolta verso l'aula
				gui.CanvasSize = Vector2.new(600, 200)
				gui.LightInfluence = 1             -- il gesso si vede solo se lo illumini
				gui.Parent = board

				local testo = Instance.new("TextLabel")
				testo.Size = UDim2.new(1, 0, 1, 0)
				testo.BackgroundTransparency = 1
				testo.Font = Enum.Font.PermanentMarker
				testo.TextScaled = true
				testo.TextColor3 = Color3.fromRGB(228, 226, 214)
				testo.TextTransparency = 0.25
				testo.Text = LAVAGNA[rng:NextInteger(1, #LAVAGNA)]
				testo.Parent = gui
			end

			-- Dove cade la roba per terra. Nei posti abbandonati i detriti non
			-- sono sparsi uniformemente: si ammucchiano contro i muri, perche'
			-- li' nessuno li ha mai calpestati via. Spargerli a caso e' la cosa
			-- che piu' fa sembrare finto un pavimento.
			local function sparso(centro, ampiezza)
				if rng:NextNumber() < cfg.DebrisHugWalls then
					local bordo = rng:NextNumber() < 0.5 and -1 or 1
					return centro + bordo * (ampiezza / 2 - 1.5 - rng:NextNumber() * 3)
				end
				return centro + (rng:NextNumber() - 0.5) * (ampiezza - 5)
			end

			-- fogli sparsi ovunque: costano poco e sporcano molto
			for _ = 1, cfg.PapersPerCell do
				part(props, {
					Size = Vector3.new(1.3, 0.04, 0.95),
					CFrame = CFrame.new(sparso(cx, sx), 0.05, sparso(cz, sz))
						* CFrame.Angles(0, rng:NextNumber() * 6.28, 0),
					Color = jc(C_PAPER), Material = Enum.Material.SmoothPlastic,
					CanCollide = false,
				})
			end

			-- calcinacci: rompono la vista, e nel nostro gioco la vista e' meccanica
			for _ = 1, cfg.DebrisPerCell do
				local s = rng:NextNumber() * 2 + 0.6
				part(props, {
					Size = Vector3.new(s, s * 0.4, s),
					CFrame = CFrame.new(sparso(cx, sx), s * 0.2, sparso(cz, sz))
						* CFrame.Angles(0, rng:NextNumber() * 6.28, 0),
					Color = jc(C_CEIL), Material = Enum.Material.Rock,
				})
			end
		end
	end

	-- --- 9. i pochi neon ancora vivi ---
	local lights = Instance.new("Folder")
	lights.Name = "Neon"
	lights.Parent = parent

	local spots = {}
	for y = 1, D do
		for x = 1, W do
			if isCorridor(x, y) then
				table.insert(spots, Vector3.new(
					(xEdge[x] + xEdge[x + 1]) / 2, H - 1.2, (zEdge[y] + zEdge[y + 1]) / 2))
			end
		end
	end

	for _ = 1, math.min(cfg.WorkingLights, #spots) do
		local pick = table.remove(spots, rng:NextInteger(1, #spots))
		-- la plafoniera spenta attorno al tubo: si vede anche da luce spenta
		part(lights, {
			Size = Vector3.new(7, 0.5, 2),
			CFrame = CFrame.new(pick) * CFrame.new(0, 0.5, 0),
			Color = jc(C_METAL), Material = Enum.Material.DiamondPlate,
			CanCollide = false,
		})
		local tube = part(lights, {
			Size = Vector3.new(6, 0.3, 1),
			CFrame = CFrame.new(pick),
			Color = Color3.fromRGB(220, 225, 210),
			Material = Enum.Material.Neon, CanCollide = false,
		})
		local light = Instance.new("PointLight")
		light.Range = 26
		light.Brightness = 1.6
		light.Color = Color3.fromRGB(205, 220, 200)
		light.Shadows = false
		light.Parent = tube
		-- a farli sfarfallare ci pensa Main
		if rng:NextNumber() < cfg.FlickerChance then
			tube:SetAttribute("Flicker", true)
		end
	end

	-- --- 10. la lampada sopra l'ingresso ---
	-- Non e' decorazione: fuori e' nero assoluto e senza un punto verso cui
	-- camminare non si trova la porta. E' anche il riferimento per ritrovare
	-- l'uscita dall'interno.
	local entranceX = (xEdge[entranceCol] + xEdge[entranceCol + 1]) / 2

	local lampada = part(parent, {
		Name = "LampadaIngresso",
		Size = Vector3.new(4, 0.6, 1.2),
		CFrame = CFrame.new(entranceX, cfg.DoorHeight + 2, totalZ + 1.6),
		Color = Color3.fromRGB(255, 236, 190),
		Material = Enum.Material.Neon, CanCollide = false,
	})
	local luce = Instance.new("PointLight")
	luce.Range      = 38
	luce.Brightness = 2.2
	luce.Color      = Color3.fromRGB(255, 226, 170)
	luce.Shadows    = false
	luce.Parent     = lampada
	lampada:SetAttribute("Flicker", true)

	-- --- 11. dove compaiono i giocatori: fuori dall'ingresso, sul piazzale ---
	return CFrame.new(entranceX, 3, totalZ + 16), Vector3.new(totalX, H, totalZ)
end

return MapGenerator
