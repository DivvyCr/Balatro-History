--- STEAMODDED HEADER
--- MOD_NAME: Divvy's History
--- MOD_ID: dvhistory
--- MOD_AUTHOR: [Divvy C.]
--- MOD_DESCRIPTION: View your last played hand!

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
   }
}

--
-- BACKEND LOGIC:
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
   local last_cards = DV.HIST.get_card_data(G.play.cards, scoring_cards)
   local last_held = DV.HIST.get_card_data(G.hand.cards, nil)
   local last_jokers = DV.HIST.get_last_jokers()

   -- NOTE: hand_chips and mult are GLOBAL, so we could display Chips x Mult!

   local new_entry = {name = scoring_name,
                      cards = last_cards,
                      held = last_held_cards,
                      jokers = last_jokers,
                      -- Globally-accessible values used during evaluate_play()
                      chips = hand_chips,
                      mult = mult}
   table.insert(DV.HIST.history[DV.HIST.latest.ante][DV.HIST.latest.rel_round], 1, new_entry)
end

function DV.HIST.get_card_data(cards, scoring_cards)
   local last_cards = {}
   for _, card in ipairs(cards) do
      local card_data = {}

      if scoring_cards then
         for _, scoring_card in ipairs(scoring_cards) do
            if card.sort_id == scoring_card.sort_id then
               card_data.scoring = true
            end
         end
      else
         card_data.scoring = true
      end

      local card_config = card.config.card
      local suit = card_config.suit:sub(1, 1)
      local value = card_config.value == "10" and "T" or card_config.value:sub(1, 1)
      card_data.id = suit .. "_" .. value
      card_data.type = card.config.center.key

      if card.edition then
         if card.edition.foil then card_data.edition = "foil"
         elseif card.edition.holo then card_data.edition = "holo"
         elseif card.edition.polychrome then card_data.edition = "poly"
         end
      end

      if card.seal then
         card_data.seal = card.seal
      end

      table.insert(last_cards, card_data)
   end
   return last_cards
end

function DV.HIST.get_last_jokers()
   last_jokers = {}
   for _, joker in pairs(G.jokers.cards) do
      local joker_data = {}
      joker_data.id = joker.config.center.key

      if joker.edition then
         if joker.edition.foil then joker_data.edition = "foil"
         elseif joker.edition.holo then joker_data.edition = "holo"
         elseif joker.edition.polychrome then joker_data.edition = "poly"
         end
      end

      table.insert(last_jokers, joker_data)
   end
   return last_jokers
end

--
-- USER INTERFACE:
--

-- Full override:
function G.UIDEF.run_info()
   return create_UIBox_generic_options({contents ={create_tabs(
      {tabs = {
         {
            label = "History",
            chosen = true,
            tab_definition_function = G.UIDEF.history,
         },
         {
            label = localize('b_poker_hands'),
            tab_definition_function = create_UIBox_current_hands,
         },
         {
            label = localize('b_blinds'),
            tab_definition_function = G.UIDEF.current_blinds,
         },
         {
            label = localize('b_vouchers'),
            tab_definition_function = G.UIDEF.used_vouchers,
         },
         G.GAME.stake > 1 and {
            label = localize('b_stake'),
            tab_definition_function = G.UIDEF.current_stake,
         } or nil,
      },
       tab_h = 8,
       snap_to_nav = true})}})
end

