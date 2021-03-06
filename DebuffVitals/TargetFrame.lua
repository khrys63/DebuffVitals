-- ------------------------------------------------------------------------
-- TargetFrame - the base panel that tracks morale/power and effects 
-- ------------------------------------------------------------------------
TargetFrame = class (Turbine.UI.Window)

function TargetFrame:Constructor(num) 
    Turbine.UI.Window.Constructor(self)

    if DEBUG_ENABLED then Turbine.Shell.WriteLine("Creating TargetFrame") end

    self.ID = num
    self.Target = nil
    self.Morale = {}
    self.Morale.visible = true
    self.Power = {}
    self.Power.visible = true 
    self.Locked = false
    self.lastCorruptionSeen = 0

    self:SetVisible(true) 
    self:SetMouseVisible (false)
    self:SetPosition(Turbine.UI.Display:GetWidth()/5 + (FrameID % 20) * 40, Turbine.UI.Display:GetHeight()/5 + (FrameID % 20) * 40)

    -- ------------------------------------------------------------------------
    -- Target Title Bar
    -- ------------------------------------------------------------------------ 
    self.TitleBar = Turbine.UI.Label()
    self.TitleBar:SetVisible(true)
    self.TitleBar:SetParent (self)
    -- to accomodate the square lock icon
    self.TitleBar:SetSize(FrameWidth - ControlHeight, ControlHeight)
    self.TitleBar:SetPosition (0,0)
    self.TitleBar:SetTextAlignment (Turbine.UI.ContentAlignment.MiddleLeft)
    self.TitleBar:SetFont (Turbine.UI.Lotro.Font.Verdana12)
    self.TitleBar:SetBackColor (Turbine.UI.Color.Black)
    self.TitleBar:SetMultiline (false)  
  
    -- ------------------------------------------------------------------------
    -- Target Selection
    -- ------------------------------------------------------------------------
    self.TargetSelection = Turbine.UI.Lotro.EntityControl()
    self.TargetSelection:SetVisible (true)
    self.TargetSelection:SetParent (self)
    -- size will be set later, when all effects are loaded
    self.TargetSelection:SetPosition (0, 20)
    self.TargetSelection:SetZOrder (100)
    
    -- ------------------------------------------------------------------------
    -- Lock Control
    -- ------------------------------------------------------------------------
    self.LockBackground = Turbine.UI.Control()
    self.LockBackground:SetParent (self)
    self.LockBackground:SetBackColor (Turbine.UI.Color.Black)
    self.LockBackground:SetSize (ControlHeight, ControlHeight)
    self.LockBackground:SetPosition (FrameWidth - ControlHeight, 0)
    
    self.Lock = Turbine.UI.Control()
    self.Lock:SetParent (self)
    self.Lock:SetBackground (0x410001D3)

    self.Lock:SetSize (ControlHeight, ControlHeight)
    self.Lock:SetPosition (FrameWidth - ControlHeight,0)
    self.Lock:SetBlendMode (Turbine.UI.BlendMode.Overlay)

    self.Lock.MouseClick = function ()
        if DEBUG_ENABLED then Turbine.Shell.WriteLine("Lock for ID "..tostring(self.ID).." was "..tostring(self.Locked)) end
        self.Locked = not self.Locked
        if self.Locked then
            self.Lock:SetBackground( 0x410001D1 )
        else
            self.Lock:SetBackground( 0x410001D3 )
            TargetChangeHandler()
        end
        if DEBUG_ENABLED then Turbine.Shell.WriteLine("Lock for ID "..tostring(self.ID).." is "..tostring(self.Locked)) end
    end

    -- ------------------------------------------------------------------------
    -- Morale 
    -- ------------------------------------------------------------------------
    local moralePosition = self.TitleBar:GetHeight()
    
    self.Morale.Bar = Turbine.UI.Control()
    self.Morale.Bar:SetParent (self)
    self.Morale.Bar:SetBackColor (Turbine.UI.Color.ForestGreen )
    self.Morale.Bar:SetSize (FrameWidth, ControlHeight)
    self.Morale.Bar:SetPosition (0, moralePosition)
    self.Morale.Bar:SetMouseVisible (false)
    self.Morale.Bar:SetVisible (ShowMorale)

    self.Morale.Percent = Turbine.UI.Label()
    self.Morale.Percent:SetParent (self)
    self.Morale.Percent:SetPosition (0, moralePosition)
    self.Morale.Percent:SetSize (45, ControlHeight)
    self.Morale.Percent:SetMouseVisible (false)
    self.Morale.Percent:SetTextAlignment (Turbine.UI.ContentAlignment.MiddleLeft)
    self.Morale.Percent:SetFont (Turbine.UI.Lotro.Font.Verdana12 )
    self.Morale.Percent:SetVisible (ShowMorale)    

    self.Morale.Title = Turbine.UI.Label()
    self.Morale.Title:SetParent (self)
    self.Morale.Title:SetPosition (45, moralePosition)
    self.Morale.Title:SetSize(FrameWidth - 45, ControlHeight)
    self.Morale.Title:SetMouseVisible (false)
    self.Morale.Title:SetText ("")
    self.Morale.Title:SetTextAlignment (Turbine.UI.ContentAlignment.MiddleRight)
    self.Morale.Title:SetFont (Turbine.UI.Lotro.Font.Verdana12)
    self.Morale.Title:SetVisible (ShowMorale)

    -- ------------------------------------------------------------------------
    -- Power
    -- ------------------------------------------------------------------------
    local powerPosition = self.TitleBar:GetHeight() + self.Morale.Bar:GetHeight()
    
    self.Power.Bar = Turbine.UI.Control()
    self.Power.Bar:SetParent (self)
    self.Power.Bar:SetBackColor (Turbine.UI.Color.RoyalBlue)
    self.Power.Bar:SetSize (FrameWidth, ControlHeight)
    self.Power.Bar:SetPosition (0, powerPosition)
    self.Power.Bar:SetMouseVisible (false)
    self.Power.Bar:SetVisible (ShowPower)

    self.Power.Percent = Turbine.UI.Label()
    self.Power.Percent:SetParent (self)
    self.Power.Percent:SetPosition (0, powerPosition)
    self.Power.Percent:SetSize (45, ControlHeight)
    self.Power.Percent:SetMouseVisible (false)
    self.Power.Percent:SetTextAlignment (Turbine.UI.ContentAlignment.MiddleLeft)
    self.Power.Percent:SetFont (Turbine.UI.Lotro.Font.Verdana12)
    self.Power.Percent:SetVisible (ShowPower)

    self.Power.Title = Turbine.UI.Label()
    self.Power.Title:SetParent (self)
    self.Power.Title:SetPosition (45, powerPosition)
    self.Power.Title:SetSize(FrameWidth - 45, ControlHeight)
    self.Power.Title:SetMouseVisible (false)
    self.Power.Title:SetText ("")
    self.Power.Title:SetTextAlignment (Turbine.UI.ContentAlignment.MiddleRight)
    self.Power.Title:SetFont (Turbine.UI.Lotro.Font.Verdana12)
    self.Power.Title:SetVisible (ShowPower)
  
    -- ------------------------------------------------------------------------
    -- Effect Display
    -- ------------------------------------------------------------------------
    self.EffectList = nil
    self.SingleEffects = {}

    self:SetEnabledEffects()
    self:Resize()
    -- ------------------------------------------------------------------------
    -- Mouse and key interactions
    -- ------------------------------------------------------------------------
    -- Hide with interface
    self:SetWantsKeyEvents( true )
    function self:KeyDown( args )
        a = args.Action
        if ( a == 268435635 ) then
            self:SetVisible( not self:IsVisible() )
        end
    end

    -- Mouse and Dragging
    self.IsDragging = false

    self.TargetSelection.MouseDown = function(sender, args)
        if args.Button == Turbine.UI.MouseButton.Left and not LockedPosition then
            startX = args.X
            startY = args.Y
            self.IsDragging = true
        end
    end

    self.TargetSelection.MouseUp = function(sender, args)
        if args.Button == Turbine.UI.MouseButton.Left then
            if self.IsDragging then
                self.IsDragging = false
                
                self:SetLeft(self:GetLeft() + (args.X - startX))
                self:SetTop(self:GetTop() + (args.Y - startY))

                if self:GetLeft() < 0 then
                    self:SetLeft(0)
                elseif self:GetLeft() + self:GetWidth() > Turbine.UI.Display:GetWidth() then
                    self:SetLeft(Turbine.UI.Display:GetWidth()-self:GetWidth())
                end
                if self:GetTop() < 0 then
                    self:SetTop(0)
                elseif self:GetTop() + self:GetHeight() > Turbine.UI.Display:GetHeight() then
                    self:SetTop(Turbine.UI.Display:GetHeight()-self:GetHeight())
                end
            end
        end
    end

    self.TargetSelection.MouseMove = function(sender, args)
        if self.IsDragging then
            self:SetLeft(self:GetLeft() + (args.X - startX))
            self:SetTop(self:GetTop() + (args.Y - startY))
        end
    end
    
    self.TitleBar.MouseClick = function (sender, args)
        if args.Button == Turbine.UI.MouseButton.Right then
            self.IsDragging = false
            if DEBUG_ENABLED then Turbine.Shell.WriteLine("Showing menu") end

            local count = 0
            for k, v in pairs (TargetFrames) do
                count = count + 1
            end

            -- Set checked states
            MenuItems:GetItems():Get(3):GetItems():Get(1):SetChecked(ShowMorale)
            MenuItems:GetItems():Get(3):GetItems():Get(2):SetChecked(ShowPower)
            MenuItems:GetItems():Get(4):GetItems():Get(1):SetChecked(LockedPosition)
            MenuItems:GetItems():Get(4):GetItems():Get(2):SetChecked(SaveFramePositions)

            if count == 1 or self.Locked then
                MenuItems:GetItems():Get(2):SetEnabled(false)
            else
                MenuItems:GetItems():Get(2):SetEnabled(true)
            end

            MenuItems.invokerID = self.ID
            MenuItems:ShowMenu()
        end
    end

    self.TitleBar.MouseDown = self.TargetSelection.MouseDown
    self.TitleBar.MouseUp = self.TargetSelection.MouseUp
    self.TitleBar.MouseMove = self.TargetSelection.MouseMove

