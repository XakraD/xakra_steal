local VorpCore = {}

TriggerEvent('getCore',function(core)
    VorpCore = core
end)

VorpInv = exports.vorp_inventory:vorp_inventoryApi()

RegisterCommand('test', function(source, args, rawCommand)
    local _source = source
    local Character = VorpCore.getUser(source).getUsedCharacter
    TriggerClientEvent('xakra_steal:OpenMenu',  source, Character.money)
end)

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

    local Character = VorpCore.getUser(_source).getUsedCharacter
    Character.addCurrency(0, amount)

    TriggerClientEvent('xakra_steal:OpenMenu', source, StealCharacter.money)
end)

RegisterServerEvent('xakra_steal:OpenInventory')
AddEventHandler('xakra_steal:OpenInventory', function()
    local _source = source
    local name = bankid
    local Character = VorpCore.getUser(_source).getUsedCharacter
    local charidentifier = Character.charIdentifier
    local identifier = Character.identifier

    local inventory = {}

    TriggerEvent('vorpCore:getUserInventory', tonumber(_source), function(getInventory)
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
    TriggerEvent('vorpCore:getUserWeapons', tonumber(_source), function(getUserWeapons)
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
    
    local inv = {}
    inv.itemList = inventory
    inv.action = 'setSecondInventoryItems'
    print(json.encode(inv))
    TriggerClientEvent('vorp_inventory:ReloadstealInventory', _source, json.encode(inv))
    TriggerClientEvent('vorp_inventory:OpenstealInventory', _source, 'SEARCH', charidentifier)
end)

RegisterServerEvent('syn_search:MoveTosteal')
AddEventHandler('syn_search:MoveTosteal', function(obj)
    local _source = source

    local decode_obj = json.decode(obj)
    local player_hogtied = GetStealSource()

    if decode_obj.type == "item_standard" then
        local canCarry = VorpInv.canCarryItem(player_hogtied, decode_obj.item.name, decode_obj.number)
        if canCarry then
            VorpInv.subItem(source, decode_obj.item.name, decode_obj.number)
            VorpInv.addItem(player_hogtied, decode_obj.item.name, decode_obj.number)
        else
            print("full")
        end
    elseif decode_obj.type == "item_standard" then
        VorpInv.canCarryWeapons(player_hogtied, 1, function(cb)
            local canCarry = cb
            if canCarry then
                VorpInv.subWeapon(_source, decode_obj.item.id)
                VorpInv.giveWeapon(player_hogtied, decode_obj.item.id, 0)
            else
              print("full")
            end
        end)
    end
end)

RegisterServerEvent('syn_search:TakeFromsteal')
AddEventHandler('syn_search:TakeFromsteal', function(obj)
    local _source = source

    local decode_obj = json.decode(obj)
    local player_hogtied = GetStealSource()

    if decode_obj.type == "item_standard" then
        local canCarry = VorpInv.canCarryItem(source, decode_obj.item.name, decode_obj.number)
        if canCarry then
            VorpInv.subItem(player_hogtied, decode_obj.item.name, decode_obj.number)
            VorpInv.addItem(_source, decode_obj.item.name, decode_obj.number)
        else
            print("full")
        end
    elseif decode_obj.type == "item_standard" then
        VorpInv.canCarryWeapons(_source, 1, function(cb)
            local canCarry = cb
            if canCarry then
                VorpInv.subWeapon(player_hogtied, decode_obj.item.id)
                VorpInv.giveWeapon(_source, decode_obj.item.id, 0)
            else
                print("full")
            end
        end)
    end
end)