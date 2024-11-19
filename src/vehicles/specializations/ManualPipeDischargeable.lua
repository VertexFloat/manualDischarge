-- ManualPipeDischargeable.lua
--
-- author: 4c65736975
--
-- Copyright (c) 2024 VertexFloat. All Rights Reserved.
--
-- This source code is licensed under the GPL-3.0 license found in the
-- LICENSE file in the root directory of this source tree.

ManualPipeDischargeable = {}

function ManualPipeDischargeable.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Pipe, specializations)
end

function ManualPipeDischargeable.initSpecialization()
  g_vehicleConfigurationManager:addConfigurationType("manualDischarge", g_i18n:getText("configuration_manualDischarge"), nil, VehicleConfigurationItem)
end

function ManualPipeDischargeable.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoad", ManualPipeDischargeable)
  SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerStart", ManualPipeDischargeable)
  SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerEnd", ManualPipeDischargeable)
end

function ManualPipeDischargeable:onLoad(savegame)
  if self.configurations.manualDischarge and self.configurations.manualDischarge > 1 or false then
    local pipeSpec = self.spec_pipe

    if pipeSpec.automaticDischarge == true then
      pipeSpec.automaticDischarge = false
    end
  else
    SpecializationUtil.removeEventListener(self, "onAIFieldWorkerStart", ManualPipeDischargeable)
    SpecializationUtil.removeEventListener(self, "onAIFieldWorkerEnd", ManualPipeDischargeable)
  end
end

function ManualPipeDischargeable:onAIFieldWorkerStart()
  self.spec_pipe.automaticDischarge = true
end

function ManualPipeDischargeable:onAIFieldWorkerEnd()
  self.spec_pipe.automaticDischarge = false
end