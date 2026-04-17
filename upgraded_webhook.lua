-- Upgraded Webhook System

local HttpService = game:GetService("HttpService")

local WEBHOOK = "https://discord.com/api/webhooks/1494489545406808237/7qxKp_Z3Ilgrntat3rr_n6RaioJyjBLKhYCVpqX9rwjvFyGalRAx5umN-WFJmHskyuG9"

local MIN_VALUE = 10000
local sentCache = {}

-- gets server link (Roblox)
local function getServerLink()
    local placeId = game.PlaceId
    local jobId = game.JobId
    return "https://www.roblox.com/games/"..placeId.."?jobId="..jobId
end

local function sendWebhook(animal)
    local data = {
        content = "",
        embeds = {{
            title = "🔥 High Value Animal Found!",
            description = "**"..animal.name.."**",
            color = 65280,
            fields = {
                {name="💎 Value", value=animal.genText, inline=true},
                {name="⭐ Rarity", value=animal.rarity, inline=true},
                {name="🧬 Mutation", value=animal.mutation, inline=true},
                {name="📊 Traits", value=animal.traits, inline=false},
                {name="👤 Owner", value=animal.owner, inline=true},
                {name="🌐 Server", value="[Join Server]("..getServerLink()..")", inline=false}
            },
            footer = {
                text = "Auto Scanner v2"
            }
        }}
    }

    local json = HttpService:JSONEncode(data)

    pcall(function()
        request({
            Url = WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    end)
end

-- Example trigger usage:
-- if genValue >= MIN_VALUE and not sentCache[uid] then
--     sentCache[uid] = true
--     sendWebhook(animalData)
-- end
