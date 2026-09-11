--[[
	Main — quello che parte all'avvio della partita.

	Fa quattro cose:
	  1. spegne il mondo (buio, nebbia, colori slavati);
	  2. costruisce la scuola chiamando MapGenerator;
	  3. fa sfarfallare i pochi neon rimasti;
	  4. gestisce le torce: il server le muove, cosi' le vedono TUTTI i giocatori
	     e non solo chi le tiene in mano. E' il motivo per cui questa parte non
	     e' semplicemente nello script del giocatore.

	Dove va in Studio:  ServerScriptService > Main   (Script normale)
--]]

local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MapGenerator = require(ServerScriptService:WaitForChild("MapGenerator"))

-- ============================================================
--  1. SPEGNERE IL MONDO
-- ============================================================
-- L'illuminazione moderna e' l'interruttore che cambia di piu' l'aspetto del
-- gioco: senza, le torce non proiettano ombre vere. Si accende in due modi
-- diversi a seconda di quanto e' aggiornato Roblox, quindi li proviamo
-- entrambi:
--   - versioni recenti: LightingStyle = Realistic  (si imposta da codice)
--   - versioni vecchie: Technology = Future        (NON si imposta da codice,
--     va messo a mano nelle proprieta' di Lighting)
-- "pcall" vuol dire "prova, e se fallisce non fermare tutto": serve perche' su
-- una versione la proprieta' che cerchiamo semplicemente non esiste.

local illuminazioneOk = pcall(function()
	Lighting.LightingStyle = Enum.LightingStyle.Realistic
end)
if not illuminazioneOk then
	illuminazioneOk = pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)
end
if not illuminazioneOk then
	warn("[Count Your Friends] Illuminazione moderna non attivata. " ..
		"Seleziona Lighting nell'Explorer e metti LightingStyle su Realistic " ..
		"(oppure Technology su Future, se e' quella che vedi).")
end

Lighting.ClockTime      = 0
Lighting.Brightness     = 0
Lighting.Ambient        = Color3.fromRGB(0, 0, 0)
Lighting.OutdoorAmbient = Color3.fromRGB(7, 8, 13)   -- un filo di luna, non zero: il nero pieno e' illeggibile
Lighting.GlobalShadows  = true
Lighting.EnvironmentDiffuseScale  = 0
Lighting.EnvironmentSpecularScale = 0

for _, name in ipairs({ "Atmosfera", "Colore" }) do
	local old = Lighting:FindFirstChild(name)
	if old then old:Destroy() end
end

local atmosphere = Instance.new("Atmosphere")
atmosphere.Name    = "Atmosfera"
atmosphere.Density = 0.42      -- la nebbia: mangia la distanza e nasconde i bordi della mappa
atmosphere.Offset  = 0.2
atmosphere.Color   = Color3.fromRGB(150, 150, 160)
atmosphere.Decay   = Color3.fromRGB(70, 74, 86)
atmosphere.Glare   = 0
atmosphere.Haze    = 1.6
atmosphere.Parent  = Lighting

local grade = Instance.new("ColorCorrectionEffect")
grade.Name        = "Colore"
grade.Saturation   = -0.35     -- slavato: il colore e' la prima cosa che toglie paura
grade.Contrast     = 0.12
grade.Brightness   = -0.03
grade.TintColor    = Color3.fromRGB(226, 232, 240)
grade.Parent       = Lighting

-- ============================================================
--  2. COSTRUIRE LA SCUOLA
-- ============================================================
-- Via il pavimento di prova che Roblox mette nei progetti nuovi.
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end
for _, inst in ipairs(workspace:GetDescendants()) do
	if inst:IsA("SpawnLocation") then inst:Destroy() end
end

local old = workspace:FindFirstChild("Mappa")
if old then old:Destroy() end

local mappa = Instance.new("Folder")
mappa.Name = "Mappa"
mappa.Parent = workspace

local spawnCFrame = MapGenerator.build(mappa)

local spawn = Instance.new("SpawnLocation")
spawn.Name        = "Ingresso"
spawn.Size        = Vector3.new(12, 1, 12)
spawn.CFrame      = spawnCFrame
spawn.Anchored    = true
spawn.Neutral     = true
spawn.Duration    = 0          -- niente scudo di comparsa
spawn.Transparency = 1
spawn.CanCollide  = true
spawn.Color       = Color3.fromRGB(40, 40, 40)
spawn.Parent      = mappa

