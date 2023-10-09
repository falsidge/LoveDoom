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
    m_iDistancePlayerToScreen = 0,
    m_UseClassicDoomScreenToAngle = true,
    m_FloorClipHeight = {},
    m_CeilingClipHeight = {},
}

local SegmentRenderData = {
    V1XScreen = 0,
    V2XScreen = 0,
    V1Angle = Angle:new(),
    V2Angle = Angle:new(),
    DistanceToV1 = 0,
    DistanceToNormal = 0,
    V1ScaleFactor = 0,
    V2ScaleFactor = 0,
    Steps = 0,

    RightSectorCeiling = 0,
    RightSectorFloor = 0,
    CeilingStep = 0,
    CeilingEnd = 0,
    FloorStep = 0,
    FloorStart = 0,

    LeftSectorCeiling = 0,
    LeftSectorFloor = 0,

    bDrawUpperSection = false,
    bDrawLowerSection = false,


    UpperHeightStep = 0,
    iUpperHeight = 0,
    LowerHeightStep = 0,
    iLowerHeight = 0,

    UpdateFloor = false,
    UpdateCeiling = false,

    pSeg = nil,
}

function SegmentRenderData:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end



local classicDoomScreenXtoView = {
    45.043945, 44.824219, 44.648437, 44.472656, 44.296875, 44.121094, 43.945312, 43.725586, 43.549805, 43.374023,
    43.154297, 42.978516, 42.802734, 42.583008, 42.407227, 42.187500, 42.011719, 41.791992, 41.616211, 41.396484,
    41.220703, 41.000977, 40.781250, 40.605469, 40.385742, 40.166016, 39.946289, 39.770508, 39.550781, 39.331055,
    39.111328, 38.891602, 38.671875, 38.452148, 38.232422, 38.012695, 37.792969, 37.573242, 37.353516, 37.133789,
    36.870117, 36.650391, 36.430664, 36.210937, 35.947266, 35.727539, 35.507812, 35.244141, 35.024414, 34.760742,
    34.541016, 34.277344, 34.057617, 33.793945, 33.530273, 33.310547, 33.046875, 32.783203, 32.519531, 32.299805,
    32.036133, 31.772461, 31.508789, 31.245117, 30.981445, 30.717773, 30.454102, 30.190430, 29.926758, 29.663086,
    29.355469, 29.091797, 28.828125, 28.564453, 28.256836, 27.993164, 27.729492, 27.421875, 27.158203, 26.850586,
    26.586914, 26.279297, 26.015625, 25.708008, 25.444336, 25.136719, 24.829102, 24.521484, 24.257812, 23.950195,
    23.642578, 23.334961, 23.027344, 22.719727, 22.412109, 22.104492, 21.796875, 21.489258, 21.181641, 20.874023,
    20.566406, 20.258789, 19.951172, 19.643555, 19.291992, 18.984375, 18.676758, 18.325195, 18.017578, 17.709961,
    17.358398, 17.050781, 16.699219, 16.391602, 16.040039, 15.732422, 15.380859, 15.073242, 14.721680, 14.370117,
    14.062500, 13.710937, 13.359375, 13.051758, 12.700195, 12.348633, 11.997070, 11.645508, 11.337891, 10.986328,
    10.634766, 10.283203, 9.931641, 9.580078, 9.228516, 8.876953, 8.525391, 8.173828, 7.822266, 7.470703, 7.119141,
    6.767578, 6.416016, 6.064453, 5.712891, 5.361328, 5.009766, 4.658203, 4.306641, 3.955078, 3.559570, 3.208008,
    2.856445, 2.504883, 2.153320, 1.801758, 1.450195, 1.054687, 0.703125, 0.351562, 0.000000, 359.648437, 359.296875,
    358.945312, 358.549805, 358.198242, 357.846680, 357.495117, 357.143555, 356.791992, 356.440430, 356.044922,
    355.693359, 355.341797, 354.990234, 354.638672, 354.287109, 353.935547, 353.583984, 353.232422, 352.880859,
    352.529297,
    352.177734, 351.826172, 351.474609, 351.123047, 350.771484, 350.419922, 350.068359, 349.716797, 349.365234,
    349.013672, 348.662109, 348.354492, 348.002930, 347.651367, 347.299805, 346.948242, 346.640625, 346.289062,
    345.937500,
    345.629883, 345.278320, 344.926758, 344.619141, 344.267578, 343.959961, 343.608398, 343.300781, 342.949219,
    342.641601, 342.290039, 341.982422, 341.674805, 341.323242, 341.015625, 340.708008, 340.356445, 340.048828,
    339.741211,
    339.433594, 339.125977, 338.818359, 338.510742, 338.203125, 337.895508, 337.587891, 337.280273, 336.972656,
    336.665039, 336.357422, 336.049805, 335.742187, 335.478516, 335.170898, 334.863281, 334.555664, 334.291992,
    333.984375,
    333.720703, 333.413086, 333.149414, 332.841797, 332.578125, 332.270508, 332.006836, 331.743164, 331.435547,
    331.171875, 330.908203, 330.644531, 330.336914, 330.073242, 329.809570, 329.545898, 329.282227, 329.018555,
    328.754883,
    328.491211, 328.227539, 327.963867, 327.700195, 327.480469, 327.216797, 326.953125, 326.689453, 326.469727,
    326.206055, 325.942383, 325.722656, 325.458984, 325.239258, 324.975586, 324.755859, 324.492187, 324.272461,
    324.052734,
    323.789062, 323.569336, 323.349609, 323.129883, 322.866211, 322.646484, 322.426758, 322.207031, 321.987305,
    321.767578, 321.547852, 321.328125, 321.108398, 320.888672, 320.668945, 320.449219, 320.229492, 320.053711,
    319.833984,
    319.614258, 319.394531, 319.218750, 318.999023, 318.779297, 318.603516, 318.383789, 318.208008, 317.988281,
    317.812500, 317.592773, 317.416992, 317.197266, 317.021484, 316.845703, 316.625977, 316.450195, 316.274414,
    316.054687,
    315.878906, 315.703125, 315.527344, 315.351562, 315.175781, 314.956055 }

