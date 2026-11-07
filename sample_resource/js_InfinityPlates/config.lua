Config = {}

-- Primary State your server is set in (e.g. 'Oregon', 'California', 'New York', etc.)
-- Ambient world traffic will prioritize this state.
-- You can set this to false or 'All' if you don't have a single primary state.
Config.ServerState = 'Oregon'

-- Percentage of ambient traffic that receives plates from your primary Config.ServerState (e.g. 90 = 90% in-state traffic)
-- The remaining percentage (e.g. 10%) will be chosen from any other states enabled in Config.EnabledStates (out-of-state travelers).
Config.ServerStateRatio = 90.0

-- Replace vanilla plate slots 0-12 with your ServerState's plates
-- When true, slots 0, 1, 2, 3, etc. are overwritten with the primary state's plates (e.g. Oregon Douglas Fir, Pacific Wonderland, etc.)
-- ensuring any vehicle spawned with vanilla plate indices (0-12) displays your server state's plates natively!
Config.ReplaceVanillaSlots = true

-- Starting slot index for custom plates (Grand Theft Auto V vanilla slots are 0-12)
Config.StartingSlotIndex = 13

-- Enable custom plates appearing on ambient / traffic vehicles
Config.EnablePopulationPlates = true

-- Overall chance (0.0 to 100.0) that a normal population vehicle spawns with a custom plate.
Config.CustomPlateChance = 100.0

-- Per-State Lore mode toggle (true = Lore equivalent texture dictionary, false = Real-world actual state dictionary)
Config.StateLoreMode = {
    ['Alabama'] = false, -- false: Real name, true: Lore name
    ['Arizona'] = false, -- false: Real name, true: Lore name
    ['California'] = false, -- false: Real name, true: Lore name
    ['Florida'] = false, -- false: Real name, true: Lore name
    ['Georgia'] = false, -- false: Real name, true: Lore name
    ['Iowa'] = false, -- false: Real name, true: Lore name
    ['Louisiana'] = false, -- false: Real name, true: Lore name
    ['Maine'] = false, -- false: Real name, true: Lore name
    ['Massachusetts'] = false, -- false: Real name, true: Lore name
    ['Michigan'] = false, -- false: Real name, true: Lore name
    ['Montana'] = false, -- false: Real name, true: Lore name
    ['Nevada'] = false, -- false: Real name, true: Lore name
    ['New Hampshire'] = false, -- false: Real name, true: Lore name
    ['New Jersey'] = false, -- false: Real name, true: Lore name
    ['New York'] = false, -- false: Real name, true: Lore name
    ['Oklahoma'] = false, -- false: Real name, true: Lore name
    ['Oregon'] = false, -- false: Real name, true: Lore name
    ['Pennsylvania'] = false, -- false: Real name, true: Lore name
    ['Utah'] = false, -- false: Real name, true: Lore name
    ['Vermont'] = false, -- false: Real name, true: Lore name
    ['Washington'] = false, -- false: Real name, true: Lore name
}

-- Per-State Ambient Enable toggle (Set true if traffic can spawn with plates from this state)
Config.EnabledStates = {
    ['Alabama'] = false,
    ['Arizona'] = false,
    ['California'] = false,
    ['Florida'] = false,
    ['Georgia'] = false,
    ['Iowa'] = false,
    ['Louisiana'] = false,
    ['Maine'] = false,
    ['Massachusetts'] = false,
    ['Michigan'] = false,
    ['Montana'] = false,
    ['Nevada'] = false,
    ['New Hampshire'] = false,
    ['New Jersey'] = false,
    ['New York'] = false,
    ['Oklahoma'] = false,
    ['Oregon'] = true,
    ['Pennsylvania'] = false,
    ['Utah'] = false,
    ['Vermont'] = false,
    ['Washington'] = false,
}

