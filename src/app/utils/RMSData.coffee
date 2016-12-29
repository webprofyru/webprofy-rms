assert = require('../../dscommon/util').assert
error = require('../../dscommon/util').error

RMSDataStart = /RMS\s*Data\s*\(DO NOT CHANGE!?\)/i
RMSDataEnd = /}\s*END/i

trimEndLF = ((text) ->
  for i in [(text.length - 1)..0] by -1
    if !((c = text.charAt(i)) == '\r' || c == '\n' || c == ' ' || c == '\t') then break
  return if i >= 0 then text.substr(0, i + 1) else '')

trimStartLF = ((text) ->
  e = -1
  for i in [0...text.length] by 1
    if (c = text.charAt(i)) == '\n' then e = i # found end of the line
    else if !(c == '\r' || c == ' ' || c == '\t') then break
  return if e == -1 then text else if i < text.length then text.substr (e + 1) else '')

clear = ((description) ->
  return description if (start = description.search RMSDataStart) == -1
  if (end = description.search RMSDataEnd) != -1 && start < end # it's right
    startText = trimEndLF(description.substr 0, start)
    endText = trimStartLF(description.substr(description.substr(start).search(/end/i) + 3 + start))
    return clear( # clear again
      if startText.length > 0
        if endText.length > 0 then "#{startText}\r\n\r\n#{endText}"
        else startText
      else endText)
  else
    return trimEndLF(description.substr 0, start - 1)) # it's corrupted RMS Data block, so trim from start to very end

module.exports =

  clear: clear

  # Returns: RMS data included in the description, or NULL if nothing was found
  get: ((description) ->
    if assert
      error.invalidArg 'description' if !(description == null || typeof description == 'string')
    return null if description == null || (start = description.search RMSDataStart) == -1
    if (end = description.search RMSDataEnd) != -1 && start < end
      if (jsonStart = description.indexOf '{', start) != -1 && jsonStart < end
        try
          return JSON.parse (description.substr jsonStart, end - jsonStart + 1).trim()
        catch ex
          console.error 'ex: ', ex
    console.error 'Corrupted RMS Data: ', description
    return null)


  put: ((description, data) ->
    if assert
      error.invalidArg 'description' if !(description == null || typeof description == 'string')
      error.invalidArg 'data' if !(data == null || typeof data == 'object')
    description = if description == null then '' else clear description
    return description if data == null || _.size(data) == 0
    return (if description.length == 0 then '' else "#{description}") +  "\r\n\r\nRMS Data (DO NOT CHANGE!) #{JSON.stringify(data)} END")
