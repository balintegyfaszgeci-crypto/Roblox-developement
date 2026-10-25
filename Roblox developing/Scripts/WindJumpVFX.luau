local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer


local function setupWindVFX(character)
	-- Attendre que le personnage soit complètement chargé
	local humanoid = character:WaitForChild("Humanoid", 10)
	local upperTorso = character:WaitForChild("UpperTorso", 10)
	if not humanoid or not upperTorso then
		warn("WindJumpVFX: Humanoid or UpperTorso not found")
		return
	end

	-- Récupérer le template Wind-01
	local windTemplate = ReplicatedStorage:WaitForChild("Wind-01", 10)
	if not windTemplate then
		warn("Wind-01 template not found in ReplicatedStorage")
		return
	end

	-- Créer un Attachment dans l'UpperTorso pour les ParticleEmitters
	local vfxAttachment = Instance.new("Attachment")
	vfxAttachment.Name = "WindVFXAttachment"
	vfxAttachment.Parent = upperTorso

	-- Cloner les ParticleEmitters depuis les Attachments de Wind-01
	for _, attachment in windTemplate:GetChildren() do
		if attachment:IsA("Attachment") then
			for _, child in attachment:GetChildren() do
				if child:IsA("ParticleEmitter") then
					local clone = child:Clone()
					clone.Enabled = false -- désactivé par défaut
					clone.Parent = vfxAttachment
				end
			end
		end
	end

	-- Fonction pour activer/désactiver les VFX
	local function setVFXEnabled(enabled)
		for _, emitter in vfxAttachment:GetChildren() do
			if emitter:IsA("ParticleEmitter") then
				emitter.Enabled = enabled
			end
		end
	end

	-- États où le joueur est en l'air (pas en collision avec le sol)
	local airborneStates = {
		[Enum.HumanoidStateType.Jumping] = true,
		[Enum.HumanoidStateType.Freefall] = true,
		[Enum.HumanoidStateType.FallingDown] = true,
	}

	-- Activer les VFX quand en l'air, désactiver quand au sol
	humanoid.StateChanged:Connect(function(oldState, newState)
		if airborneStates[newState] then
			setVFXEnabled(true)
		else
			setVFXEnabled(false)
		end
	end)
end

-- Gérer le personnage actuel et les futurs respawns
player.CharacterAdded:Connect(setupWindVFX)
if player.Character then
	setupWindVFX(player.Character)
end
