local util = ...

function util.extend(base)
  return {
    __index = base
  }
end

function util.copy(t)
  if type(t) ~= "table" then
    return t
  else
    local c = {}
    for k, v in pairs(t) do
      c[k] = util.copy(v)
    end
    setmetatable(c, getmetatable(t))
    return c
  end
end

function util.merge(t1, t2)
  local res = util.copy(t1)
  for k, v in pairs(t2) do
    if type(v) == "table" and type(t1[k]) == "table" then
      res[k] = util.merge(t1[k], v)
    else
      res[k] = v
    end
  end
  return res
end

function util.print(t)
  if type(t) == "table" then
    local res = "{"
    local tempty = true
    for k, v in pairs(t) do
      tempty = false
      res = res .. " " .. k .. ": " .. util.print(v) .. ","
    end
    if not tempty then res = string.sub(res, 1, -2) end
    res = res .. " }"
    return res
  elseif type(t) == "function" then
    return "<function>"
  else
    return t
  end
end

function util.rectContains(rect, point)
  return point[1] >= rect[1] and point[2] >= rect[2] and point[1] <= rect[3] and point[2] <= rect[4]
end

function vec2eq(v1, v2)
  return v1[1] == v2[1] and v1[2] == v2[2]
end

function ary2d()
  local newAry2d = {}

  local mt = {}

  mt.__index = function(t, k)
    local v = rawget(newAry2d, k)
    if not v then
      v = {}
      rawset(newAry2d, k, v)
    end
    return v
  end

  setmetatable(newAry2d, mt)

  return newAry2d
end
