local StealPrompt = {}
local ActivePrompt = false

local steal_source
local active_menu = false

local VorpCore = {}

TriggerEvent('getCore',function(core)
    VorpCore = core
end)

TriggerEvent("menuapi:getData", function(call)
    MenuData = call
end)

function StealPlayerPrompt(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
    local str1 = Config.Texts['StrButton']	
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
        local steal, player_id, steal_ped = GetNearbyPlayer()
        if player_id ~= 0 and steal then
            if not ActivePrompt then
                StealPlayerPrompt(steal_ped)
                ActivePrompt = true
            end

            if PromptHasHoldModeCompleted(StealPrompt[steal_ped]) then
                Wait(500) 
                steal_source = player_id
                TriggerServerEvent('xakra_steal:MoneyOpenMenu', steal_source)
            end
        else
            ActivePrompt = false
            Citizen.InvokeNative(0x00EDE88D4D13CF59, StealPrompt[steal_ped])
            if active_menu then
                ClearPedTasks(PlayerPedId())
                TriggerServerEvent('xakra_steal:CloseInventory')
                active_menu = false
                MenuData.CloseAll()
            end
        end
    end
end)

RegisterNetEvent('xakra_steal:GetSourceSteal')
AddEventHandler('xakra_steal:GetSourceSteal', function(obj, option)
    if option == 'move' and steal_source then
        TriggerServerEvent('xakra_steal:MoveTosteal', obj, steal_source)
    elseif option == 'take' and steal_source then
        TriggerServerEvent('xakra_steal:TakeFromsteal', obj, steal_source)
    end
end)

RegisterNetEvent('xakra_steal:OpenMenu')
AddEventHandler('xakra_steal:OpenMenu', function(money)
    MenuData.CloseAll()
    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey("WORLD_HUMAN_CROUCH_INSPECT"), 0, true, false, false, false)
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
                    inputHeader = Config.Texts['Money'], -- header
                    type = 'text', -- inputype text, number,date.etc if number comment out the pattern
                    pattern = '[0-9.]{1,10}', -- regular expression validated for only numbers '[0-9]', for letters only [A-Za-z]+   with charecter limit  [A-Za-z]{5,20}     with chareceter limit and numbers [A-Za-z0-9]{5,}
                    title = 'Wrong value', -- if input doesnt match show this message
                    style = 'border-radius: 10px; background-color: ; border:none;', -- style  the inptup
                }
            }
        
            TriggerEvent('vorpinputs:advancedInput', json.encode(myInput),function(result)
                local number = tonumber(result)
                if number <= money then
                    TriggerServerEvent('xakra_steal:StealMoney', steal_source, number) 
                    MenuData.CloseAll()
                else
                    VorpCore.NotifyObjective(Config.Texts['TooMuchMoney'],4000)
                end
            end)
        end

        if (data.current.value == 'inventory') then --translate here same as the config
            TriggerServerEvent('xakra_steal:ReloadInventory', steal_source)
            TriggerServerEvent('xakra_steal:OpenInventory', steal_source)
        end

    end, function(data, menu)
        menu.close()
        active_menu = false
        ClearPedTasks(PlayerPedId())
    end)
end)

function GetNearbyPlayer()
    local pcoords = GetEntityCoords(PlayerPedId())
    local steal = false
    local steal_source
    local steal_ped
    for _, id in pairs(GetActivePlayers()) do
        steal_ped = GetPlayerPed(id)
        local player_coords = GetEntityCoords(steal_ped)
        local dist = GetDistanceBetweenCoords(pcoords, player_coords, 1)  
        
        if steal_ped ~= PlayerPedId() and dist < 2.5 then
            if Config.StealHogtied then
                if Citizen.InvokeNative(0x3AA24CCC0D451379, steal_ped) and not Citizen.InvokeNative(0xD453BB601D4A606E, steal_ped) then
                    steal_source = GetPlayerServerId(id)
                    steal = true
                end
            end
            if Config.Cuffed then
                if IsPedCuffed(steal_ped) then
                    steal_source = GetPlayerServerId(id)
                    steal = true
                end
            end
            if Config.StealDead then
                if IsEntityDead(steal_ped) then
                    steal_source = GetPlayerServerId(id)
                    steal = true
                end
            end
        end
    end
    return steal, steal_source, steal_ped
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
