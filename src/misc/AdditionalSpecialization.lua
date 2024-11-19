-- AdditionalSpecialization.lua
--
-- author: 4c65736975
--
-- Copyright (c) 2024 VertexFloat. All Rights Reserved.
--
-- This source code is licensed under the GPL-3.0 license found in the
-- LICENSE file in the root directory of this source tree.

local MOD_NAME = g_currentModName

local function finalizeTypes(self)
  if self.typeName == "vehicle" then
    for typeName, typeEntry in pairs(self:getTypes()) do
      if SpecializationUtil.hasSpecialization(Pipe, typeEntry.specializations) then
        local specialization = MOD_NAME .. ".manualPipeDischargeable"

        if not SpecializationUtil.hasSpecialization(specialization, typeEntry.specializations) then
          self:addSpecialization(typeName, specialization)
        end
      end
    end
  end
end

TypeManager.finalizeTypes = Utils.appendedFunction(TypeManager.finalizeTypes, finalizeTypes)