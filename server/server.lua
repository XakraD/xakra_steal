local VORPcore = exports.vorp_core:GetCore()

RegisterServerEvent('xakra_steal:OpenMenu')
AddEventHandler('xakra_steal:OpenMenu', function(data)
    local _source = source

    local Amount = 0

    for _, player in pairs(GetPlayers()) do
        local CharacterJob = Player(player).state.Character and Player(player).state.Character.Job

        for _, job in pairs(Config.RequiredJobs.Jobs) do
            if CharacterJob == job then
                Amount = Amount + 1
                break
            end
        end
    end

    if Amount < Config.RequiredJobs.Amount then
        VORPcore.NotifyObjective(_source, T.NotJobs, 4000)
        return
    end

    Player(_source).state:set('DataSteal', data, true)

    Player(data.source).state:set('Stealing', true, true)
    local Character = VORPcore.getUser(data.source).getUsedCharacter
    TriggerClientEvent('xakra_steal:OpenMenu', _source, Character.money)
end)

RegisterServerEvent('xakra_steal:Stealing')
AddEventHandler('xakra_steal:Stealing', function(steal_source, enable)
    Player(steal_source).state:set('Stealing', enable, true)
end)

RegisterServerEvent('xakra_steal:StealMoney')
AddEventHandler('xakra_steal:StealMoney', function(steal_source, amount)
    local _source = source
    local StealCharacter = VORPcore.getUser(steal_source).getUsedCharacter

    if CheckLimit(_source, steal_source, 'Money', amount) then
        StealCharacter.removeCurrency(0, amount)

        local Character = VORPcore.getUser(_source).getUsedCharacter
        Character.addCurrency(0, amount)

        VORPcore.NotifyAvanced(_source, T.StealMoney .. ' ' .. amount .. "$", "menu_textures", "log_gang_bag", "COLOR_PURE_WHITE", 2000)

        DiscordLog(string.format(T.WebhooksLang.DiscordStealMoney, amount, GetPlayerName(_source), GetPlayerName(steal_source)))
    end
end)

RegisterServerEvent('xakra_steal:ReloadInventory')
AddEventHandler('xakra_steal:ReloadInventory', function(steal_source, player_source)
    local _source = player_source or source

    local inventory = {}

    exports.vorp_inventory:getUserInventoryItems(tonumber(steal_source), function(getInventory)
        for _, v in pairs(getInventory) do
            table.insert(inventory, v)
        end
    end)

    exports.vorp_inventory:getUserInventoryWeapons(tonumber(steal_source), function(getUserWeapons)
        for _, v in pairs(getUserWeapons) do
            v.count = 1
            v.limit = 1
            v.type = 'item_weapon'
            table.insert(inventory, v)
        end
    end)

    TriggerClientEvent('vorp_inventory:ReloadstealInventory', _source, json.encode({
        itemList = inventory,
        action = 'setSecondInventoryItems',
    }))
end)

RegisterServerEvent('xakra_steal:OpenInventory')
AddEventHandler('xakra_steal:OpenInventory', function(steal_source)
    local _source = source
    local Character = VORPcore.getUser(steal_source).getUsedCharacter

    TriggerClientEvent('vorp_inventory:OpenstealInventory', _source, T.MenuTitle, Character.charIdentifier)
end)

RegisterServerEvent('syn_search:MoveTosteal')
AddEventHandler('syn_search:MoveTosteal', function(obj)
    local _source = source

    local steal_source = Player(_source).state.DataSteal and Player(_source).state.DataSteal.source

    if not steal_source then
        return
    end

    local decode_obj = json.decode(obj)
    decode_obj.number = tonumber(decode_obj.number)

    if decode_obj.type == 'item_standard' and decode_obj.number > 0 and decode_obj.number <= tonumber(decode_obj.item.count) then
        local canCarrys = exports.vorp_inventory:canCarryItems(steal_source, decode_obj.number)
        local canCarry = exports.vorp_inventory:canCarryItem(steal_source, decode_obj.item.name, decode_obj.number)
        if canCarrys and canCarry then
            exports.vorp_inventory:subItem(_source, decode_obj.item.name, decode_obj.number, decode_obj.item.metadata)
            exports.vorp_inventory:addItem(steal_source, decode_obj.item.name, decode_obj.number, decode_obj.item.metadata)
            Wait(100)
            TriggerEvent('xakra_steal:ReloadInventory', steal_source, _source)
            DiscordLog(string.format(T.WebhooksLang.DiscordMoveItem, decode_obj.number, decode_obj.item.label, GetPlayerName(_source), GetPlayerName(steal_source)))
        else
            VORPcore.NotifyObjective(_source, T.NotStealCarryItems, 4000)
        end

    elseif decode_obj.type == 'item_weapon' then
        local canCarry = exports.vorp_inventory:canCarryWeapons(steal_source, 1, nil, decode_obj.item.name)
        if canCarry then
            -- exports.vorp_inventory:subWeapon(_source, decode_obj.item.id)
            exports.vorp_inventory:giveWeapon(steal_source, decode_obj.item.id, _source)
            Wait(100)
            TriggerEvent('xakra_steal:ReloadInventory', steal_source, _source)
            DiscordLog(string.format(T.WebhooksLang.DiscordMoveWeapon, decode_obj.item.label, GetPlayerName(_source), GetPlayerName(steal_source)))
        else
            VORPcore.NotifyObjective(_source, T.NotStealCarryWeapon, 4000)
        end
    end
end)

