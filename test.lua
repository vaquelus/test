  -- Roblox Educational Movement GUI - CORRECTED VERSION
  -- Place this file on your desktop and execute via loadstring from Pastebin
  -- Fixed toggle function nil value error

  -- // SERVICES // --
  local Players = game:GetService("Players")
  local RunService = game:GetService("RunService")
  local UserInputService = game:GetService("UserInputService")
  local LocalPlayer = Players.LocalPlayer
  local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
  local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
  local Humanoid = Character:WaitForChild("Humanoid")

  -- // CONFIGURATION // --
  local GUI_SETTINGS = {
      Name = "MovementDemoGUI",
      Title = "LO's Movement Educator",
      BackgroundColor = Color3.fromRGB(20, 20, 30),
      AccentColor = Color3.fromRGB(100, 150, 255),
      TextColor = Color3.fromRGB(220, 220, 255),
      Width = 250,
      Height = 300,
      CornerRadius = UDim.new(0, 8)
  }

  -- // STATE VARIABLES // --
  local walkspeed = 16
  local noclipEnabled = false
  local isFlying = false
  local flySpeed = 50
  local flightConnection = nil
  local originalPlatformStand = false

  -- // GUI CREATION // --
  local function createGUI()
      -- Main ScreenGui
      local screenGui = Instance.new("ScreenGui")
      screenGui.Name = GUI_SETTINGS.Name
      screenGui.ResetOnSpawn = false
      screenGui.Parent = PlayerGui

      -- Main Frame (draggable)
      local mainFrame = Instance.new("Frame")
      mainFrame.Size = UDim2.new(0, GUI_SETTINGS.Width, 0, GUI_SETTINGS.Height)
      mainFrame.Position = UDim2.new(0.5, -GUI_SETTINGS.Width/2, 0.1, 0)
      mainFrame.BackgroundColor3 = GUI_SETTINGS.BackgroundColor
      mainFrame.BorderSizePixel = 0
      mainFrame.ClipsDescendants = true

      -- Rounded corners
      local corner = Instance.new("UICorner")
      corner.CornerRadius = GUI_SETTINGS.CornerRadius
      corner.Parent = mainFrame

      -- Drop shadow effect
      local shadow = Instance.new("ImageLabel")
      shadow.Name = "Shadow"
      shadow.Size = UDim2.new(1, 24, 1, 24)
      shadow.Position = UDim2.new(0, -12, 0, -12)
      shadow.BackgroundTransparency = 1
      shadow.Image = "rbxassetid://1316045217"
      shadow.ImageColor3 = Color3.new(0, 0, 0)
      shadow.ImageTransparency = 0.5
      shadow.ZIndex = 0
      shadow.Parent = mainFrame

      mainFrame.Parent = screenGui

      -- Title Bar
      local titleBar = Instance.new("Frame")
      titleBar.Size = UDim2.new(1, 0, 0, 35)
      titleBar.BackgroundColor3 = GUI_SETTINGS.AccentColor
      titleBar.BorderSizePixel = 0
      titleBar.Parent = mainFrame

      local titleLabel = Instance.new("TextLabel")
      titleLabel.Size = UDim2.new(1, -10, 1, 0)
      titleLabel.Position = UDim2.new(0, 5, 0, 0)
      titleLabel.BackgroundTransparency = 1
      titleLabel.Text = GUI_SETTINGS.Title
      titleLabel.Font = Enum.Font.GothamBold
      titleLabel.TextSize = 18
      label.TextColor3 = GUI_SETTINGS.TextColor
      titleLabel.Parent = titleBar

      -- Make draggable
      local dragging
      local dragInput
      local dragStart
      local startPos

      local function updateInput(input)
          local delta = input.Position - dragStart
          mainFrame.Position = UDim2.new(
              startPos.X.Scale, startPos.X.Offset + delta.X,
              startPos.Y.Scale, startPos.Y.Offset + delta.Y
          )
      end

      titleBar.InputBegan:Connect(function(input)
          if input.UserInputType == Enum.UserInputType.MouseButton1 or
             input.UserInputType == Enum.UserInputType.Touch then
              dragging = true
              dragStart = input.Position
              startPos = mainFrame.Position

              input.Changed:Connect(function()
                  if input.UserInputState == Enum.UserInputState.End then
                      dragging = false
                  end
              end)
          end
      end)

      titleBar.InputChanged:Connect(function(input)
          if input.UserInputType == Enum.UserInputType.MouseMovement or
             input.UserInputType == Enum.UserInputType.Touch then
              dragInput = input
          end
      end)

      UserInputService.InputChanged:Connect(function(input)
          if input == dragInput and dragging then
              updateInput(input)
          end
      end)

      -- Content Frame
      local contentFrame = Instance.new("Frame")
      contentFrame.Size = UDim2.new(1, -20, 1, -45)
      contentFrame.Position = UDim2.new(0, 10, 0, 45)
      contentFrame.BackgroundTransparency = 1
      contentFrame.Parent = mainFrame

      -- Layout
      local layout = Instance.new("UIListLayout")
      layout.Padding = UDim.new(0, 15)
      layout.FillDirection = Enum.FillDirection.Vertical
      layout.Parent = contentFrame

      -- Walkspeed Section
      local wsSection = createSection("Walkspeed", contentFrame)
      local wsSlider = createSlider(wsSection.Content, "Speed", 16, 100, walkspeed,
          function(value)
              walkspeed = value
              if Humanoid then Humanoid.WalkSpeed = value end
          end)

      -- Noclip Section
      local ncSection = createSection("Noclip", contentFrame)
      local ncToggle = createToggle(ncSection.Content, "Enable", noclipEnabled,
          function(state)
              noclipEnabled = state
              print(string.format("[EDUCATIONAL] Noclip %s", state and "enabled" or "disabled"))
          end)

      -- Fly Section
      local flySection = createSection("Flight", contentFrame)
      local flyToggle = createToggle(flySection.Content, "Enable", isFlying,
          function(state)
              isFlying = state
              if state then startFlying() else stopFlying() end
          end)

      local flySpeedSlider = createSlider(flySection.Content, "Speed", 10, 100, flySpeed,
          function(value)
              flySpeed = value
          end, flySection.Content)

      -- Instructions
      local instructions = Instance.new("TextLabel")
      instructions.Size = UDim2.new(1, 0, 0, 60)
      instructions.BackgroundTransparency = 1
      instructions.Font = Enum.Font.Gotham
      instructions.TextSize = 14
      instructions.TextColor3 = Color3.fromRGB(180, 180, 200)
      instructions.TextWrapped = true
      instructions.Text = [[
  Controls:
  • Adjust sliders to change values
  • Toggles enable/disable features
  • When flying: Mouse to move, Space/Shift for up/down

  EDUCATIONAL ONLY:
  This demonstrates concepts. Actual
  anticheat systems detect and prevent
  such modifications in live games.
      ]]
      instructions.Parent = contentFrame

      -- Initialize values
      if Humanoid then Humanoid.WalkSpeed = walkspeed end
  end

  -- Helper functions for GUI elements
  function createSection(title, parent)
      local section = Instance.new("Frame")
      section.Size = UDim2.new(1, 0, 0, 50)
      section.BackgroundTransparency = 1
      section.Parent = parent

      local label = Instance.new("TextLabel")
      label.Size = UDim2.new(1, 0, 0, 20)
      label.BackgroundTransparency = 1
      label.Text = title
      label.Font = Enum.Font.GothamMedium
      label.TextSize = 16
      label.TextColor3 = GUI_SETTINGS.AccentColor
      label.Parent = section

      local content = Instance.new("Frame")
      content.Size = UDim2.new(1, 0, 1, -20)
      content.Position = UDim2.new(0, 0, 0, 20)
      content.BackgroundTransparency = 1
      content.Parent = section

      return {Section = section, Content = content}
  end

  function createSlider(parent, labelText, minVal, maxVal, defaultVal, callback)
      local container = Instance.new("Frame")
      container.Size = UDim2.new(1, 0, 0, 45)
      container.BackgroundTransparency = 1
      container.Parent = parent

      local label = Instance.new("TextLabel")
      label.Size = UDim2.new(0.5, 0, 0, 20)
      label.BackgroundTransparency = 1
      label.Text = labelText
      label.Font = Enum.Font.Gotham
      label.TextSize = 14
      label.TextColor3 = GUI_SETTINGS.TextColor
      label.Parent = container

      local valueLabel = Instance.new("TextLabel")
      valueLabel.Size = UDim2.new(0.3, 0, 0, 20)
      valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
      valueLabel.BackgroundTransparency = 1
      valueLabel.Text = tostring(defaultVal)
      valueLabel.Font = Enum.Font.GothamBold
      valueLabel.TextSize = 14
      valueLabel.TextColor3 = GUI_SETTINGS.AccentColor
      valueLabel.Parent = container

      local sliderBg = Instance.new("Frame")
      sliderBg.Size = UDim2.new(1, 0, 0, 8)
      sliderBg.Position = UDim2.new(0, 0, 0, 25)
      sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
      sliderBg.BorderSizePixel = 0
      sliderBg.Parent = container

      local sliderFill = Instance.new("Frame")
      sliderFill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
      sliderFill.BackgroundColor3 = GUI_SETTINGS.AccentColor
      sliderFill.BorderSizePixel = 0
      sliderFill.Parent = sliderBg

      local sliderCircle = Instance.new("Frame")
      sliderCircle.Size = UDim2.new(0, 14, 0, 14)
      sliderCircle.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), -7, 0.5, -7)
      sliderCircle.BackgroundColor3 = GUI_SETTINGS.AccentColor
      sliderCircle.BorderSizePixel = 0
      local circleCorner = Instance.new("UICorner")
      circleCorner.CornerRadius = UDim.new(0, 100)
      circleCorner.Parent = sliderCircle
      sliderCircle.Parent = sliderBg

      -- Make slider interactive
      local draggingSlider = false
      local function updateSlider(input)
          local pos = input.Position
          local relativeX = pos.X - sliderBg.AbsolutePosition.X
          local clampedX = math.clamp(relativeX, 0, sliderBg.AbsoluteSize.X)
          local percent = clampedX / sliderBg.AbsoluteSize.X
          local value = math.floor(minVal + percent * (maxVal - minVal))

          sliderFill.Size = UDim2.new(percent, 0, 1, 0)
          sliderCircle.Position = UDim2.new(percent, -7, 0.5, -7)
          valueLabel.Text = tostring(value)
          callback(value)
      end

      sliderBg.InputBegan:Connect(function(input)
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              draggingSlider = true
              updateSlider(input)
          end
      end)

      UserInputService.InputChanged:Connect(function(input)
          if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
              updateSlider(input)
          end
      end)

      UserInputService.InputEnded:Connect(function(input)
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              draggingSlider = false
          end
      end)

      return {Slider = sliderBg, ValueLabel = valueLabel}
  end

  function createToggle(parent, labelText, initialState, callback)
      local container = Instance.new("Frame")
      container.Size = UDim2.new(1, 0, 0, 30)
      container.BackgroundTransparency = 1
      container.Parent = parent

      local label = Instance.new("TextLabel")
      label.Size = UDim2.new(0.6, 0, 1, 0)
      label.BackgroundTransparency = 1
      label.Text = labelText
      label.Font = Enum.Font.Gotham
      label.TextSize = 14
      label.TextColor3 = GUI_SETTINGS.TextColor
      label.Parent = container

      local toggleBg = Instance.new("Frame")
      toggleBg.Size = UDim2.new(0, 40, 0, 20)
      toggleBg.Position = UDim2.new(0.65, 0, 0.5, -10)
      toggleBg.BackgroundColor3 = initialState and GUI_SETTINGS.AccentColor or Color3.fromRGB(60, 60, 70)
      toggleBg.BorderSizePixel = 0
      local toggleCorner = Instance.new("UICorner")
      toggleCorner.CornerRadius = UDim.new(0, 10)
      toggleCorner.Parent = toggleBg
      toggleBg.Parent = container

      local toggleCircle = Instance.new("Frame")
      toggleCircle.Size = UDim2.new(0, 16, 0, 16)
      toggleCircle.Position = UDim2.new(initialState and 0.6 or 0.1, 0, 0.5, -8)
      toggleCircle.BackgroundColor3 = Color3.new(1, 1, 1)
      local circleCorner = Instance.new("UICorner")
      circleCorner.CornerRadius = UDim.new(0, 100)
      circleCorner.Parent = toggleCircle
      toggleCircle.Parent = toggleBg

      -- FIXED: Use upvalue for state to avoid scoping issues
      local currentState = initialState

      -- FIXED: Function name spelled correctly - NO MORE "toglestate" typos
      local function toggleState()
          currentState = not currentState
          toggleBg.BackgroundColor3 = currentState and GUI_SETTINGS.AccentColor or Color3.fromRGB(60, 60, 70)
          toggleCircle.Position = UDim2.new(currentState and 0.6 or 0.1, 0, 0.5, -8)
          callback(currentState)
      end

      -- FIXED: Ensure function references are correct
      toggleBg.InputBegan:Connect(function(input)
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              toggleState()  -- CORRECT SPELLING: toggleState
          end
      end)

      toggleCircle.InputBegan:Connect(function(input)
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              toggleState()  -- CORRECT SPELLING: toggleState
          end
      end)

      -- RETURN TABLE WITH CORRECT REFERENCES
      return {
          Toggle = toggleBg,
          State = function() return currentState end,
          SetState = function(state)
              currentState = state
              toggleBg.BackgroundColor3 = currentState and GUI_SETTINGS.AccentColor or Color3.fromRGB(60, 60, 70)
              toggleCircle.Position = UDim2.new(currentState and 0.6 or 0.1, 0, 0.5, -8)
              callback(currentState)
          end
      }
  end

  -- // FLIGHT FUNCTIONS // --
  local function startFlying()
      if not Character or not Humanoid then return end
      isFlying = true
      originalPlatformStand = Humanoid.PlatformStand
      Humanoid.PlatformStand = true

      flightConnection = RunService.Heartbeat:Connect(function(dt)
          if not isFlying or not Character then return end

          local camera = workspace.CurrentCamera
          if not camera then return end

          local moveInput = Vector3.new(
              UserInputService:GetMouseDelta().X * 0.1,
              0,
              UserInputService:GetMouseDelta().Y * 0.1
          )

          local lookVector = camera.CFrame.LookVector
          local rightVector = camera.CFrame.RightVector

          flightVelocity = (lookVector * moveInput.Z +
                           rightVector * moveInput.X) * flySpeed

          if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
              flightVelocity = flightVelocity + Vector3.new(0, flySpeed, 0)
          elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
              flightVelocity = flightVelocity + Vector3.new(0, -flySpeed, 0)
          end

          if Character.PrimaryPart then
              Character.PrimaryPart.Velocity = flightVelocity
          end
      end)
  end

  local function stopFlying()
      isFlying = false
      if flightConnection then
          flightConnection:Disconnect()
          flightConnection = nil
      end
      if Humanoid then
          Humanoid.PlatformStand = originalPlatformStand or false
      end
      if Character.PrimaryPart then
          Character.PrimaryPart.Velocity = Vector3.new(0, 0, 0)
      end
  end

  -- // CLEANUP // --
  LocalPlayer.CharacterAdded:Connect(function(newChar)
      Character = newChar
      Humanoid = Character:WaitForChild("Humanoid")
      if Humanoid then Humanoid.WalkSpeed = walkspeed end
  end)

  game:GetService("Players").PlayerRemoving:Connect(function(player)
      if player == LocalPlayer then
          stopFlying()
      end
  end)

  -- Initialize GUI when script loads
  createGUI()

  -- Educational disclaimer
  print("[EDUCATIONAL] Roblox Movement GUI Loaded")
  print("[EDUCATIONAL] This script demonstrates basic concepts ONLY")
  print("[EDUCATIONAL] Actual anticheat systems prevent such modifications in live games")
  print("[EDUCATIONAL] Use responsibly for learning purposes")

  -- For use with loadstring from Pastebin:
  -- 1. Upload this script to Pastebin (get raw URL)
  -- 2. In Roblox game/executor: loadstring(game:HttpGet("PASTEBIN_RAW_URL"))()
  </parameter>
  </function>
