local ADDON_NAME,namespace = ...

local addon = CreateFrame("Button",ADDON_NAME,UIParent)


do
	local GetCursorPosition = GetCursorPosition
	local coroutine = coroutine

	local function coroutineHandler(model,rotate)
		local pX,pY,cX,cY,dX,dY = GetCursorPosition()
		while true do
			cX,cY = GetCursorPosition()
			dX,dY = (cX-pX)*0.01,(cY-pY)*0.01

			if rotate then
				model.f = (model.f or 0) + dX
				model:SetFacing(model.f)
			else
				model.x = (model.x or 0) + dX*0.2
				model.y = (model.y or 0) + dY*0.2
				model:SetPosition(0.67,model.x,model.y)
			end

			pX,pY = cX,cY
			coroutine.yield()
		end
	end

	function addon:StartDrag(button)
		local co = coroutine.create(coroutineHandler)
		coroutine.resume(co,self.model,button == "LeftButton")
		self:SetScript("OnUpdate",function() coroutine.resume(co) end)
	end

	function addon:StopDrag()
		self:SetScript("OnUpdate",nil)
	end
end

function addon:ResetModel()
	self.model:Show()
	self.model:Undress()
end

function addon:UpdateModel()
	self:ResetModel()
	self:SetItem(self.currentItemID)
end

function addon:UNIT_MODEL_CHANGED(unit)
	if unit ~= "player" then
		return
	end

	self:UpdateModel()
end

function addon:PLAYER_LOGIN()
	self.model:SetUnit("player")
	self.model:SetRotation(0.61)
	self.model:SetPosition(0.67,0,0)

	self:UpdateModel()
end

function addon:OnEvent(event,...)
	self[event](self,...)
end

function addon:SetItem(itemID)
	itemID = math.max(0,itemID)
	local link = ("item:%d:0:0:0:0:0:0:0:0"):format(itemID)

	self.fontStringItemID:SetText(itemID)
	self.model:TryOn(link)

	ShowUIPanel(ItemRefTooltip)
	if not ItemRefTooltip:IsShown() then
		ItemRefTooltip:SetOwner(UIParent,"ANCHOR_PRESERVE")
	end
	ItemRefTooltip:SetHyperlink(link)

	self.currentItemID = itemID
end

function addon:CreateButton(parent)
	local button = CreateFrame("Button",nil,parent)
	button:SetNormalTexture("Interface\\Buttons\\WHITE8x8")
	button:GetNormalTexture():SetVertexColor(0,0,0)
	button:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
	button:GetHighlightTexture():SetVertexColor(0.2,0.2,0.2)
	button:SetNormalFontObject("NumberFontNormal")

	return button
end

function addon:ConstructGUI()
	self:SetPoint("CENTER")
	self:SetSize(256,512)
	self:SetClampedToScreen(true)
	self:EnableMouseWheel(true)
	self:RegisterForDrag("LeftButton","RightButton")
	self:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 4,
	})
	self:SetBackdropColor(0.1,0.1,0.1,0.8)
	self:SetBackdropBorderColor(0,0,0)
	self:RegisterForClicks("MiddleButtonUp")
	self:SetScript("OnClick",function()
		self.model:SetFacing(0)
		self.model:SetPosition(0.67,0,0)
	end)
	self:SetScript("OnMouseWheel",function(_,delta)
		delta = IsShiftKeyDown() and delta*1e2 or delta
		self:ResetModel()
		self:SetItem(self.currentItemID+delta)
	end)
	self:SetScript("OnDragStart",function(_,...)
		addon:StartDrag(...)
	end)
	self:SetScript("OnDragStop",function()
		addon:StopDrag()
	end)

	self.titleRegion = self:CreateTitleRegion()
	self.titleRegion:SetPoint("TOPRIGHT")
	self.titleRegion:SetPoint("BOTTOMLEFT",self,"TOPLEFT",0,-20)

	self.fontStringItemID = self:CreateFontString(nil,"ARTWORK","NumberFontNormal")
	self.fontStringItemID:SetPoint("TOPRIGHT",-2,-8)
	self.fontStringItemID:SetJustifyH("LEFT")

	self.model = CreateFrame("DressUpModel",nil,self)
	self.model:SetAllPoints()

	self.CreateButton = nil
end

function addon:OnInitialize()
	self:ConstructGUI() self.ConstructGUI = nil
	self.currentItemID = 0

	self:SetScript("OnEvent",addon.OnEvent)
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("UNIT_MODEL_CHANGED")
end

addon:OnInitialize() addon.OnInitialize = nil