--- Divvy's History for Balatro - SaveManager.lua
--
-- Module to be injected into the save manager thread.

if not DV then DV = {} end
if not DV.HIST then DV.HIST = {} end

-- CAUTION: The following is duplicated in `/Init.lua`
DV.HIST.PATHS = {
   STORAGE = "DVHistory",
   AUTOSAVES = "_autosaves",
}

function DV.HIST.execute_save_manager(request)
   local profile = tostring(request.profile_num or 1)
   if not love.filesystem.getInfo(profile) then love.filesystem.createDirectory(profile) end

   local history_dir = profile .. "/".. DV.HIST.PATHS.STORAGE
   if not love.filesystem.getInfo(history_dir) then love.filesystem.createDirectory(history_dir) end

   local save_path
   local file_name = DV.HIST.get_run_name(request.save_table)

   if request.save_table.GAME.challenge then
      file_name = file_name .."_Chal"
   end

   if request.save_table.autosave_str then
      -- Autosaves will be named:
      --   SEED_RUNID_autoN
      save_path = DV.HIST.manage_autosaves(request, history_dir, file_name)
      if request.save_table.dv_settings.autosaves_total ~= "Inf." then
         DV.HIST.prune_autosaves(request, history_dir)
      end
   else
      -- Manual saves will be named:
      --   SEED_RUNID_Round-N_saveN
      save_path = DV.HIST.manage_save(request, history_dir, file_name)
   end

   compress_and_save(save_path, request.save_table)
end

function DV.HIST.manage_save(request, history_dir, file_name)
   file_name = file_name .. "_Round-" .. request.save_table.GAME.round
   file_name = file_name .. "_save"

   local file_path = history_dir .. "/" .. file_name
   local length_without_num = #file_path

   -- Find the next free save number, and use it for `save_path`:
   local save_path = nil
   local next_num = 1
   while true do
      file_path = history_dir .. "/" .. file_name .. next_num
      if love.filesystem.getInfo(file_path .. ".jkr") then
         next_num = 1 + tonumber(string.sub(file_path, length_without_num + 1))
      else
         save_path = file_path .. ".jkr"
         break
      end
   end

   return save_path
end

function DV.HIST.manage_autosaves(request, history_dir, file_name)
   local autosave_dir = history_dir .."/".. DV.HIST.PATHS.AUTOSAVES
   if not love.filesystem.getInfo(autosave_dir) then love.filesystem.createDirectory(autosave_dir) end

   local save_path = autosave_dir .. "/" .. file_name .. "_" .. request.save_table.autosave_str
   local max_autosave_slots = (request.save_table.dv_settings.autosaves_per_run or 3)
   local next_autosave_slot = -1
   for i = 1, max_autosave_slots do
      if not love.filesystem.getInfo(DV.HIST.get_ith_autosave(save_path, i)) then
         next_autosave_slot = i
         break
      end
   end

   if next_autosave_slot < 0 then
      -- All slots filled, so remove the oldest:
      love.filesystem.remove(DV.HIST.get_ith_autosave(save_path, 1))
      -- 'Shift' existing autosaves:
      local abs_path = love.filesystem.getRealDirectory(autosave_dir)
      for i = 2, max_autosave_slots do
         os.rename(DV.HIST.get_ith_autosave(abs_path .. "/" .. save_path, i),
            DV.HIST.get_ith_autosave(abs_path .. "/" .. save_path, i - 1))
      end
      -- Fix `next_autosave_slot` value:
      next_autosave_slot = max_autosave_slots
   end

   return DV.HIST.get_ith_autosave(save_path, next_autosave_slot)
end

function DV.HIST.prune_autosaves(request, history_dir)
   local autosave_dir = history_dir .."/".. DV.HIST.PATHS.AUTOSAVES
   if not love.filesystem.getInfo(autosave_dir) then love.filesystem.createDirectory(autosave_dir) end

   local all_autosaves = love.filesystem.getDirectoryItems(autosave_dir)
   if #all_autosaves > 9 then
      table.sort(all_autosaves, function(f1, f2)
         f1 = autosave_dir .."/".. f1
         f2 = autosave_dir .."/".. f2
         -- Oldest first:
         return love.filesystem.getInfo(f1).modtime < love.filesystem.getInfo(f2).modtime
      end)
      -- Delete oldest:
      for i = 1, (#all_autosaves - request.save_table.dv_settings.autosaves_total + 1) do
         love.filesystem.remove(autosave_dir .."/".. all_autosaves[i])
      end
   end
end

function DV.HIST.get_run_name(save_table)
   local seed = save_table.GAME.pseudorandom.seed
   local runid = save_table.GAME.DV.run_id
   return seed .."_".. runid
end

function DV.HIST.get_ith_autosave(path, autosave_slot)
   return path .. autosave_slot .. ".jkr"
end

return DV
