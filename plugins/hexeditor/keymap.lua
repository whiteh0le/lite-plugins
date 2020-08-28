local keymap = require "core.keymap"

keymap.add {
  ["home"]       = "hex:move-to-beginning-of-row",
  ["end"]        = "hex:move-to-end-of-row",
  ["up"]         = "hex:move-to-previous-row",
  ["down"]       = "hex:move-to-next-row",
  ["left"]       = "hex:move-to-previous-byte",
  ["right"]      = "hex:move-to-next-byte",
  ["ctrl+home"]  = "hex:move-to-beginning-of-file",
  ["ctrl+end"]   = "hex:move-to-end-of-file",
  ["ctrl+up"]    = "hex:move-to-previous-row",
  ["ctrl+down"]  = "hex:move-to-next-row",
  ["ctrl+left"]  = "hex:move-to-previous-nibble",
  ["ctrl+right"] = "hex:move-to-next-nibble",
  ["ctrl+h"]     = "hex:open-file",
  ["alt+e"]      = "hex:change-encoding",
  ["alt+b"]      = "hex:change-bytes-per-row",
  ["alt+up"]     = "hex:reset-doc-offset",
  ["alt+left"]   = "hex:shift-doc-left",
  ["alt+right"]  = "hex:shift-doc-right",
}
