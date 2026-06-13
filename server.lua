local loginAttempts = {}
local lockedAccounts = {}
local pendingAuth = {}

-- DB: mysql-async uses snake_case exports; many servers use oxmysql instead.
local function dbFetchAll(query, params, cb)
    params = params or {}

    if type(MySQL) == 'table' and MySQL.Async and MySQL.Async.fetchAll then
        MySQL.Async.fetchAll(query, params, cb)
        return
    end

    if GetResourceState('mysql-async') == 'started' then
        exports['mysql-async']:mysql_fetch_all(query, params, cb)
        return
    end

    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:query(query, params, cb)
        return
    end

    print('^1[esx-whitelist] No MySQL driver (mysql-async / oxmysql)^7')
    cb(nil)
end

local function dbExecute(query, params, cb)
    params = params or {}

    if type(MySQL) == 'table' and MySQL.Async and MySQL.Async.execute then
        MySQL.Async.execute(query, params, cb or function() end)
        return
    end

    if GetResourceState('mysql-async') == 'started' then
        exports['mysql-async']:mysql_execute(query, params, cb or function() end)
        return
    end

    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:update(query, params, cb or function() end)
        return
    end

    print('^1[esx-whitelist] No MySQL driver (mysql-async / oxmysql)^7')
    if cb then cb(nil) end
end

local function dbInsert(query, params, cb)
    params = params or {}

    if type(MySQL) == 'table' and MySQL.Async and MySQL.Async.insert then
        MySQL.Async.insert(query, params, cb)
        return
    end

    if GetResourceState('mysql-async') == 'started' then
        exports['mysql-async']:mysql_insert(query, params, cb)
        return
    end

    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:insert(query, params, cb)
        return
    end

    print('^1[esx-whitelist] No MySQL driver (mysql-async / oxmysql)^7')
    cb(nil)
end

local steamBySource = {}
local steamByUsername = {}
local accountBySource = {}
local recentAuthByName = {}

