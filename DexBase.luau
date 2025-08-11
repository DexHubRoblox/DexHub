local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- CREATING THE WINDOW
local Window = WindUI:CreateWindow({
    Title = "DexHub",
    Icon = "rbxassetid://85038777882275",
    Author = "Welcome to DexHub",
    Folder = "DexHubV1",
    Size = UDim2.fromOffset(580, 460),
    Transparent = false,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    HideSearchBar = false,
    ScrollBarEnabled = true,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("clicked")
        end,
    },
    KeySystem = {
        Note = "Get Key to Continue using DexHub",
        API = {
            { -- PlatoBoost
                Title = "Platoboost",
                Desc = "Click to copy",

                Type = "platoboost",
                ServiceId = 5565,
                Secret = "e4acd04d-3894-4b0b-b0da-8b9dd695f74d",
            }
        },
    }
})

-- TAG WHICH SHOWS THE VERSION
Window:Tag({
    Title = "v1.0.0",
})

-- THEME SWITCHER FOR TOP BAR
Window:CreateTopbarButton("theme-switcher", "moon", function()
    WindUI:SetTheme(WindUI:GetCurrentTheme() == "Dark" and "Light" or "Dark")
    WindUI:Notify({
        Title = "Theme Changed",
        Content = "Current theme: "..WindUI:GetCurrentTheme(),
        Duration = 2
    })
end, 990)

-- TABS | MAIN = MAIN TAB CALL
local Tabs = {
    Main = Window:Section({ Title = "TEST", Opened = true }),
    Settings = Window:Section({ Title = "SETTINGS", Opened = true }),
    Utilities = Window:Section({ Title = "UTILITIES", Opened = true })
}

-- TAB HANDLERS | ELEMENT = NAME OF THE TAB CALL
local TabHandles = {
    Elements = Tabs.Main:Tab({ Title = "UI_ELEMENTS", Icon = "layout-grid" }),
    Appearance = Tabs.Settings:Tab({ Title = "APPEARANCE", Icon = "brush" }),
    Config = Tabs.Utilities:Tab({ Title = "CONFIGURATION", Icon = "settings" })
}

-- PARAGRAPH | ELEMENT STANDS FOR THE TAB
TabHandles.Elements:Paragraph({
    Title = "Interactive Components",
    Desc = "Explore WindUI's powerful elements",
    Image = "component",
    ImageSize = 20,
    Color = "White",
})

TabHandles.Elements:Divider() -- DIVIDERS | ELEMENTS STAND FOR THE TAB
