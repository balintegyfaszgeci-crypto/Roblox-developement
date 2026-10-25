local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local NORMAL_SPEED = 16
local SPRINT_SPEED = 42

local MAX_STAMINA = 100
local stamina = MAX_STAMINA

local DRAIN_PER_SECOND = 25
local REGEN_PER_SECOND = 18

local sprintHeld = false
local exhausted = false

local humanoid

local function setupCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = NORMAL_SPEED
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

local function updateSpeed()
	if not humanoid then
		return
	end

	if sprintHeld and stamina > 0 and not exhausted then
		humanoid.WalkSpeed = SPRINT_SPEED
	else
		humanoid.WalkSpeed = NORMAL_SPEED
	end
end

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift
		or input.KeyCode == Enum.KeyCode.ButtonL3 then
		sprintHeld = true
		updateSpeed()
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift
		or input.KeyCode == Enum.KeyCode.ButtonL3 then
		sprintHeld = false
		updateSpeed()
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not humanoid then
		return
	end

	if sprintHeld and humanoid.MoveDirection.Magnitude > 0 and not exhausted then
		stamina -= DRAIN_PER_SECOND * dt

		if stamina <= 0 then
			stamina = 0
			exhausted = true
			updateSpeed()
		end
	else
		stamina += REGEN_PER_SECOND * dt

		if stamina >= MAX_STAMINA then
			stamina = MAX_STAMINA
		end

		if exhausted and stamina >= 30 then
			exhausted = false
		end
	end

	updateSpeed()
end)

-- Pour récupérer l'endurance dans d'autres scripts :
_G.GetStamina = function()
	return stamina
end