hexchat.register('extra-highlights', '1', 'Support highlights with spaces in them')

local OPEN_PER_SERVER = true
local tab_names = { 'pings', 'cases', 'collabs' }
local highlights = {
  pings = { 
  hexchat.get_info('nick'),
  'dhill', 
  'ping sbr%-stack',
  'ping highrollers',
  'ping highroller',
  'ping vz%-eoss',
  'ping sprint%-eoss',
  'ping stack%-seg',
  }, cases =  {
  'NEW NCQ CASE.*Stack',
  'NEW NNO CASE.*Stack',
  }, collabs = {
  'NEW COLLAB CASE.*Stack',
  }
}

local function find_highlighttab (message_type)
  local network = nil
  if OPEN_PER_SERVER then
    network = hexchat.get_info('network')
  end
  local ctx = hexchat.find_context(network, '(' .. message_type .. ')')
  if not ctx then
    if OPEN_PER_SERVER then
      hexchat.command('query -nofocus (' .. message_type .. ')')
    else
      local newtofront = hexchat.prefs['gui_tab_newtofront']
      hexchat.command('set -quiet gui_tab_newtofront off')
      hexchat.command('newserver -noconnect (' .. message_type .. ')')
      hexchat.command('set -quiet gui_tab_newtofront ' .. tostring(newtofront))
    end
    return hexchat.find_context(network, '(' .. message_type .. ')')
  end

  return ctx
end

local function on_message (args, event_type)
  local channel = hexchat.get_info('channel')
  local message = args[2]
  local format
  if event_type == 'Channel Msg Hilight' then
    format = '\00322%s\t\00318<%s%s%s>\015 %s'
  elseif event_type == 'Channel Action Hilight' then
    format = '\00322%s\t\002\00318%s%s%s\015 %s'
  end
  for _, tab_name in ipairs(tab_names) do
    for _, str in ipairs(highlights[tab_name]) do
      if message:find(str) then
        local highlight_context = find_highlighttab(tab_name)
        hexchat.emit_print(event_type, table.unpack(args))
        hexchat.command('gui color 3')
        highlight_context:print(string.format(format, channel, args[3] or '', args[4] or '', hexchat.strip(args[1]), args[2]))
        highlight_context:command('gui color 3')
        return hexchat.EAT_ALL
      end
    end
  end
end

for _, event in ipairs({{'Channel Action', 'Channel Action Hilight'}, {'Channel Message', 'Channel Msg Hilight'}}) do
  hexchat.hook_print(event[1], function (args)
  return on_message (args, event[2])
  end, hexchat.PRI_HIGHEST)
end
