-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
local table_join = awful.util.table.join or gears.table.join -- 4.{0,1} compatibility
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
local vicious = require("vicious")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Load Debian menu entries
local debian = require("debian.menu")

-- local stuff
-- local host = awful.util.pread("hostname"):match('%S*')
-- local host = 'main' --awful.util.pread("hostname"):match('%S*')
local host = "{{trim (command_output "hostname")}}"

-- TODO dotter.root?
local root_install = "{{trim (command_output "pwd")}}" .. "/awesome"
-- hardcode HOME at template generation, to avoid usage of os.getenv("HOME")
local config_dir = "{{trim (command_output "realpath ~")}}" .. "/.config/awesome/"

-- add this "local" folder in lookup paths
-- package.path = package.path .. ";" .. root_install .. "/data/?.lua"

-- [[[ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- ]]]
-- [[[ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(config_dir .. "theme.lua")

-- This is used later as the default terminal and editor to run.
-- terminal = "konsole"
terminal = "alacritty"
editor = "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- ]]]
-- [[[ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- ]]]
-- [[[ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    -- { "debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal },
                                    { "&amarok", "amarok" },
                                    { "clementine", "clementine" },
                                    { "&chromium", "chromium" },
                                    { "&dolphin", "dolphin" },
                                    { "&firefox", "/home/richard/firefox/firefox" },
                                    { "soundkonverter", "soundkonverter" },
                                    { "kaffeine", "kaffeine" },
                                    { "konqueror", "konqueror" },
                                    { "&kontact", "kontact" },
                                    { "&okular", "okular" },
                                    { "&batterry", "plasma-windowed battery" },
                                    { "&wifi", "plasma-windowed org.kde.networkmanagement" },
                                    { "&vlc", "vlc /home/richard/.vlc/channels.conf" },
                                    -- The next line add our menu (myappmenu)
                                    { "app", myappmenu, beautiful.awesome_icon }
                    },
                    theme = { width = 200 }
                })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- ]]]

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- [[[ Wibar

-- [[[ network
local netwidget = wibox.widget.textbox()
vicious.register(netwidget, vicious.widgets.net, function (widget, args)
    return string.format('<span color="#CC9393">D%5.2f</span> <span color="#7F9F7F">U%5.2f</span>',
                         args['{' .. '{{awesome_network_interface}} down_mb}'],
                         args['{' .. '{{awesome_network_interface}} up_mb}']) 
    end, 3)
local neticon = wibox.widget.imagebox()
neticon:set_image(beautiful.widget_net)
-- ]]]
-- [[[ memory
local memwidget = wibox.widget.textbox()
vicious.register(memwidget, vicious.widgets.mem, function (widget, args)
    return string.format("%2.f%%", args[1])
    end, 3)
local memicon = wibox.widget.imagebox()
memicon:set_image(beautiful.widget_mem)
-- ]]]
-- [[[ cpu
local cpuwidget = wibox.widget.textbox()
vicious.register(cpuwidget, vicious.widgets.cpu, function (widget, args)
    return string.format("%3.f%%", args[1])
    end, 3)
local cpuicon = wibox.widget.imagebox()
cpuicon:set_image((beautiful.widget_cpu))
-- ]]]
-- [[[ load
local loadwidget = wibox.widget.textbox()
vicious.register(loadwidget, vicious.widgets.uptime, function (widget, args)
    return string.format("%4.1f/%4.1f/%4.1f", args[4], args[5], args[6])
    end, 3)
local loadicon = wibox.widget.imagebox()
loadicon:set_image(beautiful.widget_load)
-- ]]]
-- [[[ volume

local volume_widget = require('awesome-wm-widgets.volume-widget.volume')

-- ]]]
-- [[[ todo

local todo_widget = require("awesome-wm-widgets.todo-widget.todo")

-- ]]]
-- [[[ battery

local battery_widget = require('awesome-wm-widgets.batteryarc-widget.batteryarc')

--  batterywidget = wibox.widget.textbox()
--  batterytimer = timer({ timeout = 10 })
--  batterytimer:connect_signal("timeout", function()
--      fh = assert(io.popen('ibam --percentbattery | head -n 1 | tr -s "  " " " | cut -d":" -f2 | sed "s/^ //g" | cut -f1 -d" "', "r"))
--      local percent = fh:read("*l")
--      fh:close()
--      if string.match(percent, "100") then
--          batterywidget.set_text()
--      else
--          fh = assert(io.popen('ibam | tail -n 1  | tr -s "  " " " | cut -d":" -f2- | sed "s/^ //g" | cut -f1 -d" "', "r"))
--          batterywidget.set_text(fh:read("*l"))
--          fh:close()
--      end
--  end)
--  batterytimer:start()

-- local battery_widget = wibox.widget.textbox()
-- battery_widget:set_text('')
-- local battery_icon = wibox.widget.imagebox()
-- battery_icon:set_image(beautiful.widget_battery_charge)

-- local battery_timer = timer({timeout = 60})
-- battery_timer:connect_signal("timeout", function() batteryCheck() end)
-- battery_timer:start()
-- 
-- function batteryInfo(adapter)
--    local fcur = io.open("/sys/class/power_supply/"..adapter.."/energy_now")
--    local fcap = io.open("/sys/class/power_supply/"..adapter.."/energy_full")
--    if fcur and fcap then
--        local cur = fcur:read()
--        local cap = fcap:read()
--        fcur:close()
--        fcap:close()
--        local battery = math.floor(cur * 100 / cap)
--        return battery
--    end
-- end
-- 
-- function batteryCheck()
--     local fsta = io.open("/sys/class/power_supply/AC/online")
--     local bat0 = batteryInfo("BAT0")
--     local bat1 = batteryInfo("BAT1")
--     if fsta and bat0 and bat1 then
--         local sta = fsta:read()
--         fsta:close()
--         local green = '#C0FFC0'
--         local orange = '#FFA848'
--         local color = green
--         if sta:match("1") then
--             battery_icon:set_image(beautiful.widget_battery_charge)
--         else
--             if tonumber(bat0) < 10 or tonumber(bat1) < 10 then
--                 color = orange
--                 battery_icon:set_image(beautiful.widget_battery_low)
--                 naughty.notify({ preset = naughty.config.presets.critical,
--                     title = "Battery Low",
--                     text = " ".. bat0 .. "% & ".. bat1 .. "% left",
--                     timeout = 50,
--                     font = "Liberation 11", })
--             else
--                 battery_icon:set_image(beautiful.widget_battery)
--             end
--         end
--         -- battery_widget:set_text(bat0 .. "%".. bat1 .. "%")
--         local text = string.format('<span color=\"%s\">%2.2d%%/%2.2d%%</span>', 
--                                         color, bat0, bat1)
--         battery_widget:set_markup(text)
--     end
-- end

-- ]]]
-- [[[ brightness

local brightness_widget = require('awesome-wm-widgets.brightness-widget.brightness')

-- ]]]
-- [[[ io
local iowidget = wibox.widget.textbox()
vicious.register(iowidget, vicious.widgets.dio, function (widget, args)
    return string.format('<span color="#498FE4">R%4.1f</span> <span color="#E48671">W%4.1f</span>', 
                         args['{sda read_mb}'], args['{sda write_mb}'])
    end, 3)
local ioicon = wibox.widget.imagebox()
ioicon:set_image(beautiful.widget_io)
-- ]]]
-- [[[ date
local datewidget = wibox.widget.textbox()
vicious.register(datewidget, vicious.widgets.date, '%R %a %d/%m')
local dateicon = wibox.widget.imagebox()
dateicon:set_image(beautiful.widget_date)
-- ]]]

-- Create a wibox for each screen and add it
local taglist_buttons = table_join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = table_join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" },
              s,
              {awful.layout.suit.magnifier,
               awful.layout.suit.tile,
               awful.layout.suit.tile,
               awful.layout.suit.tile,
               awful.layout.suit.tile,
               awful.layout.suit.tile,
               awful.layout.suit.tile,
               awful.layout.suit.tile,
               awful.layout.suit.magnifier})
              -- { awful.layout.layouts[2]})

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(table_join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
            mykeyboardlayout,
            cpuicon,
            cpuwidget,
            memicon,
            memwidget,
            loadicon,
            loadwidget,
            ioicon,
            iowidget,
            neticon,
            netwidget,
            dateicon,
            datewidget,
            volume_widget{
                widget_type = 'arc'
            },
{{#if dotter.packages.laptop}}
            -- battery_icon,
            battery_widget{
                show_current_level = true,
                arc_thickness = 1,
            },
            brightness_widget{
                type = 'icon_and_text',
                program = 'light',
                step = 5,
                timeout = 100000,
                base = 25,
            },
{{/if}}
            wibox.widget.systray(),
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            todo_widget(),
            s.mylayoutbox,
        },
    }
end)
-- ]]]
-- [[[ Mouse bindings
root.buttons(table_join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- ]]]
-- [[[ Key bindings
globalkeys = table_join(
    -- awful.key({ modkey,           }, "s",      hotkeys_popup.show_help, {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev, {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "i",      awful.tag.viewprev, {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext, {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "o",      awful.tag.viewnext, {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore, {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),

    -- awful.key({ modkey,           }, "u", awful.client.urgent.jumpto, {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Layout modification: shift i/o move windows to left/right
    -- XXX awesome 4 TODO
    -- awful.key({ modkey, "Shift"   }, "i", function ()
    --    local curidx = awful.tag.getidx()
    --    if curidx == 1 then
    --        awful.client.movetotag(tags[client.focus.screen][9])
    --    else
    --        awful.client.movetotag(tags[client.focus.screen][curidx - 1])
    --    end
    --    awful.tag.viewprev()
    -- end),
    -- awful.key({ modkey, "Shift"   }, "o", function ()
    --    local curidx = awful.tag.getidx()
    --    if curidx == 9 then
    --        awful.client.movetotag(tags[client.focus.screen][1])
    --    else
    --        awful.client.movetotag(tags[client.focus.screen][curidx + 1])
    --    end
    --    awful.tag.viewnext()
    -- end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end, {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart, {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit, {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end, {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end, {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end, {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end, {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end, {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end, {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end, {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end, {description = "select previous", group = "layout"}),

    -- awful.key({ modkey, "Control" }, "n",
    --           function ()
    --               local c = awful.client.restore()
    --               -- Focus restored client
    --               if c then
    --                   client.focus = c
    --                   c:raise()
    --               end
    --           end,
    --           {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),

    -- lock
    awful.key({ modkey            }, "BackSpace", function ()
                  awful.util.spawn("kshutdown --lock") end),

    -- shudown
    awful.key({ modkey , "Shift"  }, "BackSpace", function ()
                  awful.util.spawn("kshutdown --shutdown now") end),

    -- logout
    awful.key({ modkey , "Shift"  }, "q", function ()
                  awful.util.spawn("kshutdown --logout now") end),

{{#if dotter.packages.laptop}}
    -- light control
    awful.key({ }, "XF86MonBrightnessUp", function () brightness_widget:inc() end,
              {description = "increase brightness", group = "custom"}),
    awful.key({ }, "XF86MonBrightnessDown", function () brightness_widget:dec() end,
          {description = "decrease brightness", group = "custom"}),
{{/if}}

    -- audio control
    awful.key({ }, "XF86AudioRaiseVolume", function() volume_widget:inc() end),
    awful.key({ }, "XF86AudioLowerVolume", function() volume_widget:dec() end),
    awful.key({ }, "XF86AudioMute", function() volume_widget:toggle() end),

    -- RB : F1/F2 XXX FIXME
    -- awful.key({modkey,            }, "u",    function (c) c:move_to_screen(1) end), --rb
    -- awful.key({modkey,            }, "p",    function (c) c:move_to_screen(2) end)  --rb
    awful.key({ modkey,           }, "a",
        function ()
            for _, cl in ipairs(mouse.screen.selected_tag:clients()) do
                local c = cl
                if c then
                    c.maximized = false
                    c.minimized = false
                end
                c:emit_signal("request::activate", "key.unminimize", {raise = true})
            end
        end,
        {description = "restore all clients, unmaximize and unminimized in current tag", group = "client"})
)

clientkeys = table_join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey,           }, "c",      function (c) c:kill()                         end, {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     , {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end, {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end, {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end, {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.maximized = false
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = table_join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = table_join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- ]]]
-- [[[ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },
    { rule = { class = "Kaffeine" }, properties = { screen = 1, tag = "2", switchtotag = true, focus = true } },
    { rule = { class = "Vlc" }, properties      = { screen = 1, tag = "4", switchtotag = true, focus = true } },
    { rule = { class = "Firefox" }, properties  = { screen = 1, tag = "5", switchtotag = true, focus = true } },
    { rule = { class = "Chromium" }, properties = { screen = 1, tag = "7", switchtotag = true, focus = true } },
    { rule = { class = "Kopete" }, properties   = { screen = 1, tag = "7", switchtotag = true, focus = true } },
    { rule = { class = "Amarok" }, properties   = { screen = 1, tag = "8", switchtotag = true, focus = true } },
    { rule = { class = "Kontact" }, properties  = { screen = 1, tag = "9", switchtotag = true, focus = true } },
    { rule = { class = "Kwalletd" }, properties = { screen = 1, tag = "9", switchtotag = true, focus = true, ontop = true } },
    { rule = { instance = "plugin-container" }, properties = { floating = true } },
    { rule = { class = "Exe" }, properties = { floating = true } },
    { rule = { class = "kshutdown" }, properties = { floating = true } },

    -- Floating clients.
    { rule_any = {
        -- use xprop to get a window class
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- ]]]
-- [[[ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = table_join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

-- client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
-- client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
--
--
-- ]]]
-- [[[ Startup
--
function run_if_not_running(program, arguments)
   awful.spawn.easy_async_with_shell(
      "pgrep -f -u $(whoami) " .. program,
      function(stdout, stderr, reason, exit_code)
         naughty.notify { text = stdout .. exit_code }
         -- awful.spawn.with_shell(" echo 'program:" .. program .. " stdout:" .. stdout .. " stderr:" .. stderr .. " reason:" .. reason .. " exit-code:" .. exit_code .. "' >> /tmp/a")
         if exit_code ~= 0 then
            awful.spawn(program .. " " .. arguments)
         end
   end)
end

-- run_once("kshutdown","--init")
-- run_once("nm-applet")
-- run_once("parcellite")
-- awful.spawn("kshutdown --init")
run_if_not_running("nm-applet", "")
run_if_not_running("parcellite", "")

{{#if dotter.packages.mac}}
-- macbook
-- awful.spawn("setxkbmap -layout us -variant mac -option compose:rwin,ctrl:nocaps,shift:both_capslock_cancel,lv3:menu_switch,apple:alupckeys")
{{else}}
-- usual keyboard setup
-- awful.spawn("setxkbmap -layout us -option compose:lalt,ctrl:nocaps,shift:both_capslock_cancel,lv3:menu_switch")
{{/if}}
-- awful.spawn.with_shell("sleep 1 && xkbcomp -I${HOME}/.config/xkb -R${HOME}/.config/xkb ~/.config/xkb/keymap/keymap.xkb $DISPLAY")
run_if_not_running("inputplug", "-d -0 -c ${HOME}/.config/xkb/inputplug.sh")

-- awful.spawn("kmix")
{{#if dotter.packages.bluetooth}}
-- bluetooth (TODO also sake once dongle installed in sake)
run_if_not_running("blueman-applet", "")
run_if_not_running("pasystray", "")
{{/if}}

{{#if dotter.packages.redshift}}
run_if_not_running("redshift-gtk", "")
{{/if}}

--if host == 'sake' or host == 'suze' then
--    run_once("nm-applet")
--end
-- ]]]

-- dotter/handlebars+fold incompatibility: temporary [ instead of {
-- vim: foldmarker=[[[,]]]
-- vim: filetype=lua
