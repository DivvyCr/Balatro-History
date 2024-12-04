--- Divvy's History for Balatro - Runs.lua
--
-- ???

DV.HIST._end_round = end_round
function end_round()
   if G.GAME.blind:get_type() == "Boss" then
      DV.HIST.store_run()
   end
   DV.HIST._end_round()
end

-- The following is a customised version of functions/misc_functions.lua#save_run()
function DV.HIST.store_run()
   local card_areas = {}
   for k, v in pairs(G) do
      if (type(v) == "table") and v.is and v:is(CardArea) then
         local card_area = v:save()
         if card_area then card_areas[k] = card_area end
      end
   end

   local tags = {}
   for k, v in ipairs(G.GAME.tags) do
      if (type(v) == "table") and v.is and v:is(Tag) then
         local tag = v:save()
         if tag then tags[k] = tag end
      end
   end

   local history_data = {
      history = DV.HIST.history,
      view = DV.HIST.view,
      latest = DV.HIST.latest
   }

   G.ARGS.store_run = recursive_table_cull({
         cardAreas = card_areas,
         tags = tags,
         GAME = G.GAME,
         STATE = G.STATE,
         ACTION = G.action or nil,
         BLIND = G.GAME.blind:save(),
         BACK = G.GAME.selected_back:save(),
         HISTORY = history_data,
         VERSION = G.VERSION
   })

   G.FILE_HANDLER = G.FILE_HANDLER or {}
   G.FILE_HANDLER.store_run = true
end

-- Injected into game.lua#Game:update() near other FILE_HANDLER options;
-- see lovely.toml
function DV.HIST.queue_save_manager()
   if G.FILE_HANDLER.store_run then
      G.SAVE_MANAGER.channel:push({
         type = "store_run",
         save_table = G.ARGS.store_run,
         profile_num = G.SETTINGS.profile
      })
   end

   G.FILE_HANDLER.store_run = nil
end
