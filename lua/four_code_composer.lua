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

local function collect_dict_entries(env, code)
  if not env.mem:dict_lookup(code, false, env.per_chunk_limit) then
    return {}
  end
  local entries = {}
  local seen = {}
  for entry in env.mem:iter_dict() do
    if entry and entry.text and entry.text ~= "" then
      if not seen[entry.text] then
        table.insert(entries, entry)
        seen[entry.text] = true
      end
    end
  end
  return entries
end

local function translate(input, seg, env)
  if not input:match("^[a-y]+$") or #input <= env.chunk_size then
    return
  end

  local chunks = split_four_first(input, env.chunk_size)
  if #chunks < 2 or #chunks[1] ~= env.chunk_size then
    return
  end

  local entries_by_chunk = {}
  for _, code in ipairs(chunks) do
    local entries = collect_dict_entries(env, code)
    if #entries == 0 then
      return
    end
    table.insert(entries_by_chunk, entries)
  end

  local fixed_parts = {}
  for i = 1, #entries_by_chunk - 1 do
    fixed_parts[i] = entries_by_chunk[i][1].text
  end

  local last_entries = entries_by_chunk[#entries_by_chunk]
  local yielded = 0
  for _, entry in ipairs(last_entries) do
    if yielded >= env.max_candidates then
      return
    end
    local parts = {}
    for i = 1, #fixed_parts do
      parts[i] = fixed_parts[i]
    end
    parts[#entries_by_chunk] = entry.text

    local cand = Candidate("four_code_compose", seg.start, seg._end,
      table.concat(parts, ""), "〔四码组句〕")
    cand.preedit = table.concat(chunks, "'")
    cand.quality = env.initial_quality - yielded
    yield(cand)
    yielded = yielded + 1
  end
end

local function init(env)
  local config = env.engine.schema.config
  env.chunk_size = get_config_int(config, env.name_space .. "/chunk_size", 4)
  env.per_chunk_limit = get_config_int(config, env.name_space .. "/per_chunk_limit",
    get_config_int(config, env.name_space .. "/lookup_limit", 5))
  env.max_candidates = get_config_int(config, env.name_space .. "/max_candidates", 30)
  env.initial_quality = get_config_int(config, env.name_space .. "/initial_quality", 10000000)
  env.mem = Memory(env.engine, env.engine.schema, "translator")
end

return { init = init, func = translate }
