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
   if type == "New Run" then return ui end

   -- TODO: Handle case when there is no 'Continue' run

   ui.nodes[4].nodes[3].config = {align = "cm", minw = 2.1, minh = 0.8, padding = 0.2, r = 0.1, hover = true, shadow = true, colour = G.C.RED, button = "dv_hist_select_run"}

   ui.nodes[4].nodes[3].nodes = {
      {n=G.UIT.R, config={align = "cm", padding = 0}, nodes = {
          {n=G.UIT.T, config={text = "Select Run", scale = 0.4, colour = G.C.UI.TEXT_LIGHT}}
      }}
   }

   local button_padding = {n=G.UIT.C, config={align = "cm", minw = 0.2}, nodes={}}
   table.insert(ui.nodes[4].nodes, 3, button_padding)

   return ui
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