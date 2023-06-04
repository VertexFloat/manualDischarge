-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 10|05|2023
-- @filename: AdditionalConfiguration.lua

local function getConfigurationsFromXML(xmlFile, superFunc, key, baseDir, customEnvironment, isMod, storeItem)
	local configurations, defaultConfigurationIds = superFunc(xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
	local hasAutoAim = xmlFile:getValue('vehicle.pipe.pipeConfigurations.pipeConfiguration(0).pipeNodes.pipeNode(0)#autoAimYRotation', false) or xmlFile:getValue('vehicle.pipe.pipeNodes.pipeNode(0)#autoAimYRotation', false)

	if xmlFile:hasProperty('vehicle.pipe') and not hasAutoAim then
		if configurations == nil then
			configurations = {}
		end

		if defaultConfigurationIds == nil then
			defaultConfigurationIds = {}
		end

		configurations.manualDischarge = {
			{
				isDefault = true,
				saveId = '1',
				isSelectable = true,
				index = 1,
				dailyUpkeep = 0,
				price = 0,
				name = g_i18n:getText('configuration_valueNo'),
				nameCompareParams = {}
			},
			{
				isDefault = false,
				saveId = '2',
				isSelectable = true,
				index = 2,
				dailyUpkeep = 0,
				price = 0,
				name = g_i18n:getText('configuration_valueYes'),
				nameCompareParams = {}
			}
		}
	end

	return configurations, defaultConfigurationIds
end

StoreItemUtil.getConfigurationsFromXML = Utils.overwrittenFunction(StoreItemUtil.getConfigurationsFromXML, getConfigurationsFromXML)