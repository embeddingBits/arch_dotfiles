-- Pywal-generated color variables
-- ~/.config/hypr/lua/colors.lua
--
-- To regenerate these from pywal, create a template at:
--   ~/.config/wal/templates/hypr-colors.lua
-- and add the following pywal template variables mapped to Lua table fields.
-- Then run `wal -R` or `wal -i <wallpaper>` to regenerate.

local M = {}

M.background                  = "rgba(141312ff)"
M.error                       = "rgba(ffb4abff)"
M.error_container             = "rgba(93000aff)"
M.inverse_on_surface          = "rgba(31302fff)"
M.inverse_primary             = "rgba(635e52ff)"
M.inverse_surface             = "rgba(e6e2dfff)"
M.on_background               = "rgba(e6e2dfff)"
M.on_error                    = "rgba(690005ff)"
M.on_error_container          = "rgba(ffdad6ff)"
M.on_primary                  = "rgba(343026ff)"
M.on_primary_container        = "rgba(3c382eff)"
M.on_primary_fixed            = "rgba(1f1b12ff)"
M.on_primary_fixed_variant    = "rgba(4b463cff)"
M.on_secondary                = "rgba(33302bff)"
M.on_secondary_container      = "rgba(e9e3dcff)"
M.on_secondary_fixed          = "rgba(1d1b17ff)"
M.on_secondary_fixed_variant  = "rgba(494641ff)"
M.on_surface                  = "rgba(e6e2dfff)"
M.on_surface_variant          = "rgba(ccc6bbff)"
M.on_tertiary                 = "rgba(2e322aff)"
M.on_tertiary_container       = "rgba(363a32ff)"
M.on_tertiary_fixed           = "rgba(191d16ff)"
M.on_tertiary_fixed_variant   = "rgba(444840ff)"
M.outline                     = "rgba(969087ff)"
M.outline_variant             = "rgba(4a463fff)"
M.primary                     = "rgba(eee5d6ff)"
M.primary_container           = "rgba(d1c9bbff)"
M.primary_fixed               = "rgba(eae1d3ff)"
M.primary_fixed_dim           = "rgba(cdc6b8ff)"
M.scrim                       = "rgba(000000ff)"
M.secondary                   = "rgba(cbc6bfff)"
M.secondary_container         = "rgba(4c4944ff)"
M.secondary_fixed             = "rgba(e8e2daff)"
M.secondary_fixed_dim         = "rgba(cbc6bfff)"
M.shadow                      = "rgba(000000ff)"
M.source_color                = "rgba(d1c9bbff)"
M.surface                     = "rgba(141312ff)"
M.surface_bright              = "rgba(3a3938ff)"
M.surface_container           = "rgba(201f1eff)"
M.surface_container_high      = "rgba(2b2a29ff)"
M.surface_container_highest   = "rgba(363433ff)"
M.surface_container_low       = "rgba(1c1b1aff)"
M.surface_container_lowest    = "rgba(0f0e0dff)"
M.surface_dim                 = "rgba(141312ff)"
M.surface_tint                = "rgba(cdc6b8ff)"
M.surface_variant             = "rgba(4a463fff)"
M.tertiary                    = "rgba(e4e7dcff)"
M.tertiary_container          = "rgba(c8cbc0ff)"
M.tertiary_fixed              = "rgba(e1e4d8ff)"
M.tertiary_fixed_dim          = "rgba(c5c8bdff)"

-- Border aliases (old $color11 = $secondary, $color8 = $on_secondary)
M.active_border   = M.secondary    -- rgba(cbc6bfff)
M.inactive_border = M.on_secondary -- rgba(33302bff)

return M
