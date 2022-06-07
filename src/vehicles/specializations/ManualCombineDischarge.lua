-- Author: VertexFloat
-- Date: 05.04.2022
-- Version: Farming Simulator 22, 1.0.0.0
-- Copyright (C): VertexFloat, All Rights Reserved
-- Manual Combine Discharge specialization

source(g_currentModDirectory .. "src/vehicles/specializations/events/ManualCombineDischargeEvent.lua")

ManualCombineDischarge = {}

function ManualCombineDischarge.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Combine, specializations) and SpecializationUtil.hasSpecialization(Pipe, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations)
end

function ManualCombineDischarge.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setDischargeCombineState", ManualCombineDischarge.setDischargeCombineState)
	SpecializationUtil.registerFunction(vehicleType, "getIsDischargeCombineToggleable", ManualCombineDischarge.getIsDischargeCombineToggleable)
	SpecializationUtil.registerFunction(vehicleType, "getIsPipeUnfolded", ManualCombineDischarge.getIsPipeUnfolded)
end

function ManualCombineDischarge.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeRaycast", ManualCombineDischarge.handleDischargeRaycast)
end

function ManualCombineDischarge.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ManualCombineDischarge)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ManualCombineDischarge)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ManualCombineDischarge)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ManualCombineDischarge)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ManualCombineDischarge)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ManualCombineDischarge)
end

function ManualCombineDischarge:onLoad(savegame)
	self.spec_manualCombineDischarge = {}
	local spec = self.spec_manualCombineDischarge
	local specP = self.spec_pipe
	
	if specP.automaticDischarge == false then
		specP.automaticDischarge = true
	end
	
	spec.actionEvents = {}
	spec.allowDischarge = false
	spec.isActionAllowed = false
end

function ManualCombineDischarge:onUpdate(dt)
	local spec = self.spec_manualCombineDischarge
	local specP = self.spec_pipe
	local isUnavailable = specP.autoAimingStates[specP.currentState]
	local isActive = g_currentMission.manualDischarge:getSettingsValue(true, false)
	
	if self:getIsAIActive() or isUnavailable or not isActive then
		spec.allowDischarge = true
	end
end

function ManualCombineDischarge:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		ManualCombineDischarge.updateActionEvents(self)
		
		local spec = self.spec_manualCombineDischarge
		local specD = self.spec_dischargeable
		local dischargeNode = specD.currentDischargeNode
		local fillTypeIndex = self:getFillUnitFillType(dischargeNode.fillUnitIndex)
		local isActive = g_currentMission.manualDischarge:getSettingsValue(true, false)
		
		if self:getIsActiveForInput() and self:getCanDischargeToObject(dischargeNode) and self:getIsDischargeCombineToggleable() and isActive then
			g_currentMission.manualDischarge:showCombineDischargeContext(fillTypeIndex)
		end
	end
end

function ManualCombineDischarge:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_manualCombineDischarge
		local specP = self.spec_pipe
		
		self:clearActionEventsTable(spec.actionEvents)
		
		if self:getIsActiveForInput(true, true) and specP.hasMovablePipe and not self:getIsAIActive() then
			local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_DISCHARGE_COMBINE, self, ManualCombineDischarge.actionEventDischargePipe, false, true, false, true, nil)
			
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)	
			
			ManualCombineDischarge.updateActionEvents(self)
		end
	end
end

function ManualCombineDischarge:actionEventDischargePipe(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_manualCombineDischarge
	
	self:setDischargeCombineState(not spec.allowDischarge)
end

function ManualCombineDischarge:setDischargeCombineState(state, noEventSend)
	local spec = self.spec_manualCombineDischarge
	
	if spec.allowDischarge ~= state then
		spec.allowDischarge = state
	end
	
	ManualCombineDischargeEvent.sendEvent(self, state, noEventSend)
end

function ManualCombineDischarge:onWriteStream(streamId, connection)
	if not connection:getIsServer() then 
		local spec = self.spec_manualCombineDischarge
		
		streamWriteBool(streamId, spec.allowDischarge)
	end
end

function ManualCombineDischarge:onReadStream(streamId, connection)
	if not connection:getIsServer() then 
		local spec = self.spec_manualCombineDischarge
		
		spec.allowDischarge = streamReadBool(streamId)
	end
end

function ManualCombineDischarge:updateActionEvents()
	local spec = self.spec_manualCombineDischarge
	local specP = self.spec_pipe
	local isUnavailable = specP.autoAimingStates[specP.currentState]
	local isPipeUnfolded = self:getIsPipeUnfolded()
	local isActive = g_currentMission.manualDischarge:getSettingsValue(true, false)
	local actionEvent = spec.actionEvents[InputAction.TOGGLE_DISCHARGE_COMBINE]
	
	if actionEvent ~= nil then
		if not isUnavailable and isPipeUnfolded and spec.isActionAllowed and not self:getIsAIActive() and isActive then
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

function ManualCombineDischarge:handleDischargeRaycast(superFunc, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	local specP = self.spec_pipe
	local spec = self.spec_manualCombineDischarge
	
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
				self:setDischargeCombineState(false)
			end
		elseif self:getIsPowered() and specP.toggleableDischargeToGround then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_GROUND, true)
		else
			stopDischarge = true
			spec.isActionAllowed = false
			self:setDischargeCombineState(false)
		end
		
		if stopDischarge and self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OBJECT then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
		end
		
		return
	end
	
	superFunc(self, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
end

function ManualCombineDischarge:getIsPipeUnfolded()
	local spec = self.spec_manualCombineDischarge
	local specP = self.spec_pipe
	
	local isPipeUnfolded = specP.targetState > 1 or specP.numStates == 1
	
	if specP.animation.name ~= nil then
		isPipeUnfolded = isPipeUnfolded and not self:getIsAnimationPlaying(specP.animation.name)
	end
	
	if isPipeUnfolded == false then
		spec.isActionAllowed = false
		self:setDischargeCombineState(false)
	end
	
	return isPipeUnfolded
end

function ManualCombineDischarge:getIsDischargeCombineToggleable()
	return self.spec_manualCombineDischarge.isActionAllowed
end