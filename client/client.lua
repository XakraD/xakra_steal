local StealPrompt = {}

local steal_source
local active_menu = false

local VorpCore = {}

local stealing_players = {}

TriggerEvent('getCore',function(core)
    VorpCore = core
end)

TriggerEvent("menuapi:getData", function(call)
    MenuData = call
end)

function StealPlayerPrompt(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
    local str1 = Config.Texts['StrPrompt']	
    StealPrompt[entity] = PromptRegisterBegin()
    PromptSetControlAction(StealPrompt[entity], Config.KeySteal)
    str = CreateVarString(10, 'LITERAL_STRING', str1)
    PromptSetText(StealPrompt[entity], str)
    PromptSetEnabled(StealPrompt[entity], true)
    PromptSetVisible(StealPrompt[entity], true)
    PromptSetHoldMode(StealPrompt[entity], true)
    PromptSetGroup(StealPrompt[entity], group)
    PromptRegisterEnd(StealPrompt[entity])
end

Citizen.CreateThread(function()
	while true do
        Wait(100)
        local data_steal = GetNearbyPlayer()
        for _, steal in pairs(data_steal) do
            if steal.steal_source ~= 0 and steal.steal_enable then
                if not StealPrompt[steal.steal_ped] then
                    StealPlayerPrompt(steal.steal_ped)
                end

                if PromptHasHoldModeCompleted(StealPrompt[steal.steal_ped]) then
                    Wait(500) 
                    steal_source = steal.steal_source
                    TriggerServerEvent('xakra_steal:MoneyOpenMenu', steal.steal_source)
                end
            elseif active_menu and steal_source == steal.steal_source then
                ClearPedTasks(PlayerPedId())
                TriggerServerEvent('xakra_steal:CloseInventory')
                active_menu = false
                MenuData.CloseAll()
            end
        end
    end
end)

RegisterNetEvent('xakra_steal:StealingPlayers')
AddEventHandler('xakra_steal:StealingPlayers', function(source)
    if source ~= steal_source then
        table.insert(stealing_players, source)
    end
end)

RegisterNetEvent('xakra_steal:DelStealingPlayers')
AddEventHandler('xakra_steal:DelStealingPlayers', function(source)
    for i, player_id in pairs(stealing_players) do
        if player_id == source then
            table.remove(stealing_players, i)
        end
    end
end)

RegisterNetEvent('xakra_steal:OpenMenu')
AddEventHandler('xakra_steal:OpenMenu', function(money)
    MenuData.CloseAll()
    ClearPedTasksImmediately(PlayerPedId())
    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey("WORLD_HUMAN_CROUCH_INSPECT"), 0, true, false, false, false)
    active_menu = true

    local elements = {
        {
            label = Config.Texts['Money']..' ['..money..'$]',
            value = 'money',
            desc = Config.Texts['DescStealMoney']
        },
        {
            label = Config.Texts['Inventory'],
            value = 'inventory',
            desc = Config.Texts['DescStealInventory']
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
                    inputHeader = Config.Texts['Money'], -- header
                    type = 'text', -- inputype text, number,date.etc if number comment out the pattern
                    pattern = '[0-9.]{1,10}', -- regular expression validated for only numbers '[0-9]', for letters only [A-Za-z]+   with charecter limit  [A-Za-z]{5,20}     with chareceter limit and numbers [A-Za-z0-9]{5,}
                    title = 'Wrong value', -- if input doesnt match show this message
                    style = 'border-radius: 10px; background-color: ; border:none;', -- style  the inptup
                }
            }
        
            TriggerEvent('vorpinputs:advancedInput', json.encode(myInput),function(result)
                local number = tonumber(result)
                if number and number <= money then
                    TriggerServerEvent('xakra_steal:StealMoney', steal_source, number) 
                    MenuData.CloseAll()
                else
                    VorpCore.NotifyObjective(Config.Texts['TooMuchMoney'],4000)
                end
            end)
        end

        if (data.current.value == 'inventory') then
            TriggerServerEvent('xakra_steal:ReloadInventory', steal_source)
            TriggerServerEvent('xakra_steal:OpenInventory', steal_source)
            Wait(500)
        end

    end, function(data, menu)
        menu.close()
        active_menu = false
        ClearPedTasks(PlayerPedId())
        TriggerServerEvent('xakra_steal:CallDelStealingPlayers', steal_source)
        steal_source = nil
    end)
end)

RegisterNetEvent('xakra_steal:GetSourceSteal')
AddEventHandler('xakra_steal:GetSourceSteal', function(obj, option)
    if option == 'move' and steal_source then
        TriggerServerEvent('xakra_steal:MoveTosteal', obj, steal_source)
    elseif option == 'take' and steal_source then
        TriggerServerEvent('xakra_steal:TakeFromsteal', obj, steal_source)
    end
end)

function GetNearbyPlayer()
    local pcoords = GetEntityCoords(PlayerPedId())

    local data_steal = {}

    for _, id in pairs(GetActivePlayers()) do 
        local steal_enable = false
        local steal_source = GetPlayerServerId(id)
        local steal_ped = GetPlayerPed(id)

        local already_stealing = false
        for i, source in pairs(stealing_players) do
            if source == steal_source then
                already_stealing = true
            end
        end

        if steal_ped ~= PlayerPedId() and not already_stealing then
            local player_coords = GetEntityCoords(steal_ped)
            local dist = GetDistanceBetweenCoords(pcoords, player_coords, 1)  
            
            if Config.StealHogtied and dist < 2.5 and not IsEntityDead(steal_ped) then
                if Citizen.InvokeNative(0x3AA24CCC0D451379, steal_ped) and not Citizen.InvokeNative(0xD453BB601D4A606E, steal_ped) then
                    steal_enable = true
                end
            end
            if Config.Cuffed and dist < 2.5 and not IsEntityDead(steal_ped) then
                if IsPedCuffed(steal_ped) then
                    steal_enable = true
                end
            end
            if Config.StealDead and dist < 2.5 then
                if IsEntityDead(steal_ped) then
                    steal_enable = true
                end
            end
        end

        data_steal[#data_steal+1] = { 
            steal_enable = steal_enable,
            steal_source = steal_source,
            steal_ped = steal_ped,
        }
        
        if not steal_enable and StealPrompt[steal_ped] then
            Citizen.InvokeNative(0x00EDE88D4D13CF59, StealPrompt[steal_ped])    -- UiPromptDelete 
            StealPrompt[steal_ped] = nil
        end
    end
    return data_steal
end

AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
	  return
	end

    for _, v in pairs(StealPrompt) do
        Citizen.InvokeNative(0x00EDE88D4D13CF59, v) -- UiPromptDelete 
    end

    MenuData.CloseAll()
    if IsPedActiveInScenario(PlayerPedId()) then
        ClearPedTasksImmediately(PlayerPedId())
    end
end)