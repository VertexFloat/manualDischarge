-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.3, 09|05|2023
-- @filename: ManualDischarge.lua

-- Changelog (1.0.0.1):
-- completly new, better and cleaner code
-- merged functionality with 'main' file

-- Changelog (1.0.0.2):
-- cleaned and improved code
-- moved settings code to ManualDischargeSettings.lua

-- Changelog (1.0.0.3):
-- cleaned and improved code
-- merged functionality with ManualDischargeHUD.lua

local modDirectory = g_currentModDirectory
local hudElements = Utils.getFilename('data/menu/hud/hud_elements.png', modDirectory)

source(modDirectory .. 'src/misc/AdditionalSpecialization.lua')
source(modDirectory .. 'src/misc/AdditionalConfiguration.lua')

FSBaseMission.showPipeDischargeContext = function (self, fillTypeIndex)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

	self.hud:showPipeDischargeContext(fillType.title)
end

HUD.showPipeDischargeContext = function (self, fillTypeName)
	self.contextActionDisplay:setContext(InputAction.TOGGLE_MANUAL_DISCHARGE_PIPE, ContextActionDisplay.CONTEXT_ICON.PIPE_DISCHARGE, fillTypeName, HUD.CONTEXT_PRIORITY.MEDIUM)
end

local function createActionIcons(self, superFunc, hudAtlasPath, baseX, baseY)
	local posX, posY = getNormalizedScreenValues(unpack(ContextActionDisplay.POSITION.CONTEXT_ICON))
	local width, height = getNormalizedScreenValues(unpack(ContextActionDisplay.SIZE.CONTEXT_ICON))
	local centerY = baseY + (self:getHeight() - height) * 0.5 + posY

	for _, iconName in pairs(ContextActionDisplay.CONTEXT_ICON) do
		local iconOverlay = Overlay.new(iconName == 'pipeDischarge' and hudElements or hudAtlasPath, baseX + posX, centerY, width, height)
		local uvs = ContextActionDisplay.UV[iconName]

		iconOverlay:setUVs(GuiUtils.getUVs(uvs))
		iconOverlay:setColor(unpack(ContextActionDisplay.COLOR.CONTEXT_ICON))

		local iconElement = HUDElement.new(iconOverlay)

		iconElement:setVisible(false)

		self.contextIconElements[iconName] = iconElement

		self:addChild(iconElement)
	end
end

local function setContext(self, superFunc, contextAction, contextIconName, targetText, priority, actionText)
	if priority == nil then
		priority = 0
	end

	self:resetContext()

	if priority >= self.contextPriority and self.contextIconElements[contextIconName] ~= nil then
		self.contextAction = contextAction
		self.contextIconName = contextIconName
		self.targetText = targetText
		self.contextPriority = priority

		local eventHelpElement = self.inputDisplayManager:getEventHelpElementForAction(self.contextAction)

		self.contextEventHelpElement = eventHelpElement

		if eventHelpElement ~= nil then
			self.inputGlyphElement:setAction(contextAction)
			self.actionText = utf8ToUpper(actionText or eventHelpElement.textRight or eventHelpElement.textLeft)

			local targetTextWidth = getTextWidth(self.targetTextSize, self.targetText)

			self.rightSideX = 0.5 - targetTextWidth * 0.5

			local contextIconWidth = 0
			local posX = self.rightSideX + self.contextIconOffsetX

			for name, element in pairs(self.contextIconElements) do
				element:setPosition(posX - element:getWidth(), nil)

				if name == self.contextIconName then
					contextIconWidth = element:getWidth()
				end
			end

			posX = posX - contextIconWidth + self.inputIconOffsetX - contextIconWidth

			self.inputGlyphElement:setPosition(posX, nil)
		end

		if not self:getVisible() then
			self:setVisible(true, true)
		end
	end

	for name, element in pairs(self.contextIconElements) do
		element:setVisible(name == self.contextIconName)
	end

	self.displayTime = ContextActionDisplay.MIN_DISPLAY_DURATION
end

local function validateTypes(self)
	if self.typeName == 'vehicle' then
		ContextActionDisplay.createActionIcons = Utils.overwrittenFunction(ContextActionDisplay.createActionIcons, createActionIcons)
		ContextActionDisplay.setContext = Utils.overwrittenFunction(ContextActionDisplay.setContext, setContext)
	end
end

TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, validateTypes)

ContextActionDisplay.CONTEXT_ICON.PIPE_DISCHARGE = 'pipeDischarge'
ContextActionDisplay.UV[ContextActionDisplay.CONTEXT_ICON.PIPE_DISCHARGE] = {
	0,
	0,
	48,
	48
}