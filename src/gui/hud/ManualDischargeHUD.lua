-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.1, 12/07/2022
-- @filename: ManualDischargeHUD.lua

-- fixed changing context actions (game base bug)
-- fixed input icon positioning (game base bug)

-- Changelog (1.0.0.1) :
--
-- completly new, better and cleaner code
-- merged functionality with 'ContextActionsDisplay' file
-- completly new method to add context action for manual discharge

ManualDischargeHUD = {
	HUD_ATLAS_PATH = Utils.getFilename('src/resources/hud/hud_elements.png', g_currentModDirectory)
}

ManualDischargeHUD.CONTEXT_ICON = {
	FUEL = 'fuel',
	ATTACH = 'attach',
	NO_DETACH = 'noDetach',
	TIP = 'tip',
	FILL_BOWL = 'fillBowl',
	PIPE_DISCHARGE = 'pipeDischarge'
}

function ManualDischargeHUD:setContext(contextAction, contextIconName, targetText, priority, actionText)
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

function ManualDischargeHUD:createActionIcons(hudAtlasPath, baseX, baseY)
	local posX, posY = getNormalizedScreenValues(unpack(ContextActionDisplay.POSITION.CONTEXT_ICON))
	local width, height = getNormalizedScreenValues(unpack(ContextActionDisplay.SIZE.CONTEXT_ICON))
	local centerY = baseY + (self:getHeight() - height) * 0.5 + posY

	for _, iconName in pairs(ContextActionDisplay.CONTEXT_ICON) do
		local iconOverlay = Overlay.new(ManualDischargeHUD.HUD_ATLAS_PATH, baseX + posX, centerY, width, height)
		local uvs = ContextActionDisplay.UV[iconName]

		iconOverlay:setUVs(GuiUtils.getUVs(uvs))
		iconOverlay:setColor(unpack(ContextActionDisplay.COLOR.CONTEXT_ICON))

		local iconElement = HUDElement.new(iconOverlay)

		iconElement:setVisible(false)

		self.contextIconElements[iconName] = iconElement

		self:addChild(iconElement)
	end
end

ManualDischargeHUD.UV = {
	[ManualDischargeHUD.CONTEXT_ICON.ATTACH] = {
		48,
		0,
		48,
		48
	},
	[ManualDischargeHUD.CONTEXT_ICON.FUEL] = {
		192,
		0,
		48,
		48
	},
	[ManualDischargeHUD.CONTEXT_ICON.TIP] = {
		0,
		0,
		48,
		48
	},
	[ManualDischargeHUD.CONTEXT_ICON.NO_DETACH] = {
		96,
		0,
		48,
		48
	},
	[ManualDischargeHUD.CONTEXT_ICON.FILL_BOWL] = {
		144,
		0,
		48,
		48
	},
	[ManualDischargeHUD.CONTEXT_ICON.PIPE_DISCHARGE] = {
		240,
		0,
		48,
		48
	}
}