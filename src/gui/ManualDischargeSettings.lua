-- Author: VertexFloat
-- Date: 06.08.2022
-- Version: Farming Simulator 22, 1.0.0.1
-- Copyright (C): VertexFloat, All Rights Reserved
-- Handling Manual Discharge Settings

-- Changelog (1.0.0.1) :
--
-- fixed incompatibility with other mods which adding settings

ManualDischargeSettings = {
    SETTINGS_XML_FILE = g_modSettingsDirectory .. "ManualDischarge.xml"
}

local ManualDischargeSettings_mt = Class(ManualDischargeSettings)

function ManualDischargeSettings.new(customMt)
    local self = setmetatable({}, customMt or ManualDischargeSettings_mt)

    self.headerName = g_i18n:getText("ui_header_manualDischarge")
    self.isCreated = false
    self.settings = {}

    return self
end

function ManualDischargeSettings:addSetting(name, title, description, callback, callbackTarget, default)
    local setting = {
        name = name,
        title = title,
        description = description,
        callback = callback,
        callbackTarget = callbackTarget,
        default = default
    }

    setting.element = nil

    if default ~= nil then
        setting.state = default
    else
        setting.state = false
    end

    table.insert(self.settings, setting)

    for i = 1, #self.settings do
        self.settings[i].id = i
    end

    self:onLoadSetting()
end

function ManualDischargeSettings:overwriteGameFunctions()
    ManualDischargeUtil.overwriteGameFunction(InGameMenuGameSettingsFrame, "onFrameOpen", function(superFunc, frame, element)
        superFunc(frame, element)

        if not self.isCreated then
            for i = 1, #frame.boxLayout.elements do
                local elem = frame.boxLayout.elements[i]

                if elem:isa(TextElement) then
                    local header = elem:clone(frame.boxLayout)

                    header:setText(self.headerName)

                    break
                end
            end

            if self.settings ~= nil then
                for i = 1, #self.settings do
                    local setting = self.settings[i]

                    setting.element = frame.checkStopAndGoBraking:clone(frame.boxLayout)

                    function setting.element.onClickCallback(_, ...)
                        self:onClickCheckbox(..., setting.id)
                    end

                    setting.element:setIsChecked(setting.state)

                    setting.element.elements[4]:setText(setting.title)
                    setting.element.elements[6]:setText(setting.description)
                end
            end

            frame.boxLayout:invalidateLayout()

            self.isCreated = true
        end
    end)
end

function ManualDischargeSettings:onLoadSetting()
    local xmlFile = XMLFile.loadIfExists("manualDischargeSettingsXML", ManualDischargeSettings.SETTINGS_XML_FILE, "gameSettings")

    if xmlFile ~= nil then
        for i = 1, #self.settings do
            local setting = self.settings[i]

            setting.state = xmlFile:getBool(string.format("gameSettings.manualDischarge.%s#state", setting.name), setting.state)
        end

        xmlFile:delete()
    end
end

function ManualDischargeSettings:onSaveSetting()
    local xmlFile = XMLFile.create("manualDischargeSettingsXML", ManualDischargeSettings.SETTINGS_XML_FILE, "gameSettings")

    if xmlFile ~= nil then
        for i = 1, #self.settings do
            local setting = self.settings[i]

            xmlFile:setBool(string.format("gameSettings.manualDischarge.%s#state", setting.name), setting.state)
        end

        xmlFile:save()
        xmlFile:delete()
    end
end

function ManualDischargeSettings:onClickCheckbox(state, id)
    for i = 1, #self.settings do
        local setting = self.settings[i]

        if setting.id == id then
            setting.state = state == CheckedOptionElement.STATE_CHECKED

            self:onSettingChanged(setting)
        end
    end
end

function ManualDischargeSettings:onSettingChanged(setting)
    if setting.callback ~= nil and setting.callbackTarget == nil then
        setting.callback(setting.state)
    elseif setting.callback ~= nil and setting.callbackTarget ~= nil then
        setting.callback(setting.callbackTarget, setting.state)
    end

    self:onSaveSetting()
end

function ManualDischargeSettings:initializeSettingsStates()
    for i = 1, #self.settings do
        local setting = self.settings[i]

        if setting.name == "isHarvestersDischargeManually" then
            g_manualDischarge.isHarvestersDischargeManually = setting.state
        end

        if setting.name == "isPotatoHarvestersDischargeManually" then
            g_manualDischarge.isPotatoHarvestersDischargeManually = setting.state
        end

        if setting.name == "isBeetHarvestersDischargeManually" then
            g_manualDischarge.isBeetHarvestersDischargeManually = setting.state
        end

        if setting.name == "isAugerWagonsDischargeManually" then
            g_manualDischarge.isAugerWagonsDischargeManually = setting.state
        end
    end

    if fileExists(ManualDischargeSettings.SETTINGS_XML_FILE) then
        Logging.info("Manual Discharge Settings 'Loaded settings from: %s'", ManualDischargeSettings.SETTINGS_XML_FILE)
    else
        Logging.info("Manual Discharge Settings 'Could not find saved settings ! Creating settings file: (%s) with default values'", ManualDischargeSettings.SETTINGS_XML_FILE)

        self:onSaveSetting()
    end
end

function ManualDischargeSettings:onClickIsHarvestersDischargeManually(state)
    g_manualDischarge:setIsHarvestersDischargeManually(state)
end

function ManualDischargeSettings:onClickIsPotatoHarvestersDischargeManually(state)
    g_manualDischarge:setIsPotatoHarvestersDischargeManually(state)
end

function ManualDischargeSettings:onClickIsBeetHarvestersDischargeManually(state)
    g_manualDischarge:setIsBeetHarvestersDischargeManually(state)
end

function ManualDischargeSettings:onClickIsAugerWagonsDischargeManually(state)
    g_manualDischarge:setIsAugerWagonsDischargeManually(state)
end