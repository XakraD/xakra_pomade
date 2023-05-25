RegisterNetEvent("xakra_pomade:TaskPomade")
AddEventHandler("xakra_pomade:TaskPomade", function()
	local playerPed = PlayerPedId()
    if Citizen.InvokeNative(0xFB4891BD7578CDC1, playerPed, tonumber(0x9925C067)) then   -- _IS_METAPED_USING_COMPONENT
        TaskItemInteraction(playerPed, 0, GetHashKey("APPLY_POMADE_WITH_HAT"), 1, 0, -1082130432)
    else
        TaskItemInteraction(playerPed, 0, GetHashKey("APPLY_POMADE_WITH_NO_HAT"), 1, 0, -1082130432)
    end
    Wait(2500)

    Citizen.InvokeNative(0x66B957AAC2EAAEAB, playerPed, GetCurrentPedComponent(playerPed, "hair"), GetHashKey("POMADE"), 0, true, 1) -- _UPDATE_SHOP_ITEM_WEARABLE_STATE
    Citizen.InvokeNative(0xCC8CA3E88256E58F, playerPed, false, true, true, true, false) -- _UPDATE_PED_VARIATION
end)

function GetCurrentPedComponent(ped, category)

    local componentsCount = GetNumComponentsInPed(ped)
    if not componentsCount then
        return 0
    end
    local metaPedType = GetMetaPedType(ped)
    local dataStruct = DataView.ArrayBuffer(6 * 8)
    local fullPedComponents = {}
    for i = 0, componentsCount, 1 do
        local componentHash = GetShopPedComponentAtIndex(ped, i, true, dataStruct:Buffer(), dataStruct:Buffer())
        if componentHash then
            local componentCategoryHash = GetShopPedComponentCategory(componentHash, metaPedType, true)
            if category ~= nil then
                if GetHashKey(category) == componentCategoryHash then
                    return componentHash
                end
            else
                fullPedComponents[componentCategoryHash] = componentHash
            end
        end
    end
    if category then
        return 0
    end
    return fullPedComponents
end

function GetNumComponentsInPed(ped)
    return Citizen.InvokeNative(0x90403E8107B60E81, ped)
end

function GetMetaPedType(ped)
    return Citizen.InvokeNative(0xEC9A1261BF0CE510, ped)
end

function GetShopPedComponentAtIndex(ped, index, bool, struct1, struct2)
    return Citizen.InvokeNative(0x77BA37622E22023B, ped, index, bool, struct1, struct2)
end

function GetShopPedComponentCategory(componentHash, metaPedType, bool)
    return Citizen.InvokeNative(0x5FF9A878C3D115B8, componentHash, metaPedType, bool)
end

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
----------------- 			                     DATAVIEW FUNCTIONS					            -------------
-----------------										                                        -------------
----------------- 		         BIG THNKS to gottfriedleibniz for this DataView in LUA.		-------------
-----------------   https://gist.github.com/gottfriedleibniz/8ff6e4f38f97dd43354a60f8494eedff	-------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

local _strblob = string.blob or function(length)
    return string.rep("\0", math.max(40 + 1, length))
end

DataView = {
    EndBig = ">",
    EndLittle = "<",
    Types = {
        Int8 = { code = "i1", size = 1 },
        Uint8 = { code = "I1", size = 1 },
        Int16 = { code = "i2", size = 2 },
        Uint16 = { code = "I2", size = 2 },
        Int32 = { code = "i4", size = 4 },
        Uint32 = { code = "I4", size = 4 },
        Int64 = { code = "i8", size = 8 },
        Uint64 = { code = "I8", size = 8 },

        LuaInt = { code = "j", size = 8 },
        UluaInt = { code = "J", size = 8 },
        LuaNum = { code = "n", size = 8 },
        Float32 = { code = "f", size = 4 },
        Float64 = { code = "d", size = 8 },
        String = { code = "z", size = -1, },
    },

    FixedTypes = {
        String = { code = "c", size = -1, },
        Int = { code = "i", size = -1, },
        Uint = { code = "I", size = -1, },
    },
}
DataView.__index = DataView
local function _ib(o, l, t) return ((t.size < 0 and true) or (o + (t.size - 1) <= l)) end

