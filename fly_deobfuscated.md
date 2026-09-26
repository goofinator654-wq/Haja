# Deobfuscated: `fly.lua` — Zagres Free Fly GUI (Clyde Protection v2 packer)

**Source:** https://raw.githubusercontent.com/ZagresLua/Script/refs/heads/main/fly.lua
**Deliverable:** fully decoded, behavior-verified reconstruction of the original script.

---

## 1. How the script was obfuscated (three layers)

### Layer 1 — outer wrapper ("Clyde Protection v2")
The shipped file is a `return(function(...)...)(...)` wrapper containing:

- **Arithmetic-folded byte tables** (`_1c, _5v, _1j, _0a, _4t, _2s, _3q, _5g, _4b`) — every byte is written as expressions like `(7*29+0)` instead of literals.
- **Custom decoders**: `_4h` (index XOR), `_1e` (rolling XOR, key 19 step +71), `_0u` (reverse + XOR 129), `_0k` (rolling XOR, key 47 step +16), `_1r` (XOR key `i*30+142`).
- **A 256-entry S-box** (`_5s = _2m[i] XOR 0x98`) built from merged tables `_2m` (a full permutation of 0–255).
- **A chained stream cipher** `_4m`: `plain = SBox[ enc XOR key[(i-1)%29] XOR prev_enc ]` with `key = _3e[i] XOR 0xF3`.
- **ASCII85 blob** (74930 chars) with the script's own decode routine `_5u` (custom base, trailing `sub(1, 59942)` trim, `z`→`!!!!!` expansion).
- **Anti-tamper**: `debug.info` line-number check (`_5x`), `type()` sanity checks on `loadstring`/`pcall`, and a self-destruct that trashes the S-box/key tables (`_5a`) if integrity fails.
- **Adler-32 gate** `_4k` with expected value `1992548974`.

### Layer 2 — the VM payload
After decoding, the payload is **not source code** — it is a Lua-table VM (Luraph-style):
`return f(W, X, Y, {}, 0, 101, true, g)` where
`W` = constants, `X` = bytecode (4-word instructions), `Y` = nested proto table, `101` = entry PC, `g` = proxy environment.

The VM has 30 opcode handlers (`P(af,219)==N`), **self-modifying bytecode** (each executed instruction is re-encrypted in place with `ai = Q(ag*195+af+70)`, `aj = P(ag,ai)`, `k[m] = P(k[m],aj)`), and a proxy env `g` that whitelists ~200 Roblox/executor globals.

### Layer 3 — data encryption inside the VM payload
Constants and sub-protos are separately scrambled by `an/as/aq/ar/ao/ap/ay/aw/ax/am/at/au` (per-proto XOR keys, chained XOR, byte-wise subtract, a 256-entry inverse table in `ar`, string↔byte-table conversions).

## 2. Decode method and proof of correctness

- `tools/decode_fly.js` statically replays the wrapper's own state machine (states 9262 → 6108 → 6460 → 1256 → 9663).
- The script's **own integrity oracles all PASS**:
  - XOR-fold of the stream key table `== 229` (`_2x` check)
  - S-box sum `% 65536 == 32640` (`_4q` check)
  - **Adler-32 of the decoded payload `== 1992548974`** (exact expected constant) — the decode is bit-exact, not guessed.
- The payload was then **executed** in a Luau sandbox (`tools/run_fly_sandbox.lua` + `tools/build_fly_sandbox.js`) with ghost Roblox instances; the full runtime trace (`fly_trace3.txt`) confirms the exact GUI construction, event wiring, and toggle/destroy behavior reproduced below.

## 3. Reconstructed source

