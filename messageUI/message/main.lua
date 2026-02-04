require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"
import "java.net.InetAddress"
import "android.view.WindowManager"
import "SendServerClass"
import "android.content.Context"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.Rect"
import "android.content.pm.PackageManager"
import "android.media.MediaRecorder"
import "android.media.MediaPlayer"
import "android.media.AudioManager"
import "java.io.File"

text = {}
inputtext = {}

local appDir = activity.getExternalFilesDir(nil).getAbsolutePath()
path = appDir .. "/messagetext.lua"
Sportfile = appDir .. "/IPfile.lua"
urlvoicefile =appDir .. "/voicefile"




whitehomeFunc = nil

File(urlvoicefile).mkdirs()

local f = io.open(path, "r")
if not f then
  f = io.open(path, "w")
  f:close()
  local ffff = io.open(Sportfile, "w")
  ffff:write('return {\n server= { \n host = "192.168.10.7",\n port = 8080\n }\n}')
  ffff:close()
end
local config = dofile(Sportfile).server.host

function onCreate()


  if Build.VERSION.SDK_INT >= 21 then
    activity.getWindow().setStatusBarColor(0x00000000)
    activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
    activity.getWindow().getDecorView().setSystemUiVisibility(
    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
    )
  end
  activity.setContentView(loadlayout(layout))
  Handler().postDelayed(function()
    Edit.requestFocus()
  end, 200)


  local currentDir = activity.getLuaDir()
  local currenfilePath = currentDir .. "/ButtonEvent.lua"
  dofile(currenfilePath)
  whitehome()
  whitehomeFunc = whitehome
  import "messageUI"


  initApp()
  connectin(config)
end

function initApp()

  local filepath = dofile(path)

  task(5, function()
    if filepath then
      for i, msg in ipairs(filepath) do
        if msg.Mtype == "voice_message|"
          if msg.name == "我"
            voicemessage(msg.s,msg.text, true)
           else
            voicemessage(msg.s,msg.text, false)
          end

          goto continue
         elseif msg.Mtype == "imgae|"
          if msg.name == "我"
            imgpageUI(msg.text, false)
           else
            imgpageUI(msg.text, true)
          end
          goto continue
         elseif msg.name == "我" then

          message(msg.text, true)

         else
          message(msg.text, false)

        end
::continue::
      end
    end
  end)



  setupButton()

  startTask()
end



