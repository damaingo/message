require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"
import "SendServerClass"
import "android.view.WindowManager"
import "android.content.Context"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.Rect"
import "android.content.pm.PackageManager"
import "android.media.MediaRecorder"
import "android.media.MediaPlayer"
import "android.media.AudioManager"
import "android.content.Intent"
import "android.net.Uri"
local touchTime = 0

local dp = activity.getResources().getDisplayMetrics().density
local h = 60 * dp
local kh = 0
local screenHeight = activity.getResources().getDisplayMetrics().heightPixels








textlist.setOnTouchListener{
  onTouch = function(view, event)
    local action = event.getAction()

    if action == MotionEvent.ACTION_DOWN then
      whitehomeFunc()



      activity.getSystemService("input_method").hideSoftInputFromWindow(Edit.getWindowToken(), 0)

      touchTime = System.currentTimeMillis()
      return true
     elseif action == MotionEvent.ACTION_MOVE then
      if touchTime > 0 and System.currentTimeMillis() - touchTime > 800 then
        touchTime = 0
        local portEditText = EditText(activity)
        portEditText.setHint("输入端口号")
        portEditText.setInputType(1)

        local dialog = AlertDialog.Builder(activity)
        .setTitle("连接端口")
        .setView(LinearLayout(activity)
        .setOrientation(1)
        .setPadding(50,30,50,30)
        .addView(portEditText))
        .setPositiveButton("连接", {
          onClick = function()

            local port = portEditText.getText().toString()
            if port ~= "" then
              print("连接端口：" .. port)
              local ffff = io.open(Sportfile, "w")
              ffff:write('return {\n server= { \n host = "'..port .. '",\n port = 8080\n }\n}')
              ffff:close()
              connectin(port)
            end
          end
        })
        .setNegativeButton("取消", nil)
        .show()
        return true
      end
    end
    return false
  end
}
if activity.checkSelfPermission("android.permission.RECORD_AUDIO") ~= PackageManager.PERMISSION_GRANTED then
  activity.requestPermissions({"android.permission.RECORD_AUDIO"}, 1)
end

Edit.onFocusChange = function(view, hasFocus)
  if hasFocus then
    view.setCursorVisible(true)
   else
    view.setCursorVisible(false)
  end
end

function message(inputmessage, isMyMessage)

  local processedText = inputmessage
  if inputmessage:find("【系统】") then
    processedText = processedText
    :gsub("%[%d%d:%d%d:%d%d%]", "")
    :gsub("服务器:", "")
    :gsub("【系统】", "")
    :gsub("^%s+", ""):gsub("%s+$", "")
  end

  activity.runOnUiThread(function()
    if inputmessage:find("【系统】") then

      local container = LinearLayout(activity)
      container.setOrientation(LinearLayout.HORIZONTAL)
      container.setGravity(Gravity.CENTER)

      local params = LinearLayout.LayoutParams(
      LinearLayout.LayoutParams.WRAP_CONTENT,
      LinearLayout.LayoutParams.WRAP_CONTENT
      )
      params.setMargins(0, 15, 0, 15)
      container.setLayoutParams(params)

      local textView = createTextView(processedText, 12, 0xFF888888)
      textView.setPadding(25, 8, 25, 8)


      import "android.graphics.drawable.GradientDrawable"
      local shape = GradientDrawable()
      shape.setColor(0xFFF0F0F0)
      shape.setCornerRadius(20)
      shape.setStroke(1, 0xFFE0E0E0)
      textView.setBackgroundDrawable(shape)

      container.addView(textView)
      textlist.addView(container)

     else

      local cardView = CardView(activity)


      cardView.setCardElevation(0)
      cardView.setRadius(20)


      local textView = createTextView(inputmessage, 18, 0xFF333333)
      textView.setPadding(40, 30, 40, 30)
      cardView.addView(textView)


      local params = LinearLayout.LayoutParams(
      LinearLayout.LayoutParams.WRAP_CONTENT,
      LinearLayout.LayoutParams.WRAP_CONTENT
      )

      cardView.setCardBackgroundColor(0x000000FF)
      local border = GradientDrawable()
      border.setShape(GradientDrawable.RECTANGLE)
      border.setCornerRadius(20)
      border.setStroke(6, 0xFF000000)
      border.setColor(0x00000000)
      if isMyMessage then
        params.gravity = Gravity.RIGHT
        params.setMargins(0, 50, 40, 0)



       else
        params.gravity = Gravity.LEFT
        params.setMargins(40, 40, 0, 0)

        cardView.setCardBackgroundColor(0x000000FF)
      end
      cardView.setBackground(border)
      cardView.setLayoutParams(params)
      textlist.addView(cardView)
    end
  end)
