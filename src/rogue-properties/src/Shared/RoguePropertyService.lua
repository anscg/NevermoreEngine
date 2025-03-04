--[=[
	@class RoguePropertyService
]=]

local require = require(script.Parent.loader).load(script)

local RunService = game:GetService("RunService")

local Signal = require("Signal")
local Maid = require("Maid")
local Observable = require("Observable")

local RoguePropertyService = {}
RoguePropertyService.ServiceName = "RoguePropertyService"

function RoguePropertyService:Init(serviceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	self._maid = Maid.new()

	-- Internal
	self._serviceBag:GetService(require("RogueBindersShared"))
	self._roguePropertyBinderGroups = self._serviceBag:GetService(require("RoguePropertyBinderGroups"))

	self._providers = {}

	self.ProviderAddedEvent = Signal.new()
	self._maid:GiveTask(self.ProviderAddedEvent)

	-- Internal providers
	self._serviceBag:GetService(require("RogueSetterProvider"))
	self._serviceBag:GetService(require("RogueAdditiveProvider"))
	self._serviceBag:GetService(require("RogueMultiplierProvider"))
end

function RoguePropertyService:AddProvider(provider)
	self._roguePropertyBinderGroups.RogueModifiers:Add(provider:GetBinder())

	table.insert(self._providers, provider)

	self.ProviderAddedEvent:Fire(provider)
end

function RoguePropertyService:GetProviders()
	if not RunService:IsRunning() then
		return {}
	end

	return self._providers
end

function RoguePropertyService:ObserveProviderList()
	if not RunService:IsRunning() then
		return Observable.new(function(sub)
			sub:Fire({})
		end)
	end

	return Observable.new(function(sub)
		local maid = Maid.new()

		sub:Fire(self._providers)

		maid:GiveTask(self.ProviderAddedEvent:Connect(function()
			sub:Fire(self._providers)
		end))

		return maid
	end)
end

function RoguePropertyService:CanInitializeProperties()
	return RunService:IsServer()
end

function RoguePropertyService:Destroy()
	self._maid:DoCleaning()
end

return RoguePropertyService