end

-- ------------------------------------------------------------------------
-- Clears and sets up all enabled/tracked effects
-- ------------------------------------------------------------------------
function TargetFrame:SetEnabledEffects()
    if DEBUG_ENABLED then Turbine.Shell.WriteLine("Entering SetEnabledEffects") end
    -- clear current effects
    for k, v in ipairs (self.SingleEffects) do
        v:SetVisible(false)
        v = nil
    end

    self.SingleEffects = {}
    
    -- generate new effects
    for k, v in ipairs (EffectsSet) do
        self.SingleEffects[k] = EffectFrame(self, v)
    end     
    
    if DEBUG_ENABLED then Turbine.Shell.WriteLine("Exiting SetEnabledEffects") end  
end

-- ------------------------------------------------------------------------
-- Set handlers, morale, power, and effects, when player target changes
-- ------------------------------------------------------------------------
function TargetFrame:UpdateTarget()
    if DEBUG_ENABLED then Turbine.Shell.WriteLine("Entering UpdateTarget") end
    if self.Locked then
        if self.TargetSelection:GetEntity() then
            if DEBUG_ENABLED then Turbine.Shell.WriteLine("  No change - locked on target : "..tostring(self.TargetSelection:GetEntity():GetName())) end
            self:SetWantsUpdates(true)
        else
            if DEBUG_ENABLED then Turbine.Shell.WriteLine("  No change - locked on NO TARGET") end
        end
    else
        if DEBUG_ENABLED then Turbine.Shell.WriteLine("  Changing target") end

        self.TitleBar:SetText("No target")

        self.Morale.Title:SetText("")
        self.Morale.Percent:SetText("")
        self.Morale.Bar:SetSize (FrameWidth, ControlHeight)

        self.Power.Title:SetText("")
        self.Power.Percent:SetText("")
        self.Power.Bar:SetSize(FrameWidth, ControlHeight)

        if self.Target then
            RemoveCallback(self.Target, "MoraleChanged", MoraleChangedHandler)
            RemoveCallback(self.Target, "BaseMaxMoraleChanged", MoraleChangedHandler)
            RemoveCallback(self.Target, "MaxMoraleChanged", MoraleChangedHandler)
            RemoveCallback(self.Target, "MaxTemporaryMoraleChanged", MoraleChangedHandler)
            RemoveCallback(self.Target, "TemporaryMoraleChanged", MoraleChangedHandler)
            RemoveCallback(self.Target, "PowerChanged", PowerChangedHandler)
            RemoveCallback(self.Target, "BaseMaxPowerChanged", PowerChangedHandler)
            RemoveCallback(self.Target, "MaxPowerChanged", PowerChangedHandler)
            RemoveCallback(self.Target, "MaxTemporaryPowerChanged", PowerChangedHandler)
            RemoveCallback(self.Target, "TemporaryPowerChanged", PowerChangedHandler)
            self.Target = nil
        end

        for k, v in ipairs (self.SingleEffects) do
            v:ClearCurrentEffect()
        end

        if self.EffectList then
            RemoveCallback(self.EffectList, "EffectAdded", EffectsChangedHandler)
            RemoveCallback(self.EffectList, "EffectRemoved", EffectsChangedHandler)
            RemoveCallback(self.EffectList, "EffectsCleared", EffectsChangedHandler)
            self.EffectList = nil   
        end

        self.Target = LocalUser:GetTarget()
        self.TargetSelection:SetEntity( self.Target )

        -- ------------------------------------------------------------------------
        -- This one command is currently critical for EntityControl to work as expected.
        -- Deleting or re-ordering this command impacts target locks. 
        -- ------------------------------------------------------------------------
        local ThrowAwayGetTargetCall = LocalUser:GetTarget()
    
        if self.Target then
            if DEBUG_ENABLED then Turbine.Shell.WriteLine("  New target's name : "..tostring(self.Target:GetName())) end
            self.TitleBar:SetText(self.TargetSelection:GetEntity():GetName())
    
            if self.Target.GetLevel ~= nil then            
                if DEBUG_ENABLED then Turbine.Shell.WriteLine("  New target - got level") end
                self.TitleBar:SetText("["..self.Target:GetLevel().."] " ..self.Target:GetName())
                self.Target.self = self
                
                if ShowMorale then
                    AddCallback(self.Target, "MoraleChanged", MoraleChangedHandler)
                    AddCallback(self.Target, "BaseMaxMoraleChanged", MoraleChangedHandler)
                    AddCallback(self.Target, "MaxMoraleChanged", MoraleChangedHandler)
                    AddCallback(self.Target, "MaxTemporaryMoraleChanged", MoraleChangedHandler)
                    AddCallback(self.Target, "TemporaryMoraleChanged", MoraleChangedHandler)
                    
                    MoraleChangedHandler(self.Target)
                end

                if ShowPower then
                    AddCallback(self.Target, "PowerChanged", PowerChangedHandler)
                    AddCallback(self.Target, "BaseMaxPowerChanged", PowerChangedHandler)
                    AddCallback(self.Target, "MaxPowerChanged", PowerChangedHandler)
                    AddCallback(self.Target, "MaxTemporaryPowerChanged", PowerChangedHandler)
                    AddCallback(self.Target, "TemporaryPowerChanged", PowerChangedHandler)
    
                    PowerChangedHandler(self.Target)
                end

                if #EffectsSet > 0 then             
                    self.EffectList = self.Target:GetEffects()
                    self.EffectList.self = self
    
                    AddCallback(self.EffectList, "EffectAdded", EffectsChangedHandler)
                    AddCallback(self.EffectList, "EffectRemoved", EffectsChangedHandler)
                    AddCallback(self.EffectList, "EffectsCleared", EffectsChangedHandler)
    
                    EffectsChangedHandler(self.Target)
                end
            else
                if DEBUG_ENABLED then Turbine.Shell.WriteLine("  Changing on target - no level found") end
                self.TitleBar:SetText(self.Target:GetName())
                self:SetWantsUpdates(false)                    
            end
        else
            if DEBUG_ENABLED then Turbine.Shell.WriteLine("NO TARGET") end      
            self:SetWantsUpdates(false)        
        end
    end

    if DEBUG_ENABLED then Turbine.Shell.WriteLine("Exiting UpdateTarget") end