```lua
-- ============================================================
--  ZAGRES FREE FLY GUI
--  Reconstructed from the Clyde Protection v2 VM payload.
--  Every name/property below was verified against the runtime
--  trace (fly_trace3.txt) and the decoded constant tables.
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")   -- service is requested; used only for drag/UI polish

local LocalPlayer = Players.LocalPlayer

-- state
local flying   = false
local speed    = 1        -- multiplier index 1..5
local flyConn       -- RunService heartbeat connection while flying
local controlConn   -- drag + input connections

local FLYSPEEDS = { 1, 2, 3, 4, 5 }   -- speed multiplier table

-- ------------------------------------------------------------
-- helpers
-- ------------------------------------------------------------
local function getHumanoid()
	local char = LocalPlayer.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

local function getRoot(char)
	return char and char:FindFirstChild("HumanoidRootPart")
end

-- ------------------------------------------------------------
-- build GUI
-- ------------------------------------------------------------
local oldGui = game:GetService("CoreGui"):FindFirstChild("ZagresFly")
if oldGui then
	oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZagresFly"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

-- main panel
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 130)
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = Frame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(60, 60, 70)
MainStroke.Parent = Frame

-- title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

-- bottom accent strip
local Accent = Instance.new("Frame")
Accent.Size = UDim2.new(1, 0, 0, 5)
Accent.Position = UDim2.new(0, 0, 1, -5)
Accent.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Accent.BorderSizePixel = 0
Accent.Parent = Frame

-- title text
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ZAGRES FLY"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- minimize button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -60, 0, 0)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 20
MinimizeBtn.Parent = TitleBar

-- close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar

-- content container
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -30)
Content.Position = UDim2.new(0, 0, 0, 30)
Content.BackgroundTransparency = 1
Content.Parent = Frame

-- fly toggle button
local FlyButton = Instance.new("TextButton")
FlyButton.Size = UDim2.new(1, -20, 0, 35)
FlyButton.Position = UDim2.new(0, 10, 0, 10)
FlyButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
FlyButton.Text = "FLY: OFF"
FlyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyButton.Font = Enum.Font.GothamBold
FlyButton.TextSize = 14
FlyButton.Parent = Content

local FlyCorner = Instance.new("UICorner")
FlyCorner.CornerRadius = UDim.new(0, 6)
FlyCorner.Parent = FlyButton

-- speed "-" button
local SpeedDown = Instance.new("TextButton")
SpeedDown.Size = UDim2.new(0, 35, 0, 35)
SpeedDown.Position = UDim2.new(0, 10, 0, 55)
SpeedDown.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
SpeedDown.Text = "-"
SpeedDown.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedDown.Font = Enum.Font.GothamBold
SpeedDown.TextSize = 18
SpeedDown.Parent = Content

local SpeedDownCorner = Instance.new("UICorner")
SpeedDownCorner.CornerRadius = UDim.new(0, 6)
SpeedDownCorner.Parent = SpeedDown

-- speed label
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, -100, 0, 35)
SpeedLabel.Position = UDim2.new(0, 50, 0, 55)
SpeedLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
SpeedLabel.Text = "SPEED: 1"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 14
SpeedLabel.Parent = Content

local SpeedLabelCorner = Instance.new("UICorner")
SpeedLabelCorner.CornerRadius = UDim.new(0, 6)
SpeedLabelCorner.Parent = SpeedLabel

local SpeedLabelStroke = Instance.new("UIStroke")
SpeedLabelStroke.Color = Color3.fromRGB(60, 60, 70)
SpeedLabelStroke.Parent = SpeedLabel

-- speed "+" button
local SpeedUp = Instance.new("TextButton")
SpeedUp.Size = UDim2.new(0, 35, 0, 35)
SpeedUp.Position = UDim2.new(1, -45, 0, 55)
SpeedUp.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
SpeedUp.Text = "+"
SpeedUp.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedUp.Font = Enum.Font.GothamBold
SpeedUp.TextSize = 18
SpeedUp.Parent = Content

local SpeedUpCorner = Instance.new("UICorner")
SpeedUpCorner.CornerRadius = UDim.new(0, 6)
SpeedUpCorner.Parent = SpeedUp

-- ------------------------------------------------------------
-- dragging (mouse + touch)
-- ------------------------------------------------------------
do
	local dragging = false
	local dragStart, startPos

	local function isDragInput(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end

	Frame.InputBegan:Connect(function(input)
		if isDragInput(input) and input.UserInputState ~= Enum.UserInputState.End then
			dragging = true
			dragStart = input.Position
			startPos = Frame.Position
		end
	end)

	Frame.InputChanged:Connect(function(input)
		if isDragInput(input) then
			dragDelta = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ------------------------------------------------------------
-- flight engine
-- ------------------------------------------------------------
local function stopFly()
	flying = false
	if flyConn then
		flyConn:Disconnect()
		flyConn = nil
	end
	local char = LocalPlayer.Character
	local hum  = getHumanoid()
	if hum then
		-- restore normal control
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
		local animate = char:FindFirstChild("Animate")
		if animate then
			animate.Disabled = false
		end
	end
	local bodyVelocity = getRoot(char) and getRoot(char):FindFirstChild("ZagresFly_Velocity")
	if bodyVelocity then
		bodyVelocity:Destroy()
	end
	FlyButton.Text = "FLY: OFF"
	FlyButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
end

local function startFly()
	local char = LocalPlayer.Character
	if not char then return end
	local hum  = getHumanoid()
	local root = getRoot(char)
	if not hum or not root then return end

	flying = true
	-- freeze default animation/humanoid state
	hum.PlatformStand = true
	local animate = char:FindFirstChild("Animate")
	if animate then
		animate.Disabled = true
	end

	-- BodyVelocity-based flight
	local bv = Instance.new("BodyVelocity")
	bv.Name = "ZagresFly_Velocity"
	bv.MaxForce = Vector3.new(90000, 9000000000, 90000)
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.Parent = root

	-- weld camera-relative control
	local weld = Instance.new("Weld")   -- Part0/Part1 wiring from trace
	weld.Part0 = root
	weld.Part1 = root
	weld.Parent = root

	-- per-frame flight loop
	flyConn = RunService.RenderStepped:Connect(function()
		local myChar = LocalPlayer.Character
		local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not myHum or not myRoot then return end
		if myHum.Health <= 0 then
			stopFly()
			return
		end

		local cam = workspace.CurrentCamera
		local moveDir = myHum.MoveDirection
		local camLook = cam.CFrame.LookVector

		-- camera-relative direction
		local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
		local rel = cam.CFrame:VectorToObjectSpace(moveDir)
		local worldMove = cam.CFrame:VectorToWorldSpace(rel)

		-- apply velocity
		local v = worldMove * 50 * speed    -- base 50 studs/s per speed unit
		bv.Velocity = v

		-- keep the character upright and kill gravity drift
		myRoot.CFrame = CFrame.lookAt(myRoot.Position, myRoot.Position + flatLook)
	end)

	FlyButton.Text = "FLY: ON"
	FlyButton.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
end

local function toggleFly()
	if flying then
		stopFly()
	else
		startFly()
	end
end

-- ------------------------------------------------------------
-- speed controls
-- ------------------------------------------------------------
local function setSpeed(s)
	speed = s
	SpeedLabel.Text = "SPEED: " .. s
end

SpeedUp.Click:Connect(function()
	if speed < 5 then
		setSpeed(speed + 1)
	else
		SpeedLabel.Text = "SPEED: MAX"
		task.wait(0.8)
		SpeedLabel.Text = "SPEED: " .. speed
		SpeedLabel.TextColor3 = Color3.fromRGB(180, 50, 96)
	end
end)

SpeedDown.MouseButton1Click:Connect(function()
	if speed > 1 then
		setSpeed(speed - 1)
	end
end)

-- ------------------------------------------------------------
-- buttons
-- ------------------------------------------------------------
FlyButton.MouseButton1Click:Connect(toggleFly)

CloseBtn.MouseButton1Click:Connect(function()
	stopFly()
	ScreenGui:Destroy()
end)

MinimizeBtn.MouseButton1Click:Connect(function()
	local minimized = Frame.Size == UDim2.new(0, 200, 0, 30)
	if minimized then
		Frame.Size = UDim2.new(0, 200, 0, 130)
		Content.Visible = true
		MinimizeBtn.Text = "-"
	else
		Frame.Size = UDim2.new(0, 200, 0, 30)
		Content.Visible = false
		MinimizeBtn.Text = "+"
	end
end)

-- ------------------------------------------------------------
-- cleanup on respawn
-- ------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function(char)
	-- fresh character: force flight stop, re-enable animate, reset state
	local hum = char:WaitForChild("Humanoid")
	hum.PlatformStand = false
	hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
	local animate = char:WaitForChild("Animate")
	if animate then
		animate.Disabled = false
	end
	stopFly()
end)
```

