-- Author: VertexFloat
-- Date: 05.04.2022
-- Version: Farming Simulator 22, 1.0.0.0
-- Copyright (C): VertexFloat, All Rights Reserved
-- Manual Auger Wagon Discharge specialization

source(g_currentModDirectory .. "src/vehicles/specializations/events/ManualAugerWagonDischargeEvent.lua")

ManualAugerWagonDischarge = {}

function ManualAugerWagonDischarge.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Trailer, specializations) and SpecializationUtil.hasSpecialization(Pipe, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations)
end

function ManualAugerWagonDischarge.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setDischargeAugerWagonState", ManualAugerWagonDischarge.setDischargeAugerWagonState)
	SpecializationUtil.registerFunction(vehicleType, "getIsDischargeAugerWagonToggleable", ManualAugerWagonDischarge.getIsDischargeAugerWagonToggleable)
	SpecializationUtil.registerFunction(vehicleType, "getIsPipeUnfolded", ManualAugerWagonDischarge.getIsPipeUnfolded)
end

function ManualAugerWagonDischarge.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeRaycast", ManualAugerWagonDischarge.handleDischargeRaycast)
end

function ManualAugerWagonDischarge.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ManualAugerWagonDischarge)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ManualAugerWagonDischarge)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ManualAugerWagonDischarge)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ManualAugerWagonDischarge)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ManualAugerWagonDischarge)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ManualAugerWagonDischarge)
end

function ManualAugerWagonDischarge:onLoad(savegame)
	self.spec_manualAugerWagonDischarge = {}
	local spec = self.spec_manualAugerWagonDischarge
	local specP = self.spec_pipe
	
	if specP.automaticDischarge == false then
		specP.automaticDischarge = true
	end
	
	spec.actionEvents = {}
	spec.allowDischarge = false
	spec.isActionAllowed = false
end

function ManualAugerWagonDischarge:onUpdate(dt)
	local spec = self.spec_manualAugerWagonDischarge
	local specP = self.spec_pipe
	local isUnavailable = specP.autoAimingStates[specP.currentState]
	local isActive = g_currentMission.manualDischarge:getSettingsValue(false, true)
	
	if self:getIsAIActive() or isUnavailable or not isActive then
		spec.allowDischarge = true
	end
end

function ManualAugerWagonDischarge:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		ManualAugerWagonDischarge.updateActionEvents(self)
		
		local spec = self.spec_manualAugerWagonDischarge
		local specD = self.spec_dischargeable
		local dischargeNode = specD.currentDischargeNode
		local fillTypeIndex = self:getFillUnitFillType(dischargeNode.fillUnitIndex)
		local isActive = g_currentMission.manualDischarge:getSettingsValue(false, true)
		
		if self:getIsActiveForInput() and self:getCanDischargeToObject(dischargeNode) and self:getIsDischargeAugerWagonToggleable() and isActive then
			g_currentMission.manualDischarge:showAugerWagonDischargeContext(fillTypeIndex)
		end
	end
end

function ManualAugerWagonDischarge:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_manualAugerWagonDischarge
		local specP = self.spec_pipe
		
		self:clearActionEventsTable(spec.actionEvents)
		
		if self:getIsActiveForInput(true, true) and specP.hasMovablePipe then
			local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_DISCHARGE_AUGER_WAGON, self, ManualAugerWagonDischarge.actionEventDischargeAugerWagonPipe, false, true, false, true, nil)
			
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)	
			
			ManualAugerWagonDischarge.updateActionEvents(self)
		end
	end
end

function ManualAugerWagonDischarge:actionEventDischargeAugerWagonPipe(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_manualAugerWagonDischarge
	
	self:setDischargeAugerWagonState(not spec.allowDischarge)
end

function ManualAugerWagonDischarge:setDischargeAugerWagonState(state, noEventSend)
	local spec = self.spec_manualAugerWagonDischarge
	
	if spec.allowDischarge ~= state then
		spec.allowDischarge = state
	end
	
	ManualAugerWagonDischargeEvent.sendEvent(self, state, noEventSend)
end

function ManualAugerWagonDischarge:onWriteStream(streamId, connection)
	if not connection:getIsServer() then 
		local spec = self.spec_manualAugerWagonDischarge
		
		streamWriteBool(streamId, spec.allowDischarge)
	end
end

function ManualAugerWagonDischarge:onReadStream(streamId, connection)
	if not connection:getIsServer() then 
		local spec = self.spec_manualAugerWagonDischarge
		
		spec.allowDischarge = streamReadBool(streamId)
	end
end

function ManualAugerWagonDischarge:updateActionEvents()
	local spec = self.spec_manualAugerWagonDischarge
	local isPipeUnfolded = self:getIsPipeUnfolded()
	local isActive = g_currentMission.manualDischarge:getSettingsValue(false, true)
	local actionEvent = spec.actionEvents[InputAction.TOGGLE_DISCHARGE_AUGER_WAGON]
	
	if actionEvent ~= nil then
		if isPipeUnfolded and spec.isActionAllowed and not self:getIsAIActive() and isActive then
			local text = nil
			
			g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)
			
			if spec.allowDischarge then
				text = g_i18n:getText("action_stopOverloading")
			else
				text = g_i18n:getText("action_startOverloading")
			end
			
			g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
		else
			g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
		end
	end
end

function ManualAugerWagonDischarge:handleDischargeRaycast(superFunc, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	local specP = self.spec_pipe
	local spec = self.spec_manualAugerWagonDischarge
	
	if specP.automaticDischarge then
		local stopDischarge = false
		
		if self:getIsPowered() and hitObject ~= nil then
			local fillType = self:getDischargeFillType(dischargeNode)
			local allowFillType = hitObject:getFillUnitAllowsFillType(hitFillUnitIndex, fillType)
			
			if allowFillType and hitObject:getFillUnitFreeCapacity(hitFillUnitIndex, fillType, self:getOwnerFarmId()) > 0 then
				if spec.allowDischarge then
					self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT, true)
				else
					stopDischarge = true
				end
				
				spec.isActionAllowed = true
			else
				stopDischarge = true
				spec.isActionAllowed = false
				self:setDischargeAugerWagonState(false)
			end
		elseif self:getIsPowered() and specP.toggleableDischargeToGround then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_GROUND, true)
		else
			stopDischarge = true
			spec.isActionAllowed = false
			self:setDischargeAugerWagonState(false)
		end
		
		if stopDischarge and self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OBJECT then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
		end
		
		return
	end
	
	superFunc(self, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
end

function ManualAugerWagonDischarge:getIsPipeUnfolded()
	local spec = self.spec_manualAugerWagonDischarge
	local specP = self.spec_pipe
	
	local isPipeUnfolded = specP.targetState > 1 or specP.numStates == 1
	
	if specP.animation.name ~= nil then
		isPipeUnfolded = isPipeUnfolded and not self:getIsAnimationPlaying(specP.animation.name)
	end
	
	if isPipeUnfolded == false then
		spec.isActionAllowed = false
		self:setDischargeAugerWagonState(false)
	end
	
	return isPipeUnfolded
end

function ManualAugerWagonDischarge:getIsDischargeAugerWagonToggleable()
	return self.spec_manualAugerWagonDischarge.isActionAllowed
end