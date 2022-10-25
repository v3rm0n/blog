---
layout: post
title:  "Bassdrive Radio addon for VLC"
tags: music api lua
---

I have been listening to [Bassdrive Radio][bd] almost daily for over 10 years now. It's a worldwide
drum and bass radio, but it's aired from the USA which means that usually when I'm active they are
airing reruns, so I listen to the shows in the [archive][bd-archive] instead. I didn't
want to have a browser tab open for it and I wanted a bit better UI. I decided to build a [VLC][vlc]
addon for that.

## VLC addons

VLC has a [lua][lua] [API][vlc-lua] for addons. Basically you need to drop a lua (or compiled luac)
file to a specific directory and VLC will load the addon next time it starts. The addons allow you
to extend VLC functionality in multiple (limited) ways. For my purpose it seemed that a "Service
Discovery" addon was needed.

What I wanted the addon to do is to allow me to choose any show from the Bassdrive Archive or the
live stream when I open VLC. Initially I though that I will scrape the archive HTML and build the
archive, but it was very slow, so I quickly decided to have another layer between the archive and
the addon: an API.

## Bassdrive API

Since I was mainly programming in [Dart][dart] during that time I decided to build the [scraper/API
builder][bd-api] in that. Basically what it does is:

- Using GitHub Actions, scheduled to run every hour
- Scrape the Bassdrive Archive and build a JSON tree from the shows
- Publish the JSON tree as a file in GitHub Pages

Since the archive does not update that often, having it running once per hour is more than enough.
The actual published API is available [here][bd-api-json].

## VLC Bassdrive addon

The addon itself is pretty simple: it fetches the JSON file from the API and builds a menu from the
tree. It still takes some time though so I hardcoded the live URL in case I want to start listening
to it straight away.

```lua
local json = nil
local dayOrder = {'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'}

function descriptor()
    	return { title = "Bassdrive Radio", capabilities = {} }
end

function indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

function daysort(a, b)
	return indexOf(dayOrder, a) < indexOf(dayOrder, b)
end

function pairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
end

function main()
	lazy_load()
	local live = "https://bassdrive.radioca.st/stream"; --parsed['live']; Live URL doesn't change so hardcode it to make it load faster

	vlc.sd.add_item({path=live, title='Live'})
	
	local parsed, _, err = parse_json('http://bd.maido.io/api.json')

	if err ~= nil then
        	vlc.msg.err("Error to parse JSON response: " .. err)
        	return
        end

	for dayName, day in pairsByKeys(parsed['archive'], daysort) do
		local dayNode = vlc.sd.add_node( {title=dayName} )
		for _, show in ipairs(day['shows']) do
			local showNode = dayNode:add_subnode({title=show['name']})
			for _, episode in ipairs(show['episodes']) do
				showNode:add_subitem({path=episode['encodedUrl'], title=episode['name']})
			end
		end
	end
end


function lazy_load()
	if json ~= nil then return nil end
	json = require("dkjson")
end

function parse_json(url)
    local stream = vlc.stream(url)
    local string = ""
    local line   = ""

    if not stream then
        return nil, nil, "Failed creating VLC stream"
    end


    while true do
        line = stream:readline()
        if not line then
            break
        end

        string = string .. line
    end

    if string == "" then
        return nil, nil, "Got empty response from server."
    end

    return json.decode(string)
end

function log(msg)
    vlc.msg.dbg( "[BASSDRIVE] " .. msg )
end
```

And here's how it looks like:

![Addon](/assets/images/bassdrive/vlc.png)

## Install

To install, copy the script to the following location:

- Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\
- Windows (current user): %APPDATA%\VLC\lua\
- Linux (all users): /usr/lib/vlc/lua/
- Linux (current user): ~/.local/share/vlc/lua/
- Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/
- Mac OS X (current user): /Users/%your_name%/Library/Application Support/org.videolan.vlc/lua/

[bd]: https://bassdrive.com

[bd-api]: https://github.com/v3rm0n/bassdrive-api

[bd-api-json]: https://bd.maido.io/api.json

[bd-archive]: http://archives.bassdrivearchive.com

[vlc]: https://www.videolan.org/vlc/

[vlc-lua]: https://vlc.verg.ca

[lua]: https://www.lua.org

[dart]: https://dart.dev