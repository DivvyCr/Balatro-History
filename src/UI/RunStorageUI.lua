--- Divvy's History for Balatro - UI/RunStorageUI.lua
--
-- All UI elements related to the display (and access) of stored runs.

function G.UIDEF.stored_runs()
   -- TODO: Clean-up this function.

   -- TODO: Ensure directories exist?
   local history_dir = (G.SETTINGS.profile or 1) .. "/DVHistory"
   local autosave_dir = history_dir .."/autosaves"
   local run_paths = love.filesystem.getDirectoryItems(autosave_dir)
   for i, file in ipairs(run_paths ) do
      run_paths [i] = "autosaves/" .. run_paths [i]
   end

   -- Only collect files from `history_dir`:
   for _, file in ipairs(love.filesystem.getDirectoryItems(history_dir)) do
      if love.filesystem.isFile(history_dir .."/".. file) then
         table.insert(run_paths , file)
      end
   end

   table.sort(run_paths , function(f1, f2)
                 f1 = history_dir .."/".. f1
                 f2 = history_dir .."/".. f2
                 -- Newest first:
                 return love.filesystem.getInfo(f1).modtime > love.filesystem.getInfo(f2).modtime
   end)

   local page_numbers = {}
   local runs_per_page = 8
   local total_pages = math.ceil(#run_paths /runs_per_page)
   for i = 1, total_pages do
      table.insert(page_numbers, localize("k_page").." "..i.."/"..total_pages)
   end

   local runs = UIBox({
      definition = DV.HIST.get_stored_runs_page({run_paths = run_paths , runs_per_page = runs_per_page, page_num = 1}),
      config = {type = "cm"}
   })

   local callback_args = {
      ui = runs,
      rpp = runs_per_page,
      rds = run_paths ,
   }

   local nav = {n=G.UIT.R, config={align = "cm", colour = G.C.CLEAR}, nodes={
                   create_option_cycle({options = page_numbers, current_option = 1, opt_callback = "dv_hist_update_runs_page", dv = callback_args, w = 4.5, colour = G.C.RED, cycle_shoulders = false, no_pips = true})
               }}

   return create_UIBox_generic_options({
         back_func = "setup_run",
         contents = {
            {n=G.UIT.R, config={align = "cm"}, nodes={
                {n=G.UIT.O, config={id = "dv_hist_runs", object = runs}}
            }},
            nav
         }
   })
end

function DV.HIST.get_stored_runs_page(args)
   local run_paths = args.run_paths
   local offset = (args.page_num - 1) * args.runs_per_page
   local actual_runs_on_page = math.min((#run_paths - offset), args.runs_per_page)

   local run_nodes = {}
   for i = 1, actual_runs_on_page do
      local next_idx = offset + i

      local run_data = get_compressed(G.SETTINGS.profile .."/DVHistory/".. run_paths[next_idx])
      if run_data ~= nil then run_data = STR_UNPACK(run_data) end

      table.insert(run_nodes, DV.HIST.get_stored_run_node(run_paths[next_idx], run_data))
   end

   return
      {n=G.UIT.ROOT, config={align = "tm", minh = 6, r = 0.1, colour = G.C.CLEAR}, nodes={
          {n=G.UIT.R, config={align = "cm", padding = 0.05, r = 0.1}, nodes=run_nodes}
      }}
end

function DV.HIST.get_stored_run_node(run_path, run_data)
   local run_name = run_path
   if string.sub(run_path, 1, 10) == "autosaves/" then
      run_name = string.sub(run_path, 11)
   end

   local tooltip = {dv=true, filler={func = DV.HIST.get_run_overlay, args = run_data}}

   return
      {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
          {n=G.UIT.R, config={button = "dv_hist_load_run", ref_table = {run_path = run_path, run_data = run_data}, align = "cl", minw = 8, colour = G.C.RED, padding = 0.1, r = 0.1, on_demand_tooltip = tooltip, hover = true, shadow = true}, nodes={
              {n=G.UIT.T, config={text = run_name, colour=G.C.UI.TEXT_LIGHT, scale = 0.45}}
          }}
      }}
end

--
-- SUMMARY OVERLAY:
--

function DV.HIST.get_run_overlay(run)
   local scale = 0.3
   local ov_width = 6

   return
      {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes={
          -- Seed in the top-left, and save date in the top-right:
           {n=G.UIT.R, config={align = "cm"}, nodes={
               {n=G.UIT.C, config={align = "cl", minw = ov_width/2.2}, nodes={
                   {n=G.UIT.T, config={text = "Seed: " .. run.GAME.pseudorandom.seed, align = "cl", colour = G.C.UI.TEXT_LIGHT, scale = 0.25}}
               }},
               {n=G.UIT.C, config={align = "cr", minw = ov_width/2.2}, nodes={
                   {n=G.UIT.T, config={text = (run.date_str or ""), align = "cr", colour = G.C.UI.TEXT_LIGHT, scale = 0.25}}
               }}
           }},

          -- Main info:
          {n=G.UIT.R, config={align = "cm"}, nodes={
              {n=G.UIT.C, config={align = "cm"}, nodes={
                  {n=G.UIT.O, config={object = DV.HIST.get_run_summary_deck(run)}}
              }},
              {n=G.UIT.C, config={minw = 0.2}, nodes={}},
              {n=G.UIT.C, config={align = "cm"}, nodes=DV.HIST.get_run_summary_data(run, scale)},
              {n=G.UIT.C, config={minw = 0.2}, nodes={}},
              {n=G.UIT.C, config={align = "cm", r = 0.1, padding = 0.05, colour = lighten(G.C.BLACK, 0.15), float = true, shadow = true}, nodes=DV.HIST.get_run_summary_blind(run, scale)}
          }},

          -- Cardareas:
          {n=G.UIT.R, config={minh = 0.1}, nodes={}},
          {n=G.UIT.R, config={align = "cm", minw = ov_width}, nodes={
              DV.HIST.get_run_summary_cardarea(DV.HIST.get_run_summary_jokers(run), "Jokers", scale)
          }},
          {n=G.UIT.R, config={minh = 0.1}, nodes={}},
          {n=G.UIT.R, config={align = "cm", minw = ov_width}, nodes={
              DV.HIST.get_run_summary_cardarea(DV.HIST.get_run_summary_vouchers(run), "Vouchers", scale),
              DV.HIST.get_run_summary_cardarea(DV.HIST.get_run_summary_consumables(run), "Consumables", scale)
          }}
      }}
end

function DV.HIST.get_run_summary_deck(run_data)
   local deck_area = CardArea(
      0, 0,
      G.CARD_W/2, G.CARD_H/2,
      {card_limit = 1, type = "deck", highlight_limit = 0, deck_height = 0.6, thin_draw = 1}
   )

   G.GAME.viewed_back:change_to(G.P_CENTERS[run_data.BACK.key])

   -- Populate deck, to add volume to its sprite:
   for i = 1, 10 do
      local card = Card(
         G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
         G.CARD_W / 2, G.CARD_H / 2,
         G.P_CARDS.H_A, G.P_CENTERS.c_base,
         { playing_card = 1, viewed_back = true }
      )
      card.sprite_facing = "back"
      card.facing = "back"
      deck_area:emplace(card)
   end
   return deck_area
end

function DV.HIST.get_run_summary_data(run_data, text_scale)
   local function get_label_and_value(label, value, value_colour)
      local w_txt = 0.8
      local w_num = 0.5

      local label_node =
         {n=G.UIT.C, config={align = "cr", minw = w_txt, maxw = w_txt}, nodes={
             {n=G.UIT.T, config={text = label..": ", align = "cr", colour = G.C.UI.TEXT_LIGHT, scale = text_scale}}
         }}

      local value_node =
         {n=G.UIT.C, config={align = "cl", minw = w_num}, nodes={
             (label == "Stake")
                and {n=G.UIT.O, config={object = get_stake_sprite(run_data.GAME.stake, 0.4)}}
                or {n=G.UIT.T, config={text = value, align = "cl", colour = value_colour, scale = text_scale}}
         }}

      return {n=G.UIT.R, config={align = "cm"}, nodes={label_node, value_node}}
   end

   -- Assuming that the parent node has `n=G.UIT.C`;
   -- use as: `{..., nodes = DV.HIST.get_run_summary_data(..)}`
   return {
      get_label_and_value("Round", run_data.GAME.round, G.C.RED),
      get_label_and_value("Ante", run_data.GAME.round_resets.ante, G.C.BLUE),
      get_label_and_value("Money", "$"..run_data.GAME.dollars, G.C.MONEY),
      {n=G.UIT.R, config={minh = 0.1}, nodes={}},
      get_label_and_value("Stake", nil, nil)
   }
end

function DV.HIST.get_run_summary_blind(run_data, text_scale)
   local next_blind_key = DV.HIST.get_next_blind_key(run_data)
   local next_blind = G.P_BLINDS[next_blind_key]

   local blind_sprite = AnimatedSprite(0, 0, 0.7, 0.7, G.ANIMATION_ATLAS["blind_chips"], next_blind.pos)
   blind_sprite:define_draw_steps({{shader = "dissolve", shadow_height = 0.05}, {shader = "dissolve"}})
   blind_sprite.config = {blind = next_blind}
   blind_sprite.float = true

   -- Assuming that the parent node has `n=G.UIT.C`;
   -- use as: `{..., nodes = DV.HIST.get_run_summary_data(..)}`
   return {
      {n=G.UIT.R, config={align = "cm", r = 0.1}, nodes={
          {n=G.UIT.T, config={text = "Upcoming:", colour = G.C.UI.TEXT_LIGHT, scale = text_scale}}
      }},
      {n=G.UIT.R, config={align = "cm", r = 0.1, padding = 0.1, colour = lighten(G.C.BLACK, 0.05), emboss = 0.03}, nodes={
          {n=G.UIT.C, config={align = "cm"}, nodes={
              {n=G.UIT.O, config={object = blind_sprite}}
          }},
          {n=G.UIT.C, config={align = "cm"}, nodes=DV.HIST.get_run_summary_blind_description(run_data, next_blind_key, text_scale)}
      }}
   }
end

function DV.HIST.get_run_summary_blind_description(run_data, next_blind_key, text_scale)
   local blind_description = DV.HIST.get_blind_description(run_data, next_blind_key)
   local blind_chips = DV.HIST.get_blind_chips(run_data, next_blind_key)

   local line1 = nil
   if blind_description[1] then
      line1 = {n=G.UIT.R, config={align = "cl"}, nodes={
                  {n=G.UIT.T, config={text = blind_description[1], colour = G.C.UI.TEXT_LIGHT, scale = 0.2}}
              }}
   end

   local line2 = nil
   if blind_description[2] then
      line2 = {n=G.UIT.R, config={align = "cl"}, nodes={
                  {n=G.UIT.T, config={text = blind_description[2], colour = G.C.UI.TEXT_LIGHT, scale = 0.2}}
              }}
   end

   -- Assuming that the parent node has `n=G.UIT.C`;
   -- use as: `{..., nodes = DV.HIST.get_run_summary_data(..)}`
   return {
      line1,
      line2,
      -- Insert padding only if `line1` or `line2` contain text:
      ((line1 or line2) and {n=G.UIT.R, config={minh = 0.1}, nodes={}} or nil),

      -- Chip requirement format, split across two lines:
      {n=G.UIT.R, config={align = "cl"}, nodes={
          {n=G.UIT.C, config={align = "cm"}, nodes={
              -- Line 1:
              {n=G.UIT.R, config={align = "cl"}, nodes={
                  {n=G.UIT.T, config={text = "Score at least: ", colour = G.C.UI.TEXT_LIGHT, scale = 0.2}},
              }},
              -- Line 2:
              {n=G.UIT.R, config={align = "cl"}, nodes={
                  {n=G.UIT.C, config={align = "cl"}, nodes={
                      {n=G.UIT.O, config={object = get_stake_sprite(run_data.GAME.stake, 0.2)}}
                  }},
                  {n=G.UIT.C, config={minw = 0.05}, nodes={}},
                  {n=G.UIT.C, config={align = "cl"}, nodes={
                      {n=G.UIT.T, config={text = blind_chips, colour = G.C.RED, scale = text_scale}}
                  }}
              }}
          }}
      }}
   }
end

function DV.HIST.get_run_summary_cardarea(cardarea, label, text_scale)
   local content = {n=G.UIT.T, config={text = "None", colour = G.C.UI.TEXT_INACTIVE, scale = 1.5 * text_scale}}
   if #cardarea.cards > 0 then
      content = {n=G.UIT.O, config={object = cardarea}}
   end
   return
      {n=G.UIT.C, config={align = "cm"}, nodes={
           -- Ensure card area wrap takes up at least half of overlay's width,
           -- so that if the card area is empty, the text 'None' appears centered.
           -- (if in doubt, remove minw/minh and see the result):
          {n=G.UIT.R, config={align = "cm", minw = 2.5 * G.CARD_W/2, minh = G.CARD_H/2}, nodes={
              content
          }},
          {n=G.UIT.R, config={align = "cm"}, nodes={
              {n=G.UIT.T, config={text = label, colour = G.C.UI.TEXT_LIGHT, scale = text_scale}}
          }}
      }}
end

function DV.HIST.get_run_summary_jokers(run_data)
   local joker_scale = 0.5
   local joker_area = DV.HIST.create_cardarea(5, joker_scale)

   for _, joker_data in ipairs(run_data.cardAreas.jokers.cards) do
      local c = DV.HIST.create_card(G.P_CARDS.empty, G.P_CENTERS[joker_data.save_fields.center], joker_scale)
      c:set_edition(joker_data.edition)
      joker_area:emplace(c)
   end
   return joker_area
end

function DV.HIST.get_run_summary_consumables(run_data)
   local consumable_scale = 0.5
   local consumable_area = DV.HIST.create_cardarea(3, consumable_scale)

   for _, consumable_data in ipairs(run_data.cardAreas.consumeables.cards) do
      local c = DV.HIST.create_card(G.P_CARDS.empty, G.P_CENTERS[consumable_data.save_fields.center], consumable_scale)
      consumable_area:emplace(c)
   end
   return consumable_area
end

function DV.HIST.get_run_summary_vouchers(run_data)
   local voucher_scale = 0.5
   local voucher_area = DV.HIST.create_cardarea(3, voucher_scale)

   for voucher_key, _ in pairs(run_data.GAME.used_vouchers) do
      local c = DV.HIST.create_card(G.P_CARDS.empty, G.P_CENTERS[voucher_key], voucher_scale)
      voucher_area:emplace(c)
   end
   return voucher_area
end