end

function createTextView(text, textSize, textColor)
  local textView = TextView(activity)
  textView.setText(text)
  textView.setTextSize(textSize)
  textView.setTextColor(textColor)
  textView.setLayoutParams(LinearLayout.LayoutParams(
  LinearLayout.LayoutParams.WRAP_CONTENT,
  LinearLayout.LayoutParams.WRAP_CONTENT
  ))
  textView.maxWidth = 1000
  return textView
end





function setupButton()
  function getinputText()
    return Edit.getText().toString()
  end

  textin.onClick = function()
    local inputText = getinputText()


    if #inputText > 0 then
      message(inputText, true)
      clearinput()
      table.insert(inputtext, inputText)
     else
      Toast.makeText(activity, "请输入内容", Toast.LENGTH_SHORT).show()
    end

  end
  function clearinput()
    if Edit then
      Edit.setText("")
    end
  end
end





---------------- 语音消息ui -------
---------------- 语音消息ui -------
---------------- 语音消息ui -------
---------------- 语音消息ui -------

local player = nil
local voiceCount = 0
local isRecording = false
local startRecordTime = 0


function playVoice(Pathfile)

  if player then
    pcall(function()
      if player.isPlaying() then
        player:stop()
      end
    end)
    pcall(function() player:release() end)
    player = nil
  end


  player = MediaPlayer()


  local success, err = pcall(function()
    player.setDataSource(Pathfile)
    player.setAudioStreamType(AudioManager.STREAM_MUSIC)
    player.prepare()
    player.start()
    return true
  end)

  if not success then
    print("播放失败: " .. tostring(err))
    player = nil
    return
  end

  print("正在播放: " .. Pathfile)
end

function voicemessage(duration, voicefilePath,sp)
  local bubble = TextView(activity)
  local width = 210 + (duration * 10)
  if width > 900 then width = 900 end


  local params = LinearLayout.LayoutParams(
  width,
  125
  )
  if sp then
    params.gravity = Gravity.RIGHT
    params.setMargins(0, 50, 40, 0)
   else
    params.gravity = Gravity.LEFT
    params.setMargins(40, 50, 0, 0)

  end

  bubble.setLayoutParams(params)


  local gd = GradientDrawable()
  gd.setShape(0)
  gd.setCornerRadius(20)
  gd.setStroke(6, 0xFF000000)
  gd.setColor(0x00000000)
  bubble.setBackground(gd)


  bubble.setText(duration .. "''")
  bubble.setTextSize(16)
  bubble.setTextColor(0xFF000000)
  bubble.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL)
  bubble.setPadding(20, 0, 20, 0)

  bubble.onClick = function()
    playVoice(voicefilePath)
  end

  textlist.addView(bubble)
end

function simpleRecord(voicefilePath)
  if isRecording == true then

    recorder = MediaRecorder()
    local success, err = pcall(function()
      recorder.setAudioSource(MediaRecorder.AudioSource.MIC)
      recorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
      recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
      recorder.setOutputFile(voicefilePath)
      recorder.prepare()
      recorder.start()
    end)

    if not success then
      print("录音启动失败: " .. tostring(err))
      if recorder then
        recorder.release()
      end
      recorder = nil
      return false
    end


    return true

   else

    if recorder then
      print("停止录音...")
      local success, err = pcall(function()
        recorder.stop()
        recorder.release()
      end)

      if not success then
        print("停止录音失败: " .. tostring(err))

        pcall(function() recorder.release() end)
      end

      recorder = nil
      return success
     else
      print("没有正在进行的录音")
      return false
    end
  end
