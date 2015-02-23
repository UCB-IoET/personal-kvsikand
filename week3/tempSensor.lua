REG = require("reg")
require("storm")
require("cord")

local TEMP = {}

function TEMP:new()
   local obj = {port=storm.i2c.INT, 
                addr = 0x80, 
                reg=REG:new(storm.i2c.INT, 0x80)}
   setmetatable(obj, self)
   self.__index = self
   return obj
end


function TEMP:init()
    --configure the conversion rate (0x02 0x00 = 2 sample/second, 0x04 0x00 = 1 s/s)
    self.reg:w(storm.n.TMP006_CONFIG, {0x00 + 0x70 + 0x01, 0x00})
    return true
end

function TEMP:reset()
    -- reset the sensor, this bit self clears
    self.reg:w(storm.n.TMP006_CONFIG, {0x80, 0x00})
    return true
end

function TEMP:getTemp()
    --Read ambient temperature
    local result = self.reg:r(storm.n.TMP006_LOCAL_TEMP, 2)
    --Converting temperature into Celsius (each LSB = 1/32 Deg. Celsius)
    local temperature = bit.rshift(result:get_as(storm.array.INT16_BE, 0), 2) / 32
    return temperature
end

function TEMP:getConfig()
    -- Read configuration register
    local result = self.reg:r(storm.n.TMP006_CONFIG, 2)
    local config = bit.rshift(result:get_as(storm.array.INT16_BE,0), 7)
    return config
end

function TEMP:isReady()
    --reading 8th bit of configuration, which indicates if conversion is ready
    return bit.band(self:getConfig(), 0x0001) == 0x0001
end

function TEMP:get_mfg_id()
    --Read Mfg ID, should be 21577
    local result = self.reg:r(storm.n.TMP006_MFG_ID, 2)
    local mfg_id = result:get_as(storm.array.INT16_BE,0)
    return mfg_id
end

function TEMP:get_dev_id()
    --Read Device ID, should be 103
    local result = self.reg:r(storm.n.TMP006_DEVICE_ID, 2)
    local dev_id = result:get_as(storm.array.INT16_BE,0)
    return dev_id
end

function TEMP:get_raw_voltage()
    -- Get the sensor voltage reading result directly in uV
    local result = self.reg:r(storm.n.TMP006_VOLTAGE, 2)
    -- Each LSB is 156.25 nV, we convert it to mV
    local voltage = result:get_as(storm.array.INT16_BE,0) * 156 / 1000
    return voltage 
end

return TEMP
