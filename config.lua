Config = {}

Config.Align = 'top-left' -- align to menu

Config.KeySteal = 0xA1ABB953

Config.StealHogtied = true -- Steal from hogtied players
Config.Cuffed = true  -- Steal from handcuffed players
Config.StealDead = true  -- Steal from dead players

Config.Webhook = ''

Config.ItemsBlackList = { -- Names of items or weapons that cannot be stolen
    'water',
    'WEAPON_MELEE_KNIFE',
}

Config.Texts = {
    ['StrPrompt'] = 'Robar',
    ['DescStealMoney'] = 'Robar dinero',
    ['MenuTitle'] = 'Jugador',
    ['MenuSubtext'] = 'Eliga una opción',
    ['Confirm'] = 'Confirmar',
    ['AmountMoney'] = 'Cantidad',
    ['Money'] = 'Dinero',
    ['Inventory'] = 'Inventario',
    ['DescStealInventory'] = 'Buscar en el inventario',
    ['NotStealCarryItems'] = 'El jugador no puede llevar mas items',
    ['NotStealCarryWeapon'] = 'El jugador no puede llevar mas armas',
    ['NotCarryItems'] = 'No puedes llevar mas items.',
    ['TooMuchMoney'] = 'No puedes robar mas de lo que tiene el jugador',
    ['StealMoney'] = 'Has robado: ',
    ['ItemInBlackList'] = 'No puedes robar este objeto.',
    ['WebHookTakeSteal'] = 'Ha robado: ',
    ['WebHookMoveSteal'] = 'Ha entregado: ',
    ['WebHookPlayer'] = ', al jugador: ',
}
