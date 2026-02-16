local propModel = ''
local spawnedProp = nil
local boneIndex = 57005
local animDict = ''
local animName = ''
local animFlag = 49

local xPos, yPos, zPos = 0.0, 0.0, 0.0
local xRot, yRot, zRot = 0.0, 0.0, 0.0
local increment = 0.01
local uiOpen = false

local useSoftPinning = false
local collision = false
local fixedRot = false
local cameraMode = false

local function LoadAnimDict(dict)
    if not DoesAnimDictExist(dict) then return false end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then return false end
    end
    return true
end

local function LoadModel(model)
    local hash = GetHashKey(model)
    if not IsModelValid(hash) then return false end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then return false end
    end
    return true
end

local function GetState()
    return {
        propModel = propModel,
        boneIndex = boneIndex,
        animDict = animDict,
        animName = animName,
        animFlag = animFlag,
        xPos = xPos,
        yPos = yPos,
        zPos = zPos,
        xRot = xRot,
        yRot = yRot,
        zRot = zRot,
        increment = increment,
        useSoftPinning = useSoftPinning,
        collision = collision,
        fixedRot = fixedRot,
        hasProp = spawnedProp ~= nil
    }
end

local function SendState()
    SendNUIMessage({ action = 'updateState', data = GetState() })
end

local function RemoveProp()
    if spawnedProp and DoesEntityExist(spawnedProp) then
        DeleteObject(spawnedProp)
    end
    spawnedProp = nil
end

local function AttachPropToPed()
    local ped = PlayerPedId()
    if propModel == '' then return end

    if spawnedProp and DoesEntityExist(spawnedProp) then
        DeleteObject(spawnedProp)
        spawnedProp = nil
    end

    local hash = GetHashKey(propModel)
    if not IsModelValid(hash) then return end

    if not HasModelLoaded(hash) then
        if not LoadModel(propModel) then return end
    end

    local coords = GetEntityCoords(ped)
    spawnedProp = CreateObject(hash, coords.x, coords.y, coords.z, true, true, true)

    if not spawnedProp or not DoesEntityExist(spawnedProp) then
        spawnedProp = nil
        return
    end

    AttachEntityToEntity(
        spawnedProp,
        ped,
        GetPedBoneIndex(ped, boneIndex),
        xPos, yPos, zPos,
        xRot, yRot, zRot,
        true,
        useSoftPinning,
        collision,
        fixedRot,
        2,
        true
    )

    SetModelAsNoLongerNeeded(hash)
end

RegisterCommand('offsets', function()
    uiOpen = not uiOpen
    cameraMode = false
    SetNuiFocus(uiOpen, uiOpen)
    if uiOpen then
        SendState()
    end
    SendNUIMessage({ action = uiOpen and 'open' or 'close' })
end, false)