end

-- ------------------------------------------------------------------------
-- Update triggered after an Effect handler triggers, cross-checking lists of effects
-- ------------------------------------------------------------------------
function TargetFrame:Update()
    if DEBUG_ENABLED then Turbine.Shell.WriteLine(">>>>>>>>>>Entering TargetFrame:Update") end

    if self.Target then
        if DEBUG_ENABLED then Turbine.Shell.WriteLine("Target name "..tostring(self.Target:GetName()).." with "..tostring(self.EffectList:GetCount()).." effects.") end

        -- in this loop, 'v' is the list of EffectFrames
        local trackedEffects = self.SingleEffects
        local targetEffects = self.EffectList

        for k, v in ipairs (trackedEffects) do
            for i = 1, targetEffects:GetCount() do
                local matchPattern = {}
                if v.patternMatch == nil then
                    matchPattern = v.effectName
                else
                    matchPattern = v.patternMatch
                end                

                if DEBUG_ENABLED then Turbine.Shell.WriteLine(">>>>Matching '"..tostring(matchPattern).."' to '"..tostring(self.EffectList:Get(i):GetName())..tostring"'") end                                                

                if type (matchPattern) == "string" then                  
                    if string.find (targetEffects:Get(i):GetName(), matchPattern) then
                        if DEBUG_ENABLED then Turbine.Shell.WriteLine(">>>> FOUND") end                 
                        v:SetCurrentEffect(targetEffects:Get(i))
                        v.lastSeen = Turbine.Engine.GetGameTime()
                        break
                    end
                else
                    local found = false
                    for key, pattern in pairs (matchPattern) do
                        if DEBUG_ENABLED then Turbine.Shell.WriteLine(">>>>Matching '"..tostring(pattern).."' to '"..tostring(self.EffectList:Get(i):GetName())..tostring"'") end                    
                        if string.find (self.EffectList:Get(i):GetName(), pattern) then
                            if DEBUG_ENABLED then Turbine.Shell.WriteLine(">>>> FOUND") end
                            v:SetCurrentEffect(self.EffectList:Get(i))
                            v.lastSeen = Turbine.Engine.GetGameTime()
                            found = true
                            break
                        end                   
                    end
                    if found then
                        break
                    end
                end
            end
            if v.toggle == 1 and v.lastSeen then
                if DEBUG_ENABLED then Turbine.Shell.WriteLine("Checking last seen on "..tostring(v.name:GetText())) end
                if (Turbine.Engine.GetGameTime() - v.lastSeen) > 5 then       
                    if DEBUG_ENABLED then Turbine.Shell.WriteLine("   not seen for "..tostring(Turbine.Engine.GetGameTime() - v.lastSeen).." seconds ago.") end
                    v:ClearCurrentEffect()
                end
            end                        
        end
        
        local number = nil
        local count = 0
        for i = 1, targetEffects:GetCount() do
            if targetEffects:Get(i):GetCategory() == Turbine.Gameplay.EffectCategory.Corruption then
                if DEBUG_ENABLED then Turbine.Shell.WriteLine("Corruption detected : "..tostring(targetEffects:Get(i):GetName())) end
                number = string.match(targetEffects:Get(i):GetName(), "%d+")
                if number then
                    if DEBUG_ENABLED then Turbine.Shell.WriteLine("Corruption count : "..tostring(number)) end
                end
                count = count + 1
                self.lastCorruptionSeen = Turbine.Engine.GetGameTime() 
            end
        end

        if number then           
            self.TitleBar:SetText(tostring(number).." ["..self.Target:GetLevel().."] " ..self.Target:GetName())
        elseif count > 0 then
            self.TitleBar:SetText(tostring(count).." ["..self.Target:GetLevel().."] " ..self.Target:GetName())
        else
            if (Turbine.Engine.GetGameTime() - self.lastCorruptionSeen) > 1 then
                self.TitleBar:SetText("["..self.Target:GetLevel().."] " ..self.Target:GetName())
                self.lastCorruptionSeen = 0
            end
        end
        
    end
    
    self:SetWantsUpdates(false)
    if DEBUG_ENABLED then Turbine.Shell.WriteLine(">>>>>>>>>>Exiting TargetFrame:Update") end
