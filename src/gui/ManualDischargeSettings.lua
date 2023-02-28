-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.2, 11/02/2023
-- @filename: ManualDischargeSettings.lua

-- Changelog (1.0.0.1) :
--
-- fixed incompatibility with other mods which adding settings

-- Changelog (1.0.0.2) :
--
-- cleaned code
-- merged settings code from ManualDischarge.lua

ManualDischargeSettings = {}

local ManualDischargeSettings_mt = Class(ManualDischargeSettings)

function ManualDischargeSettings.new(customMt)
	local self = setmetatable({}, customMt or ManualDischargeSettings_mt)

	self.headerName = g_i18n:getText('ui_header_manualDischarge')

	self.settings = {}
	self.nameToSetting = {}

	self.isCreated = false

	return self
end

function ManualDischargeSettings:initialize()
	self:addSetting('isHarvestersDischargeManually', g_i18n:getText('setting_manualDischargeHarvesters'), g_i18n:getText('setting_info_manualDischargeHarvesters'), true)
	self:addSetting('isPotatoHarvestersDischargeManually', g_i18n:getText('setting_manualDischargePotatoHarvesters'), g_i18n:getText('setting_info_manualDischargePotatoHarvesters'), true)
	self:addSetting('isBeetHarvestersDischargeManually', g_i18n:getText('setting_manualDischargeBeetHarvesters'), g_i18n:getText('setting_info_manualDischargeBeetHarvesters'), true)
	self:addSetting('isAugerWagonsDischargeManually', g_i18n:getText('setting_manualDischargeAugerWagons'), g_i18n:getText('setting_info_manualDischargeAugerWagons'), true)

	self:overwriteGameFunctions()
end

function ManualDischargeSettings:addSetting(name, title, description, default)
	local setting = {
		name = name,
		title = title,
		description = description
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

	self.nameToSetting[name] = setting

	self:onLoadSetting()
end

function ManualDischargeSettings:overwriteGameFunctions()
	ManualDischargeUtil.overwriteGameFunction(InGameMenuGameSettingsFrame, 'onFrameOpen', function(superFunc, frame, element)
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
	if g_savegameXML ~= nil then
		for i = 1, #self.settings do
			local setting = self.settings[i]

			setting.state = Utils.getNoNil(getXMLBool(g_savegameXML, string.format('gameSettings.manualDischarge.%s#state', setting.name)), setting.state)
		end
	end
end

function ManualDischargeSettings:onSaveSetting()
	if g_savegameXML ~= nil then
		for i = 1, #self.settings do
			local setting = self.settings[i]

			setXMLBool(g_savegameXML, string.format('gameSettings.manualDischarge.%s#state', setting.name), setting.state)
		end
	end

	g_gameSettings:saveToXMLFile(g_savegameXML)
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
	g_manualDischarge:setManualDischargeableSettingState(setting.name, setting.state)

	Logging.info("Manual Discharge Setting '%s': %s", setting.name, setting.state)

	self:onSaveSetting()
end