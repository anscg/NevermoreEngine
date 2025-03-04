--[=[
	@class GameConfigAssetBase
]=]

local require = require(script.Parent.loader).load(script)

local BadgeUtils = require("BadgeUtils")
local BaseObject = require("BaseObject")
local GameConfigAssetTypes = require("GameConfigAssetTypes")
local Rx = require("Rx")
local RxAttributeUtils = require("RxAttributeUtils")
local RxInstanceUtils = require("RxInstanceUtils")
local MarketplaceUtils = require("MarketplaceUtils")
local GameConfigAssetConstants = require("GameConfigAssetConstants")
local Promise = require("Promise")

local GameConfigAssetBase = setmetatable({}, BaseObject)
GameConfigAssetBase.ClassName = "GameConfigAssetBase"
GameConfigAssetBase.__index = GameConfigAssetBase

--[=[
	Constructs a new GameConfigAssetBase. Should be done via binder. This is a base class.
	@param obj Folder
	@return GameConfigAssetBase
]=]
function GameConfigAssetBase.new(obj)
	local self = setmetatable(BaseObject.new(obj), GameConfigAssetBase)

	return self
end

--[=[
	Gets the asset id
	@return number
]=]
function GameConfigAssetBase:GetAssetId()
	return self._obj:GetAttribute(GameConfigAssetConstants.ASSET_ID_ATTRIBUTE)
end

--[=[
	Observes the assetId
	@return Observable<number>
]=]
function GameConfigAssetBase:ObserveAssetId()
	return RxAttributeUtils.observeAttribute(self._obj, GameConfigAssetConstants.ASSET_ID_ATTRIBUTE, nil)
end

--[=[
	Gets the asset type
	@return string?
]=]
function GameConfigAssetBase:GetAssetType()
	return self._obj:GetAttribute(GameConfigAssetConstants.ASSET_TYPE_ATTRIBUTE)
end

--[=[
	Observes the asset type
	@return Observable<string?>
]=]
function GameConfigAssetBase:ObserveAssetType()
	return RxAttributeUtils.observeAttribute(self._obj, GameConfigAssetConstants.ASSET_TYPE_ATTRIBUTE, nil)
end

--[=[
	Observes the asset key
	@return Observable<string>
]=]
function GameConfigAssetBase:ObserveAssetKey()
	return RxInstanceUtils.observeProperty(self._obj, "Name")
end

--[=[
	Gets the asset key
	@return string
]=]
function GameConfigAssetBase:GetAssetKey()
	return self._obj.Name
end

--[=[
	Observes the asset state
	@return any
]=]
function GameConfigAssetBase:ObserveState()
	return Rx.combineLatest({
		assetId = self:ObserveAssetId();
		assetKey = self:ObserveAssetKey();
		assetType = self:ObserveAssetType();
	})
end

--[=[
	Promises the cloud price in Robux
	@param cancelToken CancelToken
	@return Promise<string?>
]=]
function GameConfigAssetBase:PromiseCloudPriceInRobux(cancelToken)
	return Rx.toPromise(self:ObserveCloudPriceInRobux(), cancelToken)
end

--[=[
	Promises the color of the game asset (for dialog and other systems)
	@param _cancelToken CancelToken
	@return Promise<Color3>
]=]
function GameConfigAssetBase:PromiseColor(_cancelToken)
	return Promise.resolved(Color3.fromRGB(66, 158, 166))
end

--[=[
	Promises the name translation key
	@param cancelToken CancelToken
	@return Promise<string?>
]=]
function GameConfigAssetBase:PromiseNameTranslationKey(cancelToken)
	return Rx.toPromise(self:ObserveNameTranslationKey(), cancelToken)
end

--[=[
	Observes the name translation key.
	@return Observable<string?>
]=]
function GameConfigAssetBase:ObserveNameTranslationKey()
	return self:_observeTranslationKey("name")
end

--[=[
	Observes the description translation key.
	@return Observable<string?>
]=]
function GameConfigAssetBase:ObserveDescriptionTranslationKey()
	return self:_observeTranslationKey("description")
end

--[=[
	Observes the cloud name. See [GameConfigAssetBase.ObserveNameTranslationKey] for
	translation keys.
	@return Observable<string?>
]=]
function GameConfigAssetBase:ObserveCloudName()
	return self:_observeCloudProperty("Name", "string")
end

--[=[
	Observes the cloud name. See [GameConfigAssetBase.ObserveDescriptionTranslationKey] for
	translation keys.
	@return Observable<string?>
]=]
function GameConfigAssetBase:ObserveCloudDescription()
	return self:_observeCloudProperty("Description", "string")
end

--[=[
	Observes the cost in Robux.
	@return Observable<number?>
]=]
function GameConfigAssetBase:ObserveCloudPriceInRobux()
	return self:_observeCloudProperty("PriceInRobux", "number")
end

--[=[
	@return Observable<number?>
]=]
function GameConfigAssetBase:ObserveCloudIconImageAssetId()
	return self:_observeCloudProperty("IconImageAssetId", "number")
end

function GameConfigAssetBase:_observeTranslationKey(postfix)
	return self:ObserveState():Pipe({
		Rx.map(function(state)
			if type(state) == "table" and type(state.assetType) == "string" and type(state.assetKey) == "string" then
				return ("cloud.%s.%s.%s"):format(state.assetType, state.assetKey, postfix)
			else
				return nil
			end
		end)
	})
end

function GameConfigAssetBase:_observeCloudProperty(propertyName, expectedType)
	assert(type(propertyName) == "string", "Bad propertyName")
	assert(type(expectedType) == "string", "Bad expectedType")

	return self:_observeCloudDataFromState():Pipe({
		Rx.map(function(data)
			if type(data) == "table" then
				local result = data[propertyName]
				if type(result) == expectedType then
					return result
				end
			else
				return nil
			end
		end)
	})
end

function GameConfigAssetBase:_observeCloudDataFromState()
	-- TODO: Multicast

	return self:ObserveState():Pipe({
		Rx.switchMap(function(state)
			if type(state.assetId) == "number" and type(state.assetType) == "string" and type(state.assetKey) == "string" then
				return Rx.fromPromise(self:_promiseCloudDataForState(state))
			else
				return Rx.of(nil)
			end
		end);
		Rx.distinct();
	})
end

function GameConfigAssetBase:_promiseCloudDataForState(state)
	-- We really hope this stuff is cached
	if state.assetType == GameConfigAssetTypes.BADGE then
		return BadgeUtils.promiseBadgeInfo(state.assetId)
	elseif state.assetType == GameConfigAssetTypes.PRODUCT then
		return MarketplaceUtils.promiseProductInfo(state.assetId, Enum.InfoType.Product)
	elseif state.assetType == GameConfigAssetTypes.PASS then
		return MarketplaceUtils.promiseProductInfo(state.assetId, Enum.InfoType.GamePass)
	elseif state.assetType == GameConfigAssetTypes.PLACE then
		return MarketplaceUtils.promiseProductInfo(state.assetId, Enum.InfoType.Asset)
	else
		warn(("Unknown GameConfigAssetType %q. Ignoring asset."):format(tostring(state.assetType)))
		return Promise.resolved(nil)
	end
end

return GameConfigAssetBase