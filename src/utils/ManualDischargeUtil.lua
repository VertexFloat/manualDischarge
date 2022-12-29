-- Author: VertexFloat
-- Date: 06.08.2022
-- Version: Farming Simulator 22, 1.0.0.1
-- Copyright (C): VertexFloat, All Rights Reserved
-- Manual Discharge Utils

-- Changelog (1.0.0.1) :
--
-- fixed 'getAttachedImplements' lua error in specific situations

ManualDischargeUtil = {}

function ManualDischargeUtil.overwriteEnvTableElement(tableKey, ovrTable)
    if tableKey == nil then
        return
    end

    if type(ovrTable) ~= "table" or ovrTable == nil then
        return
    end

    local env = getmetatable(_G).__index

    for table, _ in pairs(env) do
        if table == tableKey then
            local tab = env[table]

            for element, _ in pairs(tab) do
                for ovrElement, _ in pairs(ovrTable) do
                    if element == ovrElement then
                        tab[element] = ovrTable[ovrElement]
                    end
                end
            end
        end
    end
end

function ManualDischargeUtil.overwriteGameFunction(object, funcName, newFunc)
    if object == nil then
        return
    end

    local oldFunc = object[funcName]

    if oldFunc ~= nil then
        object[funcName] = function (...)
            return newFunc(oldFunc, ...)
        end
    end
end

function ManualDischargeUtil.deleteOldModFiles(modName, modSettings)
    local folder = modSettings .. modName
    local file = folder .. "/" .. "ManualDischargeSettings.xml"

    if fileExists(file) then
        Logging.info("Manual Discharge 'Deleting previous version files: (%s)'", file)

        deleteFolder(folder)
    end
end

function ManualDischargeUtil.getVehicleCategoryName(configFileName)
    return g_storeManager:getItemByXMLFilename(configFileName).categoryName
end

function ManualDischargeUtil.getAttachedImplementCategoryName(configFileName)
    for _, vehicle in pairs(g_currentMission.vehicles) do
        if vehicle ~= nil then
            if SpecializationUtil.hasSpecialization(AttacherJoints, vehicle.specializations) then
                local attachedImplements = vehicle:getAttachedImplements()

                if attachedImplements ~= nil then
                    for _, attachedImplement in pairs(attachedImplements) do
                        if attachedImplement.object.configFileName == configFileName then
                            return g_storeManager:getItemByXMLFilename(attachedImplement.object.configFileName).categoryName
                        end
                    end
                end
            end
        end
    end
end