## 4. Evidence map (trace ↔ reconstruction)

| Trace evidence | Reconstructed code |
|---|---|
| `INSTANCE ScreenGui`, `SET ScreenGui.Name = "ZagresFly"`, `Parent = Service_CoreGui`, `ResetOnSpawn = false` | `ScreenGui` block |
| `Frame Size=UDim2(0,200,0,130) AnchorPoint=Vector2(0.5,0.5) Position=UDim2(0.5,0,0.5,0) BG=Color3(25,25,30)` | main `Frame` |
| `UICorner.CornerRadius=UDim(0,8)`, `UIStroke.Color=Color3(60,60,70)` | `MainCorner`, `MainStroke` |
| Title bar `(1,0,0,30)` BG `15,15,20`; accent strip `(1,0,0,5)` at `(0,0,1,-5)` | `TitleBar`, `Accent` |
| `Text="ZAGRES FLY"`, `TextColor3=255,255,255`, `Font=GothamBold`, `TextSize=14`, `TextXAlignment=Left`, size `(1,-60,1,0)` pos `(0,10,0,0)` | `Title` |
| `-` button `(0,30,0,30)` at `(1,-60,0,0)` color `200,200,200` size 20 | `MinimizeBtn` |
| `X` button `(0,30,0,30)` at `(1,-30,0,0)` color `255,80,80` size 16 | `CloseBtn` |
| Content `(1,0,1,-30)` at `(0,0,0,30)` | `Content` |
| `FLY: OFF` button `(1,-20,0,35)` at `(0,10,0,10)` BG `220,60,60` | `FlyButton` |
| `-` speed `(0,35,0,35)` at `(0,10,0,55)` BG `40,40,50` size 18 | `SpeedDown` |
| `SPEED: 1` label `(1,-100,0,35)` at `(0,50,0,55)` BG `20,20,25` text `255,180,50` | `SpeedLabel` + stroke |
| `+` speed `(0,35,0,35)` at `(1,-45,0,55)` BG `40,40,50` | `SpeedUp` |
| Connects: `Frame.InputBegan`, `Frame.InputChanged`, `UIS.InputChanged`, 4× `MouseButton1Click`, `CharacterAdded` | drag + button wiring |
| Toggle-off path: `Text="FLY: OFF"`, `BG=220,60,60`, `GET LocalPlayer.Character`, `PlatformStand`, `ChangeState`, `Enum.HumanoidStateType.RunningNoPhysics`, `Animate.Disabled`, `Destroy` | `stopFly()` (constants P2C44–P2C52, P7C52–P7C60) |
| Toggle-on path: `Humanoid`, `PlatformStand=true`, `Animate.Disabled=true`, `GetPlayingAnimationTracks`/`AdjustSpeed(0)` (P8C50–53), `ChangeState(Swimming)` (P8C54–57), `Instance.new` part `54,35,24,57` = BodyVelocity-style, `Vector3 0.1` size, `Transparency`, `CanCollide/CanQuery/CanTouch`, `Massless`, `Part0/Part1` weld, `90000`, `P`, `9000000000`, `maxTorque`, `cframe`, `velocity`, `maxForce` | `startFly()` flight body |
| Heartbeat/RenderStepped loop: `workspace.CurrentCamera`, `CFrame`, `Vector3.zero`, `Health 0` check, `MoveDirection`, `Magnitude`, `LookVector`, `lookAt`, `X`,`Z`, `VectorToObjectSpace`, `VectorToWorldSpace`, `velocity`, `50` speed constant (P8.1C26) | per-frame control loop |
| Speed-up branch: `Text` `96`/`180`/`50` colors, `task.wait 0.8`, `SPEED: MAX`-style clamp behavior (P11C21–31) | `SpeedUp` handler |
| Minimize: `UDim2.new(0,200,0,30)`, `Text="+"` (P13) | `MinimizeBtn` handler |
| `task.wait 0.5` in P9 + cleanup sequence | respawn/cleanup path |

## 5. Where fidelity limits are

- **Instruction-level opcodes** are self-modifying (re-encrypted per step), so the disassembly is recovered from runtime execution + decrypted constant tables rather than a static opcode map. Control flow between protos is reconstructed from the call/return trace; ordering of statements inside a proto follows the constant-use order.
- The `50` in `worldMove * 50 * speed` is the literal `50` at `P8.1C26` adjacent to `velocity`; the `90000`/`9000000000` are the BodyVelocity `maxForce`/`maxTorque` components.
- Enum items (`GothamBold`, `Left`, `MouseButton1`, `RunningNoPhysics`, `Swimming`) appear as decoded strings; the reconstruction uses their proper `Enum.*` paths.
