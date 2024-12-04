--- Divvy's History for Balatro - Interface.lua
--
-- The user interface components that display the recorded history.

-- Full override:
function G.UIDEF.run_info()
   return create_UIBox_generic_options({contents ={create_tabs(
      {tabs = {
         {
            label = localize('b_poker_hands'),
            tab_definition_function = create_UIBox_current_hands,
            chosen = true,
         },
         {
            label = localize('b_blinds'),
            tab_definition_function = G.UIDEF.current_blinds,
         },
         {
            label = localize('b_vouchers'),
            tab_definition_function = G.UIDEF.used_vouchers,
         },
         {
            label = "History",
            tab_definition_function = G.UIDEF.history,
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
-- OVERLAY:
--

function DV.HIST.get_card_area_wrap(card_area, caption)
   return {n=G.UIT.C, config={align = "cm"}, nodes={
      {n=G.UIT.R, config={align = "cm", no_fill = true}, nodes={
         {n=G.UIT.O, config={object = card_area}}
      }},
      {n=G.UIT.R, config={align = "cm"}, nodes={
         {n=G.UIT.T, config={text = caption, padding = 0.05, colour = G.C.L_BLACK, scale = 0.3}}
      }}
   }}
end

function DV.HIST.get_hand_overlay(hand)
   return {n=G.UIT.C, config={align = "cm"}, nodes = {
      {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes = {
         DV.HIST.get_card_area_wrap(DV.HIST.get_cards_area(4, hand.cards), "Cards Played"),
         {n=G.UIT.C, config={minw = 0.05, r = 0.2, colour = G.C.L_BLACK}, nodes={}},
         DV.HIST.get_card_area_wrap(DV.HIST.get_joker_area(4, hand.jokers), "Active Jokers"),
      }}
   }}
end

function DV.HIST.get_shop_overlay(shop)
   return {n=G.UIT.C, config={align = "cm", padding = 0.2}, nodes = {
      {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes = {
         DV.HIST.get_card_area_wrap(DV.HIST.get_joker_area(3, shop.jokers), "Jokers"),
         {n=G.UIT.C, config={minw = 0.05, r = 0.2, colour = G.C.L_BLACK}, nodes={}},
         DV.HIST.get_card_area_wrap(DV.HIST.get_consumable_area(3, shop.consumables), "Consumables"),
         -- Only show bought playing cards area if shop.play_cards is not nil:
         (shop.play_cards and {n=G.UIT.C, config={minw = 0.05, r = 0.2, colour = G.C.L_BLACK}, nodes={}} or nil),
         (shop.play_cards and DV.HIST.get_card_area_wrap(DV.HIST.get_cards_area(3, shop.play_cards), "Playing Cards") or nil),
      }},
      {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes = {
         DV.HIST.get_card_area_wrap(DV.HIST.get_consumable_area(2, shop.boosters), "Packs"),
         {n=G.UIT.C, config={minw = 0.05, r = 0.2, colour = G.C.L_BLACK}, nodes={}},
         DV.HIST.get_card_area_wrap(DV.HIST.get_consumable_area(2, shop.vouchers), "Vouchers"),
      }}
   }}
end

function DV.HIST.get_card_area(norm_width)
   return CardArea(
      G.ROOM.T.x + 0.2*G.ROOM.T.w/2, G.ROOM.T.h, -- Position (x,y)
      norm_width * G.CARD_W/1.6, G.CARD_H/1.6,   -- Size     (w,h)
      {card_w = G.CARD_W/1.8, type = "title_2", highlight_limit = 0})   -- Configuration
end

function DV.HIST.get_cards_area(norm_width, cards)
   local cards_area = DV.HIST.get_card_area(norm_width)
   for _, card in ipairs(cards) do
      local card_obj = Card(
         cards_area.T.x + cards_area.T.w/2, cards_area.T.y, -- Create card in center of CardArea
         G.CARD_W/1.6, G.CARD_H/1.6,
         G.P_CARDS[card.id],
         G.P_CENTERS[card.type] -- Enhancement
      )

      if card.edition then card_obj:set_edition(card.edition, true, true) end
      if card.seal then card_obj:set_seal(card.seal, true) end
      if not card.scoring then card_obj.greyed = true end

      cards_area:emplace(card_obj)
   end
   return cards_area
end

function DV.HIST.get_joker_area(norm_width, jokers)
   local joker_area = DV.HIST.get_card_area(norm_width)
   for _, joker in ipairs(jokers) do
      local card_obj = Card(
         joker_area.T.x + joker_area.T.w/2, joker_area.T.y,
         G.CARD_W/1.6, G.CARD_H/1.6,
         G.P_CENTERS.empty,
         G.P_CENTERS[joker.id])

      if joker.edition then card_obj:set_edition(joker.edition, true, true) end
      -- card_obj.ability = joker.ability

      joker_area:emplace(card_obj)
   end
   return joker_area
end

function DV.HIST.get_consumable_area(norm_width, consumables)
   local consumable_area = DV.HIST.get_card_area(norm_width)
   for _, consumable in ipairs(consumables) do
      local card_obj = Card(
         consumable_area.T.x + consumable_area.T.w/2, consumable_area.T.y,
         G.CARD_W/1.6, G.CARD_H/1.6,
         nil,
         G.P_CENTERS[consumable.id])

      if consumable.edition then card_obj:set_edition(consumable.edition, true, true) end

      consumable_area:emplace(card_obj)
   end
   return consumable_area
end

function DV.HIST.get_content(args)
   local empty = {n=G.UIT.ROOT, config={colour = G.C.CLEAR}, nodes={}}
   if not DV.HIST.history[args.ante_num]
      or not DV.HIST.history[args.ante_num][args.rel_round_num]
   then return empty end

   local data = DV.HIST.history[args.ante_num][args.rel_round_num]
   if data[1] and data[1].type == DV.HIST.TYPES.SKIP then
      return DV.HIST.get_tag_node(args)
   else
      return DV.HIST.get_action_nodes(args)
   end
end

function DV.HIST.get_action_nodes(args)
   local round_actions = DV.HIST.history[args.ante_num][args.rel_round_num]
   if #round_actions == 0 then
      return {n=G.UIT.ROOT, config = {align = "tm", r = 0.1, colour = G.C.CLEAR}, nodes={
         {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {"Play a Hand!"}, colours = {G.C.UI.TEXT_LIGHT}, scale = 0.6, bump = true})}}
         }}
      }}
   end

   local all_nodes = {}
   local hand_idx = #round_actions
   for _, action in ipairs(round_actions) do
      if action.type == DV.HIST.TYPES.SHOP then
         table.insert(all_nodes, DV.HIST.get_shop_node(action))
      elseif action.type == DV.HIST.TYPES.HAND then
         table.insert(all_nodes, DV.HIST.get_hand_node(hand_idx, action))
      elseif action.type == DV.HIST.TYPES.DISCARD then
         table.insert(all_nodes, DV.HIST.get_discard_node(hand_idx, action))
      end
      hand_idx = hand_idx - 1
   end
   return {n=G.UIT.ROOT, config = {align = "tm", r = 0.1, colour = G.C.CLEAR}, nodes={
      {n=G.UIT.R, config={align = "cm", padding = 0.1, r = 0.1}, nodes=all_nodes}
   }}
end

function DV.HIST.get_hand_node(idx, hand)
   local fmt_total = DV.HIST.format_number(math.floor(hand.chips*hand.mult), 1e9)
   return {n=G.UIT.R, config={align = "cm", colour = lighten(G.C.BLUE, 0.25), emboss = 0.05, hover = true, force_focus = true, padding = 0.05, r = 0.1, on_demand_tooltip = {dv=true, filler={func = DV.HIST.get_hand_overlay, args = hand}}}, nodes={
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

function DV.HIST.get_discard_node(idx, hand)
   return {n=G.UIT.R, config={align = "cm", colour = lighten(G.C.RED, 0.25), emboss = 0.05, hover = true, force_focus = true, padding = 0.05, r = 0.1, on_demand_tooltip = {dv=true, filler={func = DV.HIST.get_hand_overlay, args = hand}}}, nodes={
      {n=G.UIT.C, config={align = "cm", minw = 0.8, padding = 0.05, r = 0.1, colour = G.C.L_BLACK}, nodes={
         {n=G.UIT.T, config={text = idx .. ".", colour = G.C.FILTER, shadow = true, scale = 0.45}},
      }},
      {n=G.UIT.C, config={align = "cl", minw = 7.4}, nodes={
         {n=G.UIT.T, config={text = "Discard", color=G.C.UI.TEXT_LIGHT, shadow = true, scale = 0.45}}
      }}
   }}
end

function DV.HIST.get_shop_node(shop)
   return {n=G.UIT.R, config={align = "cm", colour = darken(G.C.JOKER_GREY, 0.1), emboss = 0.05, hover = true, force_focus = true, padding = 0.05, r = 0.1, on_demand_tooltip = {dv=true, filler={func = DV.HIST.get_shop_overlay, args = shop}}}, nodes={
      {n=G.UIT.C, config={align = "cm", minw = 8.2, padding = 0.05}, nodes={
         {n=G.UIT.T, config={text = "Shop!", color=G.C.UI.TEXT_LIGHT, shadow = true, scale = 0.45}}
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
   if data.type == DV.HIST.TYPES.SKIP or #data == 0 then
      -- Align info text to center
      return "cm"
   else
      -- Align hand rows to top
      return "tm"
   end
end

--
-- CUSTOM TOOLTIP:
--

DV.HIST._create_tooltip = create_popup_UIBox_tooltip
function create_popup_UIBox_tooltip(tooltip)
   if tooltip.dv == true then
      return {n=G.UIT.ROOT, config = {align = "cm", padding = 0.05, r = 0.1, float = true, shadow = true, colour = lighten(G.C.GREY, 0.6)}, nodes=
                 {{n=G.UIT.C, config={align = "cm", padding = 0.05, r = 0.1, emboss = 0.05, colour = G.C.BLACK}, nodes={tooltip.filler.func(tooltip.filler.args)}}
                 }}
   end
   return DV.HIST._create_tooltip(tooltip)
end
