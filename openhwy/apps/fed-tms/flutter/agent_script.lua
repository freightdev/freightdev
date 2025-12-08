-- Example Agent Script for Moon Environment
-- This shows what an agent can do in the sandbox

moon.log("info", "CoDriver agent starting...")

-- Read a file
local content = moon.read_file("/home/admin/WORKSPACE/openhwy/README.md")
if content then
    moon.print("Found README with " .. #content .. " characters")
end

-- List directory
local files = moon.list_dir("/home/admin/WORKSPACE/openhwy")
moon.print("Found " .. #files .. " items in workspace")

-- Execute a command
local stdout, stderr, code = moon.exec("ls", {"-la", "/home/admin"})
moon.print("Command output:")
moon.print(stdout)

-- Set some state
moon.set_state("last_check", os.date("%Y-%m-%d %H:%M:%S"))
moon.set_state("files_found", tostring(#files))

-- If network is enabled, fetch something
if moon.http_get then
    local data = moon.http_get("http://example.com")
    moon.log("info", "Fetched " .. #data .. " bytes from network")
end

-- Define a function that can be called from outside
function process_task(task_name)
    moon.log("info", "Processing task: " .. task_name)
    
    -- Do some work
    local result = "Task " .. task_name .. " completed at " .. os.date()
    
    -- Save result
    moon.write_file("/tmp/agent-workspace/result.txt", result)
    
    return result
end

-- Agent loop
function agent_loop()
    while true do
        moon.log("info", "Agent checking for tasks...")
        
        -- Check for new tasks
        local tasks = moon.list_dir("/tmp/agent-workspace/tasks")
        
        if #tasks > 0 then
            for _, task in ipairs(tasks) do
                moon.log("info", "Found task: " .. task)
                process_task(task)
            end
        end
        
        -- Sleep (would need to be implemented)
        -- For now, just break after one iteration
        break
    end
end

moon.print("CoDriver agent initialized and ready!")
