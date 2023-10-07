ViewRenderer = {
    m_pMap = nil,
    m_pPlayer = nil,
    m_iAutoMapScaleFactor = 15
}

function ViewRenderer:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function ViewRenderer:Init(pMap, pPlayer)
    self.m_pMap = pMap
    self.m_pPlayer = pPlayer
end


iRenderYSize = 199
function ViewRenderer:RemapXToScreen(XMapPosition)
    return (XMapPosition + -self.m_pMap:GetXMin()) / self.m_iAutoMapScaleFactor
end

function ViewRenderer:RemapYToScreen(YMapPosition)
    return iRenderYSize - (YMapPosition + -self.m_pMap:GetYMin()) / self.m_iAutoMapScaleFactor
end

function ViewRenderer:Render(IsRenderAutoMap)
    if IsRenderAutoMap == true then
        self:RenderAutoMap()
    else
        self:Render3DView()
    end
end

function ViewRenderer:InitFrame()
    love.graphics.clear(0,0,0,1)
end

function ViewRenderer:AddWallInFOV(seg, V1Angle, V2Angle)
    local V1XScreen = self:AngleToScreen(V1Angle)
    local V2XScreen = self:AngleToScreen(V2Angle)

    love.graphics.line(V1XScreen, 0, V1XScreen, iRenderYSize)
    love.graphics.line(V2XScreen, 0, V2XScreen, iRenderYSize)
end
function ViewRenderer:RenderAutoMap()
    self.m_pMap:RenderAutoMap()
    self.m_pPlayer:RenderAutoMap()
end

function ViewRenderer:Render3DView()
    self.m_pMap:Render3DView()
end

function ViewRenderer:AngleToScreen(angle)
    local iX = 0
    if angle > Angle:new(90) then
        angle = angle - 90
        iX = 160 - math.tan(angle.m_Angle * math.pi / 180) * 160
    else
        angle = 90 - angle
        local f = math.tan(angle.m_Angle)
        iX = math.tan(angle.m_Angle * math.pi / 180) * 160
        iX = iX + 160
    end

    return iX
end

function ViewRenderer:SetDrawColor(r, g, b, a)
    if a == nil then
        a = 1
    end
    love.graphics.setColor(r, g, b, a)
end

function ViewRenderer:DrawRect(x1, y1, x2, y2)
    love.graphics.rectangle('line',self:RemapXToScreen(x1),self:RemapYToScreen(y1), self:RemapXToScreen(x2) - self:RemapXToScreen(x1)+1, self:RemapYToScreen(y2)- self:RemapXToScreen(y1)+1)
end

function ViewRenderer:DrawLine(x1, y1, x2, y2)
    love.graphics.line(self:RemapXToScreen(x1),self:RemapYToScreen(y1), self:RemapXToScreen(x2), self:RemapYToScreen(y2))
end

return ViewRenderer