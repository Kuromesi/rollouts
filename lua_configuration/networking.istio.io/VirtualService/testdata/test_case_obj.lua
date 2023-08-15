steps = {
    step_0 = { canaryWeight = 20, stableWeight = 80,
        matches = {
            { headers = { { name = "user-agent", value = "pc", type = "Exact", },
                { type = "RegularExpression", name = "name", value = ".*demo", }, }, }, },
        canaryService = "nginx-service-canary", stableService = "nginx-service",
        data = {
            spec = { hosts = { "*", }, http = { { route = { { destination = { host = "nginx-service", }, }, }, }, },
                gateways = { "nginx-gateway", }, }, }, },
    step_1 = { canaryWeight = 50, stableWeight = 50, canaryService = "nginx-service-canary",
        stableService = "nginx-service",
        data = {
            spec = { gateways = { "nginx-gateway", }, hosts = { "*", },
                http = { { route = { { destination = { host = "nginx-service", }, }, }, }, }, }, }, }, }
