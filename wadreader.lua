local types = require("datatypes")


local WADReader = {
      file = types.fileproto
}
function trim(s)
    return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
 end

function WADReader:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function WADReader:ReadHeaderData(file, offset)
    if file == nil then
        file = self.file
    end
    if offset ~= nil then
        file.jump(offset)
    end
    return types.Header:new{
        WADType = file.read_string(4),
        DirectoryCount = file.read_u32(),
        DirectoryOffset = file.read_u32()
    }

end
function WADReader:ReadDirectoryData(file, offset, directory)
    if file == nil then
        file = self.file
    end
    if offset ~= nil then
        file.jump(offset)
    end    
    if directory == nil then
        return types.Directory:new{
            LumpOffset = file.read_u32(),
            LumpSize = file.read_u32(),
            LumpName = file.read_trimmed_string(8)
        }
    end
    directory.LumpOffset  = file.read_u32()
    directory.LumpSize  = file.read_u32()
    directory.LumpName = file.readread_trimmed_string_string(8)
    return directory
end

function WADReader:ReadVertexData(file, offset, vertex)
    if file == nil then
        file = self.file
    end
    if offset ~= nil then
        file.jump(offset)
    end    
    if vertex == nil then
        return types.Vertex:new{
            x = file.read_i16(),
            y = file.read_i16()
        }
    end
    vertex.x = file.read_i16()
    vertex.y = file.read_i16()
    return vertex
end
function WADReader:ReadLineDefData(file, offset, linedef)
    if file == nil then
        file = self.file
    end
    if offset ~= nil then
        file.jump(offset)
    end    
    if linedef == nil then
        return types.Linedef:new{
            StartVertex = file.read_u16(),
            EndVertex = file.read_u16(),
            Flags = file.read_u16(),
            LineType = file.read_u16(),
            SectorTag = file.read_u16(),
            RightSidedef = file.read_u16(),
            LeftSidedef = file.read_u16()
        }
    end
    linedef.StartVertex = file.read_u16()
    linedef.EndVertex = file.read_u16()
    linedef.Flags = file.read_u16()
    linedef.LineType = file.read_u16()
    linedef.SectorTag = file.read_u16()
    linedef.RightSidedef = file.read_u16()
    linedef.LeftSidedef = file.read_u16()
    return linedef
end

function WADReader:ReadThingData(file, offset, thing)
    if file == nil then
        file = self.file
    end
    if offset ~= nil then
        file.jump(offset)
    end    
    if thing == nil then
        return types.Thing:new{
            x = file.read_i16(),
            y = file.read_i16(),
            Angle = file.read_u16(),
            Type = file.read_u16(),
            Flags = file.read_u16()
        }
    end
    thing.x = file.read_i16()
    thing.y = file.read_i16()
    thing.Angle = file.read_u16()
    thing.Type = file.read_u16()
    thing.Flags = file.read_u16()
    return thing
end

function WADReader:ReadNodesData(file, offset, node)
    if file == nil then
        file = self.file
    end
    if offset ~= nil then
        file.jump(offset)
    end    
    if node == nil then
        return types.Node:new({
            XPartition = file.read_i16(),
            YPartition = file.read_i16(),
            ChangeXPartition = file.read_i16(),
            ChangeYPartition = file.read_i16(),
            RightBoxTop = file.read_i16(),
            RightBoxBottom = file.read_i16(),
            RightBoxLeft = file.read_i16(),
            RightBoxRight = file.read_i16(),
            LeftBoxTop = file.read_i16(),
            LeftBoxBottom = file.read_i16(),
            LeftBoxLeft = file.read_i16(),
            LeftBoxRight = file.read_i16(),
            RightChildID = file.read_u16(),
            LeftChildID = file.read_u16()
        })
    end
    node.XPartition = file.read_i16()
    node.YPartition = file.read_i16()
    node.ChangeXPartition = file.read_i16()
    node.ChangeYPartition = file.read_i16()
    node.RightBoxTop = file.read_i16()
    node.RightBoxBottom = file.read_i16()
    node.RightBoxLeft = file.read_i16()
    node.RightBoxRight = file.read_i16()
    node.LeftBoxTop = file.read_i16()
    node.LeftBoxBottom = file.read_i16()
    node.LeftBoxLeft = file.read_i16()
    node.LeftBoxRight = file.read_i16()
    node.RightChildID = file.read_u16()
    node.LeftChildID = file.read_u16()
    return node
end

function WADReader:ReadSubsectorData(file, offset, subsector)
    if file == nil then
        file = self.file
    end
    if offset ~= nil then
        file.jump(offset)
    end    
    if subsector == nil then
        return types.Subsector:new{
            SegCount = file.read_u16(),
            FirstSegID = file.read_u16()
        }
    end
    subsector.SegCount = file.read_u16()
    subsector.FirstSegID = file.read_u16()
    return subsector
end

function WADReader:ReadSegData(file, offset, seg)
    if file == nil then
        file = self.file
    end
    if offset ~= nil then
        file.jump(offset)
    end    
    if seg == nil then
        return types.Seg:new(
            {
                StartVertexID  = file.read_u16(),
                EndVertexID  = file.read_u16(),
                Angle = file.read_u16(),
                LinedefID  = file.read_u16(),
                Direction = file.read_u16(),
                Offset = file.read_u16()
            }
        )
    end
    seg.StartVertexID  = file.read_u16()
    seg.EndVertexID  = file.read_u16()
    seg.Angle = file.read_u16()
    seg.LinedefID  = file.read_u16()
    seg.Direction = file.read_u16()
    seg.Offset = file.read_u16()

    return seg
end

return WADReader