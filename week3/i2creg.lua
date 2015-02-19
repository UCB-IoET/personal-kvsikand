require "cord"
require "table"

local REG = {}

-- Create a new I2C register binding
function REG:new(port, address)
    obj = {port=port, address=address}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- Read a given register address
function REG:r(reg)
    -- TODO:
    -- create array with address
    -- write address
    -- read register with RSTART
    -- check all return values
    local arr = storm.array.create(1, storm.array.UINT8)
    arr:set(1, reg)
    local rv = cord.await(storm.i2c.write, self.port + self.address, storm.i2c.START, arr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    rv = cord.await(storm.i2c.read, self.port + self.address, storm.i2c.RSTART + storm.i2c.STOP, arr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    return arr:get(1)
end

-- Read a given register address (a num of bytes)
-- Return an array of UNIT8
function REG:r_multiple(reg, num)
    -- TODO:
    -- create array with address
    -- write address
    -- read register with RSTART
    -- check all return values
    local arr = storm.array.create(1, storm.array.UINT8)
    arr:set(1, reg)
    local rv = cord.await(storm.i2c.write, self.port + self.address, storm.i2c.START, arr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    local result = storm.array.create(num, storm.array.UINT8)
    rv = cord.await(storm.i2c.read, self.port + self.address, storm.i2c.RSTART + storm.i2c.STOP, result)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
    return result
end

function REG:w(reg, value)
    -- TODO:
    -- create array with address and value
    -- write
    -- check return value
    local arr = storm.array.create(2, storm.array.UINT8)
    arr:set(1, reg)
    arr:set(2, value)
    local rv = cord.await(storm.i2c.write, self.port + self.address, storm.i2c.START + storm.i2c.STOP, arr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
end

function REG:w_multiple(reg, values)
    -- TODO:
    -- create array with address and value
    -- write
    -- check return value
    local arr = storm.array.create(table.maxn(values) + 1, storm.array.UINT8)
    arr:set(1,reg)
    local i = 2
    for key, value in pairs(values) do
        arr:set(i, value)
        i = i + 1
    end
    local rv = cord.await(storm.i2c.write, self.port + self.address, storm.i2c.START + storm.i2c.STOP, arr)
    if (rv ~= storm.i2c.OK) then
        print ("ERROR ON I2C: ",rv)
    end
end

return REG