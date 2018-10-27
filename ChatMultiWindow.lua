-----------------------------------------
--                                     --
--            ChatMultiWindow          --
--                                     --
-----------------------------------------

ChatMultiWindow = {
    ["name"] = "ChatMultiWindow",
    ["version"] = 1.1,
}
local ChatMultiWindow = ChatMultiWindow

local Defaults =
{
  NoFade = false,
}

function ChatMultiWindow.FixContainerAnchor(container)
	  container.windowContainer:ClearAnchors()
	  container.windowContainer:SetAnchor(TOPRIGHT, container.scrollUpButton, TOPLEFT, 0, 0)
	  container.windowContainer:SetAnchor(BOTTOMLEFT, container.windowContainer:GetParent(), BOTTOMLEFT, 20, -20)
end

local ChatEventFormatters = ZO_ChatSystem_GetEventHandlers()

function ChatMultiWindow.OnChatEvent(event, ...)
  -- Fix any windows that were loaded on startup
  for i=2, #CHAT_SYSTEM.containers do
    ChatMultiWindow.FixContainerAnchor(CHAT_SYSTEM.containers[i])
  end
  
  ChatMultiWindow.ChangeFade()

	-- We don't need these anymore, so clear them
  for event in pairs(ChatEventFormatters) do
    EVENT_MANAGER:UnregisterForEvent(ChatMultiWindow.name.."_OnEventId" .. event)
  end
end

function ChatMultiWindow.FixEmptyContainers()
  if GetNumChatContainers() > 1 then
	  for i=GetNumChatContainers(), 2, -1  do
	      local numContainerTabs = GetNumChatContainerTabs(i)
	      if numContainerTabs == 0 then
	        DestroyContainer(CHAT_SYSTEM.containers[i])
	      end
	  end
  end
end

function ChatMultiWindow.ChangeFade()
  for i=1, GetNumChatContainers()  do
    if ChatMultiWindow.SavedVars.NoFade then
      CHAT_SYSTEM.containers[i].fadeInReferences = 100
      for j=1, #CHAT_SYSTEM.containers[i].windows do
        CHAT_SYSTEM.containers[i].windows[j].buffer:SetLineFade(1000000, 2)
      end
      CHAT_SYSTEM.containers[i]:FadeIn()
    else
    	if CHAT_SYSTEM.containers[i] then
	      if #CHAT_SYSTEM.containers[i].windows then
		      for j=1, #CHAT_SYSTEM.containers[i].windows do
		        CHAT_SYSTEM.containers[i].windows[j].buffer:SetLineFade(25, 2)
		      end
	      end
	      CHAT_SYSTEM.containers[i].fadeInReferences = 0
	      CHAT_SYSTEM.containers[i]:FadeOut()
      end
    end
  end
end

function ChatMultiWindow.AddonLoaded(event, name)
  if name ~= "ChatMultiWindow" then
	  return
	end
  CHAT_SYSTEM:SetAllowMultipleContainers(true)

  ChatMultiWindow.SavedVars = ZO_SavedVars:NewAccountWide(ChatMultiWindow.name.."_SavedVariables", 1, "internal", Defaults)

  ChatMultiWindow.FixEmptyContainers();
  --ChatMultiWindow.ChangeFade()

	-- Need to anchor the existing windows after everything is active, so use the first chat event
  for event in pairs(ChatEventFormatters) do
    EVENT_MANAGER:RegisterForEvent(ChatMultiWindow.name.."_OnEventId" .. event, event, ChatMultiWindow.OnChatEvent)
  end
end

function ChatMultiWindow.SetFade(extra)
  if extra == "1" then
    ChatMultiWindow.SavedVars.NoFade = false
    ChatMultiWindow.ChangeFade()
  elseif extra == "0" then
    ChatMultiWindow.SavedVars.NoFade = true
    ChatMultiWindow.ChangeFade()
  end
end

-- Register addon
EVENT_MANAGER:RegisterForEvent(ChatMultiWindow.name.."_OnAddOnLoaded", EVENT_ADD_ON_LOADED, ChatMultiWindow.AddonLoaded)

SLASH_COMMANDS["/chat_fade"] = ChatMultiWindow.SetFade

-- Replace the original function so we can fix the anchors
function CHAT_SYSTEM:TransferWindow(window, previousContainer, targetContainer)
  -- First, do what the original function did...
  local container = targetContainer or self:CreateChatContainer()
  
  self.isTransferring = true
  local tabIndex = window.tab.index
  local newTabIndex = container:TakeWindow(window, previousContainer)

  if not self.suppressSave then
      TransferChatContainerTab(previousContainer.id, tabIndex, container.id, newTabIndex)
  end

  container:FinalizeWindowTransfer(window)

  self.isTransferring = false
    
  -- Second, fix the anchors so the text is visible
  ChatMultiWindow.FixContainerAnchor(container)
  
  -- Flag to not fade if enabled
  if ChatMultiWindow.SavedVars.NoFade then
    ChatMultiWindow.ChangeFade()
  end
end
