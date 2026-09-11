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
local C_WALL   = Color3.fromRGB(126, 122, 110)   -- intonaco sporco
local C_TRIM   = Color3.fromRGB(64, 84, 78)      -- verde istituzionale della zoccolatura
local C_FRAME  = Color3.fromRGB(104, 96, 82)     -- stipiti
local C_FLOOR  = Color3.fromRGB(84, 82, 78)
local C_CEIL   = Color3.fromRGB(98, 96, 90)
local C_METAL  = Color3.fromRGB(76, 82, 80)
local C_WOOD   = Color3.fromRGB(94, 72, 50)
local C_BOARD  = Color3.fromRGB(34, 44, 40)
local C_GLASS  = Color3.fromRGB(150, 175, 190)
local C_PAPER  = Color3.fromRGB(196, 190, 172)
local C_MOON   = Color3.fromRGB(126, 158, 210)   -- la luce da fuori: fredda, per contrasto con la torcia

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
	local function jc(color)
		local h, s, v = color:ToHSV()
		local a = cfg.ColorJitter
		v = math.clamp(v + (rng:NextNumber() - 0.5) * a, 0, 1)
		s = math.clamp(s + (rng:NextNumber() - 0.5) * a * 0.5, 0, 1)
		return Color3.fromHSV(h, s, v)
	end

	local W, D = cfg.GridWidth, cfg.GridDepth
	local T, H = cfg.WallThickness, cfg.WallHeight

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
		local len = to - from
		if len < 0.05 then return end
		local mid = (from + to) / 2

		if axis == "X" then
			part(walls, {
				Size = Vector3.new(len, height, T),
				CFrame = CFrame.new(mid, yBottom + height / 2, fixed),
				Color = jc(C_WALL),
			})
		else
			part(walls, {
				Size = Vector3.new(T, height, len),
				CFrame = CFrame.new(fixed, yBottom + height / 2, mid),
				Color = jc(C_WALL),
			})
		end

		-- La fascia dipinta in basso. Sporge di poco dal muro: e' quel gradino
		-- che l'occhio legge come "edificio vero" invece che "scatola".
		if cfg.Baseboard and yBottom < 0.1 then
			local bh = cfg.BaseboardHeight
			if axis == "X" then
				part(walls, {
					Size = Vector3.new(len, bh, T + 0.35),
					CFrame = CFrame.new(mid, bh / 2, fixed),
					Color = jc(C_TRIM),
				})
			else
				part(walls, {
					Size = Vector3.new(T + 0.35, bh, len),
					CFrame = CFrame.new(fixed, bh / 2, mid),
					Color = jc(C_TRIM),
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
				Color = jc(C_FRAME), Material = Enum.Material.WoodPlanks,
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

	local SILL, HEAD = 4, 10.5   -- altezza del davanzale e della sommita' delle finestre

	for _, e in ipairs(edges) do
		local mid = (e.from + e.to) / 2

		if e.mode == "door" then
			local half = cfg.DoorWidth / 2
			segment(e.axis, e.fixed, e.from, mid - half, H, 0)
			segment(e.axis, e.fixed, mid + half, e.to, H, 0)
			local lintel = H - cfg.DoorHeight
			if lintel > 0.05 then
				segment(e.axis, e.fixed, mid - half, mid + half, lintel, cfg.DoorHeight)
			end
			frame(e.axis, e.fixed, mid, cfg.DoorWidth, 0, cfg.DoorHeight)

		elseif e.mode == "window" then
			local wWidth = math.min(cfg.DoorWidth + 4, (e.to - e.from) - 6)
			if wWidth < 4 then
				segment(e.axis, e.fixed, e.from, e.to, H, 0)
			else
				local half = wWidth / 2
				-- muro pieno ai lati, sotto il davanzale e sopra la finestra
				segment(e.axis, e.fixed, e.from, mid - half, H, 0)
				segment(e.axis, e.fixed, mid + half, e.to, H, 0)
				segment(e.axis, e.fixed, mid - half, mid + half, SILL, 0)
				segment(e.axis, e.fixed, mid - half, mid + half, H - HEAD, HEAD)
				frame(e.axis, e.fixed, mid, wWidth, SILL, HEAD - SILL)

				-- il vetro, quando c'e' ancora
				if rng:NextNumber() > cfg.BrokenGlass then
					local gh = HEAD - SILL
					local size = (e.axis == "X")
						and Vector3.new(wWidth, gh, 0.3)
						or Vector3.new(0.3, gh, wWidth)
					local pos = (e.axis == "X")
						and Vector3.new(mid, SILL + gh / 2, e.fixed)
						or Vector3.new(e.fixed, SILL + gh / 2, mid)
					part(walls, {
						Name = "Vetro",
						Size = size, CFrame = CFrame.new(pos),
						Color = C_GLASS, Material = Enum.Material.Glass,
						Transparency = 0.65, Reflectance = 0.08,
					})
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
			segment(e.axis, e.fixed, e.from, e.to, H, 0)
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

	local ceilings = Instance.new("Folder")
	ceilings.Name = "Soffitto"
	ceilings.Parent = parent

	for y = 1, D do
		for x = 1, W do
			local cx = (xEdge[x] + xEdge[x + 1]) / 2
			local cz = (zEdge[y] + zEdge[y + 1]) / 2
			if rng:NextNumber() > cfg.HoleChance then
				part(ceilings, {
					Size = Vector3.new(xEdge[x + 1] - xEdge[x], 1, zEdge[y + 1] - zEdge[y]),
					CFrame = CFrame.new(cx, H + 0.5, cz),
					Color = jc(C_CEIL),
				})
			else
				-- Il soffitto e' crollato: da li' entra la luna. Prima questi
				-- buchi erano solo neri e non si capiva nemmeno che c'erano.
				table.insert(fillCandidates, {
					pos = Vector3.new(cx, H - 1, cz),
					range = 34, brightness = cfg.MoonLight * 1.3,
				})
			end
		end
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
				-- armadietti contro un muro
				if rng:NextNumber() < cfg.LockerChance then
					local lato = rng:NextNumber() < 0.5 and -1 or 1
					-- Posizioni scelte per evitare la meta' del muro: li' cadono i
					-- vani porta, e un armadietto davanti a una porta mura un'aula.
					for _, t in ipairs({ 0.12, 0.3, 0.7, 0.88 }) do
						local px = along and (xEdge[x] + t * sx) or (cx + lato * (sx / 2 - 1.6))
						local pz = along and (cz + lato * (sz / 2 - 1.6)) or (zEdge[y] + t * sz)
						part(props, {
							Size = Vector3.new(along and 3 or 2, 7, along and 2 or 3),
							CFrame = CFrame.new(px, 3.5, pz),
							Color = jc(C_METAL), Material = Enum.Material.DiamondPlate,
						})
						-- uno sportello spalancato ogni tanto
						if rng:NextNumber() < 0.25 then
							part(props, {
								Size = Vector3.new(0.2, 6, 2.6),
								CFrame = CFrame.new(px, 3.5, pz)
									* CFrame.Angles(0, math.rad(along and 65 or -25), 0)
									* CFrame.new(0, 0, 1.6),
								Color = jc(C_METAL), Material = Enum.Material.CorrodedMetal,
								CanCollide = false,
							})
						end
					end
				end

				-- tubi sotto il soffitto
				if rng:NextNumber() < cfg.PipeChance then
					local off = (rng:NextNumber() - 0.5) * (along and sz or sx) * 0.5
					part(props, {
						Size = along and Vector3.new(sx, 0.8, 0.8) or Vector3.new(0.8, 0.8, sz),
						CFrame = CFrame.new(along and cx or cx + off, H - 1.8, along and cz + off or cz),
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

			-- fogli sparsi ovunque: costano poco e sporcano molto
			for _ = 1, cfg.PapersPerCell do
				part(props, {
					Size = Vector3.new(1.3, 0.04, 0.95),
					CFrame = CFrame.new(
						cx + (rng:NextNumber() - 0.5) * (sx - 3), 0.05,
						cz + (rng:NextNumber() - 0.5) * (sz - 3)
					) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0),
					Color = jc(C_PAPER), Material = Enum.Material.SmoothPlastic,
					CanCollide = false,
				})
			end

			-- calcinacci: rompono la vista, e nel nostro gioco la vista e' meccanica
			for _ = 1, cfg.DebrisPerCell do
				local s = rng:NextNumber() * 2 + 0.6
				part(props, {
					Size = Vector3.new(s, s * 0.4, s),
					CFrame = CFrame.new(
						cx + (rng:NextNumber() - 0.5) * (sx - 4), s * 0.2,
						cz + (rng:NextNumber() - 0.5) * (sz - 4)
					) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0),
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
