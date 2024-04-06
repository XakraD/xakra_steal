local StealPrompt = {}

local active_menu = false

local VORPcore = exports.vorp_core:GetCore()

TriggerEvent("menuapi:getData", function(call)
    MenuData = call
end)

function StealPlayerPrompt(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
    StealPrompt[entity] = PromptRegisterBegin()
    PromptSetControlAction(StealPrompt[entity], Config.KeySteal)
    local VarString = CreateVarString(10, 'LITERAL_STRING', T.StrPrompt)
    PromptSetText(StealPrompt[entity], VarString)
    PromptSetEnabled(StealPrompt[entity], true)
    PromptSetVisible(StealPrompt[entity], true)
    PromptSetHoldMode(StealPrompt[entity], 1000)
    PromptSetGroup(StealPrompt[entity], group)
    PromptRegisterEnd(StealPrompt[entity])
end

CreateThread(function()
    while true do
        local t = 500

        for _, v in pairs(GetNearbyPlayer()) do
            if not active_menu and v.source ~= 0 and v.enable and not Player(v.source).state.Stealing then
                t = 0

                if not StealPrompt[v.ped] then
                    StealPlayerPrompt(v.ped)
                end

                if PromptHasHoldModeCompleted(StealPrompt[v.ped]) then
                    TriggerServerEvent('xakra_steal:OpenMenu', v)
                    Wait(500)
                end

            elseif active_menu and not v.enable and LocalPlayer.state.DataSteal and LocalPlayer.state.DataSteal.source == v.source then
                TriggerServerEvent('xakra_steal:Stealing', LocalPlayer.state.DataSteal.source, false)
                LocalPlayer.state:set('DataSteal', nil, true)

                ClearPedTasks(PlayerPedId())
                TriggerServerEvent('xakra_steal:CloseInventory')
                active_menu = false
                MenuData.CloseAll()
            end
        end

        Wait(t)
    end
end)

CreateThread(function()
    while Config.HandsUpButton do
        Wait(0)

        if IsControlJustPressed(0, Config.HandsUpButton) and IsInputDisabled(0) and not IsEntityDead(PlayerPedId()) then
            local AnimDict, AnimName = 'script_proc@robberies@shop@rhodes@gunsmith@inside_upstairs', 'handsup_register_owner'

            if IsEntityPlayingAnim(PlayerPedId(), AnimDict, AnimName, 3) then
                SetCurrentPedWeapon(PlayerPedId(), joaat('WEAPON_UNARMED'), true)
                DisablePlayerFiring(PlayerPedId(), true)
                ClearPedSecondaryTask(PlayerPedId())

            else
                SetCurrentPedWeapon(PlayerPedId(), joaat('WEAPON_UNARMED'), true)
                DisablePlayerFiring(PlayerPedId(), true)

                if not HasAnimDictLoaded(AnimDict) then
                    RequestAnimDict(AnimDict)
    
                    while not HasAnimDictLoaded(AnimDict) do
                        Wait(0)
                    end
                end    

                TaskPlayAnim(PlayerPedId(), AnimDict, AnimName, 2.0, -1.0, -1, 31, 0, true, 0, false, 0, false)

                RemoveAnimDict(AnimDict)
            end
            
        end
    end
end)

RegisterNetEvent('xakra_steal:OpenMenu')
AddEventHandler('xakra_steal:OpenMenu', function(CharacterMoney)
    MenuData.CloseAll()

    ClearPedTasksImmediately(PlayerPedId())
    SetCurrentPedWeapon(PlayerPedId(), joaat('WEAPON_UNARMED'), true, 0, false, false)
    TaskStartScenarioInPlace(PlayerPedId(), joaat("WORLD_HUMAN_CROUCH_INSPECT"), 0, true, false, false, false)

    active_menu = true

    local elements = {
        {
            label = T.Money .. ': ' .. CharacterMoney .. '$',
            value = 'money',
            desc = T.DescStealMoney
        },
        {
            label = T.Inventory,
            value = 'inventory',
            desc = T.DescStealInventory
        },
    }

    MenuData.Open('default', GetCurrentResourceName(), 'StealMenu', {
        title = T.MenuTitle,
        subtext = T.MenuSubtext,
        align = Config.Align,
        elements = elements,

    }, function(data, menu)
        if not LocalPlayer.state.DataSteal then
            return
        end

        if data.current.value == 'money' then                                      --translate here same as the config
            local myInput = {
                type = 'enableinput',                                                -- dont touch
                inputType = 'input',                                                 -- or text area for sending messages
                button = T.Confirm,                                    -- button name
                placeholder = T.AmountMoney,                           --placeholdername
                style = 'block',                                                     --- dont touch
                attributes = {
                    inputHeader = T.Money,                             -- header
                    type = 'text',                                                   -- inputype text, number,date.etc if number comment out the pattern
                    pattern = '[0-9.]{1,10}',                                        -- regular expression validated for only numbers '[0-9]', for letters only [A-Za-z]+   with charecter limit  [A-Za-z]{5,20}     with chareceter limit and numbers [A-Za-z0-9]{5,}
                    title = 'Wrong value',                                           -- if input doesnt match show this message
                    style = 'border-radius: 10px; background-color: ; border:none;', -- style  the inptup
                }
            }

            TriggerEvent('vorpinputs:advancedInput', json.encode(myInput), function(result)
                local number = tonumber(result)

                if number and number <= CharacterMoney then
                    TriggerServerEvent('xakra_steal:StealMoney', LocalPlayer.state.DataSteal.source, number)

                    CharacterMoney = CharacterMoney - number
                    menu.setElement(1, 'label', T.Money .. ': ' .. CharacterMoney .. '$')
                    menu.refresh()
                    
                else
                    VORPcore.NotifyObjective(T.TooMuchMoney, 4000)
                end
            end)
        end

        if data.current.value == 'inventory' then
            TriggerServerEvent('xakra_steal:ReloadInventory', LocalPlayer.state.DataSteal.source)
            TriggerServerEvent('xakra_steal:OpenInventory', LocalPlayer.state.DataSteal.source)
        end

    end, function(data, menu)
        TriggerServerEvent('xakra_steal:Stealing', LocalPlayer.state.DataSteal.source, false)
        LocalPlayer.state:set('DataSteal', nil, true)
        ClearPedTasks(PlayerPedId())
        active_menu = false
        menu.close()
    end)
end)

function GetNearbyPlayer()
    local pcoords = GetEntityCoords(PlayerPedId())

    local data_steal = {}

    for _, id in pairs(GetActivePlayers()) do
        local enable = false
        local source = GetPlayerServerId(id)
        local ped = GetPlayerPed(id)

        if ped ~= PlayerPedId() and DoesEntityExist(ped) and GetDistanceBetweenCoords(pcoords, GetEntityCoords(ped), true) <= 2.5 then
            if Config.StealHogtied and not IsEntityDead(ped) and IsPedHogtied(ped) == 1 and IsPedBeingHogtied(ped) == 0 then
                enable = true
            end

            if Config.Cuffed and not IsEntityDead(ped) and IsPedCuffed(ped) then
                enable = true
            end

            if Config.StealDead and IsEntityDead(ped) then
                enable = true
            end

            local isHandsUp = IsEntityPlayingAnim(ped, 'script_proc@robberies@shop@rhodes@gunsmith@inside_upstairs', 'handsup_register_owner', 3)

            if Config.StealHandsUp and not IsEntityDead(ped) and isHandsUp then
                enable = true
            end
        end

        data_steal[#data_steal + 1] = {
            enable = enable,
            source = source,
            ped = ped,
        }

        if not enable and StealPrompt[ped] then
            PromptDelete(StealPrompt[ped])
            StealPrompt[ped] = nil
        end
    end

    return data_steal
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    for _, v in pairs(StealPrompt) do
        PromptDelete(v)
    end

    if LocalPlayer.state.DataSteal then
        LocalPlayer.state:set('DataSteal', nil, true)
    end

    if LocalPlayer.state.Stealing then
        LocalPlayer.state:set('Stealing', nil, true)
    end

    if active_menu then
        MenuData.CloseAll()

        if IsPedActiveInScenario(PlayerPedId()) then
            ClearPedTasksImmediately(PlayerPedId())
        end

        TriggerServerEvent('xakra_steal:CloseInventory')
    end
end)
