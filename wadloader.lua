
local open_file_buffer = require("filebuffer")
local WADReader = require("wadreader")
local types = require("datatypes")


local WADLoader = {
    WADFile = types.fileproto,
    header = types.Header:new(),
    directories = {},
    m_reader = WADReader:new()
}



function WADLoader:ReadDirectories()
    if self.WADFile ~= nil then
        local reader = WADReader:new{file = self.WADFile}
        self.header = reader:ReadHeaderData()
        self.directories = {}
        reader.file.jump(self.header.DirectoryOffset)
        -- print(self.header.DirectoryOffset, self.header.DirectoryCount)
        for i = 1,(self.header.DirectoryCount) do
            local directory = reader:ReadDirectoryData()
            -- print(directory.LumpName)

            table.insert(self.directories, directory)
        end
        self.m_reader = reader
    else
        error("File cannot be nil")
    end
    return self
end

function WADLoader:LoadWAD(file_or_path)
    self:OpenAndLoad(file_or_path)
    self:ReadDirectories()
    return self
end

function WADLoader:OpenAndLoad(file_or_path)
    if file_or_path ~= nil then
        if type(file_or_path) == "string" then
            self.WADFile = open_file_buffer(file_or_path)
        else
            self.WADFile = file_or_path
        end
    end
    return self
end

function WADLoader:new(o)
    if o ~= nil then
        return WADLoader:new():LoadWAD(o)
    end
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function WADLoader:FindMapIndex(map)
    if map:GetLumpIndex() ~= nil then
        return map:GetLumpIndex()
    end

    for i = 1, #self.directories do
        if self.directories[i].LumpName == map:GetName() then
            map:SetLumpIndex(i)
            return i
        end
    end
    return nil
end

function WADLoader:ReadMapVertex(map)
    local iMapIndex = self:FindMapIndex(map)
    if iMapIndex == nil then
        return false
    end
    iMapIndex = iMapIndex + types.EMAPLUMPSINDEX.eVERTEXES
    if self.directories[iMapIndex].LumpName ~= "VERTEXES" then
        return false
    end
    local iVertexSizeInBytes = 4
    local iVertexCount = self.directories[iMapIndex].LumpSize / iVertexSizeInBytes
    self.m_reader.file.jump(self.directories[iMapIndex].LumpOffset)
    for i = 1,iVertexCount do 
        local vertex = self.m_reader:ReadVertexData()
        -- print("("..tostring(vertex.x)..","..tostring(vertex.y)..")")
        map:AddVertex(vertex)
    end
end
function WADLoader:ReadMapLineDef(map)
    local iMapIndex = self:FindMapIndex(map)
    if iMapIndex == nil then
        return false
    end
    iMapIndex = iMapIndex + types.EMAPLUMPSINDEX.eLINEDEFS
    if self.directories[iMapIndex].LumpName ~= "LINEDEFS" then
        return false
    end
    local iLinedefSizeInBytes  = 2*7
    local iLinedefCount  = self.directories[iMapIndex].LumpSize / iLinedefSizeInBytes 
    self.m_reader.file.jump(self.directories[iMapIndex].LumpOffset)
    for i = 1,iLinedefCount  do 
        local linedef = self.m_reader:ReadLineDefData()
        map:AddLineDef(linedef)
    end
end
function WADLoader:LoadMapData(map)
    print("INFO: Parsing Map:"..map:GetName())

    self:ReadMapVertex(map)
    print("INFO: Vertexes:"..#map.m_Vertexes)
    
    self:ReadMapLineDef(map)
    print("INFO: Linedefs:"..#map.m_Linedefs)

    self:ReadMapThing(map)
    print("INFO: Things:"..#map.m_Things)

    self:ReadMapNodes(map)
    print("INFO: Nodes:"..#map.m_Nodes)
    self:ReadMapSubsectors(map)
    print("INFO: Subsectors:"..#map.m_Subsector)
    self:ReadMapSegs(map)
    print("INFO: Segs:"..#map.m_Segs)
    return map
end

function WADLoader:ReadMapThing(map)
    local iMapIndex = self:FindMapIndex(map)
    if iMapIndex == nil then
        return false
    end
    iMapIndex = iMapIndex + types.EMAPLUMPSINDEX.eTHINGS
    if self.directories[iMapIndex].LumpName ~= "THINGS" then
        return false
    end
    local iThingSizeInBytes  = 2*5
    local iThingCount  = self.directories[iMapIndex].LumpSize / iThingSizeInBytes 
    self.m_reader.file.jump(self.directories[iMapIndex].LumpOffset)
    for i = 1,iThingCount  do 
        local thing = self.m_reader:ReadThingData()
        map:AddThing(thing)
    end
end

function WADLoader:ReadMapNodes(map)
    local iMapIndex = self:FindMapIndex(map)
    if iMapIndex == nil then
        return false
    end
    iMapIndex = iMapIndex + types.EMAPLUMPSINDEX.eNODES
    if self.directories[iMapIndex].LumpName ~= "NODES" then
        return false
    end
    local iNodesSizeInBytes   = 2*14
    local iNodesCount  = self.directories[iMapIndex].LumpSize / iNodesSizeInBytes
    self.m_reader.file.jump(self.directories[iMapIndex].LumpOffset)
    for i = 1,iNodesCount do
        local node = self.m_reader:ReadNodesData()
        map:AddNode(node)
    end
end

function WADLoader:ReadMapSubsectors(map)
    local iMapIndex = self:FindMapIndex(map)
    if iMapIndex == nil then
        return false
    end
    iMapIndex = iMapIndex + types.EMAPLUMPSINDEX.eSSECTORS
    if self.directories[iMapIndex].LumpName ~= "SSECTORS" then
        return false
    end
    local iSubsectorsSizeInBytes   = 2*2
    local iSubsectorsCount  = self.directories[iMapIndex].LumpSize / iSubsectorsSizeInBytes
    self.m_reader.file.jump(self.directories[iMapIndex].LumpOffset)
    for i = 1,iSubsectorsCount do
        local subsector = self.m_reader:ReadSubsectorData()
        map:AddSubsector(subsector)
    end
end

function WADLoader:ReadMapSegs(map)
    local iMapIndex = self:FindMapIndex(map)
    if iMapIndex == nil then
        return false
    end
    iMapIndex = iMapIndex + types.EMAPLUMPSINDEX.eSEAGS
    if self.directories[iMapIndex].LumpName ~= "SEGS" then
        return false
    end
    local iSegsSizeInBytes   = 2*6
    local iSegsCount  = self.directories[iMapIndex].LumpSize / iSegsSizeInBytes
    self.m_reader.file.jump(self.directories[iMapIndex].LumpOffset)
    for i = 1,iSegsCount do
        local seg = self.m_reader:ReadSegData()
        map:AddSeg(seg)
    end
end

return WADLoader

