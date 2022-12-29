-- Author: VertexFloat
-- Date: 17.07.2022
-- Version: Farming Simulator 22, 1.0.0.0
-- Copyright (C): VertexFloat, All Rights Reserved
-- Manual Discharge Settings Event

ManualDischargeSettingsEvent = {}

local ManualDischargeSettingsEvent_mt = Class(ManualDischargeSettingsEvent, Event)

InitEventClass(ManualDischargeSettingsEvent, "ManualDischargeSettingsEvent")

function ManualDischargeSettingsEvent.emptyNew()
    local self = Event.new(ManualDischargeSettingsEvent_mt, NetworkNode.CHANNEL_SECONDARY)

    return self
end

function ManualDischargeSettingsEvent.new()
    local self = ManualDischargeSettingsEvent.emptyNew()

    return self
end

function ManualDischargeSettingsEvent:readStream(streamId, connection)
    local isHarvestersDischargeManually = streamReadBool(streamId)
    local isPotatoHarvestersDischargeManually = streamReadBool(streamId)
    local isBeetHarvestersDischargeManually = streamReadBool(streamId)
    local isAugerWagonsDischargeManually = streamReadBool(streamId)

    if connection:getIsServer() or g_currentMission.userManager:getIsConnectionMasterUser(connection) then
        g_manualDischarge:setIsHarvestersDischargeManually(isHarvestersDischargeManually, true)
        g_manualDischarge:setIsPotatoHarvestersDischargeManually(isPotatoHarvestersDischargeManually, true)
        g_manualDischarge:setIsBeetHarvestersDischargeManually(isBeetHarvestersDischargeManually, true)
        g_manualDischarge:setIsAugerWagonsDischargeManually(isAugerWagonsDischargeManually, true)

        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false, connection)
        end
    end
end

function ManualDischargeSettingsEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, g_manualDischarge.isHarvestersDischargeManually)
    streamWriteBool(streamId, g_manualDischarge.isPotatoHarvestersDischargeManually)
    streamWriteBool(streamId, g_manualDischarge.isBeetHarvestersDischargeManually)
    streamWriteBool(streamId, g_manualDischarge.isAugerWagonsDischargeManually)
end

function ManualDischargeSettingsEvent:run(connection)
    print("Error: ManualDischargeSettingsEvent is not allowed to be executed on a local client")
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