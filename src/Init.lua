--- Divvy's History for Balatro - Init.lua
--
-- Global values that must be present for the rest of this mod to work.

if not DV then DV = {} end

DV.HIST = {
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
