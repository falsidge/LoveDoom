Angle = require('angle')
ViewRenderer = require('viewrenderer')

Player = {
    m_iPlayerID = 0,
    m_XPosition = 0,
    m_YPosition = 0,
    m_Angle = Angle:new(),
    m_FOV = Angle:new(90),
    m_iRotationSpeed = Angle:new(4),
    m_pViewRenderer = ViewRenderer:new(),
    m_iMoveSpeed = 4
}

function Player:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Player:Init(thing)
    self.m_XPosition = thing.XPosition
    self.m_YPosition = thing.YPosition
    self.m_ZPosition = 41
    self.m_Angle = Angle:new(thing.Angle)
end

function Player:SetXPosition(x)
    self.m_XPosition = x
end

function Player:SetYPosition(y)
    self.m_YPosition = y
end

function Player:SetZPosition(z)
    self.m_ZPosition = z
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

function Player:GetZPosition()
    return self.m_ZPosition
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

function Player:ClipVertexInFOV(V1, V2)
    local V1Angle = self:AngleToVertex(V1)
    local V2Angle = self:AngleToVertex(V2)

    local V1ToV2Span = V1Angle - V2Angle
    if V1ToV2Span >= Angle:new(180) then
        return false, V1Angle, V2Angle, nil, nil
    end
    local V1AngleFromPlayer = V1Angle - self.m_Angle
    local V2AngleFromPlayer = V2Angle - self.m_Angle

    local HalfFOV = self.m_FOV / 2

    local V1Moved = V1AngleFromPlayer + HalfFOV
    if (V1Moved > self.m_FOV) then
        local V1MovedAngle = V1Moved - self.m_FOV
        if (V1MovedAngle >= V1ToV2Span) then
            return false, V1Angle, V2Angle, V1AngleFromPlayer, V2AngleFromPlayer
        end 
        V1AngleFromPlayer = HalfFOV
    end
    local V2Moved = HalfFOV - V2AngleFromPlayer

    if V2Moved > self.m_FOV then
        V2AngleFromPlayer = -1*HalfFOV
    end
    V1AngleFromPlayer = V1AngleFromPlayer + 90
    V2AngleFromPlayer = V2AngleFromPlayer + 90

    return true, V1Angle, V2Angle, V1AngleFromPlayer, V2AngleFromPlayer
end

function Player:RotateLeft()
    self.m_Angle = self.m_Angle + 0.1875*self.m_iRotationSpeed
end

function Player:RotateRight()
    self.m_Angle = self.m_Angle - 0.1875*self.m_iRotationSpeed
end

function Player:MoveForward()
    self.m_XPosition = self.m_XPosition + math.cos(math.rad(self.m_Angle.m_Angle)) * self.m_iMoveSpeed
    self.m_YPosition = self.m_YPosition + math.sin(math.rad(self.m_Angle.m_Angle)) * self.m_iMoveSpeed
end



function Player:MoveBackward()
    self.m_XPosition = self.m_XPosition - math.cos(math.rad(self.m_Angle.m_Angle)) * self.m_iMoveSpeed
    self.m_YPosition = self.m_YPosition - math.sin(math.rad(self.m_Angle.m_Angle)) * self.m_iMoveSpeed
end



function Player:RenderAutoMap()
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.circle("fill", self.m_XPosition, self.m_YPosition, 2)
end

function Player:DistanceToPoint(v)
    local dx = v.x - self.m_XPosition
    local dy = v.y - self.m_YPosition
    return math.sqrt(dx*dx + dy*dy)
end

return Player