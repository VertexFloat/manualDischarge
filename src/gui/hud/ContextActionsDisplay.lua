-- Author: VertexFloat
-- Date: 27.03.2022
-- Version: Farming Simulator 22, 1.0.0.0
-- Copyright (C): VertexFloat, GIANTS Software, All Rights Reserved
-- Improved ContextActionDisplay and adjusted to Manual Discharge

-- *Fixed changing context actions (base bug)
-- *Fixed input icon positioning (base bug)

ContextActionsDisplay = {}
local ContextActionsDisplay_mt = Class(ContextActionsDisplay, HUDDisplayElement)

ContextActionsDisplay.CONTEXT_ICON = {
	FUEL = "fuel",
	ATTACH = "attach",
	NO_DETACH = "noDetach",
	TIP = "tip",
	FILL_BOWL = "fillBowl",
	DISCHARGE_COMBINE = "dischargeCombine",
	DISCHARGE_AUGER_WAGON = "dischargeAugerWagon"
}

ContextActionsDisplay.MIN_DISPLAY_DURATION = 100

function ContextActionsDisplay.new(hudAtlasPath, inputDisplayManager)
	local backgroundOverlay = ContextActionsDisplay.createBackground()
	local self = ContextActionsDisplay:superClass().new(backgroundOverlay, nil, ContextActionsDisplay_mt)
	
	self.uiScale = 1
	self.inputDisplayManager = inputDisplayManager
	self.inputGlyphElement = nil
	self.contextIconElements = {}
	self.contextAction = ""
	self.contextIconName = ""
	self.targetText = ""
	self.actionText = ""
	self.contextPriority = -math.huge
	self.contextIconElementRightX = 0
	self.contextIconOffsetY = 0
	self.contextIconOffsetX = 0
	self.contextIconSizeX = 0
	self.actionTextOffsetY = 0
	self.actionTextOffsetX = 0
	self.actionTextSize = 0
	self.targetTextOffsetY = 0
	self.targetTextOffsetX = 0
	self.targetTextSize = 0
	self.borderOffsetX = 0
	self.displayTime = 0
	
	self:createComponents(hudAtlasPath, inputDisplayManager)
	
	return self
end

function ContextActionsDisplay:setContext(contextAction, contextIconName, targetText, priority, actionText)
	if priority == nil then
		priority = 0
	end
	
	-- Quick solution that can be solved better. To be redone in free time. --
	
	local highestPriority = math.max(self.contextPriority, priority)
	
	if highestPriority > priority then
		self.contextPriority = priority
	end
	
	if self.contextPriority <= priority and self.contextIconElements[contextIconName] ~= nil then
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
	
	self.displayTime = ContextActionsDisplay.MIN_DISPLAY_DURATION
end

function ContextActionsDisplay:update(dt)
	ContextActionsDisplay:superClass().update(self, dt)
	
	self.displayTime = self.displayTime - dt
	local isVisible = self:getVisible()
	
	if self.displayTime <= 0 and isVisible and self.animation:getFinished() then
		self:setVisible(false, true)
	end
	
	if not self.animation:getFinished() then
		self:storeScaledValues()
	elseif self.contextAction ~= "" and not isVisible then
		self:resetContext()
	end
end

function ContextActionsDisplay:resetContext()
	self.contextAction = ""
	self.contextIconName = ""
	self.targetText = ""
	self.actionText = ""
	self.contextPriority = -math.huge
end

function ContextActionsDisplay:draw()
	if self.contextAction ~= "" and self.contextEventHelpElement ~= nil then
		self.inputGlyphElement:setAction(self.contextAction)
		ContextActionsDisplay:superClass().draw(self)
		local _, baseY = self:getPosition()
		
		setTextColor(unpack(ContextActionsDisplay.COLOR.ACTION_TEXT))
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_LEFT)
		local height = self:getHeight()
		local posX = self.rightSideX
		local posY = baseY + height * 0.5 + self.targetTextSize * 0.5 + self.actionTextOffsetY
		
		renderText(posX, posY, self.actionTextSize, self.actionText)
		posY = baseY + height * 0.5
		setTextColor(unpack(ContextActionsDisplay.COLOR.TARGET_TEXT))
		setTextBold(false)
		local width = self:getWidth()
		local textWrapWidth = width - self.targetTextOffsetX - self.contextIconSizeX - self.inputGlyphElement:getWidth() * 2 - self.contextIconOffsetX
		
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(0.5, posY, self.targetTextSize, self.targetText)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
		
		if g_uiDebugEnabled then
			local yPixel = 1 / g_screenHeight
			
			setOverlayColor(GuiElement.debugOverlay, 0, 1, 1, 1)
			renderOverlay(GuiElement.debugOverlay, posX, posY, textWrapWidth, yPixel)
		end
	end
