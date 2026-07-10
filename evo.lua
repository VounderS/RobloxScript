local RS = game:GetService("ReplicatedStorage")
local Task = RS:WaitForChild("Remote"):WaitForChild("Task")
local ReqCompleteTask = Task:WaitForChild("ReqCompleteTask")

local taskIds = {8000081, 8000082}
local claimRunning = true

task.spawn(function()
    while claimRunning do
        for _, taskId in ipairs(taskIds) do
            local ok, result = pcall(function()
                return ReqCompleteTask:InvokeServer(taskId)
            end)
            if ok then
                print(string.format("[CLAIM] taskId=%d result=%s", taskId, tostring(result)))
            end
            task.wait(0.5)
        end
        task.wait(3)
    end
end)
