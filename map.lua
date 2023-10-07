local bit32 = bit32 or bit or require("bit32")
local Player = require("player")
SUBSECTORIDENTIFIER = 0x8000


local Map = {
    m_Vertexes = {},
    m_Linedefs = {},
    m_Nodes = {},
    m_Segs = {},
    m_Subsector = {},
    m_sName = "",
    m_XMin = 999999,
    m_XMax = 0,
    m_YMin = 999999,
    m_YMax = 0,
    m_iAutoMapScaleFactor = 15,
    m_Things = {},
    m_Player = nil,
    m_iLumpIndex = nil,
    m_pViewRenderer = nil
}


function Map:new(o)
    o = o or {} -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
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

function Map:AddLineDef(linedef)
    table.insert(self.m_Linedefs, linedef)
end


function Map:RenderAutoMap()

    self:RenderAutoMapWalls()
    self:RenderAutoMapPlayer()
    -- self:RenderAutoMapNode()
    self:RenderBSPNodes()

end

function Map:Render3DView()
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
        local iStartVertex = linedef.StartVertex
        local iEndVertex = linedef.EndVertex
        local startVertex = self.m_Vertexes[iStartVertex + 1]
        local endVertex = self.m_Vertexes[iEndVertex + 1]
        -- print(startVertex.x, startVertex.y, endVertex.x, endVertex.y)
        -- love.graphics.line(self:RemapXToScreen(startVertex.x),
        --     self:RemapYToScreen(startVertex.y),
        --     self:RemapXToScreen(endVertex.x),
        --     self:RemapYToScreen(endVertex.y))
        self.m_pViewRenderer:DrawLine(startVertex.x,
            startVertex.y,
            endVertex.x,
            endVertex.y)
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

function Map:AddNode(node)
    table.insert(self.m_Nodes, node)
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
    love.graphics.setColor(math.random(), math.random(), math.random(), 1)
    for i = 1, subsector.SegCount do
        local seg = self.m_Segs[subsector.FirstSegID + i]
        local startVertex = self.m_Vertexes[seg.StartVertexID + 1]
        local endVertex = self.m_Vertexes[seg.EndVertexID + 1]
        local pass, V1Angle, V2Angle = self.m_Player:ClipVertexInFOV(startVertex, endVertex, Angle:new(),Angle:new())
        if pass then
            -- love.graphics.line(self:RemapXToScreen(startVertex.x),
            --     self:RemapYToScreen(startVertex.y),
            --     self:RemapXToScreen(endVertex.x),
            --     self:RemapYToScreen(endVertex.y))
            self.m_pViewRenderer:AddWallInFOV(seg, V1Angle, V2Angle)
        end
    end
end

function Map:AddSubsector(subsector)
    table.insert(self.m_Subsector, subsector)
end

function Map:AddSeg(seg)
    table.insert(self.m_Segs, seg)
end

return Map
