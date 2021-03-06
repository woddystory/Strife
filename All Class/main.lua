local _error = function(str) print("Allclass: "..tostring(str)) end
local _Chat = function(str) Game.Chat.Print(tostring(str)) end
local myHero = Game.GetLocalPlayer().hero
if myHero.team == 1 then TEAM_ENEMY = 2 else TEAM_ENEMY = 1 end

local _func_GetDistanceSqr = function(v1, v2)
    v2 = v2 or myHero
    return (v1.x - v2.x)*(v1.x - v2.x) + ((v1.z or v1.y) - (v2.z or v2.y)) * ((v1.z or v1.y) - (v2.z or v2.y))    
end

local _func_ValidTarget = function(object, Dist, enemyTeam)
    local enemy = enemyTeam or TEAM_ENEMY
    return object ~= nil and object.valid and object.team ~= myHero.team and object.uid ~= myHero.uid and (Dist == nil or myHero.pos:DistanceTo(object.pos) <= Dist)
end

local _func_CreateProtectedTable = function(table)
   return setmetatable({}, {
     __index = table,
     __newindex = function(table, key, value)
                    print("Attempt to modify read-only table")
                  end,
     __metatable = false
   })
end

local _func_GetDistanceFromMouse = function(object)
    local object = object or myHero
    if object and object.valid and object.uid then
        local mousePos = Game.GetCursor()
        return object.pos:DistanceTo(mousePos)
    end
end

local _table_EnemyPlayers = nil
local _func_GetEnemyPlayers = function()
	if type(_table_EnemyPlayers) == "table" then return _table_EnemyPlayers end
	local _table_EnemyPlayers = {}
    for i, p in ipairs(sh.players) do
        if p and p.valid and p.hero.valid and p.hero.team ~= myHero.team then
            table.insert(_table_EnemyPlayers, p.hero)
        end
        _func_CreateProtectedTable(_table_EnemyPlayers)
    end
    return _table_EnemyPlayers
end

local _table_AllyPlayers = nil
local _func_GetAllyPlayers = function()
    if type(_table_AllyPlayers) == "table" then return _table_AllyPlayers end
    local _table_AllyPlayers = {}
    for i, p in ipairs(sh.players) do
        if p and p.valid and p.hero.valid and p.hero.team == myHero.team then
            table.insert(_table_AllyPlayers, p.hero)
        end
        _func_CreateProtectedTable(_table_AllyPlayers)
    end
    return _table_AllyPlayers
end

local _func_CountEnemyPlayerInRange = function(range, object)
    object = object or myHero
    range = range and range * range or myHero.range * myHero.range
    local enemyInRange = 0
    for i, p in ipairs(sh.players) do
        if _func_ValidTarget(p.hero) and _func_GetDistanceSqr(object.pos, p.hero.pos) <= range then
            enemyInRange = enemyInRange + 1
        end
    end
    return enemyInRange
end

local _func_CountAllyPlayerInRange = function(range, object)
    object = object or myHero
    range = range and range * range or myHero.range * myHero.range
    local allyInRange = 0
    for i, p in ipairs(sh.players) do
        if p and p.valid and p.hero.team == myHero.team and p.hero.uid ~= myHero.uid and _func_GetDistanceSqr(object.pos, p.hero.pos) <= range then
            allyInRange = allyInRange + 1
        end
    end
    return allyInRange
end

local _func_GetClosestAlly = function(object)
    object = object or myHero
    local distance = math.huge
    local closest = nil
    for i, p in ipairs(sh.players) do
        if p and p.valid and p.hero.uid ~= myHero.uid and p.hero.team == myHero.team then
            if object.pos:DistanceTo(p.hero.pos) < distance or closest == nil then
                distance = object.pos:DistanceTo(p.hero.pos)
                closest = p.hero
            end
        end
    end
    return closest
end

local _func_GetClosestEnemy = function(object)
    object = object or myHero
    local distance = math.huge
    local closest = nil
    for i, p in ipairs(sh.players) do
        if _func_ValidTarget(p.hero) then
            if object.pos:DistanceTo(p.hero) < distance or closest == nil then
                distance = object.pos:DistanceTo(p.hero)
                closest = p.hero
            end
        end
    end
    return closest
end

local _func_CastItem = function(name, x, y)
    for i = 1, 9, 1 do
        if myHero:GetItem(i) and myHero:GetItem(i).name == name then
            if i == 1 then slot = 96 end
            if i == 2 then slot = 97 end
            if i == 3 then slot = 98 end
            if i == 4 then slot = 99 end
            if i == 5 then slot = 100 end
            if i == 6 then slot = 101 end
            if i == 7 then slot = 102 end
            if i == 8 then slot = 103 end
            if i == 9 then slot = 104 end
            Allclass.CastSpell(slot+1, x, y)
        end
    end
