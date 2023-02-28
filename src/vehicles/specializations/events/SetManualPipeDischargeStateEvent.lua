-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 11/07/2022
-- @filename: SetManualPipeDischargeStateEvent.lua

SetManualPipeDischargeStateEvent = {}

local SetManualPipeDischargeStateEvent_mt = Class(SetManualPipeDischargeStateEvent, Event)

InitEventClass(SetManualPipeDischargeStateEvent, 'SetManualPipeDischargeStateEvent')

function SetManualPipeDischargeStateEvent.emptyNew()
	return Event.new(SetManualPipeDischargeStateEvent_mt)
end

function SetManualPipeDischargeStateEvent.new(vehicle, state)
	local self = SetManualPipeDischargeStateEvent.emptyNew()

	self.vehicle = vehicle
	self.state = state

	return self
end

function SetManualPipeDischargeStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)

	self:run(connection)
end

function SetManualPipeDischargeStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)

	streamWriteBool(streamId, self.state)
end

function SetManualPipeDischargeStateEvent:run(connection)
	if self.vehicle ~= nil then
		if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
			self.vehicle:setManualPipeDischargeState(self.state, true)
		end
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(SetManualPipeDischargeStateEvent.new(self.vehicle, self.state), nil, connection, self.vehicle)
	end
end

function SetManualPipeDischargeStateEvent.sendEvent(vehicle, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetManualPipeDischargeStateEvent.new(vehicle, state), nil, nil, vehicle)
		else
			g_client:getServerConnection():sendEvent(SetManualPipeDischargeStateEvent.new(vehicle, state))
		end
	end
end