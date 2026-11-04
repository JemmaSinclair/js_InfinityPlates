Config = {}

-- Enable custom plates appearing on ambient / traffic vehicles
Config.EnablePopulationPlates = true

-- Overall chance (in percentage, 0.0 to 100.0) that a normal population vehicle spawns with a custom plate.
-- Examples:
--   1.0  = 1% of traffic (1 in 100 cars)
--   3.0  = 3% of traffic (1 in ~33 cars)
--   5.0  = 5% of traffic (1 in 20 cars)
Config.CustomPlateChance = 3.0

-- Weighted pool of custom plates to pick from when a vehicle qualifies:
-- Total weight is summed, and each entry's probability is weight / totalWeight.
Config.CustomPlates = {
    { slot = 13, name = "North Yankton", weight = 60 },
    { slot = 14, name = "Epsilon",       weight = 40 }
}

-- Population types eligible for custom plate assignment:
-- In GTA V:
-- 2 = POPTYPE_RANDOM_PARKED   (Parked ambient cars on roadsides/driveways)
-- 3 = POPTYPE_RANDOM_PATROL   (Patrol cars)
-- 4 = POPTYPE_RANDOM_SCENARIO (Vehicles spawned by ambient scenarios)
-- 5 = POPTYPE_RANDOM_AMBIENT  (Normal driving traffic on roads)
-- Note: Type 7 (POPTYPE_MISSION) represents player/script-spawned vehicles and is excluded.
Config.EligiblePopulationTypes = {
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true
}

-- Whether to also allow custom plates on vehicles where population type is unknown (type 0)
Config.AllowUnknownPopulationType = false

