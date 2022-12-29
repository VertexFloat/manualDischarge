-- Author: VertexFloat
-- Date: 07.07.2022
-- Version: Farming Simulator 22, 1.0.0.0
-- Copyright (C): VertexFloat, All Rights Reserved
-- Installing 'ManualPipeDischargeable' specialization to specific vehicles

local modName = g_currentModName

function finalizeTypes(self)
    if self.typeName == "vehicle" and g_modIsLoaded[modName] then
        for typeName, typeEntry in pairs(self:getTypes()) do
            if SpecializationUtil.hasSpecialization(Pipe, typeEntry.specializations) and SpecializationUtil.hasSpecialization(Dischargeable, typeEntry.specializations) then
                local additionalSpecialization = modName .. ".manualPipeDischargeable"

                if not SpecializationUtil.hasSpecialization(additionalSpecialization, typeEntry.specializations) then
                    self:addSpecialization(typeName, additionalSpecialization)
                end
            end
        end
    end
end

TypeManager.finalizeTypes = Utils.appendedFunction(TypeManager.finalizeTypes, finalizeTypes)