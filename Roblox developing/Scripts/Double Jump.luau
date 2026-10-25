local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local FIRST_JUMP_POWER = 45
local SECOND_JUMP_POWER = 95
local DOUBLE_JUMP_STAMINA_COST = 20

local character
local humanoid
local extraJumpUsed = false

local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")

	humanoid.UseJumpPower = true
	humanoid.JumpPower = FIRST_JUMP_POWER

	extraJumpUsed = false

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			extraJumpUsed = false
			humanoid.JumpPower = FIRST_JUMP_POWER
		end
	end)
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

UserInputService.JumpRequest:Connect(function()
	if not humanoid then
		return
	end

	if humanoid.FloorMaterial == Enum.Material.Air and not extraJumpUsed then
		-- Vérifier si on a assez d'endurance
		local useStamina = _G.UseStamina
		if useStamina then
			if not useStamina(DOUBLE_JUMP_STAMINA_COST) then
				return -- pas assez d'endurance, pas de double saut
			end
		end

		extraJumpUsed = true

		local root = character:WaitForChild("HumanoidRootPart")

		humanoid.JumpPower = SECOND_JUMP_POWER
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

		root.AssemblyLinearVelocity = Vector3.new(
			root.AssemblyLinearVelocity.X,
			SECOND_JUMP_POWER,
			root.AssemblyLinearVelocity.Z
		)
	end
end)