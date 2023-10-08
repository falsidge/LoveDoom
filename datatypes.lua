local types = {}

types.EMAPLUMPSINDEX = {
    eTHINGS = 1,
    eLINEDEFS = 2,
    eSIDEDDEFS = 3,
    eVERTEXES = 4,
    eSEAGS = 5,
    eSSECTORS = 6,
    eNODES = 7,
    eSECTORS = 8,
    eREJECT = 9,
    eBLOCKMAP = 10,
    eCOUNT = 11
}

types.ELINEDEFFLAGS = {
    eBLOCKING = 0,
    eBLOCKMONSTERS = 1,
    eTWOSIDED = 2,
    eDONTPEGTOP = 4,
    eDONTPEGBOTTOM = 8,
    eSECRET = 16,
    eSOUNDBLOCK = 32,
    eDONTDRAW = 64,
    eDRAW = 128
}

types.Header = {
    WADType = "",
    DirectoryCount = 0,
    DirectoryOffset = 0
}

function types.Header:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

types.Directory = {
    LumpOffset = 0,
    LumpSize = 0,
    LumpName = ""
}

function types.Directory:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

types.fileproto = {
    read_string = function(l) end,
    read_u32 = function() end,
    read_u16 = function() end,
    read_array_of_words = function() end,
    jump = function() end,
    skip = function() end,
    read_byte = function() end,
    read_bytes = function() end,
    read_words = function() end,
    read_word = function() end
}

types.Thing = {
    XPosition = 0,
    YPosition = 0,
    Angle = 0,
    Type = 0,
    Flags = 0
}

function types.Thing:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

types.Vertex = {
    x = 0,
    y = 0
}
function types.Vertex:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
types.Sector = {
    FloorHeight = 0,
    CeilingHeight = 0,
    FloorTexture = "",
    CeilingTexture = "",
    Lightlevel = 0,
    Type = 0,
    Tag = 0.
}
function types.Sector:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
types.WADSidedef = {
    XOffset = 0,
    YOffset = 0,
    UpperTexture = "",
    LowerTexture = "",
    MiddleTexture = "",
    SectorID = 0
}


function types.WADSidedef:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

types.Sidedef = {
    XOffset = 0,
    YOffset = 0,
    UpperTexture = "",
    LowerTexture = "",
    MiddleTexture = "",
    pSector = nil
}

function types.Sidedef:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

types.WADLinedef = {
    StartVertex = 0,
    EndVertex = 0,
    Flags = 0,
    LineType = 0,
    SectorTag = 0,
    RightSidedef = 0,
    LeftSidedef = 0
}

function types.WADLinedef:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

types.Linedef = {
    pStartVertex = nil,
    pEndVertex = nil,
    Flags = 0,
    LineType = 0,
    SectorTag = 0,
    pRightSidedef = nil,
    pLeftSidedef = nil
}

function types.Linedef:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

types.WADSeg = {
    StartVertexID = 0,
    EndVertexID = 0,
    SlopeAngle = 0,
    LinedefID = 0,
    Direction = 0,
    Offset = 0
}

function types.WADSeg:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

types.Seg = {
    pStartVertex = nil,
    pEndVertex = nil,
    SlopeAngle = nil,
    pLinedef = nil,
    Direction = 0,
    Offset = 0,
    pRightSector = nil,
    pLeftSector = nil
}

function types.Seg:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

types.Subsector = {
    SegCount = 0,
    FirstSegID = 0
}

function types.Subsector:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

types.Node = {
    XPartition = 0,
    YPartition = 0,

    ChangeXPartition = 0,
    ChangeYPartition = 0,

    RightBoxTop = 0,
    RightBoxBottom = 0,
    RightBoxLeft = 0,
    RightBoxRight = 0,

    LeftBoxTop = 0,
    LeftBoxBottom = 0,
    LeftBoxLeft = 0,
    LeftBoxRight = 0,

    RightChildID = 0,
    LeftChildID = 0
}

function types.Node:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

types.SolidSegmentRange = {
    XStart = 0,
    XEnd = 0
}
function types.SolidSegmentRange:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

return types
