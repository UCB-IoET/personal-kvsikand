REG = require("reg")
require("storm")
require("cord")

-- Register address --
local TMP006_VOLTAGE = 0x00
local TMP006_LOCAL_TEMP = 0x01
local TMP006_CONFIG = 0x02
local TMP006_MFG_ID = 0xFE
local TMP006_DEVICE_ID = 0xFF

-- Config register values
TMP006_CFG_RESET    = 0x80
TMP006_CFG_MODEON   = 0x70
CFG_1SAMPLE         = 0x00
CFG_2SAMPLE         = 0x02
CFG_4SAMPLE         = 0x04
CFG_8SAMPLE         = 0x06
CFG_16SAMPLE        = 0x08
TMP006_CFG_DRDYEN   = 0x01
TMP006_CFG_DRDY     = 0x80

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
    self.reg:w_multiple(TMP006_CONFIG, {0x00 + 0x70 + 0x01, 0x00})
    return true
end

function TEMP:getTemp()
    --Read ambient temperature
    local result = self.reg:r_multiple(TMP006_LOCAL_TEMP, 2)
    --Converting temperature into Celsius (each LSB = 1/32 Deg. Celsius)
    local temperature = bit.rshift(result:get_as(storm.array.INT16_BE, 0), 2) / 32
    return temperature
end

function TEMP:getStatus()
    -- Read configuration register
    local addr = storm.array.create(1, storm.array.UINT8)
    addr:set(1, TMP006_CONFIG)
    local rv = cord.await(storm.i2c.write,  self.port + self.addr,  storm.i2c.START, addr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local dat = storm.array.create(2, storm.array.UINT8)
    rv = cord.await(storm.i2c.read,  self.port + self.addr,  storm.i2c.RSTART + storm.i2c.STOP, dat)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    --reading 8th bit of configuration, which indicates if conversion is ready
    local config = bit.band((dat:get_as(storm.array.INT16_BE, 0)/128), 0x01)
    return config
end

function TEMP:get_MFG_DEV_ID()
    --Read Mfg ID, should be 21577
    addr:set(1, TMP006_MFG_ID)
    local rv = cord.await(storm.i2c.write,  self.port + self.addr,  storm.i2c.START, addr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local dat = storm.array.create(2, storm.array.UINT8)
    rv = cord.await(storm.i2c.read,  self.port + self.addr,  storm.i2c.RSTART + storm.i2c.STOP, dat)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local mfg_id = dat:get_as(storm.array.INT16_BE, 0)

    --Read Device ID, should be 103
    addr:set(1, TMP006_DEVICE_ID)
    local rv = cord.await(storm.i2c.write,  self.port + self.addr,  storm.i2c.START, addr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local dat = storm.array.create(2, storm.array.UINT8)
    rv = cord.await(storm.i2c.read,  self.port + self.addr,  storm.i2c.RSTART + storm.i2c.STOP, dat)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local device_id = dat:get_as(storm.array.INT16_BE, 0)
    
    return mfg_id, device_id
end

return TEMP
