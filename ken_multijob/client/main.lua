ESX = exports["es_extended"]:getSharedObject()

local PlayerData = {}
local currentJob2 = nil
local currentJob2Grade = 0
local isAdmin = false

 
Citizen.CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(100)
    end
    
    PlayerData = ESX.GetPlayerData()
    
    
    ESX.TriggerServerCallback('esx_multijob:isAdmin', function(admin)
        isAdmin = admin
    end)
    
  
    ESX.TriggerServerCallback('esx_multijob:getJobs', function(jobs)
        if jobs and jobs.job2 then
            currentJob2 = jobs.job2.name
            currentJob2Grade = jobs.job2.grade
        end
    end)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    
    
    Citizen.SetTimeout(1000, function()
    
        ESX.TriggerServerCallback('esx_multijob:isAdmin', function(admin)
            isAdmin = admin
        end)
        
        
        ESX.TriggerServerCallback('esx_multijob:getJobs', function(jobs)
            if jobs and jobs.job2 then
                currentJob2 = jobs.job2.name
                currentJob2Grade = jobs.job2.grade
            end
        end)
    end)
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('esx_multijob:updateJob2')
AddEventHandler('esx_multijob:updateJob2', function(job, grade)
    currentJob2 = job
    currentJob2Grade = grade or 0
end)

RegisterNetEvent('esx_multijob:jobSwitched')
AddEventHandler('esx_multijob:jobSwitched', function()
   
    PlayerData = ESX.GetPlayerData()
    
   
    ESX.TriggerServerCallback('esx_multijob:getJobs', function(jobs)
        if jobs and jobs.job2 then
            currentJob2 = jobs.job2.name
            currentJob2Grade = jobs.job2.grade
        end
    end)
end)
function OpenJobMenu()
    ESX.TriggerServerCallback('esx_multijob:getJobs', function(jobs)
        if not jobs then
            ESX.ShowNotification('~r~Error loading jobs')
            return
        end
        
        local job1Name = jobs.job and jobs.job.name or 'unemployed'
        local job1Grade = jobs.job and jobs.job.grade or 0
        local job2Name = jobs.job2 and jobs.job2.name or 'unemployed'
        local job2Grade = jobs.job2 and jobs.job2.grade or 0
        
        local options = {
            {
                title = 'Primary Job',
                description = job1Name:gsub("^%l", string.upper) .. ' (Grade ' .. job1Grade .. ')',
                icon = 'briefcase',
                iconColor = '#4CAF50',
                disabled = true
            },
            {
                title = 'Secondary Job',
                description = job2Name:gsub("^%l", string.upper) .. ' (Grade ' .. job2Grade .. ')',
                icon = 'briefcase',
                iconColor = '#2196F3',
                disabled = true
            },
            {
                title = 'Switch Jobs',
                description = 'Swap your primary and secondary jobs',
                icon = 'right-left',
                iconColor = '#2196F3',
                disabled = job2Name == 'unemployed',
                onSelect = function()
                    lib.hideContext()
                    TriggerServerEvent('esx_multijob:switchJob')
                end
            },
            {
                title = 'Created by Ken Mondragon',
                description = 'Multi Job System',
                icon = 'shield',
                iconColor = '#FFD700',
                disabled = true
            }
        }
        
        lib.registerContext({
            id = 'multijob_menu',
            title = 'Job Manager',
            options = options
        })
        
        lib.showContext('multijob_menu')
    end)
end

 
function OpenAdminSetJob1Menu()
    local input = lib.inputDialog('Set Primary Job', {
        {type = 'number', label = 'Player ID', description = 'Server ID of the player', required = true, min = 1},
        {type = 'input', label = 'Job Name', description = 'e.g., police, mechanic', required = true},
        {type = 'number', label = 'Job Grade', description = 'Grade level (default: 0)', default = 0, min = 0}
    })
    
    if input then
        local playerId = input[1]
        local jobName = input[2]
        local jobGrade = input[3] or 0
        
        ExecuteCommand('setjob1 ' .. playerId .. ' ' .. jobName .. ' ' .. jobGrade)
    end
end

 
function OpenAdminSetJob2Menu()
    local input = lib.inputDialog('Set Secondary Job', {
        {type = 'number', label = 'Player ID', description = 'Server ID of the player', required = true, min = 1},
        {type = 'input', label = 'Job Name', description = 'e.g., police, mechanic', required = true},
        {type = 'number', label = 'Job Grade', description = 'Grade level (default: 0)', default = 0, min = 0}
    })
    
    if input then
        local playerId = input[1]
        local jobName = input[2]
        local jobGrade = input[3] or 0
        
        ExecuteCommand('setjob2 ' .. playerId .. ' ' .. jobName .. ' ' .. jobGrade)
    end
end

 
function OpenAdminRemoveJobMenu()
    local input = lib.inputDialog('Remove Secondary Job', {
        {type = 'number', label = 'Player ID', description = 'Server ID of the player', required = true, min = 1}
    })
    
    if input then
        local playerId = input[1]
        
        local alert = lib.alertDialog({
            header = 'Confirm Removal',
            content = 'Are you sure you want to remove Job2 for player ' .. playerId .. '?',
            centered = true,
            cancel = true
        })
        
        if alert == 'confirm' then
            ExecuteCommand('removejob2 ' .. playerId)
        end
    end
end

 
RegisterCommand('jobmenu', function()
    OpenJobMenu()
end, false)

 
RegisterKeyMapping('jobmenu', 'Open Multi-Job Menu', 'keyboard', 'k')

 
exports('getJob2', function()
    return {
        name = currentJob2,
        grade = currentJob2Grade
    }
end)

exports('hasJob2', function(jobName)
    return currentJob2 == jobName
end)