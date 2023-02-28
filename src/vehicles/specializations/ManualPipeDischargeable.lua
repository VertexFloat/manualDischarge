-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.1, 11/02/2023
-- @filename: ManualPipeDischargeable.lua

-- Changelog (1.0.0.1) :
--
-- cleaned code
-- fixed AI bug where they couldn't discharge
-- fixed forage harvesters discharging
-- moved some functions from ManualDischargeUtil.lua

ManualPipeDischargeable = {
	MANUAL_PIPE_DISCHARGEABLE_STATE_OFF = false,
	MANUAL_PIPE_DISCHARGEABLE_STATE_ON = true,
	SETTINGS = {
		HARVESTERS = 'isHarvestersDischargeManually',
		POTATOVEHICLES = 'isPotatoHarvestersDischargeManually',
		BEETVEHICLES = 'isBeetHarvestersDischargeManually',
		AUGERWAGONS = 'isAugerWagonsDischargeManually'
	}
}

function ManualPipeDischargeable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Pipe, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations)
end

function ManualPipeDischargeable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, 'getIsDischargeableManually', ManualPipeDischargeable.getIsDischargeableManually)
	SpecializationUtil.registerFunction(vehicleType, 'setManualPipeDischargeState', ManualPipeDischargeable.setManualPipeDischargeState)
	SpecializationUtil.registerFunction(vehicleType, 'getManualPipeDischargeState', ManualPipeDischargeable.getManualPipeDischargeState)
	SpecializationUtil.registerFunction(vehicleType, 'getIsManualPipeDischargeToggleable', ManualPipeDischargeable.getIsManualPipeDischargeToggleable)
	SpecializationUtil.registerFunction(vehicleType, 'getVehicleCategoryName', ManualPipeDischargeable.getVehicleCategoryName)
	SpecializationUtil.registerFunction(vehicleType, 'getAttachedImplementCategoryName', ManualPipeDischargeable.getAttachedImplementCategoryName)
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

	if self.spec_pipe.automaticDischarge == false then
		self.spec_pipe.automaticDischarge = true
	end

	spec.actionEvents = {}

	spec.currentManualPipeDischargeState = ManualPipeDischargeable.MANUAL_PIPE_DISCHARGEABLE_STATE_OFF
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

	if (self:getIsAIActive() or not self:getIsDischargeableManually() or self.spec_pipe.autoAimingStates[self.spec_pipe.currentState]) then
		if spec.currentManualPipeDischargeState == ManualPipeDischargeable.MANUAL_PIPE_DISCHARGEABLE_STATE_OFF then
			self:setManualPipeDischargeState(ManualPipeDischargeable.MANUAL_PIPE_DISCHARGEABLE_STATE_ON)
		end
	else
		if not self:getIsManualPipeDischargeToggleable() then
			if spec.currentManualPipeDischargeState == ManualPipeDischargeable.MANUAL_PIPE_DISCHARGEABLE_STATE_ON then
				self:setManualPipeDischargeState(ManualPipeDischargeable.MANUAL_PIPE_DISCHARGEABLE_STATE_OFF)
			end
		end
	end
end

function ManualPipeDischargeable:onUpdateTick(dt)
	local spec = self.spec_manuallyPipeDischargeable
	local dischargeNode = self.spec_dischargeable.currentDischargeNode
	local fillTypeIndex = self:getFillUnitFillType(dischargeNode.fillUnitIndex)

	if self:getIsDischargeableManually() then
		if self:getIsActiveForInput() and self:getIsManualPipeDischargeToggleable() then
			g_manualDischarge:showPipeDischargeContext(fillTypeIndex)
		end
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
		if self:getIsManualPipeDischargeToggleable() and self:getIsDischargeableManually() then
			isActive = true

			if spec.currentManualPipeDischargeState == ManualPipeDischargeable.MANUAL_PIPE_DISCHARGEABLE_STATE_OFF then
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

		if isActiveForInputIgnoreSelection then
			if self:getPipeDischargeNodeIndex() ~= nil then
				local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_MANUAL_DISCHARGE_PIPE, self, ManualPipeDischargeable.actionEventManualDischargePipe, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)

				ManualPipeDischargeable.updateActionEvents(self)
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

	if self.spec_pipe.automaticDischarge then
		local stopDischarge = false

		if self:getIsPowered() and hitObject ~= nil then
			local fillType = self:getDischargeFillType(dischargeNode)
			local allowFillType = hitObject:getFillUnitAllowsFillType(hitFillUnitIndex, fillType)

			if allowFillType and hitObject:getFillUnitFreeCapacity(hitFillUnitIndex, fillType, self:getOwnerFarmId()) > 0 then
				if spec.currentManualPipeDischargeState == ManualPipeDischargeable.MANUAL_PIPE_DISCHARGEABLE_STATE_ON then
					self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT, true)
				else
					stopDischarge = true
				end
			else
				stopDischarge = true

				if spec.currentManualPipeDischargeState == ManualPipeDischargeable.MANUAL_PIPE_DISCHARGEABLE_STATE_ON then
					self:setManualPipeDischargeState(ManualPipeDischargeable.MANUAL_PIPE_DISCHARGEABLE_STATE_OFF)
				end
			end
		elseif self:getIsPowered() and self.spec_pipe.toggleableDischargeToGround then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_GROUND, true)
		else
			stopDischarge = true

			if spec.currentManualPipeDischargeState == ManualPipeDischargeable.MANUAL_PIPE_DISCHARGEABLE_STATE_ON then
				self:setManualPipeDischargeState(ManualPipeDischargeable.MANUAL_PIPE_DISCHARGEABLE_STATE_OFF)
			end
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

function ManualPipeDischargeable:getIsDischargeableManually()
	local spec = self.spec_manuallyPipeDischargeable
	local vehicleCategoryName = self:getVehicleCategoryName(self.configFileName)
	local implementCategoryName = self:getAttachedImplementCategoryName(self.configFileName)

	if vehicleCategoryName ~= nil or implementCategoryName ~= nil then
		for categoryName, settingName in pairs(ManualPipeDischargeable.SETTINGS) do
			if categoryName == vehicleCategoryName or categoryName == implementCategoryName then
				return g_manualDischarge:getManualDischargeableSettingState(settingName)
			end
		end
	end

	return false
end

function ManualPipeDischargeable:getVehicleCategoryName(configFileName)
	return g_storeManager:getItemByXMLFilename(configFileName).categoryName
end

function ManualPipeDischargeable:getAttachedImplementCategoryName(configFileName)
	for _, vehicle in pairs(g_currentMission.vehicles) do
		if vehicle ~= nil then
			if SpecializationUtil.hasSpecialization(AttacherJoints, vehicle.specializations) then
				local attachedImplements = vehicle:getAttachedImplements()

				if attachedImplements ~= nil then
					for _, attachedImplement in pairs(attachedImplements) do
						if attachedImplement.object.configFileName == configFileName then
							return g_storeManager:getItemByXMLFilename(attachedImplement.object.configFileName).categoryName
						end
					end
				end
			end
		end
	end
end