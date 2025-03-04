--[=[
	A list that can be observed for blend and other components
	@class ObservableMap
]=]

local require = require(script.Parent.loader).load(script)

local Signal = require("Signal")
local Observable = require("Observable")
local Maid = require("Maid")
local Brio = require("Brio")
local RxValueBaseUtils = require("RxValueBaseUtils")

local ObservableMap = {}
ObservableMap.ClassName = "ObservableMap"
ObservableMap.__index = ObservableMap

--[=[
	Constructs a new ObservableMap
	@return ObservableMap<TKey, TValue>
]=]
function ObservableMap.new()
	local self = setmetatable({}, ObservableMap)

	self._maid = Maid.new()
	self._map = {}

	self._keyToSubList = {}

	self._countValue = Instance.new("IntValue")
	self._countValue.Value = 0
	self._maid:GiveTask(self._countValue)

--[=[
	Fires when a key is added
	@readonly
	@prop KeyAdded Signal<TKey>
	@within ObservableMap
]=]
	self.KeyAdded = Signal.new() -- :Fire(key, value)
	self._maid:GiveTask(self.KeyAdded)

--[=[
	Fires when a key is removed
	@readonly
	@prop KeyRemoved Signal<TKey>
	@within ObservableMap
]=]
	self.KeyRemoved = Signal.new() -- :Fire(key)
	self._maid:GiveTask(self.KeyRemoved)

--[=[
	Fires when a key value changes, including add and remove.
	@readonly
	@prop KeyValueChanged Signal<(TKey, TValue, TValue)>
	@within ObservableMap
]=]
	self.KeyValueChanged = Signal.new() -- :Fire(key, value, oldValue)
	self._maid:GiveTask(self.KeyValueChanged)

--[=[
	Fires when the count changes.
	@prop CountChanged RBXScriptSignal
	@within ObservableMap
]=]
	self.CountChanged = self._countValue.Changed

	return self
end

--[=[
	Returns whether the set is an observable map
	@param value any
	@return boolean
]=]
function ObservableMap.isObservableMap(value)
	return type(value) == "table" and getmetatable(value) == ObservableMap
end

--[=[
	Observes all keys in the map
	@return Observable<Brio<TKey>>
]=]
function ObservableMap:ObserveKeysBrio()
	return self:_observeKeyValueChanged(function(key, _value)
		return Brio.new(key)
	end)
end

--[=[
	Observes all keys in the map
	@return Observable<Brio<TKey>>
]=]
function ObservableMap:ObserveValuesBrio()
	return self:_observeKeyValueChanged(function(_key, value)
		return Brio.new(value)
	end)
end

--[=[
	Observes all keys in the map
	@return Observable<Brio<(TKey, TValue)>>
]=]
function ObservableMap:ObservePairsBrio()
	return self:_observeKeyValueChanged(function(key, value)
		return Brio.new(key, value)
	end)
end

function ObservableMap:_observeKeyValueChanged(packValue)
	return Observable.new(function(sub)
		local maid = Maid.new()

		local function handleValue(key, value)
			if value ~= nil then
				local brio = packValue(key, value)
				maid[key] = brio
				sub:Fire(brio)
			else
				maid[key] = nil
			end
		end

		for key, value in pairs(self._map) do
			handleValue(key, value)
		end

		maid:GiveTask(self.KeyValueChanged:Connect(handleValue))

		self._maid[sub] = maid
		maid:GiveTask(function()
			self._maid[sub] = nil
			sub:Complete()
		end)

		return maid
	end)
end

--[=[
	Returns the value for the given key
	@param key TKey
	@return TValue
]=]
function ObservableMap:Get(key)
	assert(key ~= nil, "Bad key")

	return self._map[key]
end

--[=[
	Returns whether the map contains the key
	@param key TKey
	@return boolean
]=]
function ObservableMap:ContainsKey(key)
	assert(key ~= nil, "Bad key")

	return self._map[key] ~= nil
end

--[=[
	Gets the count of items in the set
	@return number
]=]
function ObservableMap:GetCount()
	return self._countValue.Value
end

--[=[
	Observes the count of the set
	@return Observable<number>
]=]
function ObservableMap:ObserveCount()
	return RxValueBaseUtils.observeValue(self._countValue)
end

--[=[
	Observes the value for the given slot
	@param key TKey
	@return Observable<TValue?>
]=]
function ObservableMap:ObserveValueForKey(key)
	assert(key ~= nil, "Bad key")

	return Observable.new(function(sub)
		local maid = Maid.new()

		if not self._keyToSubList[key] then
			self._keyToSubList[key] = {}
		end
		table.insert(self._keyToSubList[key], sub)

		maid:GiveTask(function()
			local subsList = self._keyToSubList[key]
			if subsList then
				local index = table.find(subsList, sub)

				if index then
					table.remove(subsList, index)
				end

				if #subsList == 0 then
					self._keyToSubList[key] = nil
				end
			end
		end)

		sub:Fire(self._map[key])

		return maid
	end)
end

--[=[
	Adds the item to the set if it does not exists.
	@param key TKey
	@param value TValue?
	@return callback -- Call to remove the value.
]=]
function ObservableMap:Set(key, value)
	assert(key ~= nil, "Bad key")

	local oldValue = self._map[key]
	if oldValue == value then
		return
	end

	self._map[key] = value

	if oldValue == nil then
		self._countValue.Value = self._countValue.Value + 1
		self.KeyAdded:Fire(key, value)
	elseif value == nil then
		self._countValue.Value = self._countValue.Value - 1
		self.KeyRemoved:Fire(key)
	end

	self.KeyValueChanged:Fire(key, value, oldValue)

	local subList = self._keyToSubList[key]
	if subList then
		for _, sub in pairs(table.clone(subList)) do
			if sub and sub:IsPending() then
				task.spawn(function()
					sub:Fire(value)
				end)
			end
		end
	end

	return function()
		if self.Destroy then
			self:Remove(key)
		end
	end
end

--[=[
	Removes the item from the map if it exists.
	@param key TKey
]=]
function ObservableMap:Remove(key)
	assert(key ~= nil, "Bad key")

	self:Set(key, nil)
end

--[=[
	Gets a list of all values.
	@return { TValue }
]=]
function ObservableMap:GetValueList()
	local list = {}
	for _, value in pairs(self._map) do
		table.insert(list, value)
	end
	return list
end

--[=[
	Gets a list of all keys.
	@return { TKey }
]=]
function ObservableMap:GetKeyList()
	local list = {}
	for key, _ in pairs(self._map) do
		table.insert(list, key)
	end
	return list
end


--[=[
	Cleans up the ObservableMap and sets the metatable to nil.
]=]
function ObservableMap:Destroy()
	self._maid:DoCleaning()
	setmetatable(self, nil)
end

return ObservableMap