-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.1, 14/02/2023
-- @filename: ManualDischargeSettingsEvent.lua

-- Changelog (1.0.0.1) :
--
-- cleaned and improved code

ManualDischargeSettingsEvent = {}

local ManualDischargeSettingsEvent_mt = Class(ManualDischargeSettingsEvent, Event)

InitEventClass(ManualDischargeSettingsEvent, 'ManualDischargeSettingsEvent')

function ManualDischargeSettingsEvent.emptyNew()
	local self = Event.new(ManualDischargeSettingsEvent_mt, NetworkNode.CHANNEL_SECONDARY)

	return self
end

function ManualDischargeSettingsEvent.new()
	local self = ManualDischargeSettingsEvent.emptyNew()

	return self
end

function ManualDischargeSettingsEvent:readStream(streamId, connection)
	if connection:getIsServer() or g_currentMission.userManager:getIsConnectionMasterUser(connection) then
		for i = 1, #g_manualDischarge.manualDischargeSettings.settings do
			local setting = g_manualDischarge.manualDischargeSettings.settings[i]
			local state = streamReadBool(streamId)

			g_manualDischarge:setManualDischargeableSettingState(setting.name, state, true)
		end

		if not connection:getIsServer() then
			g_server:broadcastEvent(self, false, connection)
		end
	end
end

function ManualDischargeSettingsEvent:writeStream(streamId, connection)
	for i = 1, #g_manualDischarge.manualDischargeSettings.settings do
		local setting = g_manualDischarge.manualDischargeSettings.settings[i]

		streamWriteBool(streamId, setting.state)
	end
end

function ManualDischargeSettingsEvent:run(connection)
	Logging.Error('ManualDischargeSettingsEvent is not allowed to be executed on local client')
end

function ManualDischargeSettingsEvent.sendEvent(noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server then
			g_server:broadcastEvent(ManualDischargeSettingsEvent.new(), false)
		else
			g_client:getServerConnection():sendEvent(ManualDischargeSettingsEvent.new())
		end
	end
end