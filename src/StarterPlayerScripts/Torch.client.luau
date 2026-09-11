--[[
	Torch — la torcia, lato giocatore.

	Questo script fa solo due cose: dice al server dove stai guardando, e
	accende/spegne. La luce vera la crea il server (vedi Main), cosi' la
	vedono anche gli altri giocatori.

	Il tasto e' F sul computer, e c'e' un pulsante in sovrimpressione sul
	telefono — che non e' un dettaglio: la maggior parte di chi giochera'
	a questo gioco lo fara' da telefono.

	Dove va in Studio:  StarterPlayer > StarterPlayerScripts > Torch   (LocalScript)
--]]

local ContextActionService = game:GetService("ContextActionService")
local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local RunService           = game:GetService("RunService")

local player   = Players.LocalPlayer
local camera   = workspace.CurrentCamera
local torchAim = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TorchAim")

local acceso    = true
local ultimoInvio = 0
local ultimaDir   = Vector3.new(0, 0, -1)

-- Non mandiamo un messaggio al server a ogni fotogramma: sarebbero 60 al
-- secondo per giocatore, sprecati. Ne bastano 15, e solo se qualcosa e'
-- cambiato davvero.
local FREQUENZA = 1 / 15
local SOGLIA    = 0.02

local function invia(forzato)
	local dir = camera.CFrame.LookVector
	local ora = os.clock()
	local cambiato = (dir - ultimaDir).Magnitude > SOGLIA
	if forzato or (cambiato and ora - ultimoInvio >= FREQUENZA) then
		ultimoInvio = ora
		ultimaDir = dir
		torchAim:FireServer(dir, acceso)
	end
end

RunService.RenderStepped:Connect(function()
	invia(false)
end)

local function premuto(_, stato)
	if stato == Enum.UserInputState.Begin then
		acceso = not acceso
		invia(true)
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("Torcia", premuto, true, Enum.KeyCode.F)
ContextActionService:SetTitle("Torcia", "TORCIA")
ContextActionService:SetPosition("Torcia", UDim2.new(1, -120, 1, -140))

-- --- scritta di aiuto, sparisce da sola ---
local gui = Instance.new("ScreenGui")
gui.Name          = "Aiuto"
gui.ResetOnSpawn  = false
gui.IgnoreGuiInset = true
gui.Parent        = player:WaitForChild("PlayerGui")

local testo = Instance.new("TextLabel")
testo.Size                   = UDim2.new(1, 0, 0, 40)
testo.Position               = UDim2.new(0, 0, 1, -70)
testo.BackgroundTransparency = 1
testo.Font                   = Enum.Font.Code
testo.TextSize               = 16
testo.TextColor3             = Color3.fromRGB(190, 190, 190)
testo.Text                   = "F — torcia"
testo.Parent                 = gui

task.delay(8, function()
	for i = 0, 20 do
		testo.TextTransparency = i / 20
		task.wait(0.05)
	end
	gui:Destroy()
end)

invia(true)