end

-- ------------------------------------------------------------------------
--  Set size/visibility of all controls
-- ------------------------------------------------------------------------
function TargetFrame:Resize()
    if DEBUG_ENABLED then Turbine.Shell.WriteLine("Entering TargetFrame:Resize ") end
    if DEBUG_ENABLED then Turbine.Shell.WriteLine("FrameWidth : "..tostring(FrameWidth)) end
    -- name 
    self.TitleBar:SetSize(FrameWidth - ControlHeight, ControlHeight)

    self.LockBackground:SetSize(ControlHeight, ControlHeight)
    self.LockBackground:SetPosition (FrameWidth - ControlHeight,0)

    self.Lock:SetSize(ControlHeight, ControlHeight)
    self.Lock:SetPosition (FrameWidth - ControlHeight,0)

    local MoralePowerHeight = 0
    -- morale/power
    if ShowMorale then
        local moralePosition = self.TitleBar:GetHeight()
        self.Morale.Bar:SetSize (FrameWidth, ControlHeight)
        self.Morale.Bar:SetPosition (0, moralePosition)
        self.Morale.Percent:SetSize(45, ControlHeight)
        self.Morale.Percent:SetPosition (0, moralePosition)
        self.Morale.Title:SetSize(FrameWidth - 45, ControlHeight)
        self.Morale.Title:SetPosition (45, moralePosition)

        MoralePowerHeight = MoralePowerHeight + ControlHeight
    end
    self.Morale.Bar:SetVisible(ShowMorale)
    self.Morale.Percent:SetVisible(ShowMorale)
    self.Morale.Title:SetVisible(ShowMorale)

    if ShowPower then
        local powerPosition = self.TitleBar:GetHeight() + MoralePowerHeight
        self.Power.Bar:SetSize(FrameWidth, ControlHeight)
        self.Power.Bar:SetPosition (0, powerPosition)
        self.Power.Percent:SetSize(45, ControlHeight)    
        self.Power.Percent:SetPosition (0, powerPosition)
        self.Power.Title:SetPosition (45, powerPosition)
        self.Power.Title:SetSize(FrameWidth - 45, ControlHeight)
        
        MoralePowerHeight = MoralePowerHeight + ControlHeight
    end
    self.Power.Bar:SetVisible(ShowPower)
    self.Power.Percent:SetVisible(ShowPower)
    self.Power.Title:SetVisible(ShowPower)

    for k, v in ipairs (EffectsSet) do
        self.SingleEffects[k]:SetPosition (0, self.TitleBar:GetHeight() + MoralePowerHeight
                + (k - 1) * ControlHeight)
    end

    -- title bar, morale bar, power bar + all effects
    local frameSize = self.TitleBar:GetHeight() + MoralePowerHeight
                + #self.SingleEffects * ControlHeight
    
    self:SetSize(FrameWidth, frameSize)
    self.TargetSelection:SetPosition(0,ControlHeight)
    self.TargetSelection:SetSize(FrameWidth, frameSize)
    
    self:UpdateTarget()

    if DEBUG_ENABLED then Turbine.Shell.WriteLine("Exiting TargetFrame:Resize") end
end
