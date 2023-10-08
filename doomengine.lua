local types = require("datatypes")
local WADLoader = require("wadloader")
local Map = require("map")
local Player = require('player')



local DoomEngine = {
    m_iRenderWidth = 320,
    m_iRenderHeight = 200,
    m_bIsOver = false,
    m_WADLoader = WADLoader:new(),
    m_Map = nil,
    m_Player = nil,
    m_pViewRenderer = nil,
    m_bRenderAutoMap = true,
}


function DoomEngine:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function DoomEngine:Render()
    -- love.graphics.clear(0,0,0,1)
    -- self.m_Map:RenderAutoMap()
    self.m_pViewRenderer:InitFrame()
    self.m_pViewRenderer:Render(self.m_bRenderAutoMap)
end


function DoomEngine:KeyPressed(key, hold)
    -- print("key pressed: " .. key)
    if hold == nil then
        hold = false
    end
    if key == "a" then
        self.m_Player:RotateLeft()
    elseif key == "d" then
        self.m_Player:RotateRight()
    elseif key == "w" then
        self.m_Player:MoveForward()
    elseif key == "s" then
        self.m_Player:MoveBackward()
    
    elseif key == "tab" and not hold then
        self.m_bRenderAutoMap = not self.m_bRenderAutoMap

    end
end

function DoomEngine:KeyReleased(key)
    -- print("key released: " .. key) 

end

function DoomEngine:Quit()
end

function DoomEngine:Update()
end

function DoomEngine:IsOver()
end
function DoomEngine:Init()
    local viewRender = ViewRenderer:new()
    self.m_pViewRenderer = viewRender

    local player = Player:new({m_iPlayerID=1, pViewRenderer = viewRender})
    self.m_Player = player

    self.m_Map = Map:new{m_sName="E1M1", m_Player = self.m_Player, m_pViewRenderer = viewRender  }

    viewRender:Init(self.m_Map, self.m_Player)
    
    
    self.m_WADLoader:LoadWAD(self:GetWADFileName())
    self.m_WADLoader:LoadMapData(self.m_Map)

    local thing = self.m_Map:GetThings():GetThingByID(1)

    -- print(thing, thing.X_Po)
    self.m_Player:Init(thing)

    print(self.m_Player:GetXPosition(), self.m_Player:GetYPosition(), self.m_Player:GetAngle().m_Angle)

    self.m_Map:Init()

end


function DoomEngine:GetRenderWidth()

end
function DoomEngine:GetRenderHeight()
end
function DoomEngine:GetTimePerFrame()
    return 1/60
end


function DoomEngine:GetName()
    return "DoomEngine"
end
function DoomEngine:GetWADFileName()
    return "./DOOM.WAD"
end

return DoomEngine