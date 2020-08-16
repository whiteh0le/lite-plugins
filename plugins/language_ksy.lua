local syntax = require "core.syntax"

syntax.add {
  files = { "%.ksy$" },
  comment = '#',
  patterns = {
    { pattern = { '"', '"', '\\' },             type = "string"   },
    { pattern = { "'", "'", '\\' },             type = "string"   },
    { pattern = "#.*\n",                        type = "comment"  },
    { pattern = "[fsu][1248][bl]?e?%W",         type = "literal"  },
    { pattern = "%-?% ?[%l%-][%l%d%-_]*%s*::?", type = "keyword"  },
    { pattern = "[%l][%l%d%-_]*%f[(]",          type = "function" },
    { pattern = "[%l_][%l%d%-_]*",              type = "symbol"   },
    { pattern = "-?0x%x+",                      type = "number"   },
    { pattern = "-?%d+",                        type = "number"   },
    { pattern = "[!=<>]=",                      type = "operator" },
    { pattern = "[+%-*/&|%^<>]",                type = "operator" },
  },
  symbols = {
    ["eos"]   = "literal",
    ["expr"]  = "literal",
    ["false"] = "literal",
    ["str"]   = "literal",
    ["strz"]  = "literal",
    ["true"]  = "literal",
    ["until"] = "literal",
    ["zlib"]  = "literal",
    ["and"]   = "operator",
    ["not"]   = "operator",
    ["or"]    = "operator",
  },
}