end

local _func_HaveItem = function(name)
    for i = 1, 9, 1 do
        if myHero:GetItem(i) and myHero:GetItem(i).name == name then
            return true
        end
    end
    return false
end

-- Master Bilbao
local _func_CastSpell = function(index, x, y)
  index = index - 1
  if x == nil then
    local p = Game.CLoLPacket(0x1B) 
    p:Encode4(myHero.uid)
    p:Encode1(index)
    p:Encode1(0)
    Game.SendPacket(p)
  elseif type(x) == 'CObjectProxy' then 
    local p = Game.CLoLPacket(0x1D) 
    p:Encode4(myHero.uid)
    p:Encode1(index)
    p:Encode4(x.uid)
    p:Encode1(0)
    p:Encode1(0)
    p:Encode1(0)
    Game.SendPacket(p)
  else
    local p = Game.CLoLPacket(0x1C) 
    p:Encode4(myHero.uid)
    p:Encode1(index)
    p:EncodeF(x)
    p:EncodeF(y)
    p:Encode1(0)
    p:Encode1(0)
    p:Encode1(0)
    Game.SendPacket(p)
  end
end

local _func_GetCharacter = function()
    if Game.GetLocalPlayer().valid and Game.GetLocalPlayer().hero.valid then
        return string.sub(Game.GetLocalPlayer().hero.name, 6)
    end
end

local _func_UnderAllyBuilding = function(object)
    local object = object or myHero
    for i, t in ipairs(sh.entities) do
        if t and t.isBuildingEntity and object.pos:DistanceTo(t.pos) < 950 and t.health > 0 and t.team == myHero.team then
            return true
        end
    end
    return false
end

local _func_UnderEnemyBuilding = function(object)
    local object = object or myHero
    for i, t in ipairs(sh.entities) do
        if t and t.isBuildingEntity and object.pos:DistanceTo(t.pos) < 950 and t.health > 0 and t.team ~= myHero.team then
            return true
        end
    end
    return false
end

local _func_ClosestBuilding = function(object, team)
    local object = object or myHero
    local distance = math.huge
    local closest = nil
    for i, t in ipairs(sh.entities) do
        if team == nil then
            if t and t.isBuildingEntity and t.health > 0 then
                if object.pos:DistanceTo(t.pos) < distance or closest == nil then
                    distance = object.pos:DistanceTo(t.pos)
                    closest = t
                end
            end
        elseif team == object.team then
            if t and t.isBuildingEntity and t.health > 0 and t.team == object.team then
                if object.pos:DistanceTo(t.pos) < distance or closest == nil then
                    distance = object.pos:DistanceTo(t.pos)
                    closest = t
                end
            end
        elseif team ~= object.team or team == TEAM_ENEMY then
            if t and t.isBuildingEntity and t.health > 0 and t.team ~= object.team then
                if object.pos:DistanceTo(t.pos) < distance or closest == nil then
                    distance = object.pos:DistanceTo(t.pos)
                    closest = t
                end
            end
        end
    end
    return closest
end

namespace 'Allclass' {
    GetDistanceSqr = function(v1, v2) return _func_GetDistanceSqr(v1, v2) end,
    GetDistanceFromMouse = function(object) return _func_GetDistanceFromMouse(object) end,
	GetEnemyPlayers = function() return _func_GetEnemyPlayers() end,
    ValidTarget = function(object, Dist, enemyTeam) return _func_ValidTarget(object, Dist, enemyTeam) end,
	GetAllyPlayers = function() return _func_GetAllyPlayers() end,
    CreateProtectedTable = function(table) return _func_CreateProtectedTable(table) end,
	GetCharacter = function() return _func_GetCharacter() end,
    CountEnemyPlayerInRange = function(range, object) return _func_CountEnemyPlayerInRange(range, object) end,
    CountAllyPlayerInRange = function(range, object) return _func_CountAllyPlayerInRange(range, object) end,
    GetClosestAlly = function(object) return _func_GetClosestAlly(object) end,
    CastSpell = function(index, x, y) return _func_CastSpell(index, x, y) end,
    CastItem = function(name, x, y) return _func_CastItem(name, x, y) end,
    HaveItem = function(name) return _func_HaveItem(name) end,
    GetClosestEnemy = function(object) return _func_GetClosestAlly(object) end,
    UnderAllyBuilding = function(object) return _func_UnderAllyBuilding(object) end,
    UnderEnemyBuilding = function(object) return _func_UnderEnemyBuilding(object) end,
    ClosestBuilding = function(object, team) return _func_ClosestBuilding(object, team) end,
}
