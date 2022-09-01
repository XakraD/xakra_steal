
local StealPrompt
local StealPrompts = GetRandomIntInRange(0, 0xffffff)

local steal_source
local active_menu = false

TriggerEvent("menuapi:getData", function(call)
    MenuData = call
end)

function StealPlayerPrompt()
    local str = Config.Texts['StrButton']
    StealPrompt = PromptRegisterBegin()
    PromptSetControlAction(StealPrompt, Config.KeySteal)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(StealPrompt, str)
    PromptSetEnabled(StealPrompt, 1)
    PromptSetVisible(StealPrompt, 1)
	PromptSetHoldMode(StealPrompt, true)
	PromptSetGroup(StealPrompt, StealPrompts)
	Citizen.InvokeNative(0xC5F428EE08FA7F2C,StealPrompt,true)
	PromptRegisterEnd(StealPrompt)
end

Citizen.CreateThread(function()
    StealPlayerPrompt()
	while true do
		Wait(4)
        local hotgied, player_id = GetNearbyPlayer()
        if Config.Hogtie then
            if hotgied and not active_menu then
                local label  = CreateVarString(10, 'LITERAL_STRING', 'Jugador')
                PromptSetActiveGroupThisFrame(StealPrompt, label)
                if PromptHasHoldModeCompleted(StealPrompt) then
                    Wait(500) 
                    steal_source = player_id
                    TriggerServerEvent('xakra_steal:MoneyOpenMenu', steal_source)
                end
            end
        end
        if Config.Dead then
            if IsEntityDead(player_id) then
                local label  = CreateVarString(10, 'LITERAL_STRING', 'Jugador')
                PromptSetActiveGroupThisFrame(StealPrompt, label)
                if PromptHasHoldModeCompleted(StealPrompt) then
                    Wait(500) 
                    steal_source = player_id
                    TriggerServerEvent('xakra_steal:MoneyOpenMenu', steal_source)
                end
            end
        end
    end
end)

RegisterNetEvent('xakra_steal:OpenMenu')
AddEventHandler('xakra_steal:OpenMenu', function(money)
    MenuData.CloseAll()
    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey("WORLD_HUMAN_CROUCH_INSPECT"), 0, true, false, false, false) -- Animación tirarse al suelo. 
    active_menu = true

    local elements = {
        {
            label = Config.Texts['Money']..' ['..money..'$]',
            value = 'money',
            desc = 'Robar dinero'
        },
        {
            label = Config.Texts['Inventory'],
            value = 'inventory',
            desc = 'Buscar en el inventario'
        },
    }

    MenuData.Open('default', GetCurrentResourceName(), 'menuapi', {
        title = Config.Texts['MenuTitle'],
        subtext = Config.Texts['MenuSubtext'],
        align = Config.Align,
        elements = elements

    }, function(data, menu)
        if (data.current.value == 'money') then --translate here same as the config
            local myInput = {
                type = 'enableinput', -- dont touch
                inputType = 'input', -- or text area for sending messages
                button = Config.Texts['Confirm'], -- button name
                placeholder = Config.Texts['AmountMoney'], --placeholdername
                style = 'block', --- dont touch
                attributes = {
                    inputHeader = Config.Texts['AmountMoney'], -- header
                    type = 'text', -- inputype text, number,date.etc if number comment out the pattern
                    pattern = '[0-9.]{1,10}', -- regular expression validated for only numbers '[0-9]', for letters only [A-Za-z]+   with charecter limit  [A-Za-z]{5,20}     with chareceter limit and numbers [A-Za-z0-9]{5,}
                    title = 'Wrong value', -- if input doesnt match show this message
                    style = 'border-radius: 10px; background-color: ; border:none;', -- style  the inptup
                }
            }
        
            TriggerEvent('vorpinputs:advancedInput', json.encode(myInput),function(result)
                if result then
                    TriggerServerEvent('xakra_steal:StealMoney', steal_source, tonumber(result)) 
                    MenuData.CloseAll()
                end
            end)
        end

        if (data.current.value == 'inventory') then --translate here same as the config
            TriggerServerEvent('xakra_steal:OpenInventory', steal_source)
        end

    end, function(data, menu)
        menu.close()
        active_menu = false
        ClearPedTasks(PlayerPedId())
    end)
end)

function GetStealSource()
    return steal_source
end

function GetNearbyPlayer()
    local pcoords = GetEntityCoords(PlayerPedId())
    local hotgied = false
    local player_id
    for i = 0, 255 do
        if NetworkIsPlayerActive(i) then
            player_id = GetPlayerPed(GetPlayerFromServerId(i))
            local player_coords = GetEntityCoords(player)
            local dist = GetDistanceBetweenCoords(pcoords, player_coords, 1)
            if Citizen.InvokeNative(0x3AA24CCC0D451379, player) and dist > 2 then
                hotgied = true
            -- table.insert(players, GetPlayerServerId(i))
            end
        end
    end
    return hotgied, player_id
end

AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
	  return
	end
    MenuData.CloseAll()
    if IsPedActiveInScenario(PlayerPedId()) then
        ClearPedTasksImmediately(PlayerPedId())
    end
end)