end


local recordState = {
  popup = nil,
  cancelView = nil,
  timeView = nil,
  startY = 0,
  startTime = 0,
  timerRunning = false,
  isCanceling = false
}

voiceStatusbutton.onTouch = function(v, e)
  local x, y = e.getX(), e.getY()
  local action = e.getAction()

  if action == MotionEvent.ACTION_DOWN then

    if recordState.popup then
      recordState.popup.dismiss()
    end

    import "android.graphics.drawable.GradientDrawable"
    import "android.widget.PopupWindow"
    import "android.view.ViewGroup"


    local fullScreenLayout = FrameLayout(activity)
    fullScreenLayout.setLayoutParams(ViewGroup.LayoutParams(-1, -1))
    fullScreenLayout.setBackgroundColor(0x99000000)


    local arcShape = GradientDrawable()
    arcShape.setColor(0xff027bd3)
    arcShape.setCornerRadii({1200,200, 1200,200, 0,0, 0,0})

    local arcView = TextView(activity)
    arcView.setText("松开 发送")
    arcView.setTextSize(20)
    arcView.setTextColor(0xFFF6F6F6)
    arcView.setGravity(Gravity.CENTER)
    arcView.setBackgroundDrawable(arcShape)


    local cardShape = GradientDrawable()
    cardShape.setColor(0xFF9B9F9F)
    cardShape.setCornerRadius(100)

    recordState.cancelView = TextView(activity)
    recordState.cancelView.setText("✕")
    recordState.cancelView.setTextSize(30)
    recordState.cancelView.setTextColor(0xFFF6F6F6)
    recordState.cancelView.setGravity(Gravity.CENTER)
    recordState.cancelView.setBackgroundDrawable(cardShape)


    local timeShape = GradientDrawable()
    timeShape.setColor(0xff97ec69)
    timeShape.setCornerRadius(20)

    recordState.timeView = TextView(activity)
    recordState.timeView.setText("00 : 00")
    recordState.timeView.setTextSize(19)
    recordState.timeView.setTextColor(0xFFF6F6F6)
    recordState.timeView.setGravity(Gravity.CENTER)
    recordState.timeView.setBackgroundDrawable(timeShape)


    local arcParams = FrameLayout.LayoutParams(-1, 450)
    arcParams.gravity = Gravity.BOTTOM

    local cancelParams = FrameLayout.LayoutParams(200, 200)
    cancelParams.gravity = Gravity.CENTER_HORIZONTAL | Gravity.BOTTOM
    cancelParams.bottomMargin = 500

    local timeParams = FrameLayout.LayoutParams(550, 300)
    timeParams.gravity = Gravity.CENTER

    fullScreenLayout.addView(arcView, arcParams)
    fullScreenLayout.addView(recordState.cancelView, cancelParams)
    fullScreenLayout.addView(recordState.timeView, timeParams)


    recordState.popup = PopupWindow(
    fullScreenLayout,
    ViewGroup.LayoutParams.MATCH_PARENT,
    ViewGroup.LayoutParams.MATCH_PARENT,
    true
    )

    recordState.popup.setBackgroundDrawable(
    luajava.newInstance("android.graphics.drawable.ColorDrawable", 0x00000000)
    )

    recordState.popup.showAtLocation(v, Gravity.NO_GRAVITY, 0, 0)


    recordState.startY = y
    recordState.startTime = os.time()
    recordState.isCanceling = false
    recordState.timerRunning = true


    startRecordTimer()

    print("开始录音")
    if activity.checkSelfPermission("android.permission.RECORD_AUDIO") == PackageManager.PERMISSION_GRANTED then
      if not isRecording then
        isRecording = true
        startRecordTime = os.time()
        voicefilePath = urlvoicefile .."/voice_" ..startRecordTime .. ".3gp"

        simpleRecord(voicefilePath)
      end
     else
      print("没有录音权限")

    end
    return true

   elseif action == MotionEvent.ACTION_MOVE then
    if recordState.popup then
      local deltaY = y - recordState.startY


      if deltaY < -400 then
        if not recordState.isCanceling then
          recordState.isCanceling = true

          local redShape = GradientDrawable()
          redShape.setColor(0xFFF44336)
          redShape.setCornerRadius(100)
          recordState.cancelView.setBackgroundDrawable(redShape)


          local timeRedShape = GradientDrawable()
          timeRedShape.setColor(0xFFF44336)
          timeRedShape.setCornerRadius(20)
          recordState.timeView.setBackgroundDrawable(timeRedShape)

          print("进入取消区域")
        end
       else
        if recordState.isCanceling then
          recordState.isCanceling = false

          local grayShape = GradientDrawable()
          grayShape.setColor(0xFF9B9F9F)
          grayShape.setCornerRadius(100)
          recordState.cancelView.setBackgroundDrawable(grayShape)

          local timeGrayShape = GradientDrawable()
          timeGrayShape.setColor(0xff97ec69)
          timeGrayShape.setCornerRadius(20)
          recordState.timeView.setBackgroundDrawable(timeGrayShape)

          print("离开取消区域")
        end
      end
    end
    return true

   elseif action == MotionEvent.ACTION_UP then
    if recordState.popup then

      recordState.timerRunning = false


      local recordDuration = os.time() - recordState.startTime

      if recordState.isCanceling then
        print("取消录音")
        if isRecording then
          isRecording = false
          simpleRecord()

        end
       else
        print("发送录音，时长: " .. recordDuration .. "秒")
        if isRecording then
          isRecording = false



          local duration = math.floor((os.time() - startRecordTime))
          print("中间几秒"..startRecordTime )
          print(os.clock())
          print("结束几秒 ".. duration)
          if duration < 1 then duration = 1 end



          table.insert(inputtext, {"voice_message|", voicefilePath, duration})
          print(inputtext[1][2])

          simpleRecord()
          voicemessage(duration,voicefilePath,true)


        end
      end

      recordState.popup.dismiss()
      recordState.popup = nil
      recordState.cancelView = nil
      recordState.timeView = nil
      recordState.isCanceling = false
    end
    return true
  end

  return false
