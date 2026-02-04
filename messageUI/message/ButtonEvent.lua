require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"
import "android.text.SpannableStringBuilder"
local commonEmojis = {
  "🤡", "😃","😄","🙃","😉","🤣",
  "🥲","😏","😒","😞","😔","😟",
  "🤢","🤮","🐶","💩","🐱","🐮","🐷","🐸",
  "🐔","🐧","🐦","🐤","🦆","🦅","🐓","🦃",
  "🦤","🦚","🦜","🦢","🦩","🦌","🫙",
  "🥹","🤏","✌️","🤞","🤟","🖖","👌",
  "☝️","👍","👎","👊","🤛","🤜","👏","🙌","👐","🤲","🤝",
  "🙏","✍️","💅","🤳","💪","🦵","🦶","👂","🦻","👃","🧠",
  "🦴","👀","👅"

}
local inputMethodManager = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
local currentVisiblePanel = nil
local panelDictionary = {}

function addplan(Pname, Panels)
  panelDictionary[Pname] = Panels
  Panels.setVisibility(View.GONE)

end
addplan("emojiBtn", EmojiPanel)
addplan("addButton", functionPanel)
addplan("voiceBtn", voiceInputBox)

function fastpanel(name)

  idpanel = panelDictionary[name]
  if name == "voiceBtn" then

    closeallpanel()
    currentVisiblePanel = nil
    if Edit.getVisibility() == View.VISIBLE then
      idpanel.setVisibility(View.VISIBLE)
      Edit.setVisibility(View.GONE)
      bottomContainer.getLayoutParams().height = -2
      inputMethodManager.hideSoftInputFromWindow(Edit.getWindowToken(), 0)
     else
      idpanel.setVisibility(View.GONE)
      Edit.setVisibility(View.VISIBLE)Edit.setVisibility(View.VISIBLE)
      currentVisiblePanel = nil
      inputMethodManager.showSoftInput(Edit, 0)
      Edit.requestFocus()
    end
    return
  end


  if not idpanel then
    return end

  if idpanel == currentVisiblePanel then
    idpanel.setVisibility(View.GONE)
    currentVisiblePanel = nil
    inputMethodManager.showSoftInput(Edit, 0)
    return
  end
  if currentVisiblePanel then
    currentVisiblePanel.setVisibility(View.GONE)

  end
  Handler().postDelayed(function()
    Edit.requestFocus()
  end, 10)
  inputMethodManager.hideSoftInputFromWindow(Edit.getWindowToken(), 0)

  idpanel.setVisibility(View.VISIBLE)
  currentVisiblePanel = idpanel

  voiceInputBox.setVisibility(View.GONE)
  Edit.setVisibility(View.VISIBLE)

  bottomContainer.getLayoutParams().height = 995

end

function closeallpanel()
  if currentVisiblePanel then
    currentVisiblePanel.setVisibility(View.GONE)
    currentVisiblePanel = nil
  end
end


function putEmojisAuto(editText)
  EmojiPanel.removeAllViews()
  local gridView = GridView(activity)
  gridView.setLayoutParams(LinearLayout.LayoutParams(-1, -1))
  gridView.setNumColumns(5)
  gridView.setHorizontalSpacing(130)

  local adapter = ArrayAdapter(activity,
  android.R.layout.simple_list_item_1,
  commonEmojis
  )

  gridView.setAdapter(adapter)


  import "android.text.SpannedString"

  gridView.onItemClick = function(parent, view, position)
    if editText then
      local emoji = commonEmojis[position + 1]
      local cursor = Edit.getSelectionStart()

      if cursor < 0 then
        cursor = Edit.getText().length()
      end


      local builder = SpannableStringBuilder(Edit.getText())
      builder.insert(cursor, emoji)
      Edit.setText(builder)


      Edit.setSelection(cursor +2)
    end
  end

  EmojiPanel.addView(gridView)
end

emojiBtn.onClick = function()

  fastpanel("emojiBtn")
  putEmojisAuto("1")

  emojiBtn.animate().rotationBy(180).setDuration(1).start()

end

addButton.onClick = function()
  fastpanel("addButton")

end
voiceBtn.onClick = function()
  fastpanel("voiceBtn")
end




function insertEmojiIntelligent(editText, emoji)

  if not editText then
    print("错误：editText为空")
    return false
  end


  local start = editText.getSelectionStart()
  local endPos = editText.getSelectionEnd()


  if start < 0 then

    local text = Edit.getText()
    start = text.length()
    endPos = start

  end

  local builder = SpannableStringBuilder(Edit.getText())


  local hasSelection = (start ~= endPos)

  if hasSelection then

    print("替换选中文本: ["..builder.subSequence(start, endPos).."]")
    builder.replace(start, endPos, emoji)
   else

    builder.insert(start, emoji)
  end


  Edit.setText(builder)


  local newCursorPos = start + #emoji
  editText.setSelection(newCursorPos)

  return true
end





Edit.addTextChangedListener{

  onTextChanged = function(text)

    if #text > 0 then
      textin.setVisibility(View.VISIBLE)
      addButton.setVisibility(View.GONE)

     else
      textin.setVisibility(View.GONE)
      addButton.setVisibility(View.VISIBLE)

    end
  end
}


Edit.onClick = function()
  closeallpanel()
  local params = bottomContainer.getLayoutParams()
  params.height = 995
  bottomContainer.setLayoutParams(params)
end


whitehome =function()
  closeallpanel()
  inputMethodManager.hideSoftInputFromWindow(Edit.getWindowToken(), 0)

  bottomContainer.getLayoutParams().height = -2
end


function onKeyDown(keyCode, event)
  if keyCode == KeyEvent.KEYCODE_BACK and currentVisiblePanel then
    closeallpanel()
    bottomContainer.getLayoutParams().height = -2 return true

  end
  return false
end

local wasKeyboardVisible = false
local rootView = activity.getWindow().getDecorView().getRootView()


rootView.getViewTreeObserver().addOnGlobalLayoutListener({
  onGlobalLayout = function()
    local rect = Rect()
    rootView.getWindowVisibleDisplayFrame(rect)
    local screenHeight = rootView.getHeight()

    if screenHeight and screenHeight > 0 then
      local currentKeyboardHeight = screenHeight - (rect.bottom - rect.top)
      local isKeyboardNowVisible = currentKeyboardHeight > 200

      if wasKeyboardVisible and not isKeyboardNowVisible and not currentVisiblePanel then
        local params = bottomContainer.getLayoutParams()
        params.height = ViewGroup.LayoutParams.WRAP_CONTENT
        bottomContainer.setLayoutParams(params)
        bottomContainer.requestLayout()
      end

      wasKeyboardVisible = isKeyboardNowVisible
    end
  end
})
