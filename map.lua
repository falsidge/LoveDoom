local bit32 = bit32 or bit or require("bit32")
local Player = require("player")
SUBSECTORIDENTIFIER = 0x8000
local Things = require('things')
local types = require("datatypes")
local Angle = require('angle')
local dbg = require('debugger')

local Map = {
    m_sName = "",

    m_Vertexes = {},
    m_Sectors = {},
    m_Sidedefs = {},
    m_Linedefs = {},
    m_Nodes = {},
    m_Segs = {},
    m_Subsector = {},

    m_pSidedefs = {},
    m_pLinedefs = {},
    m_pSegs = {},

    m_XMin = 999999,
    m_XMax = 0,
    m_YMin = 999999,
    m_YMax = 0,
    m_iLumpIndex = nil,

    m_iAutoMapScaleFactor = 15,
    m_Things = Things:new(),
    m_Player = nil,
    m_pViewRenderer = nil,
    RenderMap = false
}


function Map:new(o)
    o = o or {} -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

function Map:Init()
    self:BuildSidedefs()
    self:BuildLinedef()
    self:BuildSeg()
end

function Map:BuildSidedefs()
    for i,v in ipairs(self.m_pSidedefs) do
        table.insert(self.m_Sidedefs, types.Sidedef:new({
            XOffset = v.XOffset,
            YOffset = v.YOffset,
            UpperTexture = v.UpperTexture,
            LowerTexture = v.LowerTexture,
            MiddleTexture = v.MiddleTexture,
            pSector = self.m_Sectors[v.SectorID + 1]
        }))
    end
end

function Map:BuildLinedef()
    for i,v in pairs(self.m_pLinedefs) do
        table.insert(self.m_Linedefs, types.Linedef:new({
            pStartVertex = self.m_Vertexes[v.StartVertex + 1],
            pEndVertex = self.m_Vertexes[v.EndVertex + 1],
            Flags = v.Flags,
            LineType = v.LineType,
            SectorTag = v.SectorTag,
            pRightSidedef = v.RightSidedef ~= 0xFFFF and self.m_Sidedefs[v.RightSidedef + 1] or nil,
            pLeftSidedef = v.LeftSidedef ~= 0xFFFF and self.m_Sidedefs[v.LeftSidedef + 1] or nil
        }))
    end
end

function Map:BuildSeg()
    for i,v in pairs(self.m_pSegs) do
        local t = types.Seg:new(
            {
                Direction = v.Direction,
            }
        )
        t.pStartVertex = self.m_Vertexes[v.StartVertexID + 1]
        t.pEndVertex = self.m_Vertexes[v.EndVertexID + 1]

        t.SlopeAngle = Angle:new(bit32.lshift(v.SlopeAngle,16) *  8.38190317e-8)
        t.pLinedef = self.m_Linedefs[v.LinedefID + 1]
        t.Offset = bit32.lshift(v.Offset, 16) / (bit32.lshift(1,16))
        
        local pRightSidedef = t.pLinedef.pRightSidedef
        local pLeftSidedef  = t.pLinedef.pLeftSidedef 

        if (v.Direction ~= 0) then
            pRightSidedef = t.pLinedef.pLeftSidedef
            pLeftSidedef  = t.pLinedef.pRightSidedef
        end
        
        -- print(v.Direction, pLeftSidedef, pRightSidedef)
        if pRightSidedef ~= nil then
            t.pRightSector = pRightSidedef.pSector
        else
            t.pRightSector = nil
        end

        if pLeftSidedef ~= nil then
            t.pLeftSector = pLeftSidedef.pSector
        else
            t.pLeftSector = nil
        end

        table.insert(self.m_Segs, t)
    end
end


function Map:GetName()
    return self.m_sName
end

function Map:GetXMin()
    return self.m_XMin
end

function Map:GetXMax()
    return self.m_XMax
end

function Map:GetYMin()
    return self.m_YMin
end

function Map:GetYMax()
    return self.m_YMax
end


function Map:AddVertex(vertex)
    table.insert(self.m_Vertexes, vertex)
    if vertex.x < self.m_XMin then
        self.m_XMin = vertex.x
    end
    if vertex.x > self.m_XMax then
        self.m_XMax = vertex.x
    end
    if vertex.y < self.m_YMin then
        self.m_YMin = vertex.y
    end
    if vertex.y > self.m_YMax then
        self.m_YMax = vertex.y
    end
end


function Map:RenderAutoMap()
    self.RenderMap = true

    self:RenderAutoMapWalls()
    self:RenderAutoMapPlayer()
    -- self:RenderAutoMapNode()
    self:RenderBSPNodes()

end

function Map:Render3DView()
    self.RenderMap = false
    self:RenderBSPNodes()
end

iRenderYSize = 199
function Map:RemapXToScreen(XMapPosition)
    return (XMapPosition + -self.m_XMin) / self.m_iAutoMapScaleFactor
end

function Map:RemapYToScreen(YMapPosition)
    return iRenderYSize - (YMapPosition + -self.m_YMin) / self.m_iAutoMapScaleFactor
end

