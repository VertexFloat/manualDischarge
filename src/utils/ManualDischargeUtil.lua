-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.2, 10/02/2023
-- @filename: ManualDischargeUtil.lua

-- Changelog (1.0.0.1) :
--
-- fixed 'getAttachedImplements' lua error in specific situations

-- Changelog (1.0.0.2) :
--
-- removed/moved unnecessery functions

ManualDischargeUtil = {}

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

function ManualDischargeUtil.overwriteEnvTableElement(tableKey, ovrTable)
	if tableKey == nil then
		return
	end

	if type(ovrTable) ~= 'table' or ovrTable == nil then
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

function ManualDischargeUtil.getIsValidIndexName(indexName)
	if type(indexName) ~= 'string' then
		print(string.format("Error: ManualDischargeUtil.getIsValidIndexName: string expected, got %s", type(indexName)))

		printCallstack()
	end

	if indexName == nil or indexName == '' or indexName:find('[^%w_.]') then
		return false
	end

	return true
end