RegisterNUICallback('close', function(_, cb)
    uiOpen = false
    cameraMode = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('enableCamera', function(_, cb)
    if not uiOpen or cameraMode then
        cb('ok')
        return
    end
    cameraMode = true
    SetNuiFocus(false, false)
    cb('ok')

    CreateThread(function()
        Wait(500)
        while cameraMode and uiOpen do
            Wait(0)
            if IsControlJustPressed(0, 25) then
                break
            end
        end
        cameraMode = false
        if uiOpen then
            SetNuiFocus(true, true)
        end
    end)
end)

RegisterNUICallback('setProp', function(data, cb)
    propModel = data.model or ''
    if propModel ~= '' then
        AttachPropToPed()
    end
    cb(GetState())
end)

RegisterNUICallback('setBone', function(data, cb)
    boneIndex = tonumber(data.bone) or 57005
    if spawnedProp and DoesEntityExist(spawnedProp) then
        AttachPropToPed()
    end
    cb(GetState())
end)

RegisterNUICallback('adjustPos', function(data, cb)
    local axis = data.axis
    local dir = data.dir
    local step = increment * dir

    if axis == 'x' then
        xPos = xPos + step
    elseif axis == 'y' then
        yPos = yPos + step
    elseif axis == 'z' then
        zPos = zPos + step
    end

    xPos = math.floor(xPos * 100 + 0.5) / 100
    yPos = math.floor(yPos * 100 + 0.5) / 100
    zPos = math.floor(zPos * 100 + 0.5) / 100

    if spawnedProp and DoesEntityExist(spawnedProp) then
        AttachPropToPed()
    end
    cb(GetState())
end)

RegisterNUICallback('adjustRot', function(data, cb)
    local axis = data.axis
    local dir = data.dir
    local step = increment * 100 * dir

    if axis == 'x' then
        xRot = xRot + step
    elseif axis == 'y' then
        yRot = yRot + step
    elseif axis == 'z' then
        zRot = zRot + step
    end

    xRot = math.floor(xRot * 100 + 0.5) / 100
    yRot = math.floor(yRot * 100 + 0.5) / 100
    zRot = math.floor(zRot * 100 + 0.5) / 100

    if spawnedProp and DoesEntityExist(spawnedProp) then
        AttachPropToPed()
    end
    cb(GetState())
end)

RegisterNUICallback('setPosAxis', function(data, cb)
    local axis = data.axis
    local val = tonumber(data.value) or 0.0
    val = math.floor(val * 100 + 0.5) / 100

    if axis == 'x' then
        xPos = val
    elseif axis == 'y' then
        yPos = val
    elseif axis == 'z' then
        zPos = val
    end

    if spawnedProp and DoesEntityExist(spawnedProp) then
        AttachPropToPed()
    end
    cb(GetState())
end)

RegisterNUICallback('setRotAxis', function(data, cb)
    local axis = data.axis
    local val = tonumber(data.value) or 0.0
    val = math.floor(val * 100 + 0.5) / 100

    if axis == 'x' then
        xRot = val
    elseif axis == 'y' then
        yRot = val
    elseif axis == 'z' then
        zRot = val
    end

    if spawnedProp and DoesEntityExist(spawnedProp) then
        AttachPropToPed()
    end
    cb(GetState())
end)

RegisterNUICallback('setIncrement', function(data, cb)
    increment = tonumber(data.value) or 0.01
    increment = math.floor(increment * 100 + 0.5) / 100
    if increment < 0.01 then increment = 0.01 end
    cb(GetState())
end)


RegisterNUICallback('playAnim', function(data, cb)
    animDict = data.dict or ''
    animName = data.name or ''
    animFlag = tonumber(data.flag) or 49

    if animDict == '' or animName == '' then
        cb(GetState())
        return
    end

    local ped = PlayerPedId()
    if LoadAnimDict(animDict) then
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, animFlag, 0, false, false, false)
    end
    cb(GetState())
end)

RegisterNUICallback('stopAnim', function(_, cb)
    ClearPedTasksImmediately(PlayerPedId())
    cb(GetState())
end)

RegisterNUICallback('removeProp', function(_, cb)
    RemoveProp()
    propModel = ''
    cb(GetState())
end)

RegisterNUICallback('resetOffsets', function(_, cb)
    xPos, yPos, zPos = 0.0, 0.0, 0.0
    xRot, yRot, zRot = 0.0, 0.0, 0.0

    if spawnedProp and DoesEntityExist(spawnedProp) then
        AttachPropToPed()
    end
    cb(GetState())
end)

RegisterNUICallback('copyCode', function(data, cb)
    local code

    if data.posrot then
        code = string.format(
            "Pos = vector3(%.2f, %.2f, %.2f),\nRot = vector3(%.1f, %.1f, %.1f),",
            xPos, yPos, zPos, xRot, yRot, zRot
        )
    else
        code = string.format(
            'AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, %d), %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, true, false, false, false, 2, true)',
            boneIndex, xPos, yPos, zPos, xRot, yRot, zRot
        )

        if propModel ~= '' then
            code = code .. ' -- ' .. propModel
        end
    end

    cb({ code = code })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    RemoveProp()
    if uiOpen then
        SetNuiFocus(false, false)
    end
end)
