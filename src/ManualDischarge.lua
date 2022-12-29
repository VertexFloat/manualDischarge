-- Author: VertexFloat
-- Date: 18.07.2022
-- Version: Farming Simulator 22, 1.0.0.1
-- Copyright (C): VertexFloat, All Rights Reserved
-- Handling all functions of Manual Discharge

-- Changelog (1.0.0.1) :
--
-- completly new, better and cleaner code
-- merged functionality with 'main' file

ManualDischarge = {
    MOD_NAME = g_currentModName,
    MOD_DIRECTORY = g_currentModDirectory,
    MOD_SETTINGS_DIRECTORY = g_modSettingsDirectory
}

source(ManualDischarge.MOD_DIRECTORY .. "src/vehicles/specializations/events/SetManualPipeDischargeStateEvent.lua")
source(ManualDischarge.MOD_DIRECTORY .. "src/events/ManualDischargeSettingsEvent.lua")
source(ManualDischarge.MOD_DIRECTORY .. "src/misc/AdditionalSpecialization.lua")
source(ManualDischarge.MOD_DIRECTORY .. "src/gui/ManualDischargeSettings.lua")
source(ManualDischarge.MOD_DIRECTORY .. "src/gui/hud/ManualDischargeHUD.lua")
source(ManualDischarge.MOD_DIRECTORY .. "src/utils/ManualDischargeUtil.lua")

local ManualDischarge_mt = Class(ManualDischarge)

function ManualDischarge.new(customMt)
    local self = setmetatable({}, customMt or ManualDischarge_mt)

    self.isHarvestersDischargeManually = false
    self.isPotatoHarvestersDischargeManually = false
    self.isBeetHarvestersDischargeManually = false
    self.isAugerWagonsDischargeManually = false

    self.manualDischargeSettings = ManualDischargeSettings.new()

    return self
end

function ManualDischarge:initialize()
    ManualDischargeUtil.deleteOldModFiles(ManualDischarge.MOD_NAME, ManualDischarge.MOD_SETTINGS_DIRECTORY)
    ManualDischargeUtil.overwriteEnvTableElement("ContextActionDisplay", ManualDischargeHUD)

    self.manualDischargeSettings:addSetting("isHarvestersDischargeManually", g_i18n:getText("setting_manualDischargeHarvesters"), g_i18n:getText("setting_info_manualDischargeHarvesters"), self.manualDischargeSettings.onClickIsHarvestersDischargeManually, self, true)
    self.manualDischargeSettings:addSetting("isPotatoHarvestersDischargeManually", g_i18n:getText("setting_manualDischargePotatoHarvesters"), g_i18n:getText("setting_info_manualDischargePotatoHarvesters"), self.manualDischargeSettings.onClickIsPotatoHarvestersDischargeManually, self, true)
    self.manualDischargeSettings:addSetting("isBeetHarvestersDischargeManually", g_i18n:getText("setting_manualDischargeBeetHarvesters"), g_i18n:getText("setting_info_manualDischargeBeetHarvesters"), self.manualDischargeSettings.onClickIsBeetHarvestersDischargeManually, self, true)
    self.manualDischargeSettings:addSetting("isAugerWagonsDischargeManually", g_i18n:getText("setting_manualDischargeAugerWagons"), g_i18n:getText("setting_info_manualDischargeAugerWagons"), self.manualDischargeSettings.onClickIsAugerWagonsDischargeManually, self, true)
    self.manualDischargeSettings:overwriteGameFunctions()
end

function ManualDischarge:loadMap(filename)
    self.manualDischargeSettings:initializeSettingsStates()
end

function ManualDischarge:setIsHarvestersDischargeManually(isManually, noEventSend)
    if self.isHarvestersDischargeManually ~= isManually then
        self.isHarvestersDischargeManually = isManually

        ManualDischargeSettingsEvent.sendEvent(noEventSend)

        Logging.info("Manual Discharge Settings 'isHarvestersDischargeManually': %s", isManually)
    end
end

function ManualDischarge:setIsAugerWagonsDischargeManually(isManually, noEventSend)
    if self.isAugerWagonsDischargeManually ~= isManually then
        self.isAugerWagonsDischargeManually = isManually

        ManualDischargeSettingsEvent.sendEvent(noEventSend)

        Logging.info("Manual Discharge Settings 'isAugerWagonsDischargeManually': %s", isManually)
    end
end

function ManualDischarge:setIsPotatoHarvestersDischargeManually(isManually, noEventSend)
    if self.isPotatoHarvestersDischargeManually ~= isManually then
        self.isPotatoHarvestersDischargeManually = isManually

        ManualDischargeSettingsEvent.sendEvent(noEventSend)

        Logging.info("Manual Discharge Settings 'isPotatoHarvestersDischargeManually': %s", isManually)
    end
end

function ManualDischarge:setIsBeetHarvestersDischargeManually(isManually, noEventSend)
    if self.isBeetHarvestersDischargeManually ~= isManually then
        self.isBeetHarvestersDischargeManually = isManually

        ManualDischargeSettingsEvent.sendEvent(noEventSend)

        Logging.info("Manual Discharge Settings 'isBeetHarvestersDischargeManually': %s", isManually)
    end
end

function ManualDischarge:showPipeDischargeContext(fillTypeIndex)
    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

    g_currentMission.hud.contextActionDisplay:setContext(InputAction.TOGGLE_MANUAL_DISCHARGE_PIPE, ContextActionDisplay.CONTEXT_ICON.PIPE_DISCHARGE, fillType.title, HUD.CONTEXT_PRIORITY.MEDIUM)
end

function ManualDischarge:onStartMission()
    Logging.info("Manual Discharge Settings 'isHarvestersDischargeManually': %s", g_manualDischarge.isHarvestersDischargeManually)
    Logging.info("Manual Discharge Settings 'isAugerWagonsDischargeManually': %s", g_manualDischarge.isAugerWagonsDischargeManually)
    Logging.info("Manual Discharge Settings 'isPotatoHarvestersDischargeManually': %s", g_manualDischarge.isPotatoHarvestersDischargeManually)
    Logging.info("Manual Discharge Settings 'isBeetHarvestersDischargeManually': %s", g_manualDischarge.isBeetHarvestersDischargeManually)
end

FSBaseMission.onStartMission = Utils.appendedFunction(FSBaseMission.onStartMission, ManualDischarge.onStartMission)

function ManualDischarge:onConnectionFinishedLoading(connection)
    connection:sendEvent(ManualDischargeSettingsEvent.new())
end 

FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction(FSBaseMission.onConnectionFinishedLoading, ManualDischarge.onConnectionFinishedLoading)

g_manualDischarge = ManualDischarge.new()

addModEventListener(g_manualDischarge)

local function validateTypes(self)
    if self.typeName == "vehicle" and g_modIsLoaded[ManualDischarge.MOD_NAME] then
        g_manualDischarge:initialize()
    end
end

TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, validateTypes)