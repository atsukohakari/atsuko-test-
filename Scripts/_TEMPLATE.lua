local function notify(title, text, seconds)
	if AtsukoHub and AtsukoHub.Notify then
		AtsukoHub.Notify(title, text, "info", seconds)
	else
		pcall(warn, "[" .. tostring(title) .. "] " .. tostring(text))
	end
end


if AtsukoHub and AtsukoHub.Path then
	AtsukoHub.OnStop(function()

	end)
end