end

function ContextActionsDisplay:getWidth()
	return 1
end

function ContextActionsDisplay:setScale(uiScale)
	ContextActionsDisplay:superClass().setScale(self, uiScale, uiScale)
	
	local currentVisibility = self:getVisible()
	
	self:setVisible(true, false)
	self.uiScale = uiScale
	local posX, posY = ContextActionsDisplay.getBackgroundPosition(uiScale, self:getWidth())
	
	self:setPosition(posX, posY)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
	self:storeScaledValues()
	self.fadeBackgroundElement:setDimension(1)
	self.fadeBackgroundElement:setPosition(0, 0)
end

function ContextActionsDisplay:storeScaledValues()
	self.contextIconOffsetX, self.contextIconOffsetY = self:scalePixelToScreenVector(ContextActionsDisplay.POSITION.CONTEXT_ICON)
	self.contextIconSizeX = self:scalePixelToScreenWidth(ContextActionsDisplay.SIZE.CONTEXT_ICON[1])
	self.borderOffsetX = self:scalePixelToScreenWidth(ContextActionsDisplay.OFFSET.X)
	self.inputIconOffsetX, self.inputIconOffsetX = self:scalePixelToScreenVector(ContextActionsDisplay.POSITION.INPUT_ICON)
	self.actionTextOffsetX, self.actionTextOffsetY = self:scalePixelToScreenVector(ContextActionsDisplay.POSITION.ACTION_TEXT)
	self.actionTextSize = self:scalePixelToScreenHeight(ContextActionsDisplay.TEXT_SIZE.ACTION_TEXT)
	self.targetTextOffsetX, self.targetTextOffsetY = self:scalePixelToScreenVector(ContextActionsDisplay.POSITION.TARGET_TEXT)
	self.targetTextSize = self:scalePixelToScreenHeight(ContextActionsDisplay.TEXT_SIZE.TARGET_TEXT)
end

function ContextActionsDisplay.getBackgroundPosition(scale, width)
	local offX, offY = getNormalizedScreenValues(unpack(ContextActionsDisplay.POSITION.BACKGROUND))
	
	return 0.5 - width * 0.5 - offX * scale, g_safeFrameOffsetY - offY * scale
end

function ContextActionsDisplay.createBackground()
	local width, height = getNormalizedScreenValues(unpack(ContextActionsDisplay.SIZE.BACKGROUND))
	local posX, posY = ContextActionsDisplay.getBackgroundPosition(1, width)
	local overlay = Overlay.new(nil, posX, posY, width, height)
	
	return overlay
end

function ContextActionsDisplay:createComponents(hudAtlasPath, inputDisplayManager)
	local baseX, baseY = self:getPosition()
	
	self:createFrame(hudAtlasPath, baseX, baseY)
	self:createInputGlyph(hudAtlasPath, baseX, baseY, inputDisplayManager)
	self:createActionIcons(hudAtlasPath, baseX, baseY)
	self:createFadeBackground(hudAtlasPath)
	self:storeOriginalPosition()
end

function ContextActionsDisplay:createInputGlyph(hudAtlasPath, baseX, baseY, inputDisplayManager)
	local width, height = getNormalizedScreenValues(unpack(ContextActionsDisplay.SIZE.INPUT_ICON))
	local offX, offY = getNormalizedScreenValues(unpack(ContextActionsDisplay.POSITION.INPUT_ICON))
	local element = InputGlyphElement.new(inputDisplayManager, width, height)
	local posX = baseX + offX
	local posY = baseY + offY + (self:getHeight() - height) * 0.5
	
	element:setPosition(posX, posY)
	element:setKeyboardGlyphColor(ContextActionsDisplay.COLOR.INPUT_ICON)
	self.inputGlyphElement = element
	self:addChild(element)
end

