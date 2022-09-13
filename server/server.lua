local VorpCore = {}

TriggerEvent('getCore',function(core)
    VorpCore = core
end)

VorpInv = exports.vorp_inventory:vorp_inventoryApi()

RegisterServerEvent('xakra_steal:MoneyOpenMenu')
AddEventHandler('xakra_steal:MoneyOpenMenu', function(steal_source)
    local _source = source
    local Character = VorpCore.getUser(steal_source).getUsedCharacter

    TriggerClientEvent('xakra_steal:OpenMenu', source, Character.money)
end)

RegisterServerEvent('xakra_steal:StealMoney')
AddEventHandler('xakra_steal:StealMoney', function(steal_source, amount)
    local _source = source
    local StealCharacter = VorpCore.getUser(steal_source).getUsedCharacter
    StealCharacter.removeCurrency(0, amount)
    local steal_money = StealCharacter.money - amount

    local Character = VorpCore.getUser(_source).getUsedCharacter
    Character.addCurrency(0, amount)

    VorpCore.NotifyAvanced(_source,  Config.Texts['StealMoney']..amount.."$", "menu_textures", "log_gang_bag", "COLOR_PURE_WHITE", 2000)

    TriggerClientEvent('xakra_steal:OpenMenu', _source, steal_money)
end)

RegisterServerEvent('xakra_steal:ReloadInventory')
AddEventHandler('xakra_steal:ReloadInventory', function(steal_source, player_source)
    local _steal_source = steal_source
    local _source
    if not player_source then
        _source = source
    else
        _source = player_source
    end

    local Character = VorpCore.getUser(_steal_source).getUsedCharacter
    local charidentifier = Character.charIdentifier
    local identifier = Character.identifier

    local inventory = {}

    TriggerEvent('vorpCore:getUserInventory', tonumber(_steal_source), function(getInventory)
        for _, item in pairs (getInventory) do
            local data_item = {
                ['count'] = item.count,
                ['name'] = item.name,
                ['limit'] = item.limit,
                ['type'] = item.type,
                ['label'] = item.label
            }
            table.insert(inventory, data_item) 
        end
    end) 
    TriggerEvent('vorpCore:getUserWeapons', tonumber(_steal_source), function(getUserWeapons)
        for _, weapon in pairs (getUserWeapons) do
            local data_weapon = {
                ['count'] = -1,
                ['name'] = weapon.name,
                ['limit'] = -1,
                ['type'] = 'item_weapon',
                ['label'] = '',
                ['id'] = weapon.id
            }
            table.insert(inventory, data_weapon)
        end
    end)

    local data = {}
    data.itemList = inventory
    data.action = 'setSecondInventoryItems'
    TriggerClientEvent('vorp_inventory:ReloadstealInventory', _source, json.encode(data))
end)

RegisterServerEvent('xakra_steal:OpenInventory')
AddEventHandler('xakra_steal:OpenInventory', function(steal_source)
    local _source = source
    local Character = VorpCore.getUser(steal_source).getUsedCharacter
    local charidentifier = Character.charIdentifier

    TriggerClientEvent('vorp_inventory:OpenstealInventory', _source, Config.Texts['MenuTitle'], charidentifier)
end)

RegisterServerEvent('syn_search:MoveTosteal')
AddEventHandler('syn_search:MoveTosteal', function(obj)
    local _source = source
    TriggerClientEvent('xakra_steal:GetSourceSteal', _source, obj, 'move')
end)

RegisterServerEvent('xakra_steal:MoveTosteal')
AddEventHandler('xakra_steal:MoveTosteal', function(obj, steal_source)
    local _steal_source = steal_source
    local _source = source

    local decode_obj = json.decode(obj)

    if decode_obj.type == 'item_standard' then
        local canCarry = VorpInv.canCarryItem(_steal_source, decode_obj.item.name, decode_obj.number)
        if canCarry then
            VorpInv.subItem(_source, decode_obj.item.name, decode_obj.number)
            VorpInv.addItem(_steal_source, decode_obj.item.name, decode_obj.number)
            TriggerEvent('xakra_steal:ReloadInventory', _steal_source, _source)
        else
            VorpCore.NotifyObjective(_source, Config.Texts['NotStealCarryItems'],4000)
        end
    elseif decode_obj.type == 'item_weapon' then
        VorpInv.canCarryWeapons(_steal_source, 1, function(cb)
            local canCarry = cb
            if canCarry then
                VorpInv.subWeapon(_source, decode_obj.item.id)
                VorpInv.giveWeapon(_steal_source, decode_obj.item.id, 0)
                TriggerEvent('xakra_steal:ReloadInventory', _steal_source, _source)
            else
                VorpCore.NotifyObjective(_source, Config.Texts['NotStealCarryWeapon'],4000)
            end
        end)
    end
end)

RegisterServerEvent('syn_search:TakeFromsteal')
AddEventHandler('syn_search:TakeFromsteal', function(obj)
    local _source = source
    TriggerClientEvent('xakra_steal:GetSourceSteal', _source, obj, 'take')
end)

RegisterServerEvent('xakra_steal:TakeFromsteal')
AddEventHandler('xakra_steal:TakeFromsteal', function(obj, steal_source)
    local _steal_source = steal_source
    local _source = source

    local decode_obj = json.decode(obj)

    if decode_obj.type == 'item_standard' then
        local canCarry = VorpInv.canCarryItem(_source, decode_obj.item.name, decode_obj.number)
        if canCarry then
            VorpInv.subItem(_steal_source, decode_obj.item.name, decode_obj.number)
            VorpInv.addItem(_source, decode_obj.item.name, decode_obj.number)
            TriggerEvent('xakra_steal:ReloadInventory', _steal_source, _source)
        else
            VorpCore.NotifyObjective(_source, Config.Texts['NotCarryItems'],4000)
        end
    elseif decode_obj.type == 'item_weapon' then
        VorpInv.canCarryWeapons(_source, 1, function(cb)
            local canCarry = cb
            if canCarry then
                VorpInv.subWeapon(_steal_source, decode_obj.item.id)
                VorpInv.giveWeapon(_source, decode_obj.item.id, 0)
                TriggerEvent('xakra_steal:ReloadInventory', _steal_source, _source)
            else
                VorpCore.NotifyObjective(_source, Config.Texts['NotCarryWeapon'],4000)
            end
        end)
    end
end)

RegisterServerEvent('xakra_steal:CloseInventory')
AddEventHandler('xakra_steal:CloseInventory', function(steal_source)
    local _source = source
    VorpInv.CloseInv(_source)
end)