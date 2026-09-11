--[[
	MapGenerator — costruisce la scuola abbandonata.

	Nessun modello 3D: tutto e' fatto di parallelepipedi ("Part") creati dal
	codice. Brutti da vicino, ma al buio non si vedono — e si cambiano
	cambiando un numero, invece che rifacendoli a mano.

	Come ragiona:
	  1. divide l'edificio in una griglia di caselle;
	  2. alcune file/colonne diventano corridoi (stretti), le altre aule (larghe);
	  3. le aule vicine a volte si fondono, cosi' non sono tutte uguali;
	  4. mette un muro fra due caselle solo se appartengono a stanze diverse;
	  5. ogni aula riceve UNA porta verso un corridoio;
	  6. sparge banchi, armadietti, calcinacci e qualche neon ancora vivo.

	Dove va in Studio:  ServerScriptService > MapGenerator   (ModuleScript)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local MapGenerator = {}

-- ------------------------------------------------------------
--  Colori e materiali: la tavolozza dello "sporco"
-- ------------------------------------------------------------
local C_WALL    = Color3.fromRGB(118, 114, 103)
local C_FLOOR   = Color3.fromRGB(84, 82, 78)
local C_CEIL    = Color3.fromRGB(96, 94, 88)
local C_METAL   = Color3.fromRGB(78, 84, 82)
local C_WOOD    = Color3.fromRGB(92, 72, 52)
local C_BOARD   = Color3.fromRGB(38, 46, 42)

-- Crea un blocco. "props" sono le proprieta' da cambiare rispetto al default.
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

-- ------------------------------------------------------------
--  Costruzione
-- ------------------------------------------------------------

-- parent: dove mettere l'edificio.  Ritorna: dove far comparire i giocatori.
function MapGenerator.build(parent)
	local cfg = GameConfig
	local rng = Random.new(cfg.Seed ~= 0 and cfg.Seed or os.clock() * 1e6)

	local W, D = cfg.GridWidth, cfg.GridDepth

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
	-- Ogni casella riceve un "identificativo di spazio": tutti i corridoi
	-- condividono lo stesso (sono un unico ambiente), ogni aula ha il suo.
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
				-- prova ad allargare l'aula di una casella a destra e/o in basso
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

	-- --- 4. scegli una porta per ogni aula ---
	-- Raccogliamo tutti i confini aula/corridoio e ne promuoviamo uno a porta.
	local candidates = {}   -- candidates[idAula] = lista di confini
	local function addCandidate(id, edge)
		if id and id > 0 then
			candidates[id] = candidates[id] or {}
			table.insert(candidates[id], edge)
		end
	end

	local edges = {}
	-- confini verticali: fra la casella (x,y) e (x+1,y)
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
	-- confini orizzontali: fra la casella (x,y) e (x,y+1)
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
		local pick = list[rng:NextInteger(1, #list)]
		pick.mode = "door"
	end

	-- --- 5. muri esterni, con l'ingresso ---
	-- L'ingresso cade su un corridoio del lato sud, cosi' si entra dritti dentro.
	local entranceCol
	for x = 1, W do
		if corridorCol[x] then entranceCol = x end
	end
	entranceCol = entranceCol or math.ceil(W / 2)

	for x = 1, W do
		table.insert(edges, { axis = "X", fixed = 0, from = xEdge[x], to = xEdge[x + 1], mode = "solid" })
		table.insert(edges, { axis = "X", fixed = totalZ, from = xEdge[x], to = xEdge[x + 1],
			mode = (x == entranceCol) and "door" or "solid" })
	end
	for y = 1, D do
		table.insert(edges, { axis = "Z", fixed = 0, from = zEdge[y], to = zEdge[y + 1], mode = "solid" })
		table.insert(edges, { axis = "Z", fixed = totalX, from = zEdge[y], to = zEdge[y + 1], mode = "solid" })
	end

	-- --- 6. tira su i muri ---
	local walls = Instance.new("Folder")
	walls.Name = "Muri"
	walls.Parent = parent

	local T, H = cfg.WallThickness, cfg.WallHeight

	local function segment(axis, fixed, from, to, height, yBottom)
		local len = to - from
		if len < 0.05 then return end
		local mid = (from + to) / 2
		if axis == "X" then
			part(walls, {
				Size = Vector3.new(len, height, T),
				CFrame = CFrame.new(mid, yBottom + height / 2, fixed),
			})
		else
			part(walls, {
				Size = Vector3.new(T, height, len),
				CFrame = CFrame.new(fixed, yBottom + height / 2, mid),
			})
		end
	end

	for _, e in ipairs(edges) do
		if e.mode == "door" then
			local mid = (e.from + e.to) / 2
			local half = cfg.DoorWidth / 2
			segment(e.axis, e.fixed, e.from, mid - half, H, 0)
			segment(e.axis, e.fixed, mid + half, e.to, H, 0)
			-- architrave sopra il vano: senza, sembrano muri tagliati, non porte
			local lintel = H - cfg.DoorHeight
			if lintel > 0.05 then
				segment(e.axis, e.fixed, mid - half, mid + half, lintel, cfg.DoorHeight)
			end
		else
			segment(e.axis, e.fixed, e.from, e.to, H, 0)
		end
	end

	-- --- 7. pavimento e soffitto ---
	part(parent, {
		Name = "Pavimento",
		Size = Vector3.new(totalX, 2, totalZ),
		CFrame = CFrame.new(totalX / 2, -1, totalZ / 2),
		Color = C_FLOOR,
		Material = Enum.Material.Slate,
	})

	-- Piazzale esterno. Senza, chi compare fuori o esce dalla porta cade nel
	-- vuoto: il pavimento di sopra copre solo l'interno dell'edificio.
	local margine = 70
	part(parent, {
		Name = "Piazzale",
		Size = Vector3.new(totalX + margine * 2, 2, totalZ + margine * 2),
		CFrame = CFrame.new(totalX / 2, -1.15, totalZ / 2),
		Color = Color3.fromRGB(54, 54, 52),
		Material = Enum.Material.Asphalt,
	})

	local ceilings = Instance.new("Folder")
	ceilings.Name = "Soffitto"
	ceilings.Parent = parent
	for y = 1, D do
		for x = 1, W do
			if rng:NextNumber() > cfg.HoleChance then -- i buchi sono soffitti crollati
				part(ceilings, {
					Size = Vector3.new(xEdge[x + 1] - xEdge[x], 1, zEdge[y + 1] - zEdge[y]),
					CFrame = CFrame.new((xEdge[x] + xEdge[x + 1]) / 2, H + 0.5, (zEdge[y] + zEdge[y + 1]) / 2),
					Color = C_CEIL,
				})
			end
		end
	end

	-- --- 8. arredamento ---
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

			if id == 0 then
				-- corridoio: armadietti contro un muro
				if rng:NextNumber() < cfg.LockerChance then
					local along = corridorRow[y] == true -- il corridoio corre lungo X?
					-- Posizioni scelte per evitare la meta' del muro: li' cadono i vani
					-- porta, e un armadietto davanti a una porta mura un'aula.
					local slots = { 0.12, 0.3, 0.7, 0.88 }
					for _, t in ipairs(slots) do
						local px = along and (xEdge[x] + t * sx) or (cx + (rng:NextNumber() < 0.5 and -1 or 1) * (sx / 2 - 1.5))
						local pz = along and (cz + (rng:NextNumber() < 0.5 and -1 or 1) * (sz / 2 - 1.5)) or (zEdge[y] + t * sz)
						part(props, {
							Size = Vector3.new(along and 3 or 2, 7, along and 2 or 3),
							CFrame = CFrame.new(px, 3.5, pz),
							Color = C_METAL,
							Material = Enum.Material.DiamondPlate,
						})
					end
				end
			elseif not seen[id] then
				-- aula: la arrediamo una volta sola, alla prima casella che incontriamo
				seen[id] = true
				for i = 1, cfg.DesksPerRoom do
					local px = cx + rng:NextNumber() * (sx - 8) - (sx - 8) / 2
					local pz = cz + rng:NextNumber() * (sz - 8) - (sz - 8) / 2
					local desk = part(props, {
						Size = Vector3.new(4, 0.4, 2.5),
						CFrame = CFrame.new(px, 3, pz) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0),
						Color = C_WOOD,
						Material = Enum.Material.WoodPlanks,
					})
					-- gamba centrale, basta a farlo sembrare un banco
					part(props, {
						Size = Vector3.new(0.6, 3, 0.6),
						CFrame = desk.CFrame * CFrame.new(0, -1.5, 0),
						Color = C_METAL,
					})
				end
				-- lavagna su un muro
				part(props, {
					Size = Vector3.new(sx * 0.5, 5, 0.4),
					CFrame = CFrame.new(cx, 7, zEdge[y] + 0.8),
					Color = C_BOARD,
					Material = Enum.Material.Slate,
					CanCollide = false,   -- se il muro dietro ha una porta, non deve tapparla
				})
			end

			-- calcinacci ovunque: rompono la vista e fanno sporco
			for _ = 1, cfg.DebrisPerCell do
				local s = rng:NextNumber() * 2 + 0.6
				part(props, {
					Size = Vector3.new(s, s * 0.4, s),
					CFrame = CFrame.new(
						cx + rng:NextNumber() * (sx - 4) - (sx - 4) / 2,
						s * 0.2,
						cz + rng:NextNumber() * (sz - 4) - (sz - 4) / 2
					) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0),
					Color = C_CEIL,
					Material = Enum.Material.Rock,
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
					(xEdge[x] + xEdge[x + 1]) / 2, H - 1, (zEdge[y] + zEdge[y + 1]) / 2))
			end
		end
	end

	for i = 1, math.min(cfg.WorkingLights, #spots) do
		local pick = table.remove(spots, rng:NextInteger(1, #spots))
		local tube = part(lights, {
			Size = Vector3.new(6, 0.3, 1),
			CFrame = CFrame.new(pick),
			Color = Color3.fromRGB(220, 225, 210),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		local light = Instance.new("PointLight")
		light.Range = 26
		light.Brightness = 1.6
		light.Color = Color3.fromRGB(205, 220, 200)
		light.Parent = tube
		-- i neon che sfarfallano si marcano qui; a farli sfarfallare ci pensa Main
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
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	local luce = Instance.new("PointLight")
	luce.Range      = 38
	luce.Brightness = 2.2
	luce.Color      = Color3.fromRGB(255, 226, 170)
	luce.Parent     = lampada
	lampada:SetAttribute("Flicker", true)

	-- --- 11. dove compaiono i giocatori: fuori dall'ingresso, sul piazzale ---
	return CFrame.new(entranceX, 3, totalZ + 16), Vector3.new(totalX, H, totalZ)
end

return MapGenerator
