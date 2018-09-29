local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"
local req_set_header = ngx.req.set_header
local ngx_re_gmatch = ngx.re.gmatch

local JwtClaimsValidateHandler = BasePlugin:extend()

local function retrieve_token(request, conf)
  local uri_parameters = request.get_uri_args()

  for _, v in ipairs(conf.uri_param_names) do
    if uri_parameters[v] then
      return uri_parameters[v]
    end
  end

  local authorization_header = request.get_headers()["authorization"]
  if authorization_header then
    local iterator, iter_err = ngx_re_gmatch(authorization_header, "\\s*[Bb]earer\\s+(.+)")
    if not iterator then
      return nil, iter_err
    end

    local m, err = iterator()
    if err then
      return nil, err
    end

    if m and #m > 0 then
      return m[1]
    end
  end
end

function JwtClaimsValidateHandler:new()
  JwtClaimsValidateHandler.super.new(self, "jwt-claims-headers")
end

function JwtClaimsValidateHandler:access(conf)
  JwtClaimsValidateHandler.super.access(self)
  local continue_on_error = conf.continue_on_error

  local token, err = retrieve_token(ngx.req, conf)
  if err and not continue_on_error then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  if not token and not continue_on_error then
    return responses.send_HTTP_UNAUTHORIZED()
  end

  local jwt, err = jwt_decoder:new(token)
  if err and not continue_on_error then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR()
  end

  local claims = jwt.claims
  for confClaim in pairs(conf.claims) do
    local claim_kv = split(confClaim, ":")
    local claim_key = claim_kv[0]
    local claim_value = claim_kv
    if claims[claim_key] == nil or claims[claim_key] ~= claim_value then
      return responses.send_HTTP_UNAUTHORIZED("JSON Web Token has invalid claim value for '"..claim_key.."'")
    end
  end
end

return JwtClaimsValidateHandler