local function _ef(big) return (big and DataView.EndBig) or DataView.EndLittle end

local SetFixed = nil
function DataView.ArrayBuffer(length)
    return setmetatable({
        offset = 1, length = length, blob = _strblob(length)
    }, DataView)
end

function DataView.Wrap(blob)
    return setmetatable({
        offset = 1, blob = blob, length = blob:len(),
    }, DataView)
end

function DataView:Buffer() return self.blob end

function DataView:ByteLength() return self.length end

function DataView:ByteOffset() return self.offset end

function DataView:SubView(offset)
    return setmetatable({
        offset = offset, blob = self.blob, length = self.length,
    }, DataView)
end

for label, datatype in pairs(DataView.Types) do
    DataView["Get" .. label] = function(self, offset, endian)
        local o = self.offset + offset
        if _ib(o, self.length, datatype) then
            local v, _ = string.unpack(_ef(endian) .. datatype.code, self.blob, o)
            return v
        end
        return nil
    end

    DataView["Set" .. label] = function(self, offset, value, endian)
        local o = self.offset + offset
        if _ib(o, self.length, datatype) then
            return SetFixed(self, o, value, _ef(endian) .. datatype.code)
        end
        return self
    end
    if datatype.size >= 0 and string.packsize(datatype.code) ~= datatype.size then
        local msg = "Pack size of %s (%d) does not match cached length: (%d)"
        error(msg:format(label, string.packsize(fmt[#fmt]), datatype.size))
        return nil
    end
end
for label, datatype in pairs(DataView.FixedTypes) do
    DataView["GetFixed" .. label] = function(self, offset, typelen, endian)
        local o = self.offset + offset
        if o + (typelen - 1) <= self.length then
            local code = _ef(endian) .. "c" .. tostring(typelen)
            local v, _ = string.unpack(code, self.blob, o)
            return v
        end
        return nil
    end
    DataView["SetFixed" .. label] = function(self, offset, typelen, value, endian)
        local o = self.offset + offset
        if o + (typelen - 1) <= self.length then
            local code = _ef(endian) .. "c" .. tostring(typelen)
            return SetFixed(self, o, value, code)
        end
        return self
    end
end

SetFixed = function(self, offset, value, code)
    local fmt = {}
    local values = {}
    if self.offset < offset then
        local size = offset - self.offset
        fmt[#fmt + 1] = "c" .. tostring(size)
        values[#values + 1] = self.blob:sub(self.offset, size)
    end
    fmt[#fmt + 1] = code
    values[#values + 1] = value
    local ps = string.packsize(fmt[#fmt])
    if (offset + ps) <= self.length then
        local newoff = offset + ps
        local size = self.length - newoff + 1

        fmt[#fmt + 1] = "c" .. tostring(size)
        values[#values + 1] = self.blob:sub(newoff, self.length)
    end
    self.blob = string.pack(table.concat(fmt, ""), table.unpack(values))
    self.length = self.blob:len()
    return self
end

DataStream = {}
DataStream.__index = DataStream

function DataStream.New(view)
    return setmetatable({ view = view, offset = 0, }, DataStream)
end

for label, datatype in pairs(DataView.Types) do
    DataStream[label] = function(self, endian, align)
        local o = self.offset + self.view.offset
        if not _ib(o, self.view.length, datatype) then
            return nil
        end
        local v, no = string.unpack(_ef(endian) .. datatype.code, self.view:Buffer(), o)
        if align then
            self.offset = self.offset + math.max(no - o, align)
        else
            self.offset = no - self.view.offset
        end
        return v
    end
end
