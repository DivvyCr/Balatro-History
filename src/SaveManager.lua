--- Divvy's History for Balatro - SaveManager.lua
--
-- Module to be injected into the save manager thread.

if not DV then DV = {} end
if not DV.HIST then DV.HIST = {} end

function DV.HIST.execute_save_manager(request)
   local profile = tostring(request.profile_num or 1)
   if not love.filesystem.getInfo(profile) then love.filesystem.createDirectory(profile) end

   local file_dir = profile .. "/DVHistory"
   if not love.filesystem.getInfo(file_dir) then love.filesystem.createDirectory(file_dir) end

   local file_name = DV.HIST.generate_filename(request.save_table)
   local file_path = file_dir .. "/" .. file_name .. ".jkr"
   compress_and_save(file_path, request.save_table)
end

function DV.HIST.generate_filename(save_table)
   local datetime = os.date("%Y%m%d-%H%M%S") 
   local round = "Round-" .. save_table.HISTORY.latest.abs_round
   return datetime .."_".. save_table.GAME.pseudorandom.seed .."_".. round
end

return DV