function Map:RenderAutoMapWalls()
    love.graphics.setColor(1, 1, 1, 1)
    -- print(#self.m_Linedefs)
    for i, linedef in ipairs(self.m_Linedefs) do
        local vStart = linedef.pStartVertex
        local vEnd = linedef.pEndVertex
        -- print(startVertex.x, startVertex.y, endVertex.x, endVertex.y)
        -- love.graphics.line(self:RemapXToScreen(startVertex.x),
        --     self:RemapYToScreen(startVertex.y),
        --     self:RemapXToScreen(endVertex.x),
        --     self:RemapYToScreen(endVertex.y))
        self.m_pViewRenderer:DrawLine(vStart.x,
            vStart.y,
            vEnd.x,
            vEnd.y)
    end
end

function Map:RenderAutoMapPlayer()
    -- print("render player", (self.m_Player:GetXPosition() + iXShift)/self.m_iAutoMapScaleFactor,
    -- iRenderYSize - (self.m_Player:GetYPosition() + iYShift)/self.m_iAutoMapScaleFactor, self.m_Player:GetID())
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.circle("fill", self:RemapXToScreen(self.m_Player:GetXPosition()),
        self:RemapYToScreen(self.m_Player:GetYPosition()), 3)
end

function Map:RenderAutoMapNode(iNodeID)
    local node = self.m_Nodes[iNodeID+1]
    -- print(self.m_Nodes[1])
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.rectangle("line",
        self:RemapXToScreen(node.RightBoxLeft),
        self:RemapYToScreen(node.RightBoxTop),
        self:RemapXToScreen(node.RightBoxRight) - self:RemapXToScreen(node.RightBoxLeft) + 1,
        self:RemapYToScreen(node.RightBoxBottom) - self:RemapYToScreen(node.RightBoxTop) + 1
    )
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("line",
        self:RemapXToScreen(node.LeftBoxLeft),
        self:RemapYToScreen(node.LeftBoxTop),
        self:RemapXToScreen(node.LeftBoxRight) - self:RemapXToScreen(node.LeftBoxLeft) + 1,
        self:RemapYToScreen(node.LeftBoxBottom) - self:RemapYToScreen(node.LeftBoxTop) + 1
    )
    love.graphics.setColor(0, 0, 1, 1)
    print( node.XPartition, node.YPartition)
    love.graphics.line(self:RemapXToScreen(node.XPartition),
        self:RemapYToScreen(node.YPartition),
        self:RemapXToScreen(node.XPartition + node.ChangeXPartition)+1,
        self:RemapYToScreen(node.YPartition + node.ChangeYPartition)+1)
end

function Map:AddThing(thing)
    if thing.Type == self.m_Player:GetID() then
        self.m_Player:SetXPosition(thing.x)
        self.m_Player:SetYPosition(thing.y)
        self.m_Player:SetAngle(thing.Angle)
    end
    table.insert(self.m_Things, thing)
end

function Map:SetLumpIndex(iLumpIndex)
    self.m_iLumpIndex = iLumpIndex
end

function Map:GetLumpIndex()
    return self.m_iLumpIndex
end


function Map:IsPointOnLeftSide(XPosition, YPosition, iNodeID)
    local dx = XPosition - self.m_Nodes[iNodeID+1].XPartition
    local dy = YPosition - self.m_Nodes[iNodeID+1].YPartition
    
    return (dx* self.m_Nodes[iNodeID+1].ChangeYPartition - dy * self.m_Nodes[iNodeID+1].ChangeXPartition) <= 0
end

function Map:RenderBSPNodes(iNodeID)
    if iNodeID == nil then
        self:RenderBSPNodes(#self.m_Nodes-1)
        return
    end
    if bit32.band(iNodeID, SUBSECTORIDENTIFIER) ~= 0 then
        self:RenderSubSector(bit32.band(iNodeID, bit32.bnot(SUBSECTORIDENTIFIER)))
        return;
    end
    if self:IsPointOnLeftSide(self.m_Player:GetXPosition(), self.m_Player:GetYPosition(), iNodeID) then
        self:RenderBSPNodes(self.m_Nodes[iNodeID+1].LeftChildID)
        self:RenderBSPNodes(self.m_Nodes[iNodeID+1].RightChildID)
    else    
        self:RenderBSPNodes(self.m_Nodes[iNodeID+1].RightChildID)
        self:RenderBSPNodes(self.m_Nodes[iNodeID+1].LeftChildID)
    end
end


function Map:RenderSubSector(iSubsectorID)
    local subsector = self.m_Subsector[iSubsectorID+1]
    for i = 1, subsector.SegCount do
        local seg = self.m_Segs[subsector.FirstSegID + i]
        local pass, V1Angle, V2Angle, V1AngleFromPlayer, V2AngleFromPlayer  = self.m_Player:ClipVertexInFOV(seg.pStartVertex, seg.pEndVertex)
        if pass == true then
            if self.RenderMap then
                self.m_pViewRenderer:SetDrawColor(unpack(self.m_pViewRenderer:GetWallColor(seg)))
                self.m_pViewRenderer:DrawLine(seg.pStartVertex.x,
       seg.pStartVertex.y,
                seg.pEndVertex.x,
                seg.pEndVertex.y)
            else
                -- dbg()
                self.m_pViewRenderer:AddWallInFOV(seg, V1Angle, V2Angle, V1AngleFromPlayer, V2AngleFromPlayer)
            end
        end
    end
end



function Map:AddSidedef(sidedef)
    table.insert(self.m_pSidedefs, sidedef)
end

function Map:AddSector(sector)
    table.insert(self.m_Sectors, sector)
end


function Map:AddLineDef(linedef)
    table.insert(self.m_pLinedefs, linedef)
end

function Map:AddNode(node)
    table.insert(self.m_Nodes, node)
end

function Map:AddSubsector(subsector)
    table.insert(self.m_Subsector, subsector)
end

function Map:AddSeg(seg)
    table.insert(self.m_pSegs, seg)
end

function Map:GetThings()
    return self.m_Things
end

return Map
