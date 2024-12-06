--- Divvy's History for Balatro - Init.lua
--
-- Global values that must be present for the rest of this mod to work.

if not DV then DV = {} end

DV.HIST = {
   -- TODO: Move key data into `G.GAME.DV`?
   history = {},
   view = {
      abs_round = 1,
      text = {" ", " ", " ", " "}
   },
   latest = {
     rel_round = 0,
     abs_round = 0,
     ante = 0,
   },
   TYPES = {
      SKIP = 0,
      HAND = 1,
      DISCARD = 2,
      SHOP = 3
   }
}

DV.HIST._start_run = Game.start_run
function Game:start_run(args)
   DV.HIST._start_run(self, args)
   if not args.savetext then
      -- New run, so modify `GAME` table with custom storage:
      if not G.GAME.DV then G.GAME.DV = {} end
      G.GAME.DV.run_id = DV.HIST.simple_uuid()

      -- ...and reset mod data:
      DV.HIST.history = {}
      DV.HIST.latest = {
         rel_round = 0,
         abs_round = 0,
         ante = 0,
      }
   else
      -- Loaded run, so extract mod data from loaded data:
      DV.HIST.history = G.GAME.DV.history
      DV.HIST.latest = G.GAME.DV.latest
   end
end

DV.HIST._save_run = save_run
function save_run()
   G.GAME.DV.history = DV.HIST.history
   G.GAME.DV.latest = DV.HIST.latest
   DV.HIST._save_run()
end
