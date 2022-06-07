-- Author: VertexFloat
-- Date: 05.04.2022
-- Version: Farming Simulator 22, 1.0.0.0
-- Copyright (C): VertexFloat, All Rights Reserved
-- Main function for loading Manual Discharge

local modDirectory = g_currentModDirectory
local settingsDirectory = g_currentModSettingsDirectory

source(modDirectory .. "src/ManualDischarge.lua")
source(modDirectory .. "src/gui/hud/ManualDischargeHUD.lua")
source(modDirectory .. "src/gui/hud/ContextActionsDisplay.lua")
source(modDirectory .. "src/vehicles/specializations/ManualCombineDischarge.lua")
source(modDirectory .. "src/vehicles/specializations/ManualAugerWagonDischarge.lua")

local manualDischarge

function load(mission)
	manualDischarge = ManualDischarge.new(mission, g_inputDisplayManager, mission.inGameMenu.hud.contextActionDisplay)
	
	mission.manualDischarge = manualDischarge
	
	createFolder(settingsDirectory)
	
	local valueC, valueA = 	ManualDischarge:loadSettingsValueFromXMLFile()
	
	if valueC ~= nil and valueA ~= nil then
		ManualDischarge:setSettingsValue(0, valueC)
		ManualDischarge:setSettingsValue(1, valueA)
	end
	
	addModEventListener(manualDischarge)
end

function installSpecialization()
	for vehicleName, vehicleType in pairs(g_vehicleTypeManager.types) do
		if vehicleName == "augerWagon" then
			if SpecializationUtil.hasSpecialization(Trailer, vehicleType.specializations) and SpecializationUtil.hasSpecialization(Pipe, vehicleType.specializations) then
				g_vehicleTypeManager:addSpecialization(vehicleName, "manualAugerWagonDischarge")
			end
		end
		if SpecializationUtil.hasSpecialization(Combine, vehicleType.specializations) and SpecializationUtil.hasSpecialization(Pipe, vehicleType.specializations) then
			g_vehicleTypeManager:addSpecialization(vehicleName, "manualCombineDischarge")
		end
	end
end

function delete()
	removeModEventListener(manualDischarge)
	
	manualDischarge = nil
	
	if g_currentMission ~= nil then
		g_currentMission.manualDischarge = nil
	end
end

function init()
	g_specializationManager:addSpecialization("manualCombineDischarge", "ManualCombineDischarge", Utils.getFilename("src/vehicles/specializations/ManualCombineDischarge.lua", modDirectory), true, nil)
	g_specializationManager:addSpecialization("manualAugerWagonDischarge", "ManualAugerWagonDischarge", Utils.getFilename("src/vehicles/specializations/ManualAugerWagonDischarge.lua", modDirectory), true, nil)
	
	installSpecialization()
	
	Mission00.load = Utils.prependedFunction(Mission00.load, load)
	
	FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, delete)
	
	InGameMenuGameSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGameSettingsFrame.onFrameOpen, ManualDischarge.createSettingsElements)
	InGameMenuGameSettingsFrame.onFrameClose = Utils.appendedFunction(InGameMenuGameSettingsFrame.onFrameClose, ManualDischarge.onFrameClose)
	
	FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, ManualDischarge.saveToXMLFile)
	
	HUD.createDisplayComponents = Utils.overwrittenFunction(HUD.createDisplayComponents, ManualDischargeHUD.createDisplayComponents)
	HUD.showAttachContext = Utils.overwrittenFunction(HUD.showAttachContext, ManualDischargeHUD.showAttachContext)
end

init()