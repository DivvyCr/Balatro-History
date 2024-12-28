--- Divvy's History for Balatro - RunHistory.lua
--
-- The core logic of recording the history of actions during a run.

--
-- RECORD HANDS:
--

DV.HIST._evaluate_play = G.FUNCS.evaluate_play
function G.FUNCS.evaluate_play()
   local scoring_name = nil
   local scoring_cards = {}
   scoring_name, _, _, scoring_cards, _ = G.FUNCS.get_poker_hand_info(G.play.cards)

   -- Add cards due to Splash or Stone to scoring_cards:
   local is_splash_joker = next(find_joker("Splash"))
   for _, played_card in ipairs(G.play.cards) do
      for _, scoring_card in ipairs(scoring_cards) do
         if played_card.sort_id ~= scoring_card.sort_id
            and (is_splash_joker or played_card.ability.effect == "Stone Card")
         then
            table.insert(scoring_cards, played_card)
            break
         end
      end
   end

   DV.HIST._evaluate_play()

   DV.HIST.new_hand(scoring_name, scoring_cards)
end

function DV.HIST.new_hand(scoring_name, scoring_cards)
   local played_cards = {}
   for _, card in ipairs(G.play.cards) do
      table.insert(played_cards, DV.HIST.get_card_data(card, scoring_cards))
   end
   local held_cards = {}
   for _, card in ipairs(G.hand.cards) do
      table.insert(held_cards, DV.HIST.get_card_data(card, nil))
   end
   local active_jokers = {}
   for _, joker in pairs(G.jokers.cards) do
      table.insert(active_jokers, DV.HIST.get_joker_data(joker))
   end

   local new_entry = {
      type   = DV.HIST.RECORD_TYPE.HAND,
      name   = scoring_name,
      cards  = played_cards,
      held   = held_cards,
      jokers = active_jokers,
      -- Globally-accessible values used during evaluate_play():
      chips  = hand_chips,
      mult   = mult
   }
   table.insert(DV.HIST.history[DV.HIST.latest.ante][DV.HIST.latest.rel_round], 1, new_entry)
end

DV.HIST._discard_cards = G.FUNCS.discard_cards_from_highlighted
function G.FUNCS.discard_cards_from_highlighted(e, hook)
   local discarded_cards = {}
   for _, card in ipairs(G.hand.highlighted) do
      table.insert(discarded_cards, DV.HIST.get_card_data(card))
   end
   local active_jokers = {}
   for _, joker in ipairs(G.jokers.cards) do
      table.insert(active_jokers, DV.HIST.get_joker_data(joker))
   end

   local new_entry = {type = DV.HIST.RECORD_TYPE.DISCARD,
                      cards = discarded_cards,
                      jokers = active_jokers}
   table.insert(DV.HIST.history[DV.HIST.latest.ante][DV.HIST.latest.rel_round], 1, new_entry)

   DV.HIST._discard_cards(e, hook)
end

--
-- RECORD SHOPS:
--

function DV.HIST.get_shop_entry()
   local new_entry = nil
   local hist_entry = DV.HIST.history[DV.HIST.latest.ante][DV.HIST.latest.rel_round]
   -- NOTE: In base Balatro, it is impossible to reach here without some recorded history,
   -- but mods like DebugPlus allow to win blind without it, so we need the `not entry` condition:
   if not hist_entry[1] or hist_entry[1].type ~= DV.HIST.RECORD_TYPE.SHOP then
      new_entry = {
         type        = DV.HIST.RECORD_TYPE.SHOP,
         dollars     = 0,
         jokers      = {},
         consumables = {},
         boosters    = {},
         vouchers    = {},
         -- Only record bought playing cards if they can occur in shop:
         play_cards  = (G.GAME.playing_card_rate > 0 and {} or nil)
      }
      table.insert(hist_entry, 1, new_entry)
   else
      new_entry = hist_entry[1]
   end
   return new_entry
end

DV.HIST._buy_from_shop = G.FUNCS.buy_from_shop
function G.FUNCS.buy_from_shop(e)
   local card = e.config.ref_table
   if G.STATE == G.STATES.SHOP then
      local shop_entry = DV.HIST.get_shop_entry()
      -- TODO: Account for recuperated dollars from cards like Hermit?
      shop_entry.dollars = shop_entry.dollars + card.cost

      if card.ability.set == "Joker" then
         table.insert(shop_entry.jokers, DV.HIST.get_joker_data(card))
      elseif card.ability.set == "Tarot" or card.ability.set == "Planet" or card.ability.set == "Spectral" then
         table.insert(shop_entry.consumables, DV.HIST.get_consumable_data(card))
      elseif card.ability.set == "Default" or card.ability.set == "Enhanced" then
         table.insert(shop_entry.play_cards, DV.HIST.get_card_data(card))
      end
   end

   DV.HIST._buy_from_shop(e)
end

DV.HIST._use_card = G.FUNCS.use_card
function G.FUNCS.use_card(e, mute, nosave)
   local card = e.config.ref_table
   if G.STATE == G.STATES.SHOP then
      local shop_entry = DV.HIST.get_shop_entry()
      shop_entry.dollars = shop_entry.dollars + card.cost

      -- Jokers, Tarots, Planets, Spectrals, and Playing Cards are handled in G.FUNCS.buy_from_shop.
      if card.ability.set == "Booster" then
         table.insert(shop_entry.boosters, DV.HIST.get_consumable_data(card))
      elseif card.ability.set == "Voucher" then
         table.insert(shop_entry.vouchers, DV.HIST.get_consumable_data(card))
      end
   end

   DV.HIST._use_card(e, mute, nosave)
end
