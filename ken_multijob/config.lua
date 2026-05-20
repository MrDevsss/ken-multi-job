Config = {}

-- Menu settings
Config.MenuKey = 'F6' -- Key to open job menu (F6, F5, etc.)
Config.MenuAlign = 'top-left' -- Menu position: 'top-left', 'top-right', 'bottom-left', 'bottom-right'

-- Job restrictions
Config.RestrictedJobs = {
    -- Jobs that cannot be used as second job
    -- Example: {'police', 'ambulance'}
    -- Leave empty {} to allow all jobs
}

Config.RequireUnemployedSlot = false -- Set to true if one job must always be 'unemployed'

-- Notifications
Config.Notifications = {
    job2Set = 'Second job set to: %s',
    jobSwitched = 'Switched to job: %s',
    noJob2 = 'You don\'t have a second job!',
    sameJob = 'You already have this job active!',
    restrictedJob = 'This job cannot be used as a second job!'
}

-- Admin settings
Config.AdminGroups = {
    'admin',
    'superadmin',
    'mod'
}

-- Debug mode (set to true for console logs)
Config.Debug = false