-- ============================================================
--  3. I NEON CHE SFARFALLANO
-- ============================================================
task.spawn(function()
	local rng = Random.new()
	while true do
		task.wait(rng:NextNumber(0.05, 0.4))
		for _, tube in ipairs(mappa:GetDescendants()) do
			if tube:IsA("BasePart") and tube:GetAttribute("Flicker") then
				local light = tube:FindFirstChildOfClass("PointLight")
				if light then
					local on = rng:NextNumber() < 0.72
					light.Enabled = on
					tube.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
				end
			end
		end
	end
end)

-- ============================================================
--  4. LE TORCE
-- ============================================================
-- Il giocatore dice al server DOVE sta guardando; il server muove la torcia.
-- Cosi' la luce la vedono tutti. Se la torcia la creasse il giocatore sul
-- proprio schermo, ognuno vedrebbe solo la propria: in un gioco dove bisogna
-- ritrovarsi al buio sarebbe un disastro.

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local torchAim = remotes:FindFirstChild("TorchAim")
if not torchAim then
	torchAim = Instance.new("RemoteEvent")
	torchAim.Name = "TorchAim"
	torchAim.Parent = remotes
end

local torches = Instance.new("Folder")
torches.Name = "Torce"
torches.Parent = workspace

local state = {}   -- state[player] = { dir = Vector3, on = boolean, part = Part }

local function makeTorch(player)
	local holder = Instance.new("Part")
	holder.Name         = "Torcia_" .. player.Name
	holder.Size         = Vector3.new(0.2, 0.2, 0.2)
	holder.Transparency = 1
	holder.Anchored     = true
	holder.CanCollide   = false
	holder.CanQuery     = false
	holder.CanTouch     = false
	holder.CastShadow   = false
	holder.Parent       = torches

	local spot = Instance.new("SpotLight")
	spot.Name       = "Fascio"
	spot.Angle      = GameConfig.TorchAngle
	spot.Range      = GameConfig.TorchRange
	spot.Brightness = GameConfig.TorchBrightness
	spot.Color      = Color3.fromRGB(255, 244, 214)
	spot.Face       = Enum.NormalId.Front     -- il fascio esce dal davanti del blocco
	spot.Shadows    = true
	spot.Parent     = holder

	-- alone ravvicinato: senza, i propri piedi restano invisibili ed e' fastidioso
	local halo = Instance.new("PointLight")
	halo.Name       = "Alone"
	halo.Range      = 10
	halo.Brightness = 0.7
	halo.Color      = Color3.fromRGB(255, 240, 210)
	halo.Parent     = holder

	return holder
end

Players.PlayerAdded:Connect(function(player)
	state[player] = { dir = Vector3.new(0, 0, -1), on = true, part = makeTorch(player) }
end)

Players.PlayerRemoving:Connect(function(player)
	local s = state[player]
	if s and s.part then s.part:Destroy() end
	state[player] = nil
end)

torchAim.OnServerEvent:Connect(function(player, dir, on)
	local s = state[player]
	-- controlliamo sempre cosa arriva dal giocatore: non ci si fida mai
	if not s then return end
	if typeof(dir) ~= "Vector3" or typeof(on) ~= "boolean" then return end
	if dir.Magnitude < 0.01 then return end
	s.dir = dir.Unit
	s.on  = on
end)

RunService.Heartbeat:Connect(function()
	for player, s in pairs(state) do
		local char = player.Character
		local head = char and char:FindFirstChild("Head")
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		local alive = hum and hum.Health > 0

		local spot = s.part:FindFirstChild("Fascio")
		local halo = s.part:FindFirstChild("Alone")

		if head and alive and s.on then
			-- la torcia parte dalla testa e punta dove guarda il giocatore
			s.part.CFrame = CFrame.lookAt(head.Position, head.Position + s.dir)
			if spot then spot.Enabled = true end
			if halo then halo.Enabled = true end
		else
			if spot then spot.Enabled = false end
			if halo then halo.Enabled = false end
		end
	end
end)
