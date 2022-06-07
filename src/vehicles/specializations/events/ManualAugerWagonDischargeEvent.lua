-- Author: VertexFloat
-- Date: 04.04.2022
-- Version: Farming Simulator 22, 1.0.0.0
-- Copyright (C): VertexFloat, All Rights Reserved
-- Manual Auger Wagon Discharge specialization event

ManualAugerWagonDischargeEvent = {}

local ManualAugerWagonDischargeEvent_mt = Class(ManualAugerWagonDischargeEvent, Event)

InitEventClass(ManualAugerWagonDischargeEvent, "ManualAugerWagonDischargeEvent")

function ManualAugerWagonDischargeEvent.emptyNew()
	return Event.new(ManualAugerWagonDischargeEvent_mt)
end

function ManualAugerWagonDischargeEvent.new(vehicle, allowDischarge)
	local self = ManualAugerWagonDischargeEvent.emptyNew()
	
	self.vehicle = vehicle
	self.allowDischarge = allowDischarge
	
	return self
end

function ManualAugerWagonDischargeEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	
	self.allowDischarge = streamReadBool(streamId)
	
	self:run(connection)
end

function ManualAugerWagonDischargeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	
	streamWriteBool(streamId, self.allowDischarge)
end

function ManualAugerWagonDischargeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end
	
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setDischargeAugerWagonState(self.allowDischarge, true)
	end
end

function ManualAugerWagonDischargeEvent.sendEvent(vehicle, allowDischarge, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(ManualAugerWagonDischargeEvent.new(vehicle, allowDischarge), nil, _, vehicle)
		else
			g_client:getServerConnection():sendEvent(ManualAugerWagonDischargeEvent.new(vehicle, allowDischarge))
		end
	end
end