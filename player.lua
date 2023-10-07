Angle = require('angle')
ViewRenderer = require('viewrenderer')

Player = {
    m_iPlayerID = 0,
    m_XPosition = 0,
    m_YPosition = 0,
    m_Angle = Angle:new(),
    m_FOV = Angle:new(90),
    m_iRotationSpeed = Angle:new(4),
    m_pViewRenderer = ViewRenderer:new()

}

function Player:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Player:SetXPosition(x)
    self.m_XPosition = x
end

function Player:SetYPosition(y)
    self.m_YPosition = y
end

function Player:SetAngle(angle)
    self.m_Angle = angle
end

function Player:GetID()
    return self.m_iPlayerID
end

function Player:GetXPosition()
    return self.m_XPosition
end

function Player:GetYPosition()
    return self.m_YPosition
end

function Player:GetAngle()
    return self.m_Angle
end

function Player:AngleToVertex(vertex)
    local dx = vertex.x - self.m_XPosition
    local dy = vertex.y - self.m_YPosition
    local angle = math.atan2(dy, dx) * 180 / math.pi
    return Angle:new(angle)
end

function Player:ClipVertexInFOV(V1, V2, V1Angle, V2Angle)
    local V1Angle = self:AngleToVertex(V1)
    local V2Angle = self:AngleToVertex(V2)

    local V1ToV2Span = V1Angle - V2Angle
    if V1ToV2Span >= Angle:new(180) then
        return false, V1Angle, V2Angle
    end
    V1Angle = V1Angle - self.m_Angle
    V2Angle = V2Angle - self.m_Angle

    local HalfFOV = self.m_FOV / Angle:new(2)

    local V1Moved = V1Angle + HalfFOV
    if (V1Moved > self.m_FOV) then
        local V1MovedAngle = V1Moved - self.m_FOV
        if (V1MovedAngle >= V1ToV2Span) then
            return false, V1Angle, V2Angle
        end 
        V1Angle = HalfFOV
    end
    local V2Moved = HalfFOV -V2Angle

    if V2Moved > self.m_FOV then
        V2Angle = -1*HalfFOV
    end
    V1Angle = V1Angle + 90
    V2Angle = V2Angle + 90

    return true, V1Angle, V2Angle
end

function Player:RotateLeft()
    self.m_Angle = self.m_Angle + 0.1875*self.m_iRotationSpeed
end

function Player:RotateRight()
    self.m_Angle = self.m_Angle - 0.1875*self.m_iRotationSpeed
end

function Player:RenderAutoMap()
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.circle("fill", self.m_XPosition, self.m_YPosition, 2)
end

return Player