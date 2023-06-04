-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.2, 09|05|2023
-- @filename: ManualPipeDischargeable.lua

-- Changelog (1.0.0.1):
-- cleaned code
-- fixed AI bug where they couldn't discharge
-- fixed forage harvesters discharging
-- moved some functions from ManualDischargeUtil.lua

-- Changelog (1.0.0.2):
-- cleaned and improved code
-- added configuration
-- the code responsible for the settings has been removed

source(g_currentModDirectory .. 'src/vehicles/specializations/events/SetManualPipeDischargeStateEvent.lua')

ManualPipeDischargeable = {
	PIPE_DISCHARGE_STATE = {
		OFF = false,
		ON = true
	}
}

function ManualPipeDischargeable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Pipe, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations)
end

function ManualPipeDischargeable.initSpecialization()
	g_configurationManager:addConfigurationType('manualDischarge', g_i18n:getText('configuration_manualDischarge'), nil, nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function ManualPipeDischargeable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, 'setManualPipeDischargeState', ManualPipeDischargeable.setManualPipeDischargeState)
	SpecializationUtil.registerFunction(vehicleType, 'getManualPipeDischargeState', ManualPipeDischargeable.getManualPipeDischargeState)
	SpecializationUtil.registerFunction(vehicleType, 'getIsManualPipeDischargeToggleable', ManualPipeDischargeable.getIsManualPipeDischargeToggleable)
end

function ManualPipeDischargeable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, 'handleDischargeRaycast', ManualPipeDischargeable.handleDischargeRaycast)
end

function ManualPipeDischargeable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, 'onLoad', ManualPipeDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, 'onReadStream', ManualPipeDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, 'onWriteStream', ManualPipeDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, 'onUpdate', ManualPipeDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, 'onUpdateTick', ManualPipeDischargeable)
	SpecializationUtil.registerEventListener(vehicleType, 'onRegisterActionEvents', ManualPipeDischargeable)
end

function ManualPipeDischargeable:onLoad(savegame)
	self.spec_manuallyPipeDischargeable = {}
	local spec = self.spec_manuallyPipeDischargeable

	spec.isManual = self.configurations.manualDischarge and self.configurations.manualDischarge > 1 or false

	if spec.isManual then
		if self.spec_pipe.automaticDischarge == false then
			self.spec_pipe.automaticDischarge = true
		end

		spec.actionEvents = {}
		spec.currentManualPipeDischargeState = ManualPipeDischargeable.PIPE_DISCHARGE_STATE.OFF
	end

	if not spec.isManual then
		SpecializationUtil.removeEventListener(self, 'onUpdate', ManualPipeDischargeable)
		SpecializationUtil.removeEventListener(self, 'onUpdateTick', ManualPipeDischargeable)
		SpecializationUtil.removeEventListener(self, 'onRegisterActionEvents', ManualPipeDischargeable)
		SpecializationUtil.removeEventListener(self, 'onReadStream', ManualPipeDischargeable)
		SpecializationUtil.removeEventListener(self, 'onWriteStream', ManualPipeDischargeable)
	end
end

function ManualPipeDischargeable:onReadStream(streamId, connection)
	if not connection:getIsServer() then
		local spec = self.spec_manuallyPipeDischargeable

		self:setManualPipeDischargeState(streamReadBool(streamId), true)
	end
end

function ManualPipeDischargeable:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local spec = self.spec_manuallyPipeDischargeable

		streamWriteBool(streamId, spec.currentManualPipeDischargeState)
	end
end

function ManualPipeDischargeable:onUpdate(dt)
	local spec = self.spec_manuallyPipeDischargeable

	if self:getIsAIActive() or self.spec_pipe.autoAimingStates[self.spec_pipe.currentState] then
		if spec.currentManualPipeDischargeState == ManualPipeDischargeable.PIPE_DISCHARGE_STATE.OFF then
			self:setManualPipeDischargeState(ManualPipeDischargeable.PIPE_DISCHARGE_STATE.ON)
		end
	elseif not self:getIsManualPipeDischargeToggleable() then
		if spec.currentManualPipeDischargeState == ManualPipeDischargeable.PIPE_DISCHARGE_STATE.ON then
			self:setManualPipeDischargeState(ManualPipeDischargeable.PIPE_DISCHARGE_STATE.OFF)
		end
	end
