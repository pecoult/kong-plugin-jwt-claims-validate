package = "kong-plugin-jwt-claims-validate-rpt"
version = "1.0-1"
source = {
   url = "git+https://github.com/pecoult/kong-plugin-jwt-claims-validate.git",
   tag = "v1.1"
}
description = {
   summary = "A Kong plugin to check JWT claim values",
   homepage = "https://github.com/pecoult/kong-plugin-jwt-claims-validate",
   license = "MIT"
}
dependencies = {
   "lua ~> 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["kong.plugins.jwt-claims-validate.handler"] = "handler.lua",
      ["kong.plugins.jwt-claims-validate.schema"] = "schema.lua"
   }
}
