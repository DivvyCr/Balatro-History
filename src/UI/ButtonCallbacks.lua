--- Divvy's History for Balatro - UI/ButtonCallbacks.lua
--
-- Functions responsible for processing user's actions.

--
-- RUN HISTORY:
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
-- RUN STORAGE:
--

function G.FUNCS.dv_hist_select_run(e)
   if not e then return end
   G.FUNCS.overlay_menu({
         definition = G.UIDEF.stored_runs()
   })
end

function G.FUNCS.dv_hist_update_runs_page(args)
   if not args or not args.cycle_config then return end
   local callback_args = args.cycle_config.opt_args

   local runs_object = callback_args.ui
   local runs_wrap = runs_object.parent

   runs_wrap.config.object:remove()
   runs_wrap.config.object = UIBox({
         definition = DV.HIST.get_stored_runs_page({run_paths = callback_args.rps, runs_per_page = callback_args.rpp, page_num = args.to_key}),
         config = {parent = runs_wrap, type = "cm"}
   })
   runs_wrap.UIBox:recalculate()
end

function G.FUNCS.dv_hist_load_run(e)
   if not e then return end

   G.SAVED_GAME = e.config.ref_table.run_data

   G.FUNCS.setup_run(e)
end

function G.FUNCS.dv_hist_store_run(e)
   if not e then return end
   G.E_MANAGER:add_event(Event({
      trigger = "after",
      func = function()
         DV.HIST.store_run(DV.HIST.STORAGE_TYPE.MANUAL)
         return true
      end
   }))
   G.FUNCS.exit_overlay_menu()
end

-- Enable 'Continue' option, even when the default 'save.jkr' file is missing:
DV.HIST._can_continue = G.FUNCS.can_continue
function G.FUNCS.can_continue(e)
   if e.config.func then
      if G.SAVED_GAME and G.SAVED_GAME.VERSION and G.SAVED_GAME.VERSION >= "0.9.2" then return true end
      return DV.HIST._can_continue(e)
   end
end

--
-- SETTINGS:
-- 

function G.FUNCS.dv_hist_set_run_autosaves(args)
   G.SETTINGS.DV.autosaves_per_run = args.to_val
end

function G.FUNCS.dv_hist_set_total_autosaves(args)
   G.SETTINGS.DV.autosaves_total = args.to_val
end
