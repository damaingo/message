require "import"
import "android.app.*"
import "android.os.*"
import "java.net.InetAddress"
import "android.view.WindowManager"
confi= nil

function showTopToast(m)
  activity.runOnUiThread(function()
    local tv = TextView(activity)
    tv.setText(m); tv.setTextSize(19); tv.setTextColor(0xFF000000)
    tv.setGravity(Gravity.CENTER); tv.setPadding(30, 15, 30, 15)

    local s = GradientDrawable()
    s.setStroke(4, 0xFF000000)
    s.setCornerRadius(20)
    tv.setBackgroundDrawable(s)

    Toast(activity).setDuration(1).setView(tv).setGravity(48,0,50).show()
  end)
end



function connectin(postip)

  confi=postip



  socket = luajava.newInstance("java.net.Socket")


  local ok, result = pcall(function()
    local addressClass = luajava.bindClass("java.net.InetSocketAddress")
    local address = luajava.new(addressClass, postip, 8080)


    socket.connect(address,100000)
    showTopToast("👆已连接到服务器")
  end)


  if ok then
    print("")
   else
    print("连接异常: " .. tostring(result))
    showTopToast("⚠️ 未连接到服务器")

  end

  thread(function(a, sendtext, socket)

    print("开始")
    local ok, result = pcall(function()
      input = socket.getInputStream()
      output = socket.getOutputStream()
    end)
    local appDir = activity.getExternalFilesDir(nil).getAbsolutePath()
    local filepath = appDir .. "/messagetext.lua"
    local urlvoicefile = appDir .. "/voicefile"

    local time = os.date("%Y-%m-%d %H:%M:%S")

    function sizefile(record)
      local file= io.open(filepath, "r+")
      if not file then
        file:write('return {\n' .. record .. '}\n')
        file:close()
        return
      end
      file:seek("end")
      local size = file:seek()
      if size == 0 then
        file:write('return {\n' .. record .. '}\n')
        file:close()
        return
      end
      local found = false
      local pos = size
      local lastPos = -1

      while pos > 0 do
        file:seek("set", pos - 1)
        local char = file:read(1)
        if char == "}" then
          found = true
          lastPos = pos - 1
          break
        end
        pos = pos - 1
      end

      if found then
        file:seek("set", lastPos)
        local afterContent = file:read("*a") or ""
        file:seek("set", lastPos)
        file:write(string.format( record))
        file:write(afterContent)
      end

      file:close()
    end



    if socket then

      print("连接成功")
      socket.setSoTimeout(100)

      print("开始通信")


      function savetext(name, ip ,line)
        local formatted = '  {time="%s",name="%s",ip="%s",text="%s"},\n'
        local record = string.format(formatted, time, name, ip, line)
        sizefile(record)
      end

      function savevoice(name, ip ,line)
        local Mtype = line[1]
        local s = line[3]
        local Iline = line[2]
        local formatted = '  {time="%s",name="%s",ip="%s",Mtype="%s",s="%s",text="%s"},\n'
        local record = string.format(formatted, time, name,ip, Mtype, s, Iline)
        sizefile(record)
      end


      function sendT(v)
        savetext("我", nil,v)
        local str = luajava.newInstance("java.lang.String", v)
        output.write(str.getBytes("UTF-8"))
        output.flush()
      end

      function sendV(v)
        local filePath = tostring(v[2])
        local duration = tostring(v[3])
        print("发送文件: " .. filePath)

        savevoice("我", nil, v)

        local file = luajava.newInstance("java.io.File", filePath)
        if not file.exists() then return false end

        local fileName = file.getName()
        local fileSize = tonumber(tostring(file.length()))

        print("名称: " .. fileName)
        print("大小: " .. fileSize .. " 字节")


        local header = luajava.newInstance("java.lang.String",
        "FILE|" .. fileName .. "|" .. fileSize .. "|" .. duration .. "|")
        output.write(header.getBytes("UTF-8"))
        output.flush()
        print("头部已发送",duration)


        local fis = luajava.newInstance("java.io.FileInputStream", filePath)
        local totalSent = 0

        for i = 1, fileSize do
          local byteInt = fis.read()
          if byteInt == -1 then break end

          output.write(byteInt)
          totalSent = totalSent + 1

          if fileSize < 7000 then
            if i % 10 == 0 then
              output.flush()
            end
           else
            if i % 1000 == 0 then
              output.flush()
            end
          end
        end

        output.flush()
        fis.close()

        local waitStart = os.clock()
        while os.clock() - waitStart < 0.1 do end

        print("发送完成: " .. totalSent .. "/" .. fileSize)
        return totalSent == fileSize
      end

      while true do

        if #sendtext > 0 then
          local messageToDisplay = table.remove(sendtext, 1)

          if messageToDisplay[1] == "voice_message|" or messageToDisplay[1] == "imgae|" then
            sendV(messageToDisplay)
            print("执行if")
           else
            print("发文字")
            sendT(messageToDisplay)
          end
        end


        local ok, byte = pcall(function()
          return input.read()
        end)

        if not ok then

          if tostring(byte):find("SocketTimeoutException") then

           else
            print("读取错误: " .. tostring(byte))
            break
          end
         elseif byte ~= -1 then
          local line = string.char(byte)


          while true do
            ok, byte = pcall(function()
              return input.read()
            end)

            if not ok then

              if tostring(byte):find("SocketTimeoutException") then
                print("读取行超时，已读取部分: " .. line)
               else
                print("读取错误: " .. tostring(byte))
              end
              break
             elseif byte == -1 then
              print("连接关闭")
              break
             elseif byte == 10 then
              break
             else
              line = line .. string.char(byte)
            end
          end

          if line ~= "" and byte ~= -1 then
            print("收到数据:"..line.."结束")


            if line:find("【系统】") then
              table.insert(a, line)


             elseif line:find("^FILE|") then
              print("开始接收文件")


              local cleanLine = line:gsub("[\r\n]+$", "")
              local parts = {}
              for part in cleanLine:gmatch("[^|]+") do
                table.insert(parts, part)
              end

              if #parts >= 4 then
                print(parts)
                local fileName = parts[2]
                local fileSize = tonumber(parts[4])
                local duration = tonumber(parts[3])
                print("文件名:", fileName, "大小:", fileSize, "/",duration .."秒")


                local outpu = luajava.newInstance("java.io.FileOutputStream",
                urlvoicefile .. "/_001"..fileName)
                if fileName:match("%.3gp$") then
                  top={"voice_message|",urlvoicefile .. "/_001"..fileName,duration}
                 else
                  top={"imgae|",urlvoicefile .. "/_001"..fileName,duration}

                end

                local received= 0

                savevoice( "服务器","192.168.10.2",top)


                socket.setSoTimeout(600)


                while received < fileSize do
                  local ok, readByte = pcall(function()
                    return input.read()
                  end)

                  if not ok then
                    if tostring(readByte):find("SocketTimeoutException") then
                      print("读取文件超时")
                     else
                      print("读取文件错误: " .. tostring(readByte))
                    end
                    break
                  end

                  if readByte == -1 then
                    print("连接中断")
                    break
                  end

                  outpu.write(readByte)
                  received = received + 1


                  if received % 10240 == 0 then
                    print("接收进度: " .. received .. "/" .. fileSize)
                  end
                end


                socket.setSoTimeout(5)

                outpu.close()
                print("接收完成:", received, "/", fileSize)
                table.insert(a,urlvoicefile .. "/_001"..fileName.."|"..duration)


              end


             elseif line:find("|") then

              local parts = {}
              for part in line:gmatch("[^|]+") do
                table.insert(parts, part)
              end

              if #parts >= 3 then
                local name = parts[1]
                local ip = parts[2]
                local text = table.concat(parts, "|", 3)



               else

                table.insert(a, line)
                savetext("未知", nil, line)
              end

             else

              local text = string.match(line or "", "^[^:]+:[^:]+:(.*)$")
              if text then
                table.insert(a, text)
                local ip_port = string.match(line, "^[^:]+:[^:]+")
                savetext("服务器", ip_port, text)
               else

                table.insert(a, line)
                savetext("未知", nil, line)
              end
            end
          end

         elseif byte == -1 then
          print("连接关闭")
          break
        end
      end
    end
    print("连接失败")


    socket.close()

  end, text, inputtext, socket)



  local function Task()
    task(3000, Task)

    if socket.isClosed() then
      print("没连接重连.........",socket)
      import "android.app.AlertDialog"


      import "android.widget.Toast"
      import "android.view.Gravity"

      showTopToast("⚠️ 未连接到服务器")
      blakes()

    end
  end
  Task()
end
blakes=function()
  connectin(confi)

end