RegisterServerEvent('syn_search:TakeFromsteal')
AddEventHandler('syn_search:TakeFromsteal', function(obj)
    local _source = source

    local steal_source = Player(_source).state.DataSteal and Player(_source).state.DataSteal.source

    if not steal_source then
        return
    end

    local decode_obj = json.decode(obj)
    decode_obj.number = tonumber(decode_obj.number)

    local inblacklist = false
    for _, item in pairs(Config.ItemsBlackList) do
        if item == decode_obj.item.name then
            inblacklist = true
            VORPcore.NotifyObjective(_source, T.ItemInBlackList, 4000)
        end
    end

    if decode_obj.type == 'item_standard' and not inblacklist and decode_obj.number > 0 and decode_obj.number <= tonumber(decode_obj.item.count) then
        if not CheckLimit(_source, steal_source, 'Items', decode_obj.number) then
            return
        end

        local canCarrys = exports.vorp_inventory:canCarryItems(_source, decode_obj.number)
        local canCarry = exports.vorp_inventory:canCarryItem(_source, decode_obj.item.name, decode_obj.number)
        if canCarrys and canCarry then
            exports.vorp_inventory:subItem(steal_source, decode_obj.item.name, decode_obj.number, decode_obj.item.metadata)
            exports.vorp_inventory:addItem(_source, decode_obj.item.name, decode_obj.number, decode_obj.item.metadata)
            Wait(100)
            TriggerEvent('xakra_steal:ReloadInventory', steal_source, _source)
            DiscordLog(string.format(T.WebhooksLang.DiscordStealItem, decode_obj.number, decode_obj.item.label, GetPlayerName(_source), GetPlayerName(steal_source)))
        else
            VORPcore.NotifyObjective(_source, T.NotCarryItems, 4000)
        end

    elseif decode_obj.type == 'item_weapon' and not inblacklist then
        if not CheckLimit(_source, steal_source, 'Weapons', 1) then
            return
        end

        local canCarry = exports.vorp_inventory:canCarryWeapons(_source, 1, nil, decode_obj.item.name)
        if canCarry then
            -- exports.vorp_inventory:subWeapon(steal_source, decode_obj.item.id)
            exports.vorp_inventory:giveWeapon(_source, decode_obj.item.id, steal_source)
            Wait(100)
            TriggerEvent('xakra_steal:ReloadInventory', steal_source, _source)
            DiscordLog(string.format(T.WebhooksLang.DiscordStealWeapon, decode_obj.item.label, GetPlayerName(_source), GetPlayerName(steal_source)))
        else
            VORPcore.NotifyObjective(_source, T.NotCarryWeapon, 4000)
        end
    end
end)

RegisterServerEvent('xakra_steal:CloseInventory')
AddEventHandler('xakra_steal:CloseInventory', function(steal_source)
    local _source = source
    exports.vorp_inventory:closeInventory(_source)
end)

local PlayersLimit = {}

function CheckLimit(source, steal_source, Limit, amount)
    if Config.Limit[Limit] then
        local Character = VORPcore.getUser(steal_source).getUsedCharacter

        if not PlayersLimit[Character.charIdentifier] then
            PlayersLimit[Character.charIdentifier] = {
                Money = 0,
                Weapons = 0,
                Items = 0,
            }
        end

        if (PlayersLimit[Character.charIdentifier][Limit] + amount) > Config.Limit[Limit] then
            VORPcore.NotifyObjective(source, T.Limit .. ' ' .. PlayersLimit[Character.charIdentifier][Limit] .. '/' .. Config.Limit[Limit], 4000)
            DiscordLog(string.format(T.WebhooksLang.DiscordStealLimit, Limit, GetPlayerName(source), PlayersLimit[Character.charIdentifier][Limit], Config.Limit[Limit]))
            return false
        end

        PlayersLimit[Character.charIdentifier][Limit] = PlayersLimit[Character.charIdentifier][Limit] + amount

        return true
    end

    return true
end

function DiscordLog(message)
	if Config.Webhook.UseWebhook then
		VORPcore.AddWebhook(
			Config.Webhook.WebhookTitle,
			Config.Webhook.WebhookUrl,
			message,
			Config.Webhook.WebhookColor,
			Config.Webhook.WebhookName,
			Config.Webhook.WebhookLogo,
			Config.Webhook.WebhookLogoFooter,
			Config.Webhook.WebhookAvatar
		)
	end
end