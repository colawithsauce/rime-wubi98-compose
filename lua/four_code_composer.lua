local function get_config_int(config, key, fallback)
  local value = config:get_int(key)
  if value and value > 0 then
    return value
  end
  return fallback
end

local function split_four_first(input, chunk_size)
  local chunks = {}
  local pos = 1
  while pos <= #input do
    local rest = #input - pos + 1
    local len = rest > chunk_size and chunk_size or rest
    table.insert(chunks, input:sub(pos, pos + len - 1))
    pos = pos + len
  end
  return chunks
end

local function first_dict_entry(env, code)
  if not env.mem:dict_lookup(code, false, env.lookup_limit) then
    return nil
  end
  for entry in env.mem:iter_dict() do
    if entry and entry.text and entry.text ~= "" then
      return entry
    end
  end
  return nil
end

local function translate(input, seg, env)
  if not input:match("^[a-y]+$") or #input <= env.chunk_size then
    return
  end

  local chunks = split_four_first(input, env.chunk_size)
  if #chunks < 2 or #chunks[1] ~= env.chunk_size then
    return
  end

  local texts = {}
  for _, code in ipairs(chunks) do
    local entry = first_dict_entry(env, code)
    if not entry then
      return
    end
    table.insert(texts, entry.text)
  end

  local cand = Candidate("four_code_compose", seg.start, seg._end,
    table.concat(texts, ""), "〔四码组句〕")
  cand.preedit = table.concat(chunks, "'")
  cand.quality = env.initial_quality
  yield(cand)
end

local function init(env)
  local config = env.engine.schema.config
  env.chunk_size = get_config_int(config, env.name_space .. "/chunk_size", 4)
  env.lookup_limit = get_config_int(config, env.name_space .. "/lookup_limit", 1)
  env.initial_quality = get_config_int(config, env.name_space .. "/initial_quality", 10000000)
  env.mem = Memory(env.engine, env.engine.schema, "translator")
end

return { init = init, func = translate }
