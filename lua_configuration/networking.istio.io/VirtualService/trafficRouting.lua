spec = obj.data.spec

if obj.canaryWeight == -1 then
    obj.canaryWeight = 100
    obj.stableWeight = 0
end

function FindAllRules(spec, protocol)
    local rules = {}
    if (spec[protocol] ~= nil) then
        for _, proto in ipairs(spec[protocol]) do
            table.insert(rules, proto)
        end
    end
    return rules
end

-- find matched route of VirtualService spec with stable svc
function FindMatchedRules(spec, stableService, protocol)
    local matchedRoutes = {}
    local rules = FindAllRules(spec, protocol)
    -- a rule contains 'match' and 'route'
    for _, rule in ipairs(rules) do
        -- skip routes with matches
        if (rule.match == nil) then
            for _, route in ipairs(rule.route) do
                if route.destination.host == stableService then
                    table.insert(matchedRoutes, rule)
                    break
                end
            end
        end
    end
    return matchedRoutes
end

function HasMatchedRule(spec, stableService, protocol)
    local rules = FindAllRules(spec, protocol)
    -- a rule contains 'match' and 'route'
    for _, rule in ipairs(rules) do
        for _, route in ipairs(rule.route) do
            if route.destination.host == stableService then
                return true
            end
        end
    end
    return false
end

function DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for key, value in pairs(original) do
            copy[key] = DeepCopy(value)
        end
    else
        copy = original
    end
    return copy
end

function CalculateWeight(route, stableWeight, n)
    local weight
    if (route.weight) then
        weight = math.floor(route.weight * stableWeight / 100)
    else
        weight = math.floor(stableWeight / n)
    end
    return weight
end

-- generate routes with matches, insert a rule before other rules
function GenerateMatchedRoutes(spec, matches, stableService, canaryService, stableWeight, canaryWeight, protocol)
    for _, match in ipairs(matches) do
        local route = {}
        route["match"] = {}
        if (not HasMatchedRule(spec, stableService, protocol)) then
            return
        end
        for key, value in pairs(match) do
            local vsMatch = {}
            vsMatch[key] = {}
            for _, rule in ipairs(value) do
                if rule["type"] == "RegularExpression" then
                    matchType = "regex"
                elseif rule["type"] == "Exact" then
                    matchType = "exact"
                elseif rule["type"] == "Prefix" then
                    matchType = "prefix"
                end
                if key == "headers" then
                    vsMatch[key][rule["name"]] = {}
                    vsMatch[key][rule["name"]][matchType] = rule.value
                else
                    vsMatch[key][matchType] = rule.value
                end
            end
            table.insert(route["match"], vsMatch)
        end
        route.route = {
            {
                destination = {}
            }
        }
        -- if stableService == canaryService, then do e2e release
        if stableService == canaryService then
            route.route[1].destination.host = stableService
            route.route[1].destination.subset = "canary"
        else
            route.route[1].destination.host = canaryService
        end
        if (protocol == "http") then
            table.insert(spec.http, 1, route)
        elseif (protocol == "tls") then
            table.insert(spec.tls, 1, route)
        elseif (protocol == "tcp") then
            table.insert(spec.tcp, 1, route)
        end
    end
end

-- generate routes without matches, change every rule
function GenerateRoutes(spec, stableService, canaryService, stableWeight, canaryWeight, protocol)
    local matchedRules = FindMatchedRules(spec, stableService, protocol)
    for _, rule in ipairs(matchedRules) do
        local canary
        if stableService ~= canaryService then
            canary = {
                destination = {
                    host = canaryService,
                },
                weight = canaryWeight,
            }
        else
            canary = {
                destination = {
                    host = stableService,
                    subset = "canary",
                },
                weight = canaryWeight,
            }
        end

        -- incase there are multiple versions traffic already, do a for-loop
        for _, route in ipairs(rule.route) do
            -- update stable service weight
            route.weight = CalculateWeight(route, stableWeight, #rule.route)
        end
        table.insert(rule.route, canary)
    end
end

if (obj.matches)
then
    GenerateMatchedRoutes(spec, obj.matches, obj.stableService, obj.canaryService, obj.stableWeight, obj.canaryWeight, "http")
    GenerateMatchedRoutes(spec, obj.matches, obj.stableService, obj.canaryService, obj.stableWeight, obj.canaryWeight, "tcp")
    GenerateMatchedRoutes(spec, obj.matches, obj.stableService, obj.canaryService, obj.stableWeight, obj.canaryWeight, "tls")
else
    GenerateRoutes(spec, obj.stableService, obj.canaryService, obj.stableWeight, obj.canaryWeight, "http")
    GenerateRoutes(spec, obj.stableService, obj.canaryService, obj.stableWeight, obj.canaryWeight, "tcp")
    GenerateRoutes(spec, obj.stableService, obj.canaryService, obj.stableWeight, obj.canaryWeight, "tls")
end
return obj.data
