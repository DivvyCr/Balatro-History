--- Divvy's History for Balatro - Utils.lua
--
-- Utilities for formatting data, checking states, and formatting display.

function DV.HIST.get_card_data(card_obj, scoring_cards)
   local card_data = {}

   if scoring_cards then
      for _, scoring_card in ipairs(scoring_cards) do
         if card_obj.sort_id == scoring_card.sort_id then
            card_data.scoring = true
         end
      end
   else
      card_data.scoring = true -- Held cards are all considered 'scoring'
   end

   local card_config = card_obj.config.card
   local suit = card_config.suit:sub(1, 1)
   local value = card_config.value == "10" and "T" or card_config.value:sub(1, 1)
   card_data.id = suit .. "_" .. value
   card_data.type = card_obj.config.center.key

   card_data.edition = card_obj.edition
   card_data.seal    = card_obj.seal
   card_data.debuff  = card_obj.debuff
   return card_data
end

function DV.HIST.get_joker_data(joker_obj)
   return {
      id = joker_obj.config.center.key,
      edition = joker_obj.edition,
      -- ability = copy_table(joker_obj.ability)
   }
end

function DV.HIST.get_consumable_data(consumable_obj)
   return {
      id = consumable_obj.config.center.key,
      edition = consumable_obj.edition
   }
end

function DV.HIST.inc_round()
   DV.HIST.latest.rel_round = (DV.HIST.latest.rel_round % 3) + 1 -- Avoid round number 0 from modulo
   DV.HIST.latest.abs_round = DV.HIST.latest.abs_round + 1

   if DV.HIST.latest.rel_round == 1 then
      DV.HIST.latest.ante = DV.HIST.latest.ante + 1
      DV.HIST.history[DV.HIST.latest.ante] = {}
   end

   DV.HIST.history[DV.HIST.latest.ante][DV.HIST.latest.rel_round] = {}
end

DV.HIST._skip_blind = G.FUNCS.skip_blind
function G.FUNCS.skip_blind(e)
   DV.HIST.inc_round()
   local tag_data = e.UIBox:get_UIE_by_ID("tag_container").config.ref_table
   local new_entry = {skipped = true, tag_id = tag_data.key}
   DV.HIST.history[DV.HIST.latest.ante][DV.HIST.latest.rel_round] = new_entry
   DV.HIST._skip_blind(e)
end

DV.HIST._select_blind = G.FUNCS.select_blind
function G.FUNCS.select_blind(e)
   DV.HIST.inc_round()
   DV.HIST._select_blind(e)
end

function DV.HIST.format_number(num, switch_point)
   if not num or type(num) ~= 'number' then return num or '' end
   -- Start using e-notation earlier to reduce number length:
   if num >= switch_point then
      local x = string.format("%.4g",num)
      local fac = math.floor(math.log(tonumber(x), 10))
      return string.format("%.2f",x/(10^fac))..'e'..fac
   end
   return number_format(num) -- Default Balatro function.
end