function ContextActionsDisplay:createFrame(hudAtlasPath, baseX, baseY)
end

function ContextActionsDisplay:createActionIcons(hudAtlasPath, baseX, baseY)
	local posX, posY = getNormalizedScreenValues(unpack(ContextActionsDisplay.POSITION.CONTEXT_ICON))
	local width, height = getNormalizedScreenValues(unpack(ContextActionsDisplay.SIZE.CONTEXT_ICON))
	local centerY = baseY + (self:getHeight() - height) * 0.5 + posY
	
	for _, iconName in pairs(ContextActionsDisplay.CONTEXT_ICON) do
		local iconOverlay = Overlay.new(hudAtlasPath, baseX + posX, centerY, width, height)
		local uvs = ContextActionsDisplay.UV[iconName]
		
		iconOverlay:setUVs(GuiUtils.getUVs(uvs))
		iconOverlay:setColor(unpack(ContextActionsDisplay.COLOR.CONTEXT_ICON))
		local iconElement = HUDElement.new(iconOverlay)
		
		iconElement:setVisible(false)
		self.contextIconElements[iconName] = iconElement
		self:addChild(iconElement)
	end
end

function ContextActionsDisplay:createFadeBackground(hudAtlasPath)
	local _, height = getNormalizedScreenValues(unpack(ContextActionsDisplay.SIZE.FADE))
	local overlay = Overlay.new(g_baseUIFilename, 0, 0, 1, height)
	
	overlay:setUVs(g_colorBgUVs)
	overlay:setColor(1, 0, 0, 1)
	setOverlayCornerColor(overlay.overlayId, 0, 0, 0, 0, 0.8)
	setOverlayCornerColor(overlay.overlayId, 1, 0, 0, 0, 0)
	setOverlayCornerColor(overlay.overlayId, 2, 0, 0, 0, 0.8)
	setOverlayCornerColor(overlay.overlayId, 3, 0, 0, 0, 0)
	local element = HUDElement.new(overlay)
	
	element:setVisible(true)
	self:addChild(element)
	self.fadeBackgroundElement = element
end

function ContextActionsDisplay:getHidingTranslation()
	local _, height = getNormalizedScreenValues(unpack(ContextActionsDisplay.SIZE.FADE))
	
	return 0, -height
end

ContextActionsDisplay.UV = {
	[ContextActionDisplay.CONTEXT_ICON.ATTACH] = {
		48,
		0,
		48,
		48
	},
	[ContextActionDisplay.CONTEXT_ICON.FUEL] = {
		192,
		0,
		48,
		48
	},
	[ContextActionDisplay.CONTEXT_ICON.TIP] = {
		0,
		0,
		48,
		48
	},
	[ContextActionDisplay.CONTEXT_ICON.NO_DETACH] = {
		96,
		0,
		48,
		48
	},
	[ContextActionDisplay.CONTEXT_ICON.FILL_BOWL] = {
		144,
		0,
		48,
		48
	},
	[ContextActionsDisplay.CONTEXT_ICON.DISCHARGE_COMBINE] = {
		240,
		0,
		48,
		48
	},
	[ContextActionsDisplay.CONTEXT_ICON.DISCHARGE_AUGER_WAGON] = {
		288,
		0,
		48,
		48
	}
}

ContextActionsDisplay.SIZE = {
	BACKGROUND = {
		1920,
		60
	},
	INPUT_ICON = {
		36,
		36
	},
	CONTEXT_ICON = {
		64,
		64
	},
	FADE = {
		0,
		180
	}
}

ContextActionsDisplay.OFFSET = {
	X = 37.5
}

ContextActionsDisplay.TEXT_SIZE = {
	TARGET_TEXT = 26,
	ACTION_TEXT = 14
}

ContextActionsDisplay.POSITION = {
	BACKGROUND = {
		0,
		-20
	},
	INPUT_ICON = {
		0,
		3
	},
	CONTEXT_ICON = {
		-6,
		3
	},
	ACTION_TEXT = {
		0,
		-2
	},
	TARGET_TEXT = {
		30,
		0
	}
}

ContextActionsDisplay.COLOR = {
	INPUT_ICON = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	CONTEXT_ICON = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	ACTION_TEXT = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	TARGET_TEXT = {
		1,
		1,
		1,
		1
	}
}