--- Divvy's History for Balatro - RunStorage.lua
--
-- The core logic of storing runs for later loading from file.

-- The following is a customised version of functions/misc_functions.lua#save_run()
function DV.HIST.store_run(autosave_type)
   if autosave_type and not G.SETTINGS.DV.autosave then return end

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
      autosave_str = autosave_type,
      date_str = os.date("%H:%M, %d %b %Y"),
      dv_settings = G.SETTINGS.DV,
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

-- The following function is injected into:
--   game.lua#Game:update()
-- near other FILE_HANDLER options; see lovely.toml for details.
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

--
-- AUTO-SAVING:
--

DV.HIST._update_shop = Game.update_shop
function Game:update_shop(dt)
   DV.HIST._update_shop(self, dt)

   if DV.HIST.autosave then
      G.E_MANAGER:add_event(Event({
         -- This event is queued after all shop events;
         -- however, shop events queue more events, so triggering a save
         -- in this event will actually run before most shop events!
         func = function()
            G.E_MANAGER:add_event(Event({
               -- Hence, this event is queued after all shop events are queued:
               trigger = "after",
               func = function()
                  DV.HIST.store_run("auto")
                  return true
               end
            }))
            return true
         end
      }))
      DV.HIST.autosave = false
   end
end

DV.HIST._end_round = end_round
function end_round()
   DV.HIST.autosave = true
   DV.HIST._end_round()
end