local function getIdentifierFromSource(player, idType)
    if GetPlayerIdentifierByType then
        local byType = GetPlayerIdentifierByType(player, idType)
        if byType and byType ~= '' then
            return byType
        end
    end

    for _, id in ipairs(GetPlayerIdentifiers(player)) do
        if string.sub(id, 1, #idType + 1) == idType .. ':' then
            return id
        end
    end

    return nil
end

local function getOptionalClientLicense(player)
    if not Config.AccountAuth.saveClientLicenseIfAvailable then
        return nil
    end
    return getIdentifierFromSource(player, 'license')
        or getIdentifierFromSource(player, 'license2')
end

local function generateAccountSteam(username, salt)
    local prefix = Config.AccountAuth.hexPrefix or '1100001'
    local seed = ('wl:%s:%s'):format(username, tostring(salt or ''))
    local h = GetHashKey(seed)
    if h < 0 then
        h = h + 4294967296
    end
    return string.format('steam:%s%09x', prefix, h % 0x1000000000)
end

local function generateUniqueAccountSteam(username, cb)
    local attempt = 0

    local function tryNext()
        attempt = attempt + 1
        local steam = generateAccountSteam(username, attempt)

        dbFetchAll('SELECT id FROM whitelist_accounts WHERE synthetic_steam = @steam', {
            ['@steam'] = steam
        }, function(rows)
            if rows and rows[1] then
                if attempt < 10 then
                    tryNext()
                else
                    cb(nil)
                end
                return
            end
            cb(steam)
        end)
    end

    tryNext()
end

local function bindAccountToSource(player, account)
    if not account or not account.synthetic_steam then
        return
    end

    accountBySource[player] = {
        id = account.id,
        username = account.username,
        steam = account.synthetic_steam
    }
    steamBySource[player] = account.synthetic_steam
    steamByUsername[account.username] = account.synthetic_steam
end

local function rememberRecentAuth(playerName, account)
    if not playerName or not account then
        return
    end
    recentAuthByName[playerName] = {
        id = account.id,
        username = account.username,
        steam = account.synthetic_steam,
        expires = os.time() + 600
    }
end

local function resolveAccountForSource(src)
    if accountBySource[src] then
        return accountBySource[src]
    end

    local playerName = GetPlayerName(src)
    local recent = playerName and recentAuthByName[playerName]
    if recent and recent.expires > os.time() then
        bindAccountToSource(src, {
            id = recent.id,
            username = recent.username,
            synthetic_steam = recent.steam
        })
        return accountBySource[src]
    end

    return nil
end

local function ensureAccountHasSteam(account, cb)
    if account.synthetic_steam and account.synthetic_steam ~= '' then
        cb(account.synthetic_steam)
        return
    end

    generateUniqueAccountSteam(account.username, function(steam)
        if not steam then
            cb(nil)
            return
        end

        dbExecute('UPDATE whitelist_accounts SET synthetic_steam = @steam WHERE id = @id', {
            ['@steam'] = steam,
            ['@id'] = account.id
        })
        account.synthetic_steam = steam
        cb(steam)
    end)
end

local function completeAuthAndJoin(player, account)
    local current = pendingAuth[player]
    if not current then
        return
    end

    ensureAccountHasSteam(account, function(steam)
        local session = pendingAuth[player]
        if not session or not steam then
            if session then
                session.errorMsg = Config.Messages.registerFailed
                showMainMenu(player)
            end
            return
        end

        account.synthetic_steam = steam
        bindAccountToSource(player, account)

        local optionalLicense = getOptionalClientLicense(player)
        dbExecute(
            'UPDATE whitelist_accounts SET last_login = NOW(), license = COALESCE(@license, license) WHERE id = @id',
            {
                ['@license'] = optionalLicense,
                ['@id'] = account.id
            }
        )

        rememberRecentAuth(session.name, account)

        local successMsg = Config.Messages.loginSuccess
        if session.registerUsername and session.registerUsername == account.username then
            successMsg = Config.Messages.registerSuccess:format(account.username)
        end

        print(('^2[esx-whitelist] %s authenticated as %s | %s^7'):format(session.name, account.username, steam))
        session.deferrals.update(successMsg)
        session.deferrals.done()
        pendingAuth[player] = nil
    end)
end

local function trimInput(value)
    if type(value) ~= 'string' then
        return ''
    end
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function appendError(body, data)
    if data.errorMsg then
        table.insert(body, {
            type = 'TextBlock',
            text = data.errorMsg,
            wrap = true,
            color = 'Attention',
            spacing = 'Small'
        })
        data.errorMsg = nil
    end
end

local function presentCard(player, body, actions, onSubmit)
    local data = pendingAuth[player]
    if not data then
        return
    end

    data.deferrals.presentCard({
        type = 'AdaptiveCard',
        version = '1.2',
        body = body,
        actions = actions
    }, function(cardData)
        if not pendingAuth[player] then
            return
        end
        onSubmit(cardData or {})
    end)
end

local function validateUsername(username)
    if string.len(username) < Config.Security.minUsernameLength then
        return Config.Messages.usernameTooShort
    end
    if string.len(username) > Config.Security.maxUsernameLength then
        return Config.Messages.usernameTooLong
    end
    if not string.match(username, '^[a-zA-Z0-9_]+$') then
        return Config.Messages.invalidUsername
    end
    return nil
end

local function validatePassword(password)
    if string.len(password) < Config.Security.minPasswordLength then
        return Config.Messages.passwordTooShort
    end
    if string.len(password) > Config.Security.maxPasswordLength then
        return Config.Messages.passwordTooLong
    end
    return nil
end

function showMainMenu(player)
    local data = pendingAuth[player]
    if not data then
        return
    end

    data.step = 'main_menu'

    local body = {
        {
            type = 'TextBlock',
            text = Config.Messages.menuTitle,
            size = 'Large',
            weight = 'Bolder',
            color = 'Accent',
            wrap = true
        },
        {
            type = 'TextBlock',
            text = Config.Messages.chooseOption,
            wrap = true,
            spacing = 'Small'
        }
    }

    appendError(body, data)

    presentCard(player, body, {
        {
            type = 'Action.Submit',
            title = Config.Messages.btnLogin,
            data = { action = 'login' }
        },
        {
            type = 'Action.Submit',
            title = Config.Messages.btnRegister,
            data = { action = 'register' }
        }
    }, function(cardData)
        local session = pendingAuth[player]
        if not session then
            return
        end

        if not cardData.action then
            session.deferrals.done(Config.Messages.cancelled)
            pendingAuth[player] = nil
            return
        end

        if cardData.action == 'login' then
            startLoginProcess(player)
        elseif cardData.action == 'register' then
            startRegisterProcess(player)
        end
    end)
end

function showLoginForm(player)
    local data = pendingAuth[player]
    if not data then
        return
    end

    data.step = 'login_form'

    local body = {
        {
            type = 'TextBlock',
            text = Config.Messages.loginTitle,
            size = 'Large',
            weight = 'Bolder',
            color = 'Accent',
            wrap = true
        },
        {
            type = 'Input.Text',
            id = 'username',
            placeholder = Config.Messages.usernamePlaceholder,
            maxLength = Config.Security.maxUsernameLength
        },
        {
            type = 'Input.Text',
            id = 'password',
            placeholder = Config.Messages.passwordPlaceholder,
            style = 'password',
            maxLength = Config.Security.maxPasswordLength
        }
    }

    appendError(body, data)

    presentCard(player, body, {
        {
            type = 'Action.Submit',
            title = Config.Messages.btnSubmitLogin,
            data = { action = 'login_submit' }
        },
        {
            type = 'Action.Submit',
            title = Config.Messages.btnBack,
            data = { action = 'back' }
        }
    }, function(cardData)
        local session = pendingAuth[player]
        if not session then
            return
        end

        if cardData.action == 'back' then
            showMainMenu(player)
            return
        end

        if cardData.action ~= 'login_submit' then
            session.deferrals.done(Config.Messages.cancelled)
            pendingAuth[player] = nil
            return
        end

        local username = trimInput(cardData.username)
        local password = trimInput(cardData.password)

        if username == '' or password == '' then
            session.errorMsg = Config.Messages.fieldsRequired
            showLoginForm(player)
            return
        end

        if lockedAccounts[username] and lockedAccounts[username] > os.time() then
            local remainingTime = lockedAccounts[username] - os.time()
            session.errorMsg = Config.Messages.accountLocked:format(remainingTime)
            showLoginForm(player)
            return
        end

        session.loginUsername = username
        session.loginPassword = password
        performLogin(player)
    end)
end

function showRegisterForm(player)
    local data = pendingAuth[player]
    if not data then
        return
    end

    data.step = 'register_form'

    local body = {
        {
            type = 'TextBlock',
            text = Config.Messages.registerTitle,
            size = 'Large',
            weight = 'Bolder',
            color = 'Accent',
            wrap = true
        },
        {
            type = 'Input.Text',
            id = 'username',
            placeholder = Config.Messages.usernamePlaceholder,
            maxLength = Config.Security.maxUsernameLength
        },
        {
            type = 'Input.Text',
            id = 'password',
            placeholder = Config.Messages.passwordPlaceholder,
            style = 'password',
            maxLength = Config.Security.maxPasswordLength
        },
        {
            type = 'Input.Text',
            id = 'confirmPassword',
            placeholder = Config.Messages.confirmPasswordPlaceholder,
            style = 'password',
            maxLength = Config.Security.maxPasswordLength
        }
    }

    appendError(body, data)

    presentCard(player, body, {
        {
            type = 'Action.Submit',
            title = Config.Messages.btnSubmitRegister,
            data = { action = 'register_submit' }
        },
        {
            type = 'Action.Submit',
            title = Config.Messages.btnBack,
            data = { action = 'back' }
        }
    }, function(cardData)
        local session = pendingAuth[player]
        if not session then
            return
        end

        if cardData.action == 'back' then
            showMainMenu(player)
            return
        end

        if cardData.action ~= 'register_submit' then
            session.deferrals.done(Config.Messages.cancelled)
            pendingAuth[player] = nil
            return
        end

        local username = trimInput(cardData.username)
        local password = trimInput(cardData.password)
        local confirmPassword = trimInput(cardData.confirmPassword)

        if username == '' or password == '' or confirmPassword == '' then
            session.errorMsg = Config.Messages.fieldsRequired
            showRegisterForm(player)
            return
        end

        local usernameError = validateUsername(username)
        if usernameError then
            session.errorMsg = usernameError
            showRegisterForm(player)
            return
        end

        local passwordError = validatePassword(password)
        if passwordError then
            session.errorMsg = passwordError
            showRegisterForm(player)
            return
        end

        if password ~= confirmPassword then
            session.errorMsg = Config.Messages.passwordMismatch
            showRegisterForm(player)
            return
        end

        dbFetchAll('SELECT id FROM whitelist_accounts WHERE username = @username', {
            ['@username'] = username
        }, function(existingUser)
            local current = pendingAuth[player]
            if not current then
                return
            end

            if existingUser and existingUser[1] then
                current.errorMsg = Config.Messages.usernameExists
                showRegisterForm(player)
                return
            end

            current.registerUsername = username
            current.registerPassword = password
            performRegister(player)
        end)
    end)
end

function startLoginProcess(player)
    showLoginForm(player)
end

function startRegisterProcess(player)
    showRegisterForm(player)
end

function performLogin(player)
    local data = pendingAuth[player]
    if not data then
        return
    end

    local username = data.loginUsername
    local password = data.loginPassword

    dbFetchAll('SELECT * FROM whitelist_accounts WHERE username = @username', {
        ['@username'] = username
    }, function(result)
        local current = pendingAuth[player]
        if not current then
            return
        end

        if result and result[1] then
            local account = result[1]

            if account.is_active == 0 then
                current.errorMsg = Config.Messages.accountInactive
                showMainMenu(player)
                return
            end

            if account.password == password then
                loginAttempts[username] = 0
                completeAuthAndJoin(player, account)
            else
                handleLoginFailed(player, username, Config.Messages.loginFailed)
            end
        else
            handleLoginFailed(player, username, Config.Messages.loginFailed)
        end
    end)
end

function performRegister(player)
    local data = pendingAuth[player]
    if not data then
        return
    end

    generateUniqueAccountSteam(data.registerUsername, function(steam)
        local current = pendingAuth[player]
        if not current then
            return
        end

        if not steam then
            current.errorMsg = Config.Messages.registerFailed
            showRegisterForm(player)
            return
        end

        local optionalLicense = getOptionalClientLicense(player)

        dbInsert(
            'INSERT INTO whitelist_accounts (username, password, synthetic_steam, license, last_login, is_active) VALUES (@username, @password, @steam, @license, NOW(), 1)',
            {
                ['@username'] = current.registerUsername,
                ['@password'] = current.registerPassword,
                ['@steam'] = steam,
                ['@license'] = optionalLicense
            },
            function(insertId)
                local session = pendingAuth[player]
                if not session then
                    return
                end

                if insertId then
                    print(('^2[esx-whitelist] New account: %s | %s^7'):format(session.registerUsername, steam))
                    completeAuthAndJoin(player, {
                        id = insertId,
                        username = session.registerUsername,
                        synthetic_steam = steam
                    })
                else
                    session.errorMsg = Config.Messages.registerFailed
                    showRegisterForm(player)
                end
            end
        )
    end)
end

function handleLoginFailed(player, username, msg)
    local data = pendingAuth[player]
    if not data then
        return
    end

    local lockKey = username or 'unknown'
    loginAttempts[lockKey] = (loginAttempts[lockKey] or 0) + 1
    local attempts = loginAttempts[lockKey]

    if attempts >= Config.Security.maxLoginAttempts then
        lockedAccounts[lockKey] = os.time() + Config.Security.loginCooldown
        loginAttempts[lockKey] = 0
        data.deferrals.done(Config.Messages.maxAttempts)
        pendingAuth[player] = nil
    else
        local remaining = Config.Security.maxLoginAttempts - attempts
        data.errorMsg = msg .. ' | ' .. Config.Messages.attemptsLeft:format(remaining)
        showLoginForm(player)
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    print('^2[esx-whitelist] Account-based auth — no license required at connect^7')
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local player = source
    deferrals.defer()

    if not Config.WhitelistEnabled then
        deferrals.done()
        return
    end

    deferrals.update(Config.Messages.connecting)

    print(('^2[esx-whitelist] %s connecting (account auth)^7'):format(name))

    pendingAuth[player] = {
        player = player,
        name = name,
        deferrals = deferrals,
        step = 'main_menu',
        errorMsg = nil
    }

    showMainMenu(player)

    Citizen.SetTimeout(180000, function()
        if pendingAuth[player] then
            pendingAuth[player].deferrals.done(Config.Messages.timeout)
            pendingAuth[player] = nil
        end
    end)
end)

