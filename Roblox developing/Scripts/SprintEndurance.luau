local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ------------------- PARAMÈTRES -------------------
local NORMAL_SPEED = 26
local SPRINT_SPEED = 42
local MAX_STAMINA = 100
local DRAIN_PER_SECOND = 25
local REGEN_PER_SECOND = 18
local EXHAUST_THRESHOLD = 30 -- stamina nécessaire pour re-sprint après épuisement
local DOUBLE_JUMP_COST = 20 -- coût en endurance du double saut

-- ------------------- VARIABLES -------------------
local stamina = MAX_STAMINA
local isSprinting = false
local isExhausted = false
local isHoldingSprint = false
local humanoid = nil
local character = nil

-- ------------------- UI ENDURANCE -------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StaminaUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "StaminaBar"
frame.Size = UDim2.new(0.2, 0, 0.02, 0)
frame.Position = UDim2.new(0.4, 0, 0.85, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.new(1, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
fill.BorderSizePixel = 0
fill.Parent = frame

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 6)
fillCorner.Parent = fill

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 80)
stroke.Thickness = 1.5
stroke.Parent = frame

-- ------------------- FONCTIONS -------------------
local function updateStaminaUI()
	local ratio = stamina / MAX_STAMINA
	fill.Size = UDim2.new(ratio, 0, 1, 0)

	-- Couleur : bleu -> orange -> rouge selon l'endurance
	if ratio > 0.5 then
		fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	elseif ratio > 0.25 then
		fill.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
	else
		fill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	end
end

local function isMoving()
	if not humanoid then return false end
	local state = humanoid:GetState()
	return state == Enum.HumanoidStateType.Running
		or state == Enum.HumanoidStateType.Freefall
		or state == Enum.HumanoidStateType.Jumping
end

local function startSprint()
	if isExhausted or not isHoldingSprint then return end
	if not isMoving() then return end
	isSprinting = true
	humanoid.WalkSpeed = SPRINT_SPEED
end

local function stopSprint()
	isSprinting = false
	if humanoid then
		humanoid.WalkSpeed = NORMAL_SPEED
	end
end

-- ------------------- INPUT CLAVIER -------------------
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isHoldingSprint = true
		startSprint()
	end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isHoldingSprint = false
		stopSprint()
	end
end)

-- ------------------- INPUT MANETTE (L3) -------------------
local function handleGamepadSprint(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		isHoldingSprint = true
		startSprint()
	elseif inputState == Enum.UserInputState.End then
		isHoldingSprint = false
		stopSprint()
	end
	return Enum.ContextActionResult.Sink
end

CAS:BindAction("SprintGamepad", handleGamepadSprint, false, Enum.KeyCode.ButtonL3)

-- ------------------- BOUCLE PRINCIPALE -------------------
RunService.Heartbeat:Connect(function(dt)
	if not humanoid then return end

	-- Drain d'endurance quand on sprint ET qu'on bouge
	if isSprinting and isMoving() then
		stamina = math.max(0, stamina - DRAIN_PER_SECOND * dt)

		-- Épuisement
		if stamina <= 0 then
			isExhausted = true
			stopSprint()
		end
	-- Régénération quand on ne sprint pas
	else
		stamina = math.min(MAX_STAMINA, stamina + REGEN_PER_SECOND * dt)

		-- Récupération après épuisement
		if isExhausted and stamina >= EXHAUST_THRESHOLD then
			isExhausted = false
			-- Réessayer de sprinter si on tient toujours le bouton
			if isHoldingSprint then
				startSprint()
			end
		end
	end

	-- Si on sprint mais plus en mouvement, remettre vitesse normale
	if isSprinting and not isMoving() then
		humanoid.WalkSpeed = NORMAL_SPEED
	elseif isSprinting and isMoving() then
		humanoid.WalkSpeed = SPRINT_SPEED
	end

	updateStaminaUI()
end)

-- ------------------- SETUP PERSONNAGE -------------------
local function onCharacterAdded(char)
	character = char
	humanoid = char:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	humanoid.WalkSpeed = NORMAL_SPEED
	stamina = MAX_STAMINA
	isSprinting = false
	isExhausted = false
	isHoldingSprint = false

	-- Remettre la vitesse normale à la mort
	humanoid.Died:Connect(function()
		stopSprint()
	end)

	updateStaminaUI()
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

-- Accès global pour d'autres scripts
_G.GetStamina = function()
	return stamina
end

_G.UseStamina = function(cost)
	if stamina < cost then
		return false
	end
	stamina = math.max(0, stamina - cost)
	if stamina <= 0 then
		isExhausted = true
		stopSprint()
	end
	updateStaminaUI()
	return true
end

_G.IsExhausted = function()
	return isExhausted
end