end




function startRecordTimer()

  if recordState.timerHandler then
    recordState.timerHandler.removeCallbacksAndMessages(nil)
  end


  recordState.timerHandler = Handler()
  recordState.startTime = os.time()

  local function update()
    if not recordState.timerRunning then return end

    local elapsed = os.time() - recordState.startTime
    local seconds = elapsed % 60
    local minutes = math.floor(elapsed / 60)

    if recordState.timeView then
      recordState.timeView.setText(string.format("%02d : %02d", minutes, seconds))
    end


    if recordState.timerRunning then
      recordState.timerHandler.postDelayed(update, 500)
    end
  end


  recordState.timerHandler.post(update)
end
---------------- 图片消息ui -------
---------------- 图片消息ui -------
---------------- 图片消息ui -------
---------------- 图片消息ui -------
function imgpageUI(fileSrc,i)
  local cardView = CardView(activity)


  cardView.setCardElevation(0)
  cardView.setRadius(30)


  local img = ImageView(activity)
  local imgParams = LinearLayout.LayoutParams(
  LinearLayout.LayoutParams.WRAP_CONTENT,
  LinearLayout.LayoutParams.WRAP_CONTENT
  )



  img.setLayoutParams(imgParams)


  img.setAdjustViewBounds(true)
  img.setMaxWidth(600)
  img.setMaxHeight(800)
  img.setScaleType(ImageView.ScaleType.FIT_CENTER)
  img.setImageURI(Uri.parse("file://" .. fileSrc))


  local cardParams = LinearLayout.LayoutParams(
  LinearLayout.LayoutParams.WRAP_CONTENT,
  LinearLayout.LayoutParams.WRAP_CONTENT
  )
  if i then
    cardParams.gravity = Gravity.LEFT
    cardParams.setMargins(40, 100, 0, 0)
   else
    cardParams.gravity = Gravity.RIGHT
    cardParams.setMargins(0, 100,40, 0)
  end


  cardView.setLayoutParams(cardParams)


  cardView.addView(img)


  img.onClick = function(v)

    local container = FrameLayout(activity)
    container.setLayoutParams(ViewGroup.LayoutParams(-1, -1))
    container.setBackgroundColor(0xFF000000)


    local fullImage = ImageView(activity)
    local params = FrameLayout.LayoutParams(
    FrameLayout.LayoutParams.MATCH_PARENT,
    FrameLayout.LayoutParams.MATCH_PARENT
    )
    params.gravity = Gravity.CENTER
    fullImage.setLayoutParams(params)
    fullImage.setScaleType(ImageView.ScaleType.FIT_CENTER)


    fullImage.setImageURI(Uri.parse("file://" .. fileSrc))


    container.addView(fullImage)


    local popup = PopupWindow(container,
    ViewGroup.LayoutParams.MATCH_PARENT,
    ViewGroup.LayoutParams.MATCH_PARENT,
    true)


    popup.showAtLocation(v, Gravity.NO_GRAVITY, 0, 0)


    container.onClick = function()
      fullImage.animate()
      .scaleX(0.3)
      .scaleY(0.3)
      .alpha(0.0)
      .setDuration(250)
      .withEndAction({
        run = function()
          popup.dismiss()
        end
      })
      .start()
    end
  end


  textlist.addView(cardView)