-- ============================================================================
-- Config.Plates: Clean State-by-State Custom Plate Registry
-- ============================================================================
-- You no longer have to repeat state names, dictionary names, or boilerplate!
--
-- Plate Options:
--   name        (string)            Display name of the plate
--   tex         (string)            Texture name inside the state's .ytd
--   baseTex     (string) [Optional] Specific vehshare plate texture ('plate01', 'plate02', 'plate05', 'yankton_plate', etc.)
--   textColor   (string|number)     Font text color:
--                                     - Hex string: e.g. '#FFD700' (Gold), '#080808' (Matte Black), '#FFFFFF' (White), '#00FF66'
--                                     - Named string: 'white', 'black', 'gold', 'yellow', 'blue', 'red', 'green'
--                                     - Color Index: 5=Black (default), 11=White, 1=Yellow, 0=Blue, 6=Red, 10=Green
--   fontExtents (table)  [Optional] Text bounding box & placement: { x = 0.28, y = 0.36, w = 0.82, h = 0.90 }
--                                     - x: Left margin / horizontal offset (default ~0.28)
--                                     - y: Top margin / vertical offset (default ~0.355)
--                                     - w: Text block width (default ~0.816)
--                                     - h: Text block height (default ~0.92)
--   weight      (number) [Optional] Population spawn weight (default: 50, set 0 for Gov/Police to prevent civilian NPC spawn)
--   pattern     (string) [Optional] Character pattern (e.g. '11AAA111')
--
Config.Plates = {
    ['Alabama'] = {
        { name = 'Beach Standard (2022)', tex = 'beach_standard', pattern = '11A1111' },
        { name = 'Hills & Egret (2014)', tex = 'hills_egret', pattern = '11A111A' },
        { name = 'Protect Our Birds', tex = 'protect_our_birds', pattern = '11111' },
        { name = 'State Parks Supporter', tex = 'state_parks', textColor = 11, pattern = '11111' },
        { name = 'Municipal Government', tex = 'municipal', textColor = 0, weight = 0, pattern = '11111MU' }, -- [GOVERNMENT / EXEMPT]
        { name = 'County Government', tex = 'county', textColor = 0, weight = 0, pattern = '11111CO' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Trooper', tex = 'state_trooper', textColor = 1, weight = 0, pattern = 'ST111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Arizona'] = {
        { name = 'Grand Canyon Standard', tex = 'grand_canyon', textColor = 0, pattern = 'AAA1AAA' },
        { name = 'Rodeo Specialty', tex = 'rodeo', textColor = 0, pattern = 'AA111' },
        { name = 'Historic Route 66', tex = 'historic_route_66', pattern = 'AA111' },
        { name = 'Sound of Freedom', tex = 'sound_of_freedom', textColor = 11, pattern = 'AA111' },
        { name = 'Government Exempt', tex = 'government_exempt', weight = 0, pattern = 'G111AA' }, -- [GOVERNMENT / EXEMPT]
    },

    ['California'] = {
        { name = 'Standard DMV (2011)', tex = 'standard_dmv', textColor = 0, pattern = '1AAA111' },
        { name = 'Script Standard (1998)', tex = 'script_1998', textColor = 0, pattern = '1AAA111' },
        { name = 'Block Standard (1987)', tex = 'block_1987', textColor = 0, pattern = '1AAA111' },
        { name = '1960s Black Legacy', tex = 'legacy_1960s', textColor = 1, pattern = 'AAA111' },
        { name = 'CA Exempt Government', tex = 'ca_exempt', textColor = 0, weight = 0, pattern = '1111111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Arts Council Coastline', tex = 'arts_council', textColor = 0, pattern = 'AA1111' },
    },

    ['Florida'] = {
        { name = 'Sunshine State Standard', tex = 'sunshine_state', textColor = 10, pattern = 'AAAA11' },
        { name = 'Conserve Wildlife', tex = 'conserve_wildlife', pattern = 'AA111' },
        { name = 'Endless Summer', tex = 'endless_summer', pattern = 'AA111' },
        { name = 'Explore Off-Road', tex = 'explore_off_road', pattern = 'AA111' },
        { name = 'City Government', tex = 'city_government', weight = 0, pattern = '111111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'County Sheriff', tex = 'sheriff', weight = 0, pattern = '11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'County Government', tex = 'county_government', weight = 0, pattern = '111111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Trooper (FHP)', tex = 'state_trooper', textColor = 1, weight = 0, pattern = '11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Home of the Blue Angels', tex = 'blue_angels', pattern = 'AA111' },
    },

    ['Georgia'] = {
        { name = 'Peach State Scenic', tex = 'peach_state_scenic', pattern = 'AAA1111' },
        { name = 'Peach Standard', tex = 'peach_standard', pattern = 'AAA1111' },
        { name = 'Support Wildlife', tex = 'support_wildlife', pattern = 'AA111' },
        { name = 'Peach Standard (Alt)', tex = 'peach_commercial', pattern = 'AAA1111' },
        { name = 'City Government', tex = 'city_government', weight = 0, pattern = 'GV111A1' }, -- [GOVERNMENT / EXEMPT]
        { name = 'County Government', tex = 'county_government', weight = 0, pattern = 'GV111A1' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Trooper (GSP)', tex = 'state_trooper', textColor = 1, weight = 0, pattern = '111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Iowa'] = {
        { name = 'City & Country (Polk)', tex = 'city_country_polk', pattern = 'AAA111' },
        { name = 'City & Country (Woodbury)', tex = 'city_country_woodbury', pattern = 'AAA111' },
        { name = 'Statehood 1846 Heritage', tex = 'statehood_1846', pattern = 'AAA111' },
        { name = 'Official Government', tex = 'official_government', weight = 0, pattern = '11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Municipal Police', tex = 'municipal_police', textColor = 0, weight = 0, pattern = '11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'County Sheriff', tex = 'county_sheriff', weight = 0, pattern = 'S111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Patrol', tex = 'state_patrol', weight = 0, pattern = '111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Louisiana'] = {
        { name = 'Pelican Standard', tex = 'pelican_standard', baseTex = 'plate01', pattern = 'AAA111' },
        { name = "Sportsman's Paradise (1994)", tex = 'sportsmans_1994', baseTex = 'plate02', pattern = 'AAA111' },
        { name = 'Commercial', tex = 'commercial', baseTex = 'plate_mod_01', pattern = 'A111111' },
        { name = 'Pelican Standard (Alt)', tex = 'pelican_alt', baseTex = 'plate_02', pattern = 'AAA111' },
        { name = 'Public Government', tex = 'public_government', textColor = 0, baseTex = 'plate05', weight = 0, pattern = '111111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Police', tex = 'state_police', textColor = 6, baseTex = 'yankton_plate', weight = 0, pattern = 'A111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Maine'] = {
        { name = 'Pine Tree Standard (2025)', tex = 'pine_tree_2025', textColor = 0, pattern = '1111AA' },
        { name = 'Chickadee Standard (1999)', tex = 'chickadee_1999', pattern = '1111AA' },
        { name = 'Commercial (Chickadee)', tex = 'chickadee_commercial', pattern = '111111' },
        { name = 'Municipal Police', tex = 'municipal_police', textColor = 0, weight = 0, pattern = '1111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Municipal Government', tex = 'municipal', textColor = 0, weight = 0, pattern = '11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Police', tex = 'state_police', textColor = 11, weight = 0, pattern = '111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Massachusetts'] = {
        { name = 'Spirit of America Standard', tex = 'spirit_of_america', textColor = 6, pattern = '1AAA11' },
        { name = 'Cape Cod & Islands', tex = 'cape_cod_islands', textColor = 6, pattern = '1111' },
        { name = "Sportsmen's Land Trust", tex = 'sportsmens_land_trust', pattern = '1111' },
        { name = 'Commercial', tex = 'commercial', textColor = 6, pattern = '111111' },
        { name = 'Municipal Police Official', tex = 'police_official', textColor = 0, weight = 0, pattern = 'MP1111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Trooper (MSP)', tex = 'state_trooper', textColor = 1, weight = 0, pattern = '1111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Michigan'] = {
        { name = 'Water Wonderland (1963 Legacy)', tex = 'water_wonderland_1963', textColor = 11, pattern = 'AA1111' },
        { name = 'Water-Winter Wonderland (1965)', tex = 'water_winter_1965', textColor = 1, pattern = 'AAA111' },
        { name = 'Conserve Wildlife Habitat', tex = 'wildlife_habitat', pattern = '1111A' },
        { name = 'Pure Michigan Standard', tex = 'pure_michigan', textColor = 0, pattern = 'AAA1111' },
        { name = 'Municipal Government', tex = 'municipal', textColor = 0, weight = 0, pattern = '11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Detroit Red Wings', tex = 'detroit_red_wings', pattern = 'AA11' },
        { name = 'State Police (MSP)', tex = 'state_police', weight = 0, pattern = '111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Montana'] = {
        { name = '1950 Replica Standard (2010)', tex = 'treasure_state_2010', textColor = 11, pattern = '111111A' },
        { name = 'Big Sky Standard (2000)', tex = 'big_sky_2000', pattern = '111111A' },
        { name = 'Centennial 100 Years (1989)', tex = 'centennial_1989', pattern = '111111A' },
        { name = 'Montana Hope Project', tex = 'hope_project', pattern = '11111' },
        { name = 'Government Exempt', tex = 'exempt_government', weight = 0, pattern = 'EX1111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Nevada'] = {
        { name = 'Home Means Nevada Standard', tex = 'home_means_nevada', pattern = '111A11' },
        { name = 'Sunset Standard (2001)', tex = 'sunset_2001', textColor = 0, pattern = '111AAA' },
        { name = 'Bighorn Sheep (1984 Legacy)', tex = 'bighorn_1984', textColor = 0, pattern = '111AAA' },
        { name = 'Conserve Wildlife', tex = 'conserve_wildlife', pattern = '11111' },
        { name = 'Las Vegas Metro Police', tex = 'lvmpd_police', weight = 0, pattern = 'EX11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Clark County Sheriff', tex = 'clark_county_sheriff', weight = 0, pattern = 'EX11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Nye County Sheriff', tex = 'nye_county_sheriff', weight = 0, pattern = 'EX11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Highway Patrol (NHP)', tex = 'highway_patrol', weight = 0, pattern = 'EX11111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['New Hampshire'] = {
        { name = 'Old Man of the Mountain Standard', tex = 'old_man_standard', textColor = 10, pattern = '1111111' },
        { name = 'Moose Conservation Heritage', tex = 'moose_conservation', textColor = 10, pattern = '11111' },
        { name = 'Commercial', tex = 'commercial', textColor = 10, pattern = '111111' },
        { name = 'Old Man Standard (Alt)', tex = 'old_man_alt', textColor = 10, pattern = '1111111' },
        { name = 'Municipal Police', tex = 'municipal_police', textColor = 0, weight = 0, pattern = '1111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Police', tex = 'state_police', textColor = 6, weight = 0, pattern = '111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['New Jersey'] = {
        { name = 'Garden State Standard', tex = 'garden_state', pattern = 'A11AAA' },
        { name = 'Conserve Wildlife Bald Eagle', tex = 'conserve_wildlife', pattern = '1111AA' },
        { name = 'Commercial', tex = 'commercial', pattern = 'X11AAA' },
        { name = 'Garden State Standard (Alt)', tex = 'garden_state_alt', pattern = 'A11AAA' },
        { name = 'Municipal Government', tex = 'municipal', textColor = 5, weight = 0, pattern = '11111MG' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Police (NJSP)', tex = 'state_police', weight = 0, pattern = 'SPA111A' }, -- [GOVERNMENT / EXEMPT]
    },

    ['New York'] = {
        { name = 'Excelsior Standard (2020)', tex = 'excelsior_2020', textColor = 0, pattern = 'AAA1111' },
        { name = 'Conserve Open Space Bluebird', tex = 'conserve_open_space', pattern = 'A11111' },
        { name = 'Empire Gold Commercial', tex = 'empire_gold_commercial', textColor = 0, pattern = '11111AA' },
        { name = 'Empire Gold Standard (2010)', tex = 'empire_gold_2010', textColor = 0, pattern = 'AAA1111' },
        { name = 'Empire State White/Blue (2001)', tex = 'empire_blue_2001', textColor = 0, pattern = 'AAA1111' },
        { name = '9-11-01 United We Stand', tex = 'united_we_stand_911', pattern = 'A11111' },
        { name = 'State Police (NYSP)', tex = 'state_police', textColor = 0, weight = 0, pattern = 'A111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Oklahoma'] = {
        { name = 'Imagine That 46-Star (2024)', tex = 'imagine_that_2024', textColor = 11, pattern = 'AAA111' },
        { name = 'Explore Oklahoma Scissortail (2017)', tex = 'scissortail_2017', pattern = 'AAA111' },
        { name = 'Pioneers of the Prairie Bison', tex = 'pioneers_bison', pattern = '1111A' },
        { name = 'Commercial Truck', tex = 'commercial_truck', pattern = '11111V' },
        { name = 'City Government', tex = 'city_government', weight = 0, pattern = '11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'County Government', tex = 'county_government', weight = 0, pattern = '11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Oklahoma Highway Patrol (OHP)', tex = 'highway_patrol', weight = 0, pattern = 'OHP111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Oregon'] = {
        {
            name = 'Douglas Fir Tree Standard',
            tex = 'tree_standard',
            textColor = 0, -- Embossed Dark Blue
            pattern = '111AAA'
        },
        {
            name = 'Pacific Wonderland Centennial',
            tex = 'pacific_wonderland',
            textColor = '#FFD700', -- Gold / Yellow Hex
            fontExtents = { x = 0.28, y = 0.36, w = 0.82, h = 0.90 }, -- (x, y, width, height)
            pattern = '1A1111'
        },
        {
            name = 'Smokey Bear Keep Oregon Green',
            tex = 'smokey_bear',
            textColor = 0, -- Embossed Dark Navy Blue
            pattern = '11111'
        },
        {
            name = 'Oregon Coast Aquarium Puffin',
            tex = 'coastal_aquarium',
            textColor = 0, -- Dark Navy Blue
            pattern = '11111'
        },
        {
            name = 'Publicly Owned Government',
            tex = 'publicly_owned',
            textColor = 0, -- Dark Blue
            weight = 0,
            pattern = '111111'
        }, -- [GOVERNMENT / EXEMPT]
    },

    ['Pennsylvania'] = {
        { name = 'VisitPA Standard (2017)', tex = 'visitpa_2017', textColor = 0, pattern = 'AAA1111' },
        { name = 'Gradient Standard (1999)', tex = 'gradient_1999', textColor = 0, pattern = 'AAA1111' },
        { name = 'Emergency Vehicle', tex = 'emergency_vehicle', textColor = 6, weight = 0, pattern = 'EV11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'VisitPA Standard (Alt)', tex = 'visitpa_alt', textColor = 0, pattern = 'AAA1111' },
        { name = 'Municipal Government', tex = 'municipal_government', textColor = 0, weight = 0, pattern = '11111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Official Use State Government', tex = 'official_use', textColor = 0, weight = 0, pattern = '11111PA' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Utah'] = {
        { name = 'In God We Trust Standard', tex = 'in_god_we_trust', textColor = 0, pattern = '1AAA1' },
        { name = 'Ski Utah Greatest Snow Standard', tex = 'ski_utah', textColor = 0, pattern = 'A111AA' },
        { name = 'Delicate Arch Life Elevated', tex = 'delicate_arch', textColor = 0, pattern = 'A111AA' },
        { name = 'I Support Wildlife Elk', tex = 'support_wildlife_elk', pattern = '1AAA1' },
        { name = 'Government Exempt', tex = 'exempt_government', weight = 0, pattern = '111111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Utah Highway Patrol (UHP)', tex = 'highway_patrol', weight = 0, pattern = 'UHP111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Vermont'] = {
        { name = 'Green Mountain Standard', tex = 'green_mountain', textColor = 11, pattern = 'AAA111' },
        { name = 'Peregrine Falcon Conservation', tex = 'peregrine_falcon', textColor = 10, pattern = '11111' },
        { name = 'Volunteer Firefighter', tex = 'volunteer_fire', textColor = 6, weight = 0, pattern = 'A111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Green Mountain Standard (Alt)', tex = 'green_mountain_alt', textColor = 11, pattern = 'AAA111' },
        { name = 'Municipal Government', tex = 'municipal', textColor = 0, weight = 0, pattern = 'AAA111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Police 75th Anniversary', tex = 'state_police_75th', textColor = 10, weight = 0, pattern = '111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Police Green & Gold', tex = 'state_police', textColor = 1, weight = 0, pattern = '111' }, -- [GOVERNMENT / EXEMPT]
    },

    ['Washington'] = {
        { name = 'Mt. Rainier Evergreen Standard', tex = 'evergreen_rainier', textColor = 0, pattern = 'AAA1111' },
        { name = "Washington's Wildlife Black Bear", tex = 'wildlife_black_bear', textColor = 11, pattern = '11111' },
        { name = 'Behind the Badge Memorial', tex = 'behind_the_badge', textColor = 11, weight = 0, pattern = '1111' }, -- [GOVERNMENT / EXEMPT]
        { name = 'Mt. Rainier Standard (Alt)', tex = 'evergreen_alt', textColor = 0, pattern = 'AAA1111' },
        { name = 'Government Exempt', tex = 'exempt_government', weight = 0, pattern = '11111A' }, -- [GOVERNMENT / EXEMPT]
        { name = 'State Patrol (WSP)', tex = 'state_patrol', textColor = 0, weight = 0, pattern = '1111SP' }, -- [GOVERNMENT / EXEMPT]
    },
}

Config.EligiblePopulationTypes = {
    [2] = true, -- POPTYPE_RANDOM_PARKED
    [3] = true, -- POPTYPE_RANDOM_PATROL
    [4] = true, -- POPTYPE_RANDOM_SCENARIO
    [5] = true  -- POPTYPE_RANDOM_AMBIENT
}

Config.AllowUnknownPopulationType = false
