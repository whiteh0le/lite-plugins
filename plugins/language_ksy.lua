local syntax = require "core.syntax"

syntax.add {
  files = { "%.ksy$" },
  comment = '#',
  patterns = {
    { pattern = { '"', '"', '\\' },                   type = "string"   },
    { pattern = { "'", "'", '\\' },                   type = "string"   },
    { pattern = "#.*\n",                              type = "comment"  }, -- Comment
    { pattern = "[fsu][1]%f[%s]",                     type = "literal"  }, -- Integer types, bX, uX, sX, x = 1
    { pattern = "[fsu][248][bl]?e?%f[%s]",            type = "literal"  }, -- Integer types, bX, uX, sX, x = 2, 4, 8
    { pattern = "[%l][%l%d%-_]*%f[(]",                type = "function" }, -- Parametric types
    { pattern = "[%l%-_][%l%d%-_:]*%s*%f[:]",         type = "keyword"  }, -- Every YAML propertie and enum
    { pattern = "%f[%-]% [%l%-][%l%d%-_]*%s*%f[:]",   type = "keyword"  }, -- Propertie with '-' at the beggining
    { pattern = "[%l_][%l%d%-_]*",                    type = "symbol"   }, -- Normal token, _io, _parent, _root and methods
    { pattern = "-?0b[01_]+%f[^%w_]",                 type = "number"   }, -- Binary literal
    { pattern = "-?0o[0-7_]+%f[^%w_]",                type = "number"   }, -- Octal literal
    { pattern = "-?0x[%x_]+%f[^%w_]",                 type = "number"   }, -- Hexadecimal literal
    { pattern = "-?[%d][%d_]*%f[^%w_]",               type = "number"   }, -- Decimal literal
    { pattern = "-?[%d]*%.[%d]+%f[^%w_]",             type = "number"   }, -- Floating point literal
    { pattern = "-?[%d]*%.?[%d]+[eE]%+[%d]+%f[^%w_]", type = "number"   }, -- Decimal number scientific notation
    { pattern = "[!=<>]=",                            type = "operator" }, -- Relational operators
    { pattern = "[+%*/&|%^<>]%s*",                    type = "operator" }, -- Binary operators
    { pattern = "%-%s*%f[%d]",                        type = "operator" }, -- Unary and binary '-' operator
  },
  symbols = {
    ["_io"]     = "keyword2",
    ["_parent"] = "keyword2",
    ["_root"]   = "keyword2",
    ["eos"]     = "literal",
    ["expr"]    = "literal",
    ["false"]   = "literal",
    ["str"]     = "literal",
    ["strz"]    = "literal",
    ["true"]    = "literal",
    ["until"]   = "literal",
    ["zlib"]    = "literal",
    ["and"]     = "operator",
    ["not"]     = "operator",
    ["or"]      = "operator",
  },
}

