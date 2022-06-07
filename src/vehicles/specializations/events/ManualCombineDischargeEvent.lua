-- Author: VertexFloat
-- Date: 04.04.2022
-- Version: Farming Simulator 22, 1.0.0.0
-- Copyright (C): VertexFloat, All Rights Reserved
-- Manual Combine Discharge specialization event

ManualCombineDischargeEvent = {}

local ManualCombineDischargeEvent_mt = Class(ManualCombineDischargeEvent, Event)

InitEventClass(ManualCombineDischargeEvent, "ManualCombineDischargeEvent")

function ManualCombineDischargeEvent.emptyNew()
	return Event.new(ManualCombineDischargeEvent_mt)
end

function ManualCombineDischargeEvent.new(vehicle, allowDischarge)
	local self = ManualCombineDischargeEvent.emptyNew()
	
	self.vehicle = vehicle
	self.allowDischarge = allowDischarge
	
	return self
end

function ManualCombineDischargeEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	
	self.allowDischarge = streamReadBool(streamId)
	
	self:run(connection)
end

function ManualCombineDischargeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	
	streamWriteBool(streamId, self.allowDischarge)
end

function ManualCombineDischargeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end
	
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setDischargeCombineState(self.allowDischarge, true)
	end
end

function ManualCombineDischargeEvent.sendEvent(vehicle, allowDischarge, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(ManualCombineDischargeEvent.new(vehicle, allowDischarge), nil, _, vehicle)
		else
			g_client:getServerConnection():sendEvent(ManualCombineDischargeEvent.new(vehicle, allowDischarge))
		end
	end
end