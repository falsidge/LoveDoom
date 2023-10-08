Things = {m_Things = {}}

function Things:new(o)
    o = o or {} -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

function Things:AddThing(thing)
    table.insert(self.m_Things, thing)
end

function Things:GetThingByID(id)
    for i = 1, #Things.m_Things do
        if Things.m_Things[i].Type == id then
            return Things.m_Things[i]
        end
    end
    return nil
end



return Things
