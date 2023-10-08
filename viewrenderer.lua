local types = require("datatypes")
local Angle = require('angle')
local dbg = require('debugger')
ViewRenderer = {
    m_pMap = nil,
    m_pPlayer = nil,
    m_iAutoMapScaleFactor = 15,
    m_SolidWallRanges = {},
    m_WallColor = {},
    m_ScreenXToAngle = {},
    m_HalfScreenWidth = 0,
    m_HalfScreenHeight = 0,
    m_iDistancePlayerToScreen = 0
}

function ViewRenderer:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end
iRenderXSize = 320 
iRenderYSize =  200
function ViewRenderer:Init(pMap, pPlayer)
    self.m_pMap = pMap
    self.m_pPlayer = pPlayer
    self.m_HalfScreenWidth  = iRenderXSize / 2
    self.m_HalfScreenHeight = iRenderYSize / 2
    local HalfFOV = self.m_pPlayer.m_FOV / 2
    self.m_iDistancePlayerToScreen = math.floor(self.m_HalfScreenWidth / math.tan(HalfFOV.m_Angle * math.pi / 180)+0.5)
    for i = 0,iRenderXSize do
        self.m_ScreenXToAngle[i] = math.atan((self.m_HalfScreenWidth - i)/self.m_iDistancePlayerToScreen) * 180 / math.pi
    end
end



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
    -- self.m_SolidWallRanges = {}

    WallLeftSide = types.SolidSegmentRange:new({XStart = -999999, XEnd=-1})
    WallRightSide = types.SolidSegmentRange:new({XStart = iRenderXSize, XEnd=999999})
    self.m_SolidWallRanges = {WallLeftSide, WallRightSide}
end

