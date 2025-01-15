--- Divvy's History for Balatro - RunStorage.lua
--
-- The core logic of storing runs for later loading from file.

-- The following is a customised version of functions/misc_functions.lua#save_run()
function DV.HIST.store_run(store_type)
   -- Do nothing if this is an autosave and autosaves are disabled:
   if store_type == DV.HIST.STORAGE_TYPE.AUTO and not G.SETTINGS.DV.autosave then return end

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
      type_str = store_type,
      date_str = os.date("%H:%M, %d %b %Y"),
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
         profile_num = G.SETTINGS.profile,
         dv_settings = G.SETTINGS.DV,
         dv_paths = DV.HIST.PATHS,
         dv_types = DV.HIST.STORAGE_TYPE
      })
   end

   G.FILE_HANDLER.store_run = nil
end

--
-- AUTO-SAVING:
--

-- Autosave after round end, just when entering shop:
DV.HIST._update_shop = Game.update_shop
function Game:update_shop(dt)
   DV.HIST._update_shop(self, dt)

   if DV.HIST.autosave then
      G.E_MANAGER:add_event(Event({
         -- This event is queued after all shop events;
         -- however, shop events queue more (nested) events, so triggering
         -- a save in this event will actually run before most shop events!
         trigger = "after",
         -- The delay in only necessary to allow some shop events to take place, such as the Coupon tag
         -- TODO: Figure out a better way to do this:
         -- either combine some shop condition with top-level `if` here,
         -- or trigger run storage at a slightly different time?
         delay = 1.5,
         --
         func = function()
            G.E_MANAGER:add_event(Event({
               -- Hence, this event is queued after all shop events are queued:
               trigger = "after",
               func = function()
                  DV.HIST.store_run(DV.HIST.STORAGE_TYPE.AUTO)
                  return true
               end
            }))
            return true
         end
      }))
      DV.HIST.autosave = false
   end
end

-- ENABLE AUTOSAVING ONLY AFTER ROUND END:
-- (this avoids autosaving at awkward times)

DV.HIST._end_round = end_round
function end_round()
   DV.HIST.autosave = true

   -- Must manually check for game win/loss, in order to
   -- store run BEFORE the win/loss screen (so that it re-appears on run load):
   local game_over_status = DV.HIST.is_game_over()
   if game_over_status then
      G.E_MANAGER:add_event(Event({
         trigger = "after",
         func = function()
            DV.HIST.store_run(game_over_status)
            return true
         end
      }))
      DV.HIST.autosave = false
   end

   DV.HIST._end_round()
end

function DV.HIST.is_game_over()
   local round_beat = false
   if G.GAME.chips - G.GAME.blind.chips >= 0 then
      round_beat = true
   else
      -- Check for any saving graces:
      -- TODO: Need a more generic way that doesn't have side-effects (for other mod effects)
      for _, joker_obj in ipairs(G.jokers.cards) do
         if joker_obj.ability.name == "Mr. Bones" and G.GAME.chips/G.GAME.blind.chips >= 0.25 then
            round_beat = true
         end
      end
   end

   if round_beat then
      if G.GAME.round_resets.ante == G.GAME.win_ante and G.GAME.blind:get_type() == 'Boss' then
         return DV.HIST.STORAGE_TYPE.WIN
      else
         return nil
      end
   else
      return DV.HIST.STORAGE_TYPE.LOSS
   end
end