function G.UIDEF.history()
   DV.HIST.view.abs_round = DV.HIST.latest.abs_round
   DV.HIST.view.text[4] = "Ante " .. DV.HIST.latest.ante
   for i = 1, 3 do
      local abs_round_num = (DV.HIST.latest.ante-1)*3 + i
      DV.HIST.view.text[i] = "Round " .. abs_round_num
   end

   local content = UIBox({
      definition = DV.HIST.get_content({ante_num = DV.HIST.latest.ante, rel_round_num = DV.HIST.latest.rel_round}),
      config = {type = "cm"}
   })

   local fwd_button = UIBox({
      definition = DV.HIST.create_button("fwd"),
      config = {type = "cm"}
   })

   local bwd_button = UIBox({
      definition = DV.HIST.create_button("bwd"),
      config = {type = "cm"}
   })

   local content_align = DV.HIST.get_content_alignment(DV.HIST.latest.ante, DV.HIST.latest.rel_round)
   return {n=G.UIT.ROOT, config = {align = "cm", minw = 10, padding = 0.2, r = 0.15, colour = G.C.CLEAR}, nodes = {
      {n=G.UIT.R, config = {id = "dv_hist_align", align = content_align, minh = 6}, nodes = {
         -- Display (usually hands, sometimes skipped tag):
         {n=G.UIT.C, config = {align = "cm"}, nodes = {
            {n=G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {
               {n=G.UIT.O, config = {id = "dv_hist", object = content}}
            }},
         }}
      }},
      {n=G.UIT.R, config = {align = "cm"}, nodes = {
         -- Navigation:
         {n=G.UIT.C, config={align = "cm"}, nodes = {
            {n=G.UIT.R, config={align = "cm"}, nodes = {
               -- (<) (Round X) (Round Y) (Round Z) (>)
               {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes = {
                  {n=G.UIT.O, config = {id = "dv_hist_bwd_but", object = bwd_button}}
               }},
               {n=G.UIT.C, config={align = "cm"}, nodes = {
                  {n=G.UIT.R, config={align = "cm"}, nodes = {
                     DV.HIST.create_pip(1),
                     DV.HIST.create_pip(2),
                     DV.HIST.create_pip(3)
                  }}
               }},
               {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes = {
                  {n=G.UIT.O, config = {id = "dv_hist_fwd_but", object = fwd_button}}
               }},
            }},
            {n=G.UIT.R, config={align = "cm"}, nodes={
               -- (Ante N)
               {n=G.UIT.R, config={align = "cm", minw = 3, maxw = 3, padding = 0.05, r = 0.1, emboss = 0.05, colour = G.C.RED}, nodes = {
                  {n=G.UIT.O, config={object = DynaText({string = {{ref_table = DV.HIST.view.text, ref_value = 4}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, bump = true, scale = 0.4})}}
               }}
            }}
         }}
      }}
   }}
end

function DV.HIST.create_button(dir)
   local placeholder = {n=G.UIT.ROOT, config={align = "cm", colour = G.C.CLEAR}, nodes={
     {n=G.UIT.C, config={button = "dv_hist_change_view", dir = dir, align = "cm", minw = 0.4, padding = 0.1, r = 0.2, colour = G.C.CLEAR}, nodes={}}
   }}
   if dir == "fwd" and DV.HIST.view.abs_round >= DV.HIST.latest.abs_round then
     return placeholder
   end
   if dir == "bwd" and DV.HIST.view.abs_round <= 1 then
     return placeholder
   end

   local label = (dir == "fwd" and ">") or (dir == "bwd" and "<")
   return {n=G.UIT.ROOT, config={align = "cm", colour = G.C.CLEAR}, nodes={
      {n=G.UIT.C, config={button = "dv_hist_change_view", dir = dir, align = "cm", minw = 0.4, padding = 0.1, r = 0.2, hover = true, shadow = true, colour = G.C.RED}, nodes={
         {n=G.UIT.T, config={text = label, colour = G.C.UI.TEXT_LIGHT, scale = 0.3}}
      }}
   }}
end

function DV.HIST.create_pip(rel_round_num)
   local bg_colour = nil
   if rel_round_num > DV.HIST.latest.rel_round then
      bg_colour = G.C.GREY
   elseif rel_round_num == DV.HIST.latest.rel_round then
      bg_colour = G.C.RED
   else
      bg_colour = G.C.BLACK
   end

   local pip_id = "dv_hist_round_" .. rel_round_num

   if rel_round_num > DV.HIST.latest.rel_round then
      -- No text if round not yet reached, but need space to maintain pip height:
      DV.HIST.view.text[rel_round_num] = " "
   else
      local abs_round_num = (DV.HIST.latest.ante-1)*3 + rel_round_num
      DV.HIST.view.text[rel_round_num] = "Round " .. abs_round_num
   end

   return {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes={
      {n=G.UIT.R, config={align = "cm", minw = 2, padding = 0.05, r = 0.1, emboss = 0.05, colour = bg_colour}, nodes={
         {n=G.UIT.O, config={id = pip_id, object = DynaText({string = {{ref_table = DV.HIST.view.text, ref_value = rel_round_num}}, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, bump = true, scale = 0.4})}},
      }}
   }}
end

--
-- BUTTON CALLBACKS:
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

--
-- USER INTERFACE (OVERLAY):
--

function DV.HIST.get_history_overlay(hand)
   function get_cards_area_wrap()
      return {n=G.UIT.C, config={align = "cm"}, nodes={
       {n=G.UIT.R, config={align = "cm", no_fill = true}, nodes={
         {n=G.UIT.O, config={object = DV.HIST.get_cards_area(hand.cards)}}
       }},
         {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.T, config={text = "Cards Played", padding = 0.05, colour = G.C.L_BLACK, scale = 0.3}}
         }}
      }}
   end

   function get_joker_area_wrap()
      return {n=G.UIT.C, config={align = "cm"}, nodes={
         {n=G.UIT.R, config={align = "cm", padding = 0, no_fill = true}, nodes={
            {n=G.UIT.O, config={object = DV.HIST.get_joker_area(hand.jokers)}}
         }},
         {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.T, config={text = "Active Jokers", padding = 0.05, colour = G.C.L_BLACK, scale = 0.3}}
         }}
      }}
   end

   return {n=G.UIT.C, config={align = "cm"}, nodes = {
      {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes = {
         get_cards_area_wrap(),
         {n=G.UIT.C, config={minw = 0.05, r = 0.2, colour = G.C.L_BLACK}, nodes={}},
         get_joker_area_wrap()
      }}
   }}