function ViewRenderer:AddWallInFOV(seg, V1Angle, V2Angle, V1AngleFromPlayer, V2AngleFromPlayer)
    local V1XScreen = self:AngleToScreen(V1AngleFromPlayer)
    local V2XScreen = self:AngleToScreen(V2AngleFromPlayer)

    -- love.graphics.line(V1XScreen, 0, V1XScreen, iRenderYSize)
    -- love.graphics.line(V2XScreen, 0, V2XScreen, iRenderYSize)
    -- dbg()
    -- print(V1Angle.m_Angle, V2Angle.m_Angle, V1AngleFromPlayer.m_Angle, V2AngleFromPlayer.m_Angle, V1XScreen, V2XScreen,  seg.pLeftSector)
    if V1XScreen == V2XScreen then
        return
    end
    if seg.pLeftSector == nil then
        -- dbg()
        return self:ClipSolidWalls(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
    end
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
        iX = self.m_iDistancePlayerToScreen - math.tan(angle.m_Angle  * math.pi / 180)  * self.m_HalfScreenWidth
    else
        angle = 90 - angle
        iX = math.tan(angle.m_Angle * math.pi / 180)  * self.m_HalfScreenWidth 
        iX = iX + self.m_iDistancePlayerToScreen
    end

    return math.floor(iX+0.5)
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

function ViewRenderer:ClipSolidWalls(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
    if #self.m_SolidWallRanges < 2 then
        return
    end
    local CurrentWall = {XStart = V1XScreen, XEnd = V2XScreen}
    local FoundClipWall = self.m_SolidWallRanges[1]
    local FoundClipWallInd = 1
    
    -- for i,v in ipairs(self.m_SolidWallRanges) do
    --     if v.XEnd >= CurrentWall.XStart - 1 then
    --         break
    --     end
    
    --     FoundClipWall = v
    --     FoundClipWallInd = i
    -- end
    while FoundClipWallInd <= #self.m_SolidWallRanges and FoundClipWall.XEnd < CurrentWall.XStart - 1  do
        FoundClipWallInd = FoundClipWallInd + 1
        FoundClipWall = self.m_SolidWallRanges[FoundClipWallInd]
    end
    -- print(CurrentWall.XStart, FoundClipWall.XEnd )
    if CurrentWall.XStart < FoundClipWall.XStart then
        if (CurrentWall.XEnd < FoundClipWall.XStart - 1) then
            self:StoreWallRange(seg, CurrentWall.XStart, CurrentWall.XEnd, V1Angle, V2Angle)
            table.insert(self.m_SolidWallRanges, FoundClipWallInd, CurrentWall)
            return
        end
        self:StoreWallRange(seg, CurrentWall.XStart, FoundClipWall.XStart - 1, V1Angle, V2Angle)
        self.m_SolidWallRanges[FoundClipWallInd].XStart = CurrentWall.XStart
    end
    if CurrentWall.XEnd <= FoundClipWall.XEnd then
        return
    end

    local NextWallInd = FoundClipWallInd

    -- print(NextWallInd, #self.m_SolidWallRanges)
    if self.m_SolidWallRanges[NextWallInd+1] == nil then
        -- dbg()
        return
    end
    while CurrentWall.XEnd >= self.m_SolidWallRanges[NextWallInd+1].XStart - 1 do
        self:StoreWallRange(seg, self.m_SolidWallRanges[NextWallInd].XEnd + 1, self.m_SolidWallRanges[NextWallInd+1].XStart - 1, V1Angle, V2Angle)
        NextWallInd = NextWallInd + 1
        if CurrentWall.XEnd <= self.m_SolidWallRanges[NextWallInd].XEnd then
            self.m_SolidWallRanges[FoundClipWallInd].XEnd = self.m_SolidWallRanges[NextWallInd].XEnd
            if NextWallInd ~= FoundClipWallInd then
                FoundClipWallInd = FoundClipWallInd + 1
                NextWallInd = NextWallInd + 1
                for j = FoundClipWallInd, NextWallInd - 1 do
                    table.remove(self.m_SolidWallRanges, FoundClipWallInd)
                end
            end
            return
        end
        if self.m_SolidWallRanges[NextWallInd+1] == nil then
            -- dbg()
            return
        end
    end
    self:StoreWallRange(seg, self.m_SolidWallRanges[NextWallInd].XEnd + 1, CurrentWall.XEnd, V1Angle, V2Angle)
    self.m_SolidWallRanges[FoundClipWallInd].XEnd = CurrentWall.XEnd
    if NextWallInd ~= FoundClipWallInd then
        FoundClipWallInd = FoundClipWallInd + 1
        NextWallInd = NextWallInd + 1
        for j = FoundClipWallInd, NextWallInd - 1 do
            table.remove(self.m_SolidWallRanges, FoundClipWallInd)
        end
    end
    --[[
        while (CurrentWall.XEnd >= next(NextWall, 1)->XStart - 1)
    {
        // partially clipped by other walls, store each fragment
        StoreWallRange(seg, NextWall->XEnd + 1, next(NextWall, 1)->XStart - 1);
        ++NextWall;

        if (CurrentWall.XEnd <= NextWall->XEnd)
        {
            FoundClipWall->XEnd = NextWall->XEnd;
            if (NextWall != FoundClipWall)
            {
                //Delete a range of walls
                FoundClipWall++;
                NextWall++;
                m_SolidWallRanges.erase(FoundClipWall, NextWall);
            }
            return;
        }
    }

    StoreWallRange(seg, NextWall->XEnd + 1, CurrentWall.XEnd);
    FoundClipWall->XEnd = CurrentWall.XEnd;

    if (NextWall != FoundClipWall)
    {
        FoundClipWall++;
        NextWall++;
        m_SolidWallRanges.erase(FoundClipWall, NextWall);
    }
    ]]

end

function ViewRenderer:GetWallColor(textureName)
    if self.m_WallColor[textureName] == nil then
        local r = math.random()
        local g = math.random()
        local b = math.random()
        self.m_WallColor[textureName] = {r,g,b}
        return  self.m_WallColor[textureName]
    end
    return self.m_WallColor[textureName]
end

function ViewRenderer:StoreWallRange(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
    self:CalculateWallHeightSimple(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
end


function ViewRenderer:DrawSolidWall(visibleSeg)
    local color = self:GetWallColor(visibleSeg.seg.pLinedef.pRightSidedef.MiddleTexture)
    self:SetDrawColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle('line',visibleSeg.XStart, 0, visibleSeg.XEnd - visibleSeg.XStart  + 1, iRenderYSize)
end

function ViewRenderer:CalculateCeilingFloorHeight(seg, VXScreen, DistanceToV, CeilingVOnScreen, FloorVOnScreen)
    -- print( seg.pRightSector,  seg.pRightSector.CeilingHeight, math.floor(VXScreen))
    local Ceiling = seg.pRightSector.CeilingHeight - self.m_pPlayer:GetZPosition()
    local Floor = seg.pRightSector.FloorHeight - self.m_pPlayer:GetZPosition()

    local VScreenAngle = Angle:new(self.m_ScreenXToAngle[(VXScreen)])

    local DistanceToVScreen = self.m_iDistancePlayerToScreen / math.cos(VScreenAngle.m_Angle * math.pi / 180)

    CeilingVOnScreen = math.abs(Ceiling) * DistanceToVScreen / DistanceToV
    FloorVOnScreen = math.abs(Floor) * DistanceToVScreen / DistanceToV

    if Ceiling > 0 then
        CeilingVOnScreen = self.m_HalfScreenHeight - CeilingVOnScreen
    else
        CeilingVOnScreen = self.m_HalfScreenHeight + CeilingVOnScreen
    end

    if Floor > 0 then
        FloorVOnScreen = self.m_HalfScreenHeight - FloorVOnScreen
    else
        FloorVOnScreen = self.m_HalfScreenHeight + FloorVOnScreen
    end

    return CeilingVOnScreen, FloorVOnScreen
end

function ViewRenderer:PartialSeg(seg, V1Angle, V2Angle, DistanceToV, IsLeftSide)
    --    float SideC = sqrt(pow(seg.pStartVertex->XPosition - seg.pEndVertex->XPosition, 2) + pow(seg.pStartVertex->YPosition - seg.pEndVertex->YPosition, 2));
    local SideC = math.sqrt(math.pow(seg.pStartVertex.x - seg.pEndVertex.x, 2) + math.pow(seg.pStartVertex.y - seg.pEndVertex.y, 2))
    local V1ToV2Span = V1Angle - V2Angle

    local SINEAngleB = DistanceToV * math.sin(V1ToV2Span.m_Angle * math.pi / 180) / SideC

    local AngleB = Angle:new(math.asin(SINEAngleB) * 180 / math.pi)

    local AngleA = Angle:new(180) - V1ToV2Span - AngleB


    local AngleVToFOV
    if IsLeftSide then
        AngleVToFOV = V1Angle - (self.m_pPlayer:GetAngle() + 45)
    else
        AngleVToFOV = (self.m_pPlayer:GetAngle() - 45) - V2Angle

    end

    local newAngB = Angle:new(180-AngleVToFOV.m_Angle - AngleA.m_Angle)
    DistanceToV = DistanceToV * math.sin(AngleA.m_Angle * math.pi / 180) / math.sin(newAngB.m_Angle * math.pi / 180)
    return V1Angle, V2Angle, DistanceToV
end
function ViewRenderer:CalculateWallHeightSimple(seg,  V1XScreen,  V2XScreen,  V1Angle,  V2Angle)
    local DistanceToV1 = self.m_pPlayer:DistanceToPoint(seg.pStartVertex) 
    local DistanceToV2 = self.m_pPlayer:DistanceToPoint(seg.pEndVertex)
    
    if V1XScreen <= 0 then
        V1Angle,V2Angle, DistanceToV1 = self:PartialSeg(seg, V1Angle, V2Angle, DistanceToV1, true);
    end

    if V2XScreen >= 319 then
        V1Angle,V2Angle, DistanceToV2 = self:PartialSeg(seg, V1Angle, V2Angle, DistanceToV2, false);
    end

    local CeilingV1OnScreen, FloorV1OnScreen  =  self:CalculateCeilingFloorHeight(seg, V1XScreen, DistanceToV1)
    local CeilingV2OnScreen, FloorV2OnScreen  =  self:CalculateCeilingFloorHeight(seg, V2XScreen, DistanceToV2)

    local color = self:GetWallColor(seg.pLinedef.pRightSidedef.MiddleTexture)
    self:SetDrawColor(color[1], color[2], color[3], 1)
    
    love.graphics.line(V1XScreen, CeilingV1OnScreen, V1XScreen, FloorV1OnScreen)
    love.graphics.line(V2XScreen, CeilingV2OnScreen, V2XScreen, FloorV2OnScreen)
    love.graphics.line(V1XScreen, CeilingV1OnScreen, V2XScreen, CeilingV2OnScreen)
    love.graphics.line(V1XScreen, FloorV1OnScreen, V2XScreen, FloorV2OnScreen)
end
return ViewRenderer