function ViewRenderer:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

iRenderXSize = 320
iRenderYSize = 200

function ViewRenderer:Init(pMap, pPlayer)
    self.m_pMap                    = pMap
    self.m_pPlayer                 = pPlayer
    self.m_HalfScreenWidth         = iRenderXSize / 2
    self.m_HalfScreenHeight        = iRenderYSize / 2
    local HalfFOV                  = self.m_pPlayer.m_FOV / 2
    self.m_iDistancePlayerToScreen = math.floor(self.m_HalfScreenWidth / math.tan(HalfFOV.m_Angle * math.pi / 180) + 0.5)

    for i = 0, iRenderXSize do
        if self.m_UseClassicDoomScreenToAngle then
            self.m_ScreenXToAngle[i] = Angle:new(classicDoomScreenXtoView[i + 1])
        else
            self.m_ScreenXToAngle[i] = math.atan((self.m_HalfScreenWidth - i) / self.m_iDistancePlayerToScreen) * 180 /
            math.pi
        end
        self.m_CeilingClipHeight[i] = -1
        self.m_FloorClipHeight[i] = iRenderYSize
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
    love.graphics.clear(0, 0, 0, 1)
    -- self.m_SolidWallRanges = {}

    WallLeftSide = types.SolidSegmentRange:new({ XStart = -999999, XEnd = -1 })
    WallRightSide = types.SolidSegmentRange:new({ XStart = iRenderXSize, XEnd = 999999 })
    self.m_SolidWallRanges = { WallLeftSide, WallRightSide }
    for i = 0, iRenderXSize do
        self.m_CeilingClipHeight[i] = -1
        self.m_FloorClipHeight[i] = iRenderYSize
    end
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
    if (seg.pLeftSector.CeilingHeight <= seg.pRightSector.FloorHeight
    or seg.pLeftSector.FloorHeight >= seg.pRightSector.CeilingHeight) then
        return self:ClipSolidWalls(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
    end
    if (seg.pRightSector.CeilingHeight ~= seg.pLeftSector.CeilingHeight or
            seg.pRightSector.FloorHeight ~= seg.pLeftSector.FloorHeight) then
        return self:ClipPassWalls(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
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
        iX = self.m_iDistancePlayerToScreen - math.tan(angle.m_Angle * math.pi / 180) * self.m_HalfScreenWidth
    else
        angle = 90 - angle
        iX = math.tan(angle.m_Angle * math.pi / 180) * self.m_HalfScreenWidth
        iX = iX + self.m_iDistancePlayerToScreen
    end

    return math.floor(iX + 0.5)
end

function ViewRenderer:SetDrawColor(r, g, b, a)
    if a == nil then
        a = 1
    end
    love.graphics.setColor(r, g, b, a)
end

function ViewRenderer:DrawRect(x1, y1, x2, y2)
    love.graphics.rectangle('line', self:RemapXToScreen(x1), self:RemapYToScreen(y1),
        self:RemapXToScreen(x2) - self:RemapXToScreen(x1) + 1, self:RemapYToScreen(y2) - self:RemapXToScreen(y1) + 1)
end

function ViewRenderer:DrawLine(x1, y1, x2, y2)
    love.graphics.line(self:RemapXToScreen(x1), self:RemapYToScreen(y1), self:RemapXToScreen(x2), self:RemapYToScreen(y2))
end

function ViewRenderer:ClipSolidWalls(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
    if #self.m_SolidWallRanges < 2 then
        return
    end
    local CurrentWall = { XStart = V1XScreen, XEnd = V2XScreen }
    local FoundClipWall = self.m_SolidWallRanges[1]
    local FoundClipWallInd = 1

    -- for i,v in ipairs(self.m_SolidWallRanges) do
    --     if v.XEnd >= CurrentWall.XStart - 1 then
    --         break
    --     end

    --     FoundClipWall = v
    --     FoundClipWallInd = i
    -- end
    while FoundClipWallInd <= #self.m_SolidWallRanges and FoundClipWall.XEnd < CurrentWall.XStart - 1 do
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
    if self.m_SolidWallRanges[NextWallInd + 1] == nil then
        -- dbg()
        return
    end
    while CurrentWall.XEnd >= self.m_SolidWallRanges[NextWallInd + 1].XStart - 1 do
        self:StoreWallRange(seg, self.m_SolidWallRanges[NextWallInd].XEnd + 1,
            self.m_SolidWallRanges[NextWallInd + 1].XStart - 1, V1Angle, V2Angle)
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
        if self.m_SolidWallRanges[NextWallInd + 1] == nil then
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
function ViewRenderer:ClipPassWalls(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
    if #self.m_SolidWallRanges < 2 then
        return
    end
    local CurrentWall = { XStart = V1XScreen, XEnd = V2XScreen }
    local FoundClipWall = self.m_SolidWallRanges[1]
    local FoundClipWallInd = 1

    -- for i,v in ipairs(self.m_SolidWallRanges) do
    --     if v.XEnd >= CurrentWall.XStart - 1 then
    --         break
    --     end

    --     FoundClipWall = v
    --     FoundClipWallInd = i
    -- end
    while FoundClipWallInd <= #self.m_SolidWallRanges and FoundClipWall.XEnd < CurrentWall.XStart - 1 do
        FoundClipWallInd = FoundClipWallInd + 1
        FoundClipWall = self.m_SolidWallRanges[FoundClipWallInd]
    end
    -- print(CurrentWall.XStart, FoundClipWall.XEnd )
    if CurrentWall.XStart < FoundClipWall.XStart then
        if (CurrentWall.XEnd < FoundClipWall.XStart - 1) then
            self:StoreWallRange(seg, CurrentWall.XStart, CurrentWall.XEnd, V1Angle, V2Angle)
            -- table.insert(self.m_SolidWallRanges, FoundClipWallInd, CurrentWall)
            return
        end
        self:StoreWallRange(seg, CurrentWall.XStart, FoundClipWall.XStart - 1, V1Angle, V2Angle)
        -- self.m_SolidWallRanges[FoundClipWallInd].XStart = CurrentWall.XStart
    end
    if CurrentWall.XEnd <= FoundClipWall.XEnd then
        return
    end

    local NextWallInd = FoundClipWallInd

    -- print(NextWallInd, #self.m_SolidWallRanges)
    if self.m_SolidWallRanges[NextWallInd + 1] == nil then
        -- dbg()
        return
    end
    while CurrentWall.XEnd >= self.m_SolidWallRanges[NextWallInd + 1].XStart - 1 do
        self:StoreWallRange(seg, self.m_SolidWallRanges[NextWallInd].XEnd + 1,
            self.m_SolidWallRanges[NextWallInd + 1].XStart - 1, V1Angle, V2Angle)
        NextWallInd = NextWallInd + 1
        if CurrentWall.XEnd <= self.m_SolidWallRanges[NextWallInd].XEnd then
            return
        end
        if self.m_SolidWallRanges[NextWallInd + 1] == nil then
            -- dbg()
            return
        end
    end
    self:StoreWallRange(seg, self.m_SolidWallRanges[NextWallInd].XEnd + 1, CurrentWall.XEnd, V1Angle, V2Angle)

end
function ViewRenderer:GetWallColor(textureName)
    if self.m_WallColor[textureName] == nil then
        local r = math.random()
        local g = math.random()
        local b = math.random()
        self.m_WallColor[textureName] = { r, g, b }
        return self.m_WallColor[textureName]
    end
    return self.m_WallColor[textureName]
end

function ViewRenderer:StoreWallRange(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
    self:CalculateWallHeight(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
    -- self:CalculateWallHeightSimple(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
end

function ViewRenderer:DrawSolidWall(visibleSeg)
    local color = self:GetWallColor(visibleSeg.seg.pLinedef.pRightSidedef.MiddleTexture)
    self:SetDrawColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle('line', visibleSeg.XStart, 0, visibleSeg.XEnd - visibleSeg.XStart + 1, iRenderYSize)
end

function ViewRenderer:CalculateCeilingFloorHeight(seg, VXScreen, DistanceToV, CeilingVOnScreen, FloorVOnScreen)
    -- print( seg.pRightSector,  seg.pRightSector.CeilingHeight, math.floor(VXScreen))
    local Ceiling = seg.pRightSector.CeilingHeight - self.m_pPlayer:GetZPosition()
    local Floor = seg.pRightSector.FloorHeight - self.m_pPlayer:GetZPosition()

    local VScreenAngle = self.m_ScreenXToAngle[(VXScreen)]

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
    local SideC = math.sqrt(math.pow(seg.pStartVertex.x - seg.pEndVertex.x, 2) +
    math.pow(seg.pStartVertex.y - seg.pEndVertex.y, 2))
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

    local newAngB = Angle:new(180 - AngleVToFOV.m_Angle - AngleA.m_Angle)
    DistanceToV = DistanceToV * math.sin(AngleA.m_Angle * math.pi / 180) / math.sin(newAngB.m_Angle * math.pi / 180)
    return V1Angle, V2Angle, DistanceToV
end

function ViewRenderer:CalculateWallHeightSimple(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
    local DistanceToV1 = self.m_pPlayer:DistanceToPoint(seg.pStartVertex)
    local DistanceToV2 = self.m_pPlayer:DistanceToPoint(seg.pEndVertex)

    if V1XScreen <= 0 then
        V1Angle, V2Angle, DistanceToV1 = self:PartialSeg(seg, V1Angle, V2Angle, DistanceToV1, true);
    end

    if V2XScreen >= 319 then
        V1Angle, V2Angle, DistanceToV2 = self:PartialSeg(seg, V1Angle, V2Angle, DistanceToV2, false);
    end

    local CeilingV1OnScreen, FloorV1OnScreen = self:CalculateCeilingFloorHeight(seg, V1XScreen, DistanceToV1)
    local CeilingV2OnScreen, FloorV2OnScreen = self:CalculateCeilingFloorHeight(seg, V2XScreen, DistanceToV2)

    -- local color = self:GetWallColor(seg.pLinedef.pRightSidedef.MiddleTexture)
    -- self:SetDrawColor(color[1], color[2], color[3], 1)
    self:SetDrawColor(255, 255, 255, 1)

    love.graphics.line(V1XScreen, CeilingV1OnScreen, V1XScreen, FloorV1OnScreen)
    love.graphics.line(V2XScreen, CeilingV2OnScreen, V2XScreen, FloorV2OnScreen)
    love.graphics.line(V1XScreen, CeilingV1OnScreen, V2XScreen, CeilingV2OnScreen)
    love.graphics.line(V1XScreen, FloorV1OnScreen, V2XScreen, FloorV2OnScreen)
end

-- function ViewRenderer:CalculateWallHeight(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
--     local Angle90 = Angle:new(90)
--     local SegToNormalAngle = seg.SlopeAngle + Angle90

--     local NomalToV1Angle = SegToNormalAngle - V1Angle

--     local SegToPlayerAngle = Angle90 - NomalToV1Angle

--     local DistanceToV1 = self.m_pPlayer:DistanceToPoint(seg.pStartVertex)
--     local DistanceToNormal = math.sin(math.rad(SegToPlayerAngle.m_Angle)) * DistanceToV1

--     local V1ScaleFactor = self:GetScaleFactor(V1XScreen, SegToNormalAngle, DistanceToNormal);
--     local V2ScaleFactor = self:GetScaleFactor(V2XScreen, SegToNormalAngle, DistanceToNormal);

--     local Steps = (V2ScaleFactor - V1ScaleFactor) / (V2XScreen - V1XScreen)

--     local Ceiling = seg.pRightSector.CeilingHeight - self.m_pPlayer:GetZPosition()
--     local Floor = seg.pRightSector.FloorHeight - self.m_pPlayer:GetZPosition()


--     local CeilingStep = -(Ceiling * Steps)
--     local CeilingEnd = self.m_HalfScreenHeight - (Ceiling * V1ScaleFactor)


--     local FloorStep = -(Floor * Steps)
--     local FloorStart = self.m_HalfScreenHeight - (Floor * V1ScaleFactor)

--     local color = self:GetWallColor(seg.pLinedef.pRightSidedef.MiddleTexture)
--     self:SetDrawColor(color[1], color[2], color[3], 1)

--     local iXCurrent = V1XScreen
--     while iXCurrent <= V2XScreen do
--         love.graphics.line(iXCurrent, CeilingEnd, iXCurrent, FloorStart)
--         iXCurrent = iXCurrent + 1
--         CeilingEnd = CeilingEnd + CeilingStep
--         FloorStart = FloorStart + FloorStep
--     end
-- end

function ViewRenderer:CalculateWallHeight(seg, V1XScreen, V2XScreen, V1Angle, V2Angle)
    local Angle90 = Angle:new(90)
    local RenderData = SegmentRenderData:new()

    local SegToNormalAngle = seg.SlopeAngle + Angle90

    local NomalToV1Angle = SegToNormalAngle - V1Angle

    local SegToPlayerAngle = Angle90 - NomalToV1Angle

    RenderData.V1XScreen = V1XScreen
    RenderData.V2XScreen = V2XScreen
    RenderData.V1Angle = V1Angle
    RenderData.V2Angle = V2Angle

    local DistanceToV1 = self.m_pPlayer:DistanceToPoint(seg.pStartVertex)
    RenderData.DistanceToV1 = DistanceToV1

    local DistanceToNormal = math.sin(math.rad(SegToPlayerAngle.m_Angle)) * DistanceToV1
    RenderData.DistanceToNormal = DistanceToNormal

    local V1ScaleFactor = self:GetScaleFactor(V1XScreen, SegToNormalAngle, DistanceToNormal);
    local V2ScaleFactor = self:GetScaleFactor(V2XScreen, SegToNormalAngle, DistanceToNormal);

    RenderData.V1ScaleFactor = V1ScaleFactor
    RenderData.V2ScaleFactor = V2ScaleFactor

    local Steps = (V2ScaleFactor - V1ScaleFactor) / (V2XScreen - V1XScreen)
    RenderData.Steps = Steps

    local Ceiling = seg.pRightSector.CeilingHeight - self.m_pPlayer:GetZPosition()
    local Floor = seg.pRightSector.FloorHeight - self.m_pPlayer:GetZPosition()

    RenderData.RightSectorCeiling = Ceiling
    RenderData.RightSectorFloor = Floor

    local CeilingStep = -(Ceiling * Steps)
    local CeilingEnd = self.m_HalfScreenHeight - (Ceiling * V1ScaleFactor)

    RenderData.CeilingStep = CeilingStep
    RenderData.CeilingEnd = CeilingEnd

    local FloorStep = -(Floor * Steps)
    local FloorStart = self.m_HalfScreenHeight - (Floor * V1ScaleFactor)

    RenderData.FloorStep = FloorStep
    RenderData.FloorStart = FloorStart


    RenderData.pSeg = seg

    if seg.pLeftSector then
        RenderData.LeftSectorCeiling = seg.pLeftSector.CeilingHeight - self.m_pPlayer:GetZPosition();
        RenderData.LeftSectorFloor = seg.pLeftSector.FloorHeight - self.m_pPlayer:GetZPosition();
        self:CeilingFloorUpdate(RenderData);

        if (RenderData.LeftSectorCeiling < RenderData.RightSectorCeiling) then
            RenderData.bDrawUpperSection = true
            RenderData.UpperHeightStep = -(RenderData.LeftSectorCeiling * RenderData.Steps);
            RenderData.iUpperHeight = math.floor(0.5+self.m_HalfScreenHeight - (RenderData.LeftSectorCeiling * RenderData.V1ScaleFactor));

        end
        if (RenderData.LeftSectorFloor > RenderData.RightSectorFloor) then
            RenderData.bDrawLowerSection = true
            RenderData.LowerHeightStep = -(RenderData.LeftSectorFloor * RenderData.Steps);
            RenderData.iLowerHeight = math.floor(self.m_HalfScreenHeight+0.5 - (RenderData.LeftSectorFloor * RenderData.V1ScaleFactor));
        end
    end
    self:RenderSegment(RenderData)
    -- local color = self:GetWallColor(seg.pLinedef.pRightSidedef.MiddleTexture)
    -- self:SetDrawColor(color[1], color[2], color[3], 1)

    -- local iXCurrent = V1XScreen
    -- while iXCurrent <= V2XScreen do
    --     love.graphics.line(iXCurrent, CeilingEnd, iXCurrent, FloorStart)
    --     iXCurrent = iXCurrent + 1
    --     CeilingEnd = CeilingEnd + CeilingStep
    --     FloorStart = FloorStart + FloorStep
    -- end
end
function ViewRenderer:CeilingFloorUpdate(RenderData)
    if not RenderData.pSeg.pLeftSector then
        RenderData.UpdateFloor = true
        RenderData.UpdateCeiling = true
        return
    end

    if RenderData.LeftSectorCeiling ~= RenderData.RightSectorCeiling then
        RenderData.UpdateCeiling = true
    else
        RenderData.UpdateCeiling = false
    end

    if RenderData.LeftSectorFloor ~= RenderData.RightSectorFloor then
        RenderData.UpdateFloor = true
    else
        RenderData.UpdateFloor = false
    end

    if RenderData.pSeg.pLeftSector.CeilingHeight <= RenderData.pSeg.pRightSector.FloorHeight or RenderData.pSeg.pLeftSector.FloorHeight >= RenderData.pSeg.pRightSector.CeilingHeight then
        -- closed door
        RenderData.UpdateCeiling = true
        RenderData.UpdateFloor = true
    end

    if RenderData.pSeg.pRightSector.CeilingHeight <= self.m_pPlayer:GetZPosition() then
        -- below view plane
        RenderData.UpdateCeiling = false
    end

    if RenderData.pSeg.pRightSector.FloorHeight >= self.m_pPlayer:GetZPosition() then
        -- above view plane
        RenderData.UpdateFloor = false
    end
end
function ViewRenderer:SelectColor(seg, color)
    if seg.pLeftSector ~= nil then
        color = self:GetWallColor(seg.pLinedef.pLeftSidedef.MiddleTexture)
        self:SetDrawColor(unpack(color))
        return color
    else
        
        color = self:GetWallColor(seg.pLinedef.pRightSidedef.MiddleTexture)
        self:SetDrawColor(unpack(color))
        return color
    end
end

function ViewRenderer:GetScaleFactor(VXScreen, SegToNormalAngle, DistanceToNormal)
    local MAX_SCALEFACTOR = 64.0
    local MIN_SCALEFACTOR = 0.00390625

    local Angle90 = Angle:new(90)

    local ScreenXAngle = self.m_ScreenXToAngle[VXScreen]
    local SkewAngle = self.m_ScreenXToAngle[VXScreen] + self.m_pPlayer:GetAngle() - SegToNormalAngle

    local ScreenXAngleCos = math.cos(math.rad(ScreenXAngle.m_Angle))
    local SkewAngleCos = math.cos(math.rad(SkewAngle.m_Angle))

    local ScaleFactor = (self.m_iDistancePlayerToScreen * SkewAngleCos) / (DistanceToNormal * ScreenXAngleCos)

    if ScaleFactor > MAX_SCALEFACTOR then
        ScaleFactor = MAX_SCALEFACTOR
    elseif ScaleFactor < MIN_SCALEFACTOR then
        ScaleFactor = MIN_SCALEFACTOR
    end
    return ScaleFactor
end

function ViewRenderer:RenderSegment(RenderData)
    
    local iXCurrent = RenderData.V1XScreen

    local color = self:SelectColor(RenderData.pSeg, nil)
    while (iXCurrent <= RenderData.V2XScreen) do
        local pass, CurrentCeilingEnd, CurrentFloorStart = self:ValidateRange(RenderData, iXCurrent, RenderData.CeilingEnd, RenderData.FloorStart)
        if pass then
           if (RenderData.pSeg.pLeftSector ~= nil) then
                self:DrawUpperSection(RenderData, iXCurrent, CurrentCeilingEnd)
                self:DrawLowerSection(RenderData, iXCurrent, CurrentFloorStart)
           else
                self:DrawMiddleSection(RenderData, iXCurrent, CurrentCeilingEnd, CurrentFloorStart)
           end
           RenderData.CeilingEnd = RenderData.CeilingEnd + RenderData.CeilingStep;
           RenderData.FloorStart = RenderData.FloorStart + RenderData.FloorStep;
        end
        iXCurrent = iXCurrent + 1;
    end
end

function ViewRenderer:ValidateRange(RenderData, iXCurrent, CurrentCeilingEnd, CurrentFloorStart)
    if (CurrentCeilingEnd < self.m_CeilingClipHeight[iXCurrent]) then
        CurrentCeilingEnd = self.m_CeilingClipHeight[iXCurrent];
    end

    if (CurrentFloorStart >= self.m_FloorClipHeight[iXCurrent]) then
        CurrentFloorStart = self.m_FloorClipHeight[iXCurrent];
    end

    if (CurrentCeilingEnd > CurrentFloorStart) then
        RenderData.CeilingEnd = RenderData.CeilingEnd + RenderData.CeilingStep;
        RenderData.FloorStart = RenderData.FloorStart + RenderData.FloorStep;
        return false, CurrentCeilingEnd, CurrentFloorStart
    end
    return true, CurrentCeilingEnd, CurrentFloorStart
end

function ViewRenderer:DrawUpperSection(RenderData, iXCurrent, CurrentCeilingEnd)
    if (RenderData.bDrawUpperSection) then
        local iUpperHeight = RenderData.iUpperHeight
        RenderData.iUpperHeight = RenderData.iUpperHeight + RenderData.UpperHeightStep

        if (iUpperHeight >= self.m_FloorClipHeight[iXCurrent]) then
            iUpperHeight = self.m_FloorClipHeight[iXCurrent]
        end

        if (iUpperHeight >= CurrentCeilingEnd) then
            love.graphics.line(iXCurrent, CurrentCeilingEnd, iXCurrent, iUpperHeight)
            self.m_CeilingClipHeight[iXCurrent] = iUpperHeight
        else
            self.m_CeilingClipHeight[iXCurrent] = CurrentCeilingEnd - 1
        end
    elseif RenderData.UpdateCeiling then
        self.m_CeilingClipHeight[iXCurrent] = CurrentCeilingEnd - 1
    end
end
function ViewRenderer:DrawLowerSection(RenderData, iXCurrent, CurrentFloorStart)
    if (RenderData.bDrawLowerSection) then
        local iLowerHeight = RenderData.iLowerHeight
        RenderData.iLowerHeight = RenderData.iLowerHeight + RenderData.LowerHeightStep

        if (iLowerHeight <= self.m_CeilingClipHeight[iXCurrent]) then
            iLowerHeight = self.m_CeilingClipHeight[iXCurrent]
        end

        if (iLowerHeight <= CurrentFloorStart) then
            love.graphics.line(iXCurrent, iLowerHeight, iXCurrent, CurrentFloorStart)
            self.m_FloorClipHeight[iXCurrent] = iLowerHeight
        else
            self.m_FloorClipHeight[iXCurrent] = CurrentFloorStart + 1
        end
    elseif RenderData.UpdateFloor then
        self.m_FloorClipHeight[iXCurrent] = CurrentFloorStart + 1
    end
end

function ViewRenderer:DrawMiddleSection(RenderData, iXCurrent, CurrentCeilingEnd, CurrentFloorStart)
    love.graphics.line(iXCurrent, CurrentCeilingEnd, iXCurrent, CurrentFloorStart)
    self.m_CeilingClipHeight[iXCurrent] = iRenderYSize
    self.m_FloorClipHeight[iXCurrent] = -1
end

return ViewRenderer
