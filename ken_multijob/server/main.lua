ESX = exports["es_extended"]:getSharedObject()

--[[
    DATABASE STRUCTURE:
    users table:
    - job = PRIMARY JOB (active job, ESX main job)
    - job_grade = PRIMARY JOB grade
    - job2 = SECONDARY JOB (backup job, not active)
    - job2_grade = SECONDARY JOB grade
    
    When switching:
    - job and job2 swap places
    - ESX setJob() is called to update primary job
    - This ensures all ESX scripts recognize the active job
]]

 
ESX.RegisterServerCallback('esx_multijob:getJobs', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
        MySQL.Async.fetchAll('SELECT job, job_grade, job2, job2_grade FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] then
                cb({
                    job = {name = result[1].job, grade = result[1].job_grade},
                    job2 = {name = result[1].job2 or 'unemployed', grade = result[1].job2_grade or 0}
                })
            else
                cb({
                    job = {name = 'unemployed', grade = 0},
                    job2 = {name = 'unemployed', grade = 0}
                })
            end
        end)
    else
        cb({
            job = {name = 'unemployed', grade = 0},
            job2 = {name = 'unemployed', grade = 0}
        })
    end
end)

 
RegisterServerEvent('esx_multijob:setJob2')
AddEventHandler('esx_multijob:setJob2', function(job, grade)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
   
        MySQL.Async.execute('UPDATE users SET job2 = @job, job2_grade = @grade WHERE identifier = @identifier', {
            ['@job'] = job,
            ['@grade'] = grade,
            ['@identifier'] = xPlayer.identifier
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('esx:showNotification', source, 'Second job set to: ' .. job)
                TriggerClientEvent('esx_multijob:updateJob2', source, job, grade)
            end
        end)
    end
end)

 
local switchingJobs = {}  

RegisterServerEvent('esx_multijob:switchJob')
AddEventHandler('esx_multijob:switchJob', function()
    local _source = source  
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if not xPlayer then return end
    
   
    if switchingJobs[_source] then
        TriggerClientEvent('esx:showNotification', _source, '~r~Please wait, switching jobs...')
        return
    end
    
    switchingJobs[_source] = true
    
    MySQL.Async.fetchAll('SELECT job, job_grade, job2, job2_grade FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] then
            local currentJob = result[1].job
            local currentGrade = result[1].job_grade
            local job2 = result[1].job2 or 'unemployed'
            local job2Grade = result[1].job2_grade or 0
            
            
            if job2 == 'unemployed' then
                TriggerClientEvent('esx:showNotification', _source, '~r~You don\'t have a second job to switch to!')
                switchingJobs[_source] = nil
                return
            end
            
            
            MySQL.Async.execute('UPDATE users SET job = @job2, job_grade = @job2_grade, job2 = @oldJob, job2_grade = @oldGrade WHERE identifier = @identifier', {
                ['@job2'] = job2,
                ['@job2_grade'] = job2Grade,
                ['@oldJob'] = currentJob,
                ['@oldGrade'] = currentGrade,
                ['@identifier'] = xPlayer.identifier
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    
                    xPlayer.setJob(job2, job2Grade)
                    
                     
                    Citizen.Wait(100)
                    
                     
                    TriggerClientEvent('esx_multijob:updateJob2', _source, currentJob, currentGrade)
                    
                     
                    TriggerClientEvent('esx:showNotification', _source, '~g~Switched to: ' .. job2)
                    
                    
                    TriggerClientEvent('esx_multijob:jobSwitched', _source)
                    
                    
                    print('[esx_multijob] Player ' .. _source .. ' switched jobs: ' .. currentJob .. ' <-> ' .. job2)
                end
                
                 
                Citizen.Wait(500)
                switchingJobs[_source] = nil
            end)
        else
            switchingJobs[_source] = nil
        end
    end)
end)

 
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    MySQL.Async.fetchAll('SELECT job2, job2_grade FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] and result[1].job2 then
            TriggerClientEvent('esx_multijob:updateJob2', playerId, result[1].job2, result[1].job2_grade)
        end
    end)
end)

 
RegisterCommand('setjob1', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
     
    if not xPlayer or (xPlayer.getGroup() ~= 'admin' and xPlayer.getGroup() ~= 'superadmin') then
        TriggerClientEvent('esx:showNotification', source, '~r~You do not have permission')
        return
    end
    
    local targetId = tonumber(args[1])
    local jobName = args[2]
    local jobGrade = tonumber(args[3]) or 0
    
    if not targetId or not jobName then
        TriggerClientEvent('esx:showNotification', source, '~o~Usage: /setjob1 [playerID] [job] [grade]')
        TriggerClientEvent('esx:showNotification', source, '~o~Example: /setjob1 1 police 0')
        return
    end
    
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', source, '~r~Player ID ' .. targetId .. ' is not online!')
        return
    end
    
    
    MySQL.Async.execute('UPDATE users SET job = @job, job_grade = @grade WHERE identifier = @identifier', {
        ['@job'] = jobName,
        ['@grade'] = jobGrade,
        ['@identifier'] = targetPlayer.identifier
    }, function(rowsChanged)
        if rowsChanged > 0 then
            
            targetPlayer.setJob(jobName, jobGrade)
            
            TriggerClientEvent('esx:showNotification', source, '~g~Primary job set for player ' .. targetId .. ': ' .. jobName .. ' (Grade ' .. jobGrade .. ')')
            TriggerClientEvent('esx:showNotification', targetId, '~g~Admin set your primary job: ' .. jobName)
            
            print('[esx_multijob] Admin ' .. xPlayer.identifier .. ' set job1 "' .. jobName .. '" (grade ' .. jobGrade .. ') to player ' .. targetId)
        else
            TriggerClientEvent('esx:showNotification', source, '~r~Failed to set primary job - Database error')
        end
    end)
end, false)

 
RegisterCommand('setjob2', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    
    if not xPlayer or (xPlayer.getGroup() ~= 'admin' and xPlayer.getGroup() ~= 'superadmin') then
        TriggerClientEvent('esx:showNotification', source, '~r~You do not have permission')
        return
    end
    
    local targetId = tonumber(args[1])
    local jobName = args[2]
    local jobGrade = tonumber(args[3]) or 0
    
    if not targetId or not jobName then
        TriggerClientEvent('esx:showNotification', source, '~o~Usage: /setjob2 [playerID] [job] [grade]')
        TriggerClientEvent('esx:showNotification', source, '~o~Example: /setjob2 1 mechanic 0')
        return
    end
    
     
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', source, '~r~Player ID ' .. targetId .. ' is not online!')
        return
    end
    
     
    MySQL.Async.execute('UPDATE users SET job2 = @job, job2_grade = @grade WHERE identifier = @identifier', {
        ['@job'] = jobName,
        ['@grade'] = jobGrade,
        ['@identifier'] = targetPlayer.identifier
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('esx:showNotification', source, '~g~Secondary job set for player ' .. targetId .. ': ' .. jobName .. ' (Grade ' .. jobGrade .. ')')
            TriggerClientEvent('esx_multijob:updateJob2', targetId, jobName, jobGrade)
            TriggerClientEvent('esx:showNotification', targetId, '~g~Admin set your secondary job: ' .. jobName)
            
            print('[esx_multijob] Admin ' .. xPlayer.identifier .. ' set job2 "' .. jobName .. '" (grade ' .. jobGrade .. ') to player ' .. targetId)
        else
            TriggerClientEvent('esx:showNotification', source, '~r~Failed to set secondary job - Database error')
        end
    end)
end, false)

 
RegisterCommand('removejob1', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if admin
    if not xPlayer or (xPlayer.getGroup() ~= 'admin' and xPlayer.getGroup() ~= 'superadmin') then
        TriggerClientEvent('esx:showNotification', source, '~r~You do not have permission')
        return
    end
    
    local targetId = tonumber(args[1])
    
    if not targetId then
        TriggerClientEvent('esx:showNotification', source, '~o~Usage: /removejob1 [playerID]')
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', source, '~r~Player ID ' .. targetId .. ' is not online!')
        return
    end
    
    -- Set primary job to unemployed
    MySQL.Async.execute('UPDATE users SET job = @job, job_grade = @grade WHERE identifier = @identifier', {
        ['@job'] = 'unemployed',
        ['@grade'] = 0,
        ['@identifier'] = targetPlayer.identifier
    }, function(rowsChanged)
        if rowsChanged > 0 then
            targetPlayer.setJob('unemployed', 0)
            TriggerClientEvent('esx:showNotification', source, '~g~Primary job removed for player ' .. targetId)
            TriggerClientEvent('esx:showNotification', targetId, '~o~Your primary job has been removed by an admin')
            
            print('[esx_multijob] Admin ' .. xPlayer.identifier .. ' removed job1 from player ' .. targetId)
        else
            TriggerClientEvent('esx:showNotification', source, '~r~Failed to remove primary job')
        end
    end)
end, false)

 
RegisterCommand('removejob2', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
     
    if not xPlayer or (xPlayer.getGroup() ~= 'admin' and xPlayer.getGroup() ~= 'superadmin') then
        TriggerClientEvent('esx:showNotification', source, '~r~You do not have permission')
        return
    end
    
    local targetId = tonumber(args[1])
    
    if not targetId then
        TriggerClientEvent('esx:showNotification', source, '~o~Usage: /removejob2 [playerID]')
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', source, '~r~Player ID ' .. targetId .. ' is not online!')
        return
    end
    
    
    MySQL.Async.execute('UPDATE users SET job2 = @job, job2_grade = @grade WHERE identifier = @identifier', {
        ['@job'] = 'unemployed',
        ['@grade'] = 0,
        ['@identifier'] = targetPlayer.identifier
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('esx:showNotification', source, '~g~Job2 removed for player ' .. targetId)
            TriggerClientEvent('esx_multijob:updateJob2', targetId, 'unemployed', 0)
            TriggerClientEvent('esx:showNotification', targetId, '~o~Your second job has been removed by an admin')
            
            print('[esx_multijob] Admin ' .. xPlayer.identifier .. ' removed job2 from player ' .. targetId)
        else
            TriggerClientEvent('esx:showNotification', source, '~r~Failed to remove job2')
        end
    end)
end, false)

 
ESX.RegisterServerCallback('esx_multijob:isAdmin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local group = xPlayer.getGroup()
        cb(group == 'admin' or group == 'superadmin')
    else
        cb(false)
    end
end)

 
RegisterServerEvent('esx_multijob:deleteJob2')
AddEventHandler('esx_multijob:deleteJob2', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    
 
    if xPlayer and (xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin') then
        local targetPlayer = ESX.GetPlayerFromId(targetId)
        
        if targetPlayer then
            MySQL.Async.execute('UPDATE users SET job2 = @job, job2_grade = @grade WHERE identifier = @identifier', {
                ['@job'] = 'unemployed',
                ['@grade'] = 0,
                ['@identifier'] = targetPlayer.identifier
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    TriggerClientEvent('esx:showNotification', source, '~g~Deleted second job for player ' .. targetId)
                    TriggerClientEvent('esx_multijob:updateJob2', targetId, 'unemployed', 0)
                    TriggerClientEvent('esx:showNotification', targetId, '~o~Your second job has been removed by an admin')
                    
                    print('[esx_multijob] Admin ' .. xPlayer.identifier .. ' removed job2 from player ' .. targetId .. ' via UI')
                end
            end)
        else
            TriggerClientEvent('esx:showNotification', source, '~r~Player ID ' .. targetId .. ' is not online!')
        end
    else
        TriggerClientEvent('esx:showNotification', source, '~r~You do not have permission')
    end
end)

-- Debug command to check player jobs (admin only)
RegisterCommand('checkjobs', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer or (xPlayer.getGroup() ~= 'admin' and xPlayer.getGroup() ~= 'superadmin') then
        TriggerClientEvent('esx:showNotification', source, '~r~You do not have permission')
        return
    end
    
    local targetId = tonumber(args[1]) or source
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', source, '~r~Player not online')
        return
    end
    
    MySQL.Async.fetchAll('SELECT job, job_grade, job2, job2_grade FROM users WHERE identifier = @identifier', {
        ['@identifier'] = targetPlayer.identifier
    }, function(result)
        if result[1] then
           
            
            TriggerClientEvent('esx:showNotification', source, '~b~Check console for job info')
        end
    end)
end, false)