end

function DV.HIST.get_cards_area(cards)
   local cards_area = CardArea(
      G.ROOM.T.x + 0.2*G.ROOM.T.w/2, G.ROOM.T.h,
      4*G.CARD_W/1.6, G.CARD_H/1.6,
      {card_limit = 5, type = 'title_2', highlight_limit = 0})

   for _, card in ipairs(cards) do
      local card_obj = Card(
         cards_area.T.x + cards_area.T.w/2, cards_area.T.y, -- Create card in center of CardArea
         G.CARD_W/1.6, G.CARD_H/1.6,
         G.P_CARDS[card.id],
         G.P_CENTERS[card.type] -- Enhancement
      )

      if card.edition == "foil" then card_obj:set_edition({foil = true}, true, true)
      elseif card.edition == "holo" then card_obj:set_edition({holo = true}, true, true)
      elseif card.edition == "poly" then card_obj:set_edition({polychrome = true}, true, true)
      end

      if card.seal then card_obj:set_seal(card.seal, true) end

      if not card.scoring then card_obj.greyed = true end

      cards_area:emplace(card_obj)
   end

   return cards_area
end

function DV.HIST.get_joker_area(jokers)
   local joker_area = CardArea(
      G.ROOM.T.x + 0.2*G.ROOM.T.w/2, G.ROOM.T.h,
      4*G.CARD_W/1.6, G.CARD_H/1.6,
      {card_limit = #G.jokers.cards, type = 'title_2', highlight_limit = 0})

   for _, joker in ipairs(jokers) do
      local card_obj = Card(
         joker_area.T.x + joker_area.T.w/2, joker_area.T.y,
         G.CARD_W/1.6, G.CARD_H/1.6,
      G.P_CENTERS.empty,
         G.P_CENTERS[joker.id])

      if joker.edition == "foil" then card_obj:set_edition({foil = true}, true, true)
      elseif joker.edition == "holo" then card_obj:set_edition({holo = true}, true, true)
      elseif joker.edition == "poly" then card_obj:set_edition({polychrome = true}, true, true)
      end

      joker_area:emplace(card_obj)
   end

   return joker_area
end

function DV.HIST.get_content(args)
   local empty = {n=G.UIT.ROOT, config={colour = G.C.CLEAR}, nodes={}}
   if not DV.HIST.history[args.ante_num]
      or not DV.HIST.history[args.ante_num][args.rel_round_num]
   then return empty end

   local data = DV.HIST.history[args.ante_num][args.rel_round_num]
   if data.skipped then
      return DV.HIST.get_tag_node(args)
   end
   return DV.HIST.get_hand_nodes(args)
end

function DV.HIST.get_hand_nodes(args)
   local round_hands = DV.HIST.history[args.ante_num][args.rel_round_num]
   if #round_hands == 0 then 
      return {n=G.UIT.ROOT, config = {align = "tm", r = 0.1, colour = G.C.CLEAR}, nodes={
         {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {"Play a Hand!"}, colours = {G.C.UI.TEXT_LIGHT}, scale = 0.6, bump = true})}}
         }}
      }}
   end

   local hand_nodes = {}
   for idx, hand in ipairs(round_hands) do
      local true_hand_idx = #round_hands - (idx-1) -- They are stored in reverse order
      table.insert(hand_nodes, DV.HIST.get_one_hand_node(true_hand_idx, hand))
   end
   return {n=G.UIT.ROOT, config = {align = "tm", r = 0.1, colour = G.C.CLEAR}, nodes={
      {n=G.UIT.R, config={align = "cm", padding = 0.1, r = 0.1}, nodes=hand_nodes}
   }}
