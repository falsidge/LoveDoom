Angle = {
    m_Angle = 0
}

Angle.mt = {

}


Angle.__add = function(a, b)
    if type(a) ~= 'number' then
        a = a.m_Angle
    end
    if type(b) ~= 'number' then
        b = b.m_Angle
    end

    return Angle:new(a + b)
end

Angle.__sub = function(a, b)
    if type(a) ~= 'number' then
        a = a.m_Angle
    end
    if type(b) ~= 'number' then
        b = b.m_Angle
    end

    return Angle:new(a - b)
   
end


Angle.__mul = function(a, b)
    if type(a) ~= 'number' then
        a = a.m_Angle
    end
    if type(b) ~= 'number' then
        b = b.m_Angle
    end

    return Angle:new(a * b)
   
end


Angle.__div = function(a,b)
    if type(a) ~= 'number' then
        a = a.m_Angle
    end
    if type(b) ~= 'number' then
        b = b.m_Angle
    end

    return Angle:new(a / b)
end

Angle.__le = function(a, b)
    if type(a) ~= 'number' then
        a = a.m_Angle
    end
    if type(b) ~= 'number' then
        b = b.m_Angle
    end
    return a <= b
end

Angle.__lt = function(a, b)
    if type(a) ~= 'number' then
        a = a.m_Angle
    end
    if type(b) ~= 'number' then
        b = b.m_Angle
    end
    return a < b
end

Angle.__eq = function(a, b)
    if type(a) ~= 'number' then
        a = a.m_Angle
    end
    if type(b) ~= 'number' then
        b = b.m_Angle
    end
    return a == b
end

function Angle:new(ang)
    o = {

    }
    setmetatable(o, self)
    self.__index = self
    o.m_Angle = ang or 0
    o:Normalize360()
    return o
end


function Angle:Normalize360()
    self.m_Angle = math.fmod(self.m_Angle, 360)
    if self.m_Angle < 0 then
        self.m_Angle = self.m_Angle + 360
    end
end



return Angle