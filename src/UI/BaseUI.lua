--- Divvy's History for Balatro - UI/BaseUI.lua
--
-- Fundamental changes to the game's UI, which allow for extensions.

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

DV.HIST._run_setup_option = G.UIDEF.run_setup_option
function G.UIDEF.run_setup_option(type)
   local ui = DV.HIST._run_setup_option(type)

   ui.nodes[4].nodes[3].config = {align = "cm", minw = 2.3, minh = 0.8, padding = 0.2, r = 0.1, hover = true, shadow = true, colour = G.C.RED, button = "dv_hist_select_run"}

   ui.nodes[4].nodes[3].nodes = {
      {n=G.UIT.R, config={align = "cm", padding = 0}, nodes = {
          {n=G.UIT.T, config={text = "Select Run", scale = 0.4, colour = G.C.UI.TEXT_LIGHT}}
      }}
   }

   local button_padding = {n=G.UIT.C, config={align = "cm", minw = 0.2}, nodes={}}
   table.insert(ui.nodes[4].nodes, 3, button_padding)

   return ui
end

DV.HIST._create_UIBox_options = create_UIBox_options
function create_UIBox_options()
   local ui = DV.HIST._create_UIBox_options()
   if G.STAGE == G.STAGES.RUN then
      local store_run_button = UIBox_button({ button = "dv_hist_store_run", label = { "Save Run" }, minw = 5 })
      table.insert(ui.nodes[1].nodes[1].nodes[1].nodes, 5, store_run_button)
   end
   return ui
end

--
-- CUSTOM CARDAREA:
--

function DV.HIST.create_card(prop1, prop2, card_scale)
   if not card_scale then card_scale = 0.5 end
   return Card(
      0, 0,
      card_scale * G.CARD_W, card_scale * G.CARD_H,
      prop1, prop2)
end

function DV.HIST.create_cardarea(total_width_scale, card_scale)
   return CardArea(
      0, 0,
      card_scale * G.CARD_W * total_width_scale,
      card_scale * G.CARD_H * 1.1,
      {card_w = card_scale * G.CARD_W, type = "title_2", highlight_limit = 0})
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
