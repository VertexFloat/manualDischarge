-- Author: VertexFloat
-- Date: 05.04.2022
-- Version: Farming Simulator 22, 1.0.0.0
-- Copyright (C): VertexFloat, All Rights Reserved
-- Handling all functions of Manual Discharge

local settingsDirectory = g_currentModSettingsDirectory

ManualDischarge = {
	SETTINGS = {
		HARVESTERS = true,
		AUGER_WAGONS = true
	}
}

local ManualDischarge_mt = Class(ManualDischarge)

function ManualDischarge.new(mission, inputDisplayManager, contextActionDisplay)
	local self = setmetatable({}, ManualDischarge_mt)
	
	self.manualDischargeHUD = ManualDischargeHUD.new(mission, inputDisplayManager, contextActionDisplay)
	
	self.isCreated = false
	
	return self
end

function ManualDischarge:createSettingsElements()
	if not self.isCreated then
		local titleElement = TextElement.new()
		
		titleElement:applyProfile("settingsMenuSubtitle", true)
		titleElement:setText(g_i18n:getText("title_manualDischargeTitle"))
		
		local cElement = self.checkStopAndGoBraking:clone()
		local valueC, valueA = ManualDischarge:loadSettingsValueFromXMLFile()
		
		cElement.elements[4]:setText(g_i18n:getText("setting_manualCombineDischarge"))
		cElement.elements[6]:setText(g_i18n:getText("tip_manualCombineDischarge"))
		
		if valueC ~= nil then
			cElement:setIsChecked(valueC)
		else
			cElement:setIsChecked(ManualDischarge.SETTINGS.HARVESTERS)
		end
		
		cElement.onClickCallback = function(obj, state)
			ManualDischarge:setSettingsValue(0, state == CheckedOptionElement.STATE_CHECKED)
		end
		
		local aElement = cElement:clone()
		
		aElement.elements[4]:setText(g_i18n:getText("setting_manualAugerWagonDischarge"))
		aElement.elements[6]:setText(g_i18n:getText("tip_manualAugerWagonDischarge"))
		
		if valueA ~= nil then
			aElement:setIsChecked(valueC)
		else
			aElement:setIsChecked(ManualDischarge.SETTINGS.AUGER_WAGONS)
		end
		
		aElement.onClickCallback = function(obj, state)
			ManualDischarge:setSettingsValue(1, state == CheckedOptionElement.STATE_CHECKED)
		end
		
		self.boxLayout:addElement(titleElement)
		self.boxLayout:addElement(cElement)
		self.boxLayout:addElement(aElement)
		
		self.isCreated = true
	end
end

function ManualDischarge:loadSettingsValueFromXMLFile()
	local xmlFilename = settingsDirectory .. "ManualDischargeSettings.xml"
	local xmlFile = XMLFile.loadIfExists("manualDischargeXML", xmlFilename, "manualDischargeSettings")
	
	if xmlFile == nil then
		return
	end
	
	local valueC = xmlFile:getBool("manualDischargeSettings.combineHarvesters", valueC)
	local valueA = xmlFile:getBool("manualDischargeSettings.augerWagons", valueA)
	
	xmlFile:delete()
	
	return valueC, valueA
end

function ManualDischarge:saveSettingsValueToXMLFile()
	local xmlFilename = settingsDirectory .. "ManualDischargeSettings.xml"
	local xmlFile = XMLFile.create("manualDischargeXML", xmlFilename, "manualDischargeSettings")
	
	if xmlFile == nil then
		return
	end
	
	xmlFile:setBool("manualDischargeSettings.combineHarvesters", ManualDischarge.SETTINGS.HARVESTERS)
	xmlFile:setBool("manualDischargeSettings.augerWagons", ManualDischarge.SETTINGS.AUGER_WAGONS)
	xmlFile:save()
	xmlFile:delete()
	
	return true
end

function ManualDischarge:onFrameClose()
	ManualDischarge:saveSettingsValueToXMLFile()
end

function ManualDischarge:saveToXMLFile()
	ManualDischarge:saveSettingsValueToXMLFile()
end

function ManualDischarge:setSettingsValue(option, value)
	if option == nil then
		option = 0
	end
	
	if option == 0 then
		ManualDischarge.SETTINGS.HARVESTERS = value
	elseif option == 1 then
		ManualDischarge.SETTINGS.AUGER_WAGONS = value
	end
end

function ManualDischarge:getSettingsValue(harvesters, augerWagons)
	if not harvesters == augerWagons then
		if harvesters == true then
			return ManualDischarge.SETTINGS.HARVESTERS
		end
		if augerWagons == true then
			return ManualDischarge.SETTINGS.AUGER_WAGONS
		end
	end
end

function ManualDischarge:showCombineDischargeContext(fillTypeIndex)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	
	self.manualDischargeHUD:showCombineDischargeContext(fillType.title)
end

function ManualDischarge:showAugerWagonDischargeContext(fillTypeIndex)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	
	self.manualDischargeHUD:showAugerWagonDischargeContext(fillType.title)
end