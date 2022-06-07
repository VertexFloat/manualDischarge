-- Author: VertexFloat
-- Date: 05.04.2022
-- Version: Farming Simulator 22, 1.0.0.0
-- Copyright (C): VertexFloat, All Rights Reserved
-- Handling new ContextActionDisplay adjusted to Manual Discharge

local modDirectory = g_currentModDirectory

ManualDischargeHUD = {}

local ManualDischargeHUD_mt = Class(ManualDischargeHUD)

ManualDischargeHUD.CONTEXT_PRIORITY = {
	HIGH = 3,
	LOW = 1,
	MEDIUM = 2
}

function ManualDischargeHUD.new(mission, inputDisplayManager, contextActionDisplay)
	local self = setmetatable({}, ManualDischargeHUD_mt)
	
	self.mission = mission
	self.isClient = mission:getIsClient()
	self.contextActionDisplay = contextActionDisplay
	
	return self
end

function ManualDischargeHUD:update(dt)
	if not self.isClient then
		return
	end
end

function ManualDischargeHUD:createDisplayComponents(superFunc, uiScale)
	self.ingameMap = IngameMap.new(self, g_baseHUDFilename, self.inputDisplayManager)
	
	self.ingameMap:setScale(uiScale)
	table.insert(self.displayComponents, self.ingameMap)
	
	if g_isPresentationVersion and g_isPresentationVersionLogoEnabled then
		self.ingameMap:setIsVisible(false)
		
		local width, height = getNormalizedScreenValues(600, 150)
		local overlay = Overlay.new("dataS/menu/presentationVersionLogo.png", g_safeFrameOffsetX, g_safeFrameOffsetY, width, height)
		
		self.presentationVersionElement = HUDElement.new(overlay)
		
		table.insert(self.displayComponents, self.presentationVersionElement)
	end
	
	self.gamePausedDisplay = GamePausedDisplay.new(g_baseHUDFilename)
	
	self.gamePausedDisplay:setScale(uiScale)
	self.gamePausedDisplay:setVisible(false)
	table.insert(self.displayComponents, self.gamePausedDisplay)
	
	self.menuBackgroundOverlay = Overlay.new(HUD.MENU_BACKGROUND_PATH, 0.5, 0, 1, g_screenWidth / g_screenHeight)
	
	self.menuBackgroundOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_CENTER)
	
	self.vehicleNameDisplay = HUDTextDisplay.new(0.5, g_safeFrameOffsetY, HUD.TEXT_SIZE.VEHICLE_NAME, RenderText.ALIGN_CENTER, HUD.COLOR.VEHICLE_NAME, true)
	
	self.vehicleNameDisplay:setTextShadow(true, HUD.COLOR.VEHICLE_NAME_SHADOW)
	
	local nameFadeTween = TweenSequence.new(self.vehicleNameDisplay)
	
	nameFadeTween:addTween(Tween.new(self.vehicleNameDisplay.setAlpha, 0, 1, HUD.ANIMATION.VEHICLE_NAME_FADE))
	nameFadeTween:addInterval(HUD.ANIMATION.VEHICLE_NAME_SHOW)
	nameFadeTween:addTween(Tween.new(self.vehicleNameDisplay.setAlpha, 1, 0, HUD.ANIMATION.VEHICLE_NAME_FADE))
	self.vehicleNameDisplay:setAnimation(nameFadeTween)
	self.vehicleNameDisplay:setVisible(false, false)
	table.insert(self.displayComponents, self.vehicleNameDisplay)
	
	self.blinkingWarning = nil
	self.blinkingWarningDisplay = HUDTextDisplay.new(0.5, 0.5, HUD.TEXT_SIZE.BLINKING_WARNING, RenderText.ALIGN_CENTER, HUD.COLOR.BLINKING_WARNING, true)
	local blinkTween = TweenSequence.new(self.blinkingWarningDisplay)
	
	blinkTween:addTween(MultiValueTween.new(self.blinkingWarningDisplay.setTextColorChannels, HUD.COLOR.BLINKING_WARNING_1, HUD.COLOR.BLINKING_WARNING_2, HUD.ANIMATION.BLINKING_WARNING_TIME))
	blinkTween:addTween(MultiValueTween.new(self.blinkingWarningDisplay.setTextColorChannels, HUD.COLOR.BLINKING_WARNING_2, HUD.COLOR.BLINKING_WARNING_1, HUD.ANIMATION.BLINKING_WARNING_TIME))
	blinkTween:setLooping(true)
	self.blinkingWarningDisplay:setAnimation(blinkTween)
	self.blinkingWarningDisplay:setVisible(false)
	table.insert(self.displayComponents, self.blinkingWarningDisplay)
	
	local fadeOverlay = Overlay.new(g_baseHUDFilename, 0, 0, 1, 1)
	
	fadeOverlay:setUVs(GuiUtils.getUVs(HUD.UV.AREA))
	fadeOverlay:setColor(0, 0, 0, 0)
	
	self.fadeScreenElement = HUDElement.new(fadeOverlay)
	
	table.insert(self.displayComponents, self.fadeScreenElement)
	
	self.popupMessage = HUDPopupMessage.new(g_baseHUDFilename, self.l10n, self.inputManager, self.inputDisplayManager, self.ingameMap, self.guiSoundPlayer)
	
	self.popupMessage:setScale(uiScale)
	self.popupMessage:storeOriginalPosition()
	table.insert(self.displayComponents, self.popupMessage)
	
	self.inGameIcon = InGameIcon.new()
	
	table.insert(self.displayComponents, self.inGameIcon)
	
	self.gameInfoDisplay = GameInfoDisplay.new(g_baseHUDFilename, g_gameSettings:getValue("moneyUnit"), self.l10n)
	
	self.gameInfoDisplay:setScale(uiScale)
	self.gameInfoDisplay:setTemperatureVisible(false)
	table.insert(self.displayComponents, self.gameInfoDisplay)
	
	self.vehicleSchema = VehicleSchemaDisplay.new(self.modManager)
	
	self.vehicleSchema:setScale(uiScale)
	self.vehicleSchema:setDocked(g_gameSettings:getValue("showHelpMenu"), false)
	self.vehicleSchema:loadVehicleSchemaOverlays()
	table.insert(self.displayComponents, self.vehicleSchema)
	
	self.speakerDisplay = SpeakerDisplay.new(g_baseHUDFilename, self.ingameMap)
	
	self.speakerDisplay:setScale(uiScale)
	self.speakerDisplay:storeOriginalPosition()
	self.speakerDisplay:setVisible(false, false)
	table.insert(self.displayComponents, self.speakerDisplay)
	
	self.chatWindow = ChatWindow.new(g_baseHUDFilename, self.speakerDisplay)
	
	self.chatWindow:setScale(uiScale)
	self.chatWindow:storeOriginalPosition()
	self.chatWindow:setVisible(false, false)
	table.insert(self.displayComponents, self.chatWindow)
	
	self.inputHelp = InputHelpDisplay.new(g_baseHUDFilename, self.messageCenter, self.inputManager, self.inputDisplayManager, self.ingameMap, self.chatWindow, self.popupMessage, self.isConsoleVersion)
	
	self.inputHelp:setScale(uiScale)
	self.inputHelp:storeOriginalPosition()
	self.inputHelp:setVisible(g_gameSettings:getValue("showHelpMenu"), false)
	table.insert(self.displayComponents, self.inputHelp)
	
	self.speedMeter = SpeedMeterDisplay.new(g_baseHUDFilename)
	
	self.speedMeter:setVehicle(self.controlledVehicle)
	self.speedMeter:setScale(uiScale)
	self.speedMeter:storeOriginalPosition()
	self.speedMeter:setVisible(false, false)
	table.insert(self.displayComponents, self.speedMeter)
	
	self.fillLevelsDisplay = FillLevelsDisplay.new(g_baseHUDFilename)
	
	self.fillLevelsDisplay:setVehicle(self.controlledVehicle)
	self.fillLevelsDisplay:refreshFillTypes(self.fillTypeManager)
	self.fillLevelsDisplay:setScale(uiScale)
	self.fillLevelsDisplay:storeOriginalPosition()
	self.fillLevelsDisplay:setVisible(false, false)
	table.insert(self.displayComponents, self.fillLevelsDisplay)
	
	local hudAtlasPath = Utils.getFilename("src/resources/hud/hud_element.dds", modDirectory)
	
	self.contextActionDisplay = ContextActionsDisplay.new(hudAtlasPath, self.inputDisplayManager)
	
	self.contextActionDisplay:setScale(uiScale)
	self.contextActionDisplay:setVisible(false, false)
	table.insert(self.displayComponents, self.contextActionDisplay)
	
	self.achievementMessage = AchievementMessage.new(g_baseHUDFilename, self.inputManager, self.guiSoundPlayer, self.contextActionDisplay)
	
	self.achievementMessage:setScale(uiScale)
	self.achievementMessage:setVisible(false, false)
	table.insert(self.displayComponents, self.achievementMessage)
	
	self.sideNotifications = SideNotification.new(nil, g_baseHUDFilename)
	
	self.sideNotifications:setScale(uiScale)
	self.sideNotifications:storeOriginalPosition()
	self.sideNotifications:setVisible(true, false)
	table.insert(self.displayComponents, self.sideNotifications)
	
	self.topNotification = TopNotification.new(g_baseHUDFilename)
	
	self.topNotification:setScale(uiScale)
	self.topNotification:storeOriginalPosition()
	self.topNotification:setVisible(false, false)
	table.insert(self.displayComponents, self.topNotification)
	
	self.infoDisplay = InfoDisplay.new(g_baseHUDFilename)
	
	self.infoDisplay:setScale(uiScale)
	self.infoDisplay:storeOriginalPosition()
	self.infoDisplay:setVisible(false, false)
	table.insert(self.displayComponents, self.infoDisplay)
end

function ManualDischargeHUD:showAttachContext(superFunc, attachVehicleName)
	self.contextActionDisplay:setContext(InputAction.ATTACH, ContextActionsDisplay.CONTEXT_ICON.ATTACH, attachVehicleName, ManualDischargeHUD.CONTEXT_PRIORITY.HIGH) -- fixed original ContextActionDisplay priority bug --
end

function ManualDischargeHUD:showCombineDischargeContext(fillTypeName)
	self.contextActionDisplay:setContext(InputAction.TOGGLE_DISCHARGE_COMBINE, ContextActionsDisplay.CONTEXT_ICON.DISCHARGE_COMBINE, fillTypeName, ManualDischargeHUD.CONTEXT_PRIORITY.MEDIUM)
end

function ManualDischargeHUD:showAugerWagonDischargeContext(fillTypeName)
	self.contextActionDisplay:setContext(InputAction.TOGGLE_DISCHARGE_AUGER_WAGON, ContextActionsDisplay.CONTEXT_ICON.DISCHARGE_AUGER_WAGON, fillTypeName, ManualDischargeHUD.CONTEXT_PRIORITY.MEDIUM)
end