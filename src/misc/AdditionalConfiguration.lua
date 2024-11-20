-- AdditionalConfiguration.lua
--
-- author: 4c65736975
--
-- Copyright (c) 2024 VertexFloat. All Rights Reserved.
--
-- This source code is licensed under the GPL-3.0 license found in the
-- LICENSE file in the root directory of this source tree.

local function getConfigurationsFromXML(self, superFunc, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
  local configurations, defaultConfigurationIds = superFunc(self, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)

  if not xmlFile:hasProperty("vehicle.pipe") then
    return configurations, defaultConfigurationIds
  end

  if xmlFile:getValue("vehicle.pipe.pipeConfigurations.pipeConfiguration(0).pipeNodes.pipeNode(0)#autoAimYRotation", false) or xmlFile:getValue("vehicle.pipe.pipeNodes.pipeNode(0)#autoAimYRotation", false) then
    return configurations, defaultConfigurationIds
  end

  if configurations == nil then
    configurations = {}
  end

  configurations.manualDischarge = {
    {
      index = 1,
      saveId = "1",
      price = 0,
      dailyUpkeep = 0,
      configName = "manualDischarge",
      name = g_i18n:getText("configuration_valueNo"),
      hasDefaultName = true,
      isYesNoOption = true,
      isSelectable = true,
      isDefault = true
    },
    {
      index = 2,
      saveId = "2",
      price = 0,
      dailyUpkeep = 0,
      configName = "manualDischarge",
      name = g_i18n:getText("configuration_valueYes"),
      hasDefaultName = true,
      isYesNoOption = true,
      isSelectable = true,
      isDefault = false
    }
  }

  return configurations, defaultConfigurationIds
end

ConfigurationUtil.getConfigurationsFromXML = Utils.overwrittenFunction(ConfigurationUtil.getConfigurationsFromXML, getConfigurationsFromXML)