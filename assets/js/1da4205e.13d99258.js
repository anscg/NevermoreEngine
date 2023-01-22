"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[69071],{15850:e=>{e.exports=JSON.parse('{"functions":[{"name":"Init","desc":"Initializes the shared registry service. Should be done via [ServiceBag].","params":[{"name":"serviceBag","desc":"","lua_type":"ServiceBag"}],"returns":[],"function_type":"method","source":{"line":21,"path":"src/settings/src/Shared/SettingRegistryServiceShared.lua"}},{"name":"RegisterSettingService","desc":"Registers the shared setting service for this bridge","params":[{"name":"settingService","desc":"","lua_type":"SettingService"}],"returns":[],"function_type":"method","source":{"line":38,"path":"src/settings/src/Shared/SettingRegistryServiceShared.lua"}},{"name":"RegisterSettingDefinition","desc":"Registers settings definitions","params":[{"name":"definition","desc":"","lua_type":"SettingDefinition"}],"returns":[{"desc":"Cleanup callback","lua_type":"callback"}],"function_type":"method","source":{"line":48,"path":"src/settings/src/Shared/SettingRegistryServiceShared.lua"}},{"name":"ObserveRegisteredDefinitionsBrio","desc":"Observes the registered definitions","params":[],"returns":[{"desc":"","lua_type":"Observable<Brio<SettingDefinition>>"}],"function_type":"method","source":{"line":59,"path":"src/settings/src/Shared/SettingRegistryServiceShared.lua"}},{"name":"GetSettingsService","desc":"Gets the current settings service","params":[],"returns":[{"desc":"","lua_type":"SettingService"}],"function_type":"method","source":{"line":68,"path":"src/settings/src/Shared/SettingRegistryServiceShared.lua"}},{"name":"ObserveSettingsService","desc":"Observes the current settings service","params":[],"returns":[{"desc":"","lua_type":"Observable<SettingService>"}],"function_type":"method","source":{"line":77,"path":"src/settings/src/Shared/SettingRegistryServiceShared.lua"}},{"name":"ObservePlayerSettings","desc":"Observes the player\'s settings","params":[{"name":"player","desc":"","lua_type":"Player"}],"returns":[{"desc":"","lua_type":"Observable<PlayerSettingsBase>"}],"function_type":"method","source":{"line":87,"path":"src/settings/src/Shared/SettingRegistryServiceShared.lua"}},{"name":"PromisePlayerSettings","desc":"Promises the player\'s settings","params":[{"name":"player","desc":"","lua_type":"Player"}],"returns":[{"desc":"","lua_type":"Promise<PlayerSettingsBase>"}],"function_type":"method","source":{"line":107,"path":"src/settings/src/Shared/SettingRegistryServiceShared.lua"}},{"name":"GetPlayerSettings","desc":"Gets the player\'s settings","params":[{"name":"player","desc":"","lua_type":"Player"}],"returns":[{"desc":"","lua_type":"Promise<PlayerSettingsBase>"}],"function_type":"method","source":{"line":126,"path":"src/settings/src/Shared/SettingRegistryServiceShared.lua"}},{"name":"Destroy","desc":"Cleans up the shared registry service","params":[],"returns":[],"function_type":"method","source":{"line":140,"path":"src/settings/src/Shared/SettingRegistryServiceShared.lua"}}],"properties":[],"types":[],"name":"SettingRegistryServiceShared","desc":"Shared between client and server, letting us centralize definitions in one place.","source":{"line":6,"path":"src/settings/src/Shared/SettingRegistryServiceShared.lua"}}')}}]);