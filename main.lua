local types = require("datatypes")
local Map = require("map")
local WADLoader = require("wadloader")
local DoomEngine = require("doomengine")
local Angle = require('angle')

local test = Angle:new()
local test2 = Angle:new(350)
local test3 = Angle:new(25)
print((test + test2).m_Angle)
print((test + test2 + 25).m_Angle)

-- print("test")
-- local wad = WADLoader:new("./DOOM.WAD")

-- wad:LoadMapData(Map:new{m_sName="E1M1"})

local m_pDoomEngine = DoomEngine:new()


m_pDoomEngine:Init()

function love.draw()
    love.graphics.clear(0,0,0,1)
    m_pDoomEngine:Render()
    love.graphics.print("hello world", 400, 300)
end

local pressedKeys = {}
local tot_dt = 0
function love.update(dt)
    tot_dt = tot_dt + dt
    if tot_dt < m_pDoomEngine:GetTimePerFrame() then
        return
    end
    m_pDoomEngine:Update()
    tot_dt = 0
    for i,v in pairs(pressedKeys) do
        if v then
            m_pDoomEngine:KeyPressed(i, true)
        end
    end
end


function love.keypressed(key, scancode, isrepeat)
    pressedKeys[key] = true
    m_pDoomEngine:KeyPressed(key)
end

function love.keyreleased(key, scancode)
    pressedKeys[key] = false
    m_pDoomEngine:KeyReleased(key)
end

function love.quit()
    m_pDoomEngine:Quit()
end

