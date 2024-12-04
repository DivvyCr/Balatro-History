--- Divvy's History for Balatro - Core.lua
--
-- The main logic behind recording, viewing, saving, and loading run histories.

DV.HIST._save_run = save_run
function save_run()
   G.GAME.dv_history = DV.HIST.history
   G.GAME.dv_latest = DV.HIST.latest
   DV.HIST._save_run()
end

DV.HIST._start_run = Game.start_run
function Game:start_run(args)
   DV.HIST._start_run(self, args)
   if args.savetext then
      -- Load:
      DV.HIST.history = G.GAME.dv_history
      DV.HIST.latest = G.GAME.dv_latest
   else
      -- Reset:
      DV.HIST.history = {}
      DV.HIST.latest = {
         rel_round = 0,
         abs_round = 0,
         ante = 0,
      }
   end
end

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

   local new_entry = {type   = DV.HIST.TYPES.HAND,
                      name   = scoring_name,
                      cards  = played_cards,
                      held   = held_cards,
                      jokers = active_jokers,
                      -- Globally-accessible values used during evaluate_play()
                      chips  = hand_chips,
                      mult   = mult}
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

   local new_entry = {type = DV.HIST.TYPES.DISCARD,
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
   if hist_entry[1].type ~= DV.HIST.TYPES.SHOP then
      new_entry = {type        = DV.HIST.TYPES.SHOP,
                   jokers      = {},
                   consumables = {},
                   boosters    = {},
                   vouchers    = {}}
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

      if card.ability.set == "Joker" then
         table.insert(shop_entry.jokers, DV.HIST.get_joker_data(card))
      elseif card.ability.set == "Tarot" or card.ability.set == "Planet" or card.ability.set == "Spectral" then
         table.insert(shop_entry.consumables, DV.HIST.get_consumable_data(card))
      elseif card.ability.set == "Default" or card.ability.set == "Enhanced" then
      -- TODO: Playing card bought
      end
   end

   DV.HIST._buy_from_shop(e)
end

DV.HIST._use_card = G.FUNCS.use_card
function G.FUNCS.use_card(e, mute, nosave)
   local card = e.config.ref_table
   if G.STATE == G.STATES.SHOP then
      local shop_entry = DV.HIST.get_shop_entry()

      -- Jokers, Tarots, Planets, Spectrals, and Playing Cards are handled in G.FUNCS.buy_from_shop.
      if card.ability.set == "Booster" then
         table.insert(shop_entry.boosters, DV.HIST.get_consumable_data(card))
      elseif card.ability.set == "Voucher" then
         table.insert(shop_entry.vouchers, DV.HIST.get_consumable_data(card))
      end
   end

   DV.HIST._use_card(e, mute, nosave)
end

--
-- CHANGE VIEW:
--

function G.FUNCS.dv_hist_change_view(e)
   if not e then return end

   if e.config.dir == "fwd" then
      if DV.HIST.view.abs_round + 1 > DV.HIST.latest.abs_round then return end
      DV.HIST.view.abs_round = DV.HIST.view.abs_round + 1
   elseif e.config.dir == "bwd" then
      if DV.HIST.view.abs_round - 1 < 1 then return end
      DV.HIST.view.abs_round = DV.HIST.view.abs_round - 1
   else
      return
   end

   local new_ante = math.ceil(DV.HIST.view.abs_round / 3)
   local new_round = DV.HIST.view.abs_round - (new_ante-1)*3

   DV.HIST.view.text[4] = "Ante " .. new_ante

   -- e.UIBox is the button's UIBox; its parent UIBox is the whole history view.
   -- The button UIBox is needed to be able to show/hide the buttons at the edge rounds.
   local outer_uibox = e.UIBox.parent.UIBox
   local hands_view = outer_uibox:get_UIE_by_ID("dv_hist")

   hands_view.config.object:remove()
   hands_view.config.object = UIBox({
      definition = DV.HIST.get_content({ante_num = new_ante, rel_round_num = new_round}),
      config = {parent = hands_view, type = "cm"}
   })

   local hands_view_wrap = outer_uibox:get_UIE_by_ID("dv_hist_align")
   hands_view_wrap.config.align = DV.HIST.get_content_alignment(new_ante, new_round)

   DV.HIST.update_pips(outer_uibox, new_ante)
   DV.HIST.update_buttons(outer_uibox)

   outer_uibox:recalculate()
end

function DV.HIST.update_pips(hist_uibox, ante)
   if not hist_uibox then return end

   for i = 1, 3 do
      local abs_round_num = (ante-1)*3 + i
      if abs_round_num > DV.HIST.latest.abs_round then
         DV.HIST.view.text[i] = " "
      else
         DV.HIST.view.text[i] = "Round " .. abs_round_num
      end

      local pip = hist_uibox:get_UIE_by_ID("dv_hist_round_" .. i)
      if abs_round_num > DV.HIST.latest.abs_round then
         pip.parent.config.colour = G.C.GREY
      elseif i == (DV.HIST.view.abs_round - (ante-1)*3) then
         pip.parent.config.colour = G.C.RED
      else
         pip.parent.config.colour = G.C.BLACK
      end
   end
end

function DV.HIST.update_buttons(hist_uibox)
   local fwd_button = hist_uibox:get_UIE_by_ID("dv_hist_fwd_but")
   if DV.HIST.view.abs_round >= DV.HIST.latest.abs_round then
     fwd_button.config.object:remove()
   end
   fwd_button.config.object = UIBox({
     definition = DV.HIST.create_button("fwd"),
     config = {parent = fwd_button, type = "cm"}
   })

   local bwd_button = hist_uibox:get_UIE_by_ID("dv_hist_bwd_but")
   if DV.HIST.view.abs_round <= 1 then
      bwd_button.config.object:remove()
   end
   bwd_button.config.object = UIBox({
     definition = DV.HIST.create_button("bwd"),
     config = {parent = bwd_button, type = "cm"}
   })
end