end

function ManualPipeDischargeable:onUpdateTick(dt)
	local spec = self.spec_manuallyPipeDischargeable
	local dischargeNode = self.spec_dischargeable.currentDischargeNode
	local fillTypeIndex = self:getFillUnitFillType(dischargeNode.fillUnitIndex)

	if self:getIsActiveForInput() and self:getIsManualPipeDischargeToggleable() then
		g_currentMission:showPipeDischargeContext(fillTypeIndex)
	end

	if self.isClient then
		ManualPipeDischargeable.updateActionEvents(self)
	end
end

function ManualPipeDischargeable.updateActionEvents(self)
	local spec = self.spec_manuallyPipeDischargeable
	local actionEvent = spec.actionEvents[InputAction.TOGGLE_MANUAL_DISCHARGE_PIPE]
	local isActive = false

	if actionEvent ~= nil then
		if self:getIsManualPipeDischargeToggleable() then
			isActive = true

			if spec.currentManualPipeDischargeState == ManualPipeDischargeable.PIPE_DISCHARGE_STATE.OFF then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText('action_startOverloading'))
			else
				g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText('action_stopOverloading'))
			end
		end

		g_inputBinding:setActionEventActive(actionEvent.actionEventId, isActive)
	end
end

function ManualPipeDischargeable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_manuallyPipeDischargeable

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInput then
			if self:getPipeDischargeNodeIndex() ~= nil then
				local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_MANUAL_DISCHARGE_PIPE, self, ManualPipeDischargeable.actionEventManualDischargePipe, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
			end
		end
	end
end

function ManualPipeDischargeable:actionEventManualDischargePipe(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_manuallyPipeDischargeable

	self:setManualPipeDischargeState(not spec.currentManualPipeDischargeState)
end

function ManualPipeDischargeable:setManualPipeDischargeState(state, noEventSend)
	local spec = self.spec_manuallyPipeDischargeable

	if state ~= spec.currentManualPipeDischargeState then
		SetManualPipeDischargeStateEvent.sendEvent(self, state, noEventSend)

		spec.currentManualPipeDischargeState = state
	end
end

function ManualPipeDischargeable:handleDischargeRaycast(superFunc, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	local spec = self.spec_manuallyPipeDischargeable

	if spec.isManual and self.spec_pipe.automaticDischarge then
		local stopDischarge = false

		if self:getIsPowered() and hitObject ~= nil then
			local fillType = self:getDischargeFillType(dischargeNode)
			local allowFillType = hitObject:getFillUnitAllowsFillType(hitFillUnitIndex, fillType)

			if allowFillType and hitObject:getFillUnitFreeCapacity(hitFillUnitIndex, fillType, self:getOwnerFarmId()) > 0 then
				if spec.currentManualPipeDischargeState == ManualPipeDischargeable.PIPE_DISCHARGE_STATE.ON then
					self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT, true)
				else
					stopDischarge = true
				end
			else
				stopDischarge = true

				if spec.currentManualPipeDischargeState == ManualPipeDischargeable.PIPE_DISCHARGE_STATE.ON then
					self:setManualPipeDischargeState(ManualPipeDischargeable.PIPE_DISCHARGE_STATE.OFF)
				end
			end
		elseif self:getIsPowered() and self.spec_pipe.toggleableDischargeToGround then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_GROUND, true)
		else
			stopDischarge = true
		end

		if stopDischarge and self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OBJECT then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
		end

		return
	end

	superFunc(self, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
end

function ManualPipeDischargeable:getManualPipeDischargeState()
	return self.spec_manuallyPipeDischargeable.currentManualPipeDischargeState
end

function ManualPipeDischargeable:getIsManualPipeDischargeToggleable()
	local dischargeNode = self.spec_dischargeable.currentDischargeNode

	if self.spec_pipe.autoAimingStates[self.spec_pipe.currentState] then
		return false
	end

	if self.spec_pipe.unloadingStates[self.spec_pipe.currentState] ~= true then
		return false
	end

	if self.spec_pipe.animation.name ~= nil then
		if self:getIsAnimationPlaying(self.spec_pipe.animation.name) then
			return false
		end
	end

	if not self:getCanDischargeToObject(dischargeNode) then
		return false
	end

	if self:getIsAIActive() then
		return false
	end

	return true
end