end

function DV.HIST.get_one_hand_node(idx, hand)
   local fmt_total = DV.HIST.format_number(math.floor(hand.chips*hand.mult), 1e9)
   return {n=G.UIT.R, config={align = "cm", colour = darken(G.C.JOKER_GREY, 0.1), emboss = 0.05, hover = true, force_focus = true, padding = 0.05, r = 0.1, on_demand_tooltip = {dv=true, filler={func = DV.HIST.get_history_overlay, args = hand}}}, nodes={
      {n=G.UIT.C, config={align = "cm", minw = 0.8, padding = 0.05, r = 0.1, colour = G.C.L_BLACK}, nodes={
        {n=G.UIT.T, config={text = idx .. ".", colour = G.C.FILTER, shadow = true, scale = 0.45}},
      }},
      {n=G.UIT.C, config={align = "cl", minw = 3.4}, nodes={
         {n=G.UIT.T, config={text = hand.name, color=G.C.UI.TEXT_LIGHT, shadow = true, scale = 0.45}}
      }},
      {n=G.UIT.C, config={align = "cr", minw = 4}, nodes={
         {n=G.UIT.C, config={align = "cm", padding = 0.05, r = 0.1, colour = G.C.BLACK}, nodes={
            {n=G.UIT.B, config={w = 0.05, h = 0.01}, nodes={}},
            {n=G.UIT.O, config={w = 0.3, h = 0.3, object = get_stake_sprite(G.GAME.stake or 1), can_collide = false}},
            {n=G.UIT.T, config={text = fmt_total, colour = G.C.UI.TEXT_LIGHT, shadow = true, scale = 0.45}},
            {n=G.UIT.B, config={w = 0.1, h = 0.01}, nodes={}},
         }}
      }}
   }}
end

function DV.HIST.get_tag_node(args)
   local data = DV.HIST.history[args.ante_num][args.rel_round_num]
   local tag_ui, tag_sprite = Tag(data.tag_id):generate_UI()

   local tag_node = {}
   return {n=G.UIT.ROOT, config={align = "cm", r = 0.1, colour = G.C.CLEAR}, nodes={
      {n=G.UIT.C, config={align = "cm"}, nodes={
         {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {"Round Skipped for:"}, colours = {G.C.UI.TEXT_LIGHT}, scale = 0.6, bump = true})}}
         }},
         {n=G.UIT.R, config={align = "cm", r = 0.1, padding = 0.1, minw = 1, can_collide = true, ref_table = tag_sprite}, nodes={
            {n=G.UIT.C, config={align = "cm", minh = 1}, nodes={
               tag_ui
            }}
         }}
      }}
   }}
end

function DV.HIST.get_content_alignment(ante_num, rel_round_num)
   if not DV.HIST.history[ante_num] or
      not DV.HIST.history[ante_num][rel_round_num]
   then return "cm" end

   local data = DV.HIST.history[ante_num][rel_round_num]
   if data.skipped or #data == 0 then
      -- Align info text to center
      return "cm"
   else
      -- Align hand rows to top
      return "tm"
   end
end

--
-- USER INTERFACE (CUSTOM TOOLTIP):
--

DV.HIST._create_tooltip = create_popup_UIBox_tooltip
function create_popup_UIBox_tooltip(tooltip)
   if tooltip.dv == true then
      return {n=G.UIT.ROOT, config = {align = "cm", padding = 0.05, r = 0.1, float = true, shadow = true, colour = lighten(G.C.GREY, 0.5)}, nodes=
                 {{n=G.UIT.C, config={align = "cm", padding = 0.05, r = 0.1, emboss = 0.05, colour = G.C.BLACK}, nodes={tooltip.filler.func(tooltip.filler.args)}}
                 }}
   end
   return DV.HIST._create_tooltip(tooltip)
end

--
-- MISC:
--

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

--
-- SAVE/LOAD:
--

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