-- Admin commands
RegisterCommand('wl_accounts', function(source, args, rawCommand)
    if source == 0 then
        dbFetchAll('SELECT id, username, synthetic_steam, license, last_login, created_at, is_active FROM whitelist_accounts ORDER BY created_at DESC LIMIT 50', {}, function(accounts)
            if accounts and #accounts > 0 then
                print('^2=== ACCOUNTS ===^7')
                for _, a in ipairs(accounts) do
                    print(('^3[%s] %s | %s | lic:%s | %s^7'):format(
                        a.id, a.username, a.synthetic_steam or 'N/A', a.license or '-',
                        a.is_active == 1 and 'Active' or 'Inactive'
                    ))
                end
            else
                print('^3No accounts found.^7')
            end
        end)
    end
end, true)

RegisterCommand('wl_create', function(source, args, rawCommand)
    if source == 0 and args[1] and args[2] then
        generateUniqueAccountSteam(args[1], function(steam)
            if not steam then
                print('^1Failed to generate steam id^7')
                return
            end
            dbInsert(
                'INSERT INTO whitelist_accounts (username, password, synthetic_steam, license, is_active) VALUES (@username, @password, @steam, @license, 1)',
                {
                    ['@username'] = args[1],
                    ['@password'] = args[2],
                    ['@steam'] = steam,
                    ['@license'] = args[3]
                },
                function(insertId)
                    if insertId then
                        print(('^2Created: %s | %s^7'):format(args[1], steam))
                    end
                end
            )
        end)
    end
end, true)

