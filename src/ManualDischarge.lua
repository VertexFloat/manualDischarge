-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.2, 11/02/2023
-- @filename: ManualDischarge.lua

-- Changelog (1.0.0.1) :
--
-- completly new, better and cleaner code
-- merged functionality with 'main' file

-- Changelog (1.0.0.2) :
--
-- cleaned and improved code
-- moved settings code to ManualDischargeSettings.lua

ManualDischarge = {
	MOD_DIRECTORY = g_currentModDirectory
}

source(ManualDischarge.MOD_DIRECTORY .. 'src/vehicles/specializations/events/SetManualPipeDischargeStateEvent.lua')
source(ManualDischarge.MOD_DIRECTORY .. 'src/events/ManualDischargeSettingsEvent.lua')
source(ManualDischarge.MOD_DIRECTORY .. 'src/misc/AdditionalSpecialization.lua')
source(ManualDischarge.MOD_DIRECTORY .. 'src/gui/ManualDischargeSettings.lua')
source(ManualDischarge.MOD_DIRECTORY .. 'src/gui/hud/ManualDischargeHUD.lua')
source(ManualDischarge.MOD_DIRECTORY .. 'src/utils/ManualDischargeUtil.lua')

local ManualDischarge_mt = Class(ManualDischarge)

function ManualDischarge.new(customMt)
	local self = setmetatable({}, customMt or ManualDischarge_mt)

	self.manualDischargeSettings = ManualDischargeSettings.new()

	return self
end

function ManualDischarge:initialize()
	ManualDischargeUtil.overwriteEnvTableElement('ContextActionDisplay', ManualDischargeHUD)

	FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction(FSBaseMission.onConnectionFinishedLoading, ManualDischarge.onConnectionFinishedLoading)

	self.manualDischargeSettings:initialize()
end

function ManualDischarge:showPipeDischargeContext(fillTypeIndex)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

	g_currentMission.hud.contextActionDisplay:setContext(InputAction.TOGGLE_MANUAL_DISCHARGE_PIPE, ContextActionDisplay.CONTEXT_ICON.PIPE_DISCHARGE, fillType.title, HUD.CONTEXT_PRIORITY.MEDIUM)
end

function ManualDischarge:setManualDischargeableSettingState(name, state, noEventSend)
	local setting = self.manualDischargeSettings.nameToSetting[name]

	if setting ~= nil then
		ManualDischargeSettingsEvent.sendEvent(noEventSend)

		if setting.state ~= state then
			setting.state = state

			Logging.info("Manual Discharge Setting '%s': %s", setting.name, setting.state)
		end
	end
end

function ManualDischarge:getManualDischargeableSettingState(setting)
	if ManualDischargeUtil.getIsValidIndexName(setting) then
		return self.manualDischargeSettings.nameToSetting[setting].state
	end

	return false
end

function ManualDischarge:onConnectionFinishedLoading(connection)
	connection:sendEvent(ManualDischargeSettingsEvent.new())
end

g_manualDischarge = ManualDischarge.new()

addModEventListener(g_manualDischarge)

local function validateTypes(self)
	if self.typeName == 'vehicle' and g_manualDischarge ~= nil then
		g_manualDischarge:initialize()
	end
end

TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, validateTypes)

local function onStartMission()
	if g_manualDischarge ~= nil then
		for i = 1, #g_manualDischarge.manualDischargeSettings.settings do
			local setting = g_manualDischarge.manualDischargeSettings.settings[i]

			Logging.info("Manual Discharge Setting '%s': %s", setting.name, setting.state)
		end
	end
end

FSBaseMission.onStartMission = Utils.appendedFunction(FSBaseMission.onStartMission, onStartMission)