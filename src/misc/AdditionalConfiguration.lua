-- AdditionalConfiguration.lua
--
-- author: 4c65736975
--
-- Copyright (c) 2024 VertexFloat. All Rights Reserved.
--
-- This source code is licensed under the GPL-3.0 license found in the
-- LICENSE file in the root directory of this source tree.

local MOD_DIRECTORY = g_currentModDirectory
local CONFIGURATION_XML_PATH = MOD_DIRECTORY .. "data/manualDischargeConfiguration.xml"

local function getConfigurationsFromXML(superFunc, manager, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
  local configurations, defaultConfigurationIds = superFunc(manager, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)

  if not xmlFile:hasProperty("vehicle.pipe") then
    return configurations, defaultConfigurationIds
  end

  if xmlFile:getValue("vehicle.pipe.pipeConfigurations.pipeConfiguration(0).pipeNodes.pipeNode(0)#autoAimYRotation", false) or xmlFile:getValue("vehicle.pipe.pipeNodes.pipeNode(0)#autoAimYRotation", false) then
    return configurations, defaultConfigurationIds
  end

  local configXMLFile = XMLFile.load("manualDischargeConfigurationXML", CONFIGURATION_XML_PATH, xmlFile.schema)

  if configXMLFile then
    local configurationDescs = manager:getConfigurations()
    local configurationDesc = configurationDescs["manualDischarge"]

    if configurationDesc then
      local configurationItems = {}
      local i = 0

      while true do
        if i > 2 ^ ConfigurationUtil.SEND_NUM_BITS then
          Logging.xmlWarning(configXMLFile, "Maximum number of configurations are reached for %s. Only %d configurations per type are allowed!", configurationDesc.name, 2 ^ ConfigurationUtil.SEND_NUM_BITS)
        end

        local configKey = string.format(configurationDesc.configurationKey .."(%d)", i)

        if not configXMLFile:hasProperty(configKey) then
          break
        end

        local configItem = configurationDesc.itemClass.new(configurationDesc.name)
        configItem:setIndex(#configurationItems + 1)

        if configItem:loadFromXML(configXMLFile, configurationDesc.configurationsKey, configKey, baseDir, customEnvironment) then
          table.insert(configurationItems, configItem)
        end

        i = i + 1
      end

      if #configurationItems > 0 then
        defaultConfigurationIds[configurationDesc.name] = ConfigurationUtil.getDefaultConfigIdFromItems(configurationItems)

        configurations[configurationDesc.name] = configurationItems
      end
    end

    configXMLFile:delete()
  end

  return configurations, defaultConfigurationIds
end

local function overwrittenFunction(oldFunc, newFunc)
  return function(...)
    return newFunc(oldFunc, ...)
  end
end

ConfigurationUtil.getConfigurationsFromXML = overwrittenFunction(ConfigurationUtil.getConfigurationsFromXML, getConfigurationsFromXML)