RegisterCommand('wl_delete', function(source, args, rawCommand)
    if source == 0 and args[1] then
        dbExecute('DELETE FROM whitelist_accounts WHERE username = @username', {
            ['@username'] = args[1]
        })
        print(('^2Deleted: %s^7'):format(args[1]))
    end
end, true)

RegisterCommand('wl_deactivate', function(source, args, rawCommand)
    if source == 0 and args[1] then
        dbExecute('UPDATE whitelist_accounts SET is_active = 0 WHERE username = @username', {
            ['@username'] = args[1]
        })
        print(('^2Deactivated: %s^7'):format(args[1]))
    end
end, true)

RegisterCommand('wl_activate', function(source, args, rawCommand)
    if source == 0 and args[1] then
        dbExecute('UPDATE whitelist_accounts SET is_active = 1 WHERE username = @username', {
            ['@username'] = args[1]
        })
        print(('^2Activated: %s^7'):format(args[1]))
    end
end, true)

AddEventHandler('playerDropped', function()
    steamBySource[source] = nil
    accountBySource[source] = nil
end)

RegisterNetEvent('esx-whitelist:syncSession', function()
    resolveAccountForSource(source)
end)

AddEventHandler('playerJoining', function()
    resolveAccountForSource(source)
end)

exports('GetPlayerSteamId', function(src)
    local account = resolveAccountForSource(src)
    if account and account.steam then
        return account.steam
    end

    local realSteam = getIdentifierFromSource(src, 'steam')
    if realSteam then
        return realSteam
    end

    return steamBySource[src]
end)

exports('GetAccountUsername', function(src)
    local account = resolveAccountForSource(src)
    return account and account.username or nil
end)

exports('GetSyntheticSteam', function(src)
    if getIdentifierFromSource(src, 'steam') then
        return nil
    end
    local account = resolveAccountForSource(src)
    return (account and account.steam) or steamBySource[src]
end)

exports('HasRealSteam', function(src)
    return getIdentifierFromSource(src, 'steam') ~= nil
end)

exports('EnsureSyntheticSteam', function(_, cb)
    if cb then
        cb(nil)
    end
end)