end
image.onClick = function()
  activity.startActivityForResult(Intent(Intent.ACTION_PICK).setType("image/*"),1)

end
function onActivityResult(requestCode,resultCode,intent)
  if intent then
    local cursor =this.getContentResolver ().query(intent.getData(), nil, nil, nil, nil)
    print(cursor)
    cursor.moveToFirst()
    import "android.provider.MediaStore"
    local idx = cursor.getColumnIndex(MediaStore.Images.ImageColumns.DATA)
    print(idx)
    fileSrc = cursor.getString(idx)

    print(fileSrc)
    imgpageUI(fileSrc, false)
    table.insert(inputtext, {"imgae|", fileSrc, "0"})


  end
end



function createCardBorder(color, width, radius)
  local shape = GradientDrawable()
  shape.setShape(GradientDrawable.RECTANGLE)
  shape.setColor(0xFFFFFFFF)
  shape.setCornerRadius(radius or 16)
  shape.setStroke(width or 2, color or 0xFF3DE1AD)
  return shape
end
voiceInputBox.setBackgroundDrawable(createCardBorder(0xFF000000, 5, 26))
Edit.setBackgroundDrawable(createCardBorder(0xFF000000, 5, 15))
textin.setBackgroundDrawable(createCardBorder(0xFF000000, 5, 26))

function startTask()
  local function Task()
    task(100, Task)

    if #text > 0 then
      local messageToDisplay = table.remove(text, 1)

      if messageToDisplay:find("|") then

        local s, i = messageToDisplay:match("^(.*)|(.*)$")

        if i == "0" then
          imgpageUI(s, true)
         else
          voicemessage(i,s,false)
        end


       else

        message(messageToDisplay, false)
      end
    end
  end
  Task()
end
clear.onClick = function()

  local file = io.open(path, "w")
  if file then
    file:close()
    print("文件已清空: " .. path)
    return true
   else
    print("无法打开文件: " .. path)

  end




end


import "android.graphics.drawable.BitmapDrawable"
kion.setBackground(BitmapDrawable(loadbitmap("/storage/emulated/0/Pictures/Gallery/owner/鸭子/duck.png")).setGravity(Gravity.CENTER))
activity.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_PAN);

