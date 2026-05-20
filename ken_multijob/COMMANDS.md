# Quick Command Reference

## Admin Commands (Must be online)

### Set Jobs
```bash
/setjob1 [id] [job] [grade]    
/setjob2 [id] [job] [grade]    
```

### Remove Jobs
```bash
/removejob1 [id]         
/removejob2 [id]              
```

### Check Jobs
```bash
/checkjobs [id]                
```

## Examples

```bash
# Fresh player - give them police as primary
/setjob1 5 police 0

# Give them mechanic as secondary
/setjob2 5 mechanic 2

# Check what they have
/checkjobs 5
 

## Quick Setup for Testing

```bash
# 1. Set yourself as police (primary)
/setjob1 1 police 3

# 2. Set yourself as mechanic (secondary)
/setjob2 1 mechanic 2

# 3. Open menu and switch
Press K → Click "Switch Jobs"

 
 