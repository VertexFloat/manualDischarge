-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.3, 23|09|2023
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

-- Changelog (1.0.0.3):
-- fixed a issue that caused the vehicle to remain turned on or turn on automatically when the unloading pipe was above the unloading site
-- improved and cleaned code
-- removed unnecessary code

ManualPipeDischargeable = {}

function ManualPipeDischargeable.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Pipe, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations)
end

function ManualPipeDischargeable.initSpecialization()
  g_configurationManager:addConfigurationType("manualDischarge", g_i18n:getText("configuration_manualDischarge"), nil, nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function ManualPipeDischargeable.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoad", ManualPipeDischargeable)
  SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ManualPipeDischargeable)
  SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ManualPipeDischargeable)
  SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerStart", ManualPipeDischargeable)
  SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerEnd", ManualPipeDischargeable)
end

function ManualPipeDischargeable:onLoad(savegame)
  self.spec_manualPipeDischargeable = {}
  local spec = self.spec_manualPipeDischargeable

  spec.isManual = self.configurations.manualDischarge and self.configurations.manualDischarge > 1 or false

  if spec.isManual then
    local pipeSpec = self.spec_pipe

    if pipeSpec.automaticDischarge == true then
      pipeSpec.automaticDischarge = false
    end

    spec.actionEvents = {}
  else
    SpecializationUtil.removeEventListener(self, "onUpdateTick", ManualPipeDischargeable)
    SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", ManualPipeDischargeable)
    SpecializationUtil.removeEventListener(self, "onAIFieldWorkerStart", ManualPipeDischargeable)
    SpecializationUtil.removeEventListener(self, "onAIFieldWorkerEnd", ManualPipeDischargeable)
  end
end

function ManualPipeDischargeable:onUpdateTick(dt)
  local spec = self.spec_manualPipeDischargeable
  local currentDischargeNode = self.spec_dischargeable.currentDischargeNode

  if self:getIsActiveForInput() and self:getCanDischargeToObject(currentDischargeNode) and self:getCanToggleDischargeToObject() then
    g_currentMission:showPipeDischargeContext(self:getFillUnitFillType(currentDischargeNode.fillUnitIndex))
  end

  if self.isClient then
    ManualPipeDischargeable.updateActionEvents(self)
  end
end

function ManualPipeDischargeable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
  if self.isClient then
    local spec = self.spec_manualPipeDischargeable
    local dischargeableSpec = self.spec_dischargeable

    self:clearActionEventsTable(spec.actionEvents)

    if dischargeableSpec.actionEvents[InputAction.TOGGLE_TIPSTATE] ~= nil then
      self:removeActionEvent(dischargeableSpec.actionEvents, InputAction.TOGGLE_TIPSTATE)
    end

    if isActiveForInputIgnoreSelection then
      if self:getCanToggleDischargeToObject() then
        local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_MANUAL_DISCHARGE_PIPE, self, Dischargeable.actionEventToggleDischarging, false, true, false, true, nil)

        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
      end

      ManualPipeDischargeable.updateActionEvents(self)
    end
  end
end

function ManualPipeDischargeable:onAIFieldWorkerStart()
  local pipeSpec = self.spec_pipe

  if pipeSpec.automaticDischarge == false then
    pipeSpec.automaticDischarge = true
  end
end

function ManualPipeDischargeable:onAIFieldWorkerEnd()
  local pipeSpec = self.spec_pipe

  if pipeSpec.automaticDischarge == true then
    pipeSpec.automaticDischarge = false
  end
end

function ManualPipeDischargeable.updateActionEvents(self)
  local spec = self.spec_manualPipeDischargeable
  local dischargeableSpec = self.spec_dischargeable
  local actionEvent = spec.actionEvents[InputAction.TOGGLE_MANUAL_DISCHARGE_PIPE]
  local isActive = false

  if actionEvent ~= nil then
    if dischargeableSpec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
      local currentDischargeNode = dischargeableSpec.currentDischargeNode

      if self:getIsDischargeNodeActive(currentDischargeNode) then
        if self:getCanDischargeToObject(currentDischargeNode) and self:getCanToggleDischargeToObject() then
          g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_startOverloading"))

          isActive = true
        end
      end
    else
      g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_stopOverloading"))

      isActive = true
    end

    g_inputBinding:setActionEventActive(actionEvent.actionEventId, isActive)
  end
end