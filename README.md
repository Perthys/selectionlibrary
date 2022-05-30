# selectionlibrary

```lua
local SelectionLibrary = loadstring(game:HttpGet('https://raw.githubusercontent.com/Perthys/selectionlibrary/main/main.lua'))();
local Players = game:GetService("Players");

local Handler = SelectionLibrary.Init();

local function FindPlayer(Starting, Levels)
    local CurrentInstance = Starting;
    
    for i = 1, Levels do
        CurrentInstance = CurrentInstance["Parent"];
        
        if CurrentInstance then
            local Player = Players:GetPlayerFromCharacter(CurrentInstance) 
            
            if Player then
                return Player
            end
        end
    end
end

local PlayerHandler = Handler:AddSelectionHandler("PlayerHandler", {
    ["Handler"] = function(Hit)
        local Player = FindPlayer(Hit, 2)
        
        if Player then
            return Player.Character;
        end
    end;
    ["Properties"] = {
        ["FillTransparency"] = 1;
        ["OutlineColor"] = Color3.fromRGB(50, 168, 82)
    };
    ["Activated"] = function(ActionName, InputState, InputObject)
		 print("Activated On"..SelectionLibrary.Target.Name)
    end;
})

```
