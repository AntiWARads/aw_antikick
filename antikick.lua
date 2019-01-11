-- Anti vote-kick by ShadyRetard

local kick_command_id = 1;
local kick_potential_votes = 0;
local kick_yes_voters = 0;
local kick_getting_kicked = false;
local kick_last_command_time = globals.CurTime();
local ANTIKICK_CB = gui.Checkbox(gui.Reference("MISC", "AUTOMATION", "Other"), "ANTIKICK_CB", "Enable Anti Vote-kick", false);
local ANTIKICK_VOTE_THRESHOLD = gui.Slider(gui.Reference("MISC", "AUTOMATION", "Other"), "ANTIKICK_VOTE_THRESHOLD", "Scramble threshold %:", 80, 1, 100);

function kickEventHandler(event)
    local self_pid = client.GetLocalPlayerIndex();
    local self = entities.GetLocalPlayer();

    local active_map_name = engine.GetMapName();

    if (ANTIKICK_CB:GetValue() == false or self_pid == nil or self == nil or active_map_name == nil) then
        return;
    end

    if (event:GetName() == "vote_changed") then
        kick_potential_votes = event:GetInt("potentialVotes");
        return;
    end

    if (event:GetName() == "vote_cast") then
        local vote_option = event:GetInt("vote_option");
        local voter_eid = event:GetInt("entityid");

        if (self_pid ~= voter_eid and vote_option == 0) then
            kick_yes_voters = kick_yes_voters + 1;
        end

        if (self_pid == voter_eid and vote_option == 1) then
            kick_getting_kicked = true;

            -- We're voting NO, which means somebody else already voted yes
            kick_yes_voters = 1;
        end

        if (kick_getting_kicked == false) then
            return;
        end

        local kick_percentage = ((kick_yes_voters - 1) / (kick_potential_votes / 2) * 100);

        if (kick_yes_voters > 0 and kick_potential_votes > 0 and kick_percentage >= ANTIKICK_VOTE_THRESHOLD:GetValue() and globals.CurTime() - kick_last_command_time > 90) then
            if (kick_command_id == 1) then
                client.Command("callvote SwapTeams");
                kick_command_id = 2;
            elseif (kick_command_id == 2) then
                client.Command("callvote ScrambleTeams");
                kick_command_id = 3;
            elseif (kick_command_id == 3) then
                client.Command("callvote ChangeLevel " .. active_map_name);
                kick_command_id = 1;
            end

            kick_last_command_time = globals.CurTime();
        end
    end

end

client.AllowListener("vote_changed");
client.AllowListener("vote_cast");
callbacks.Register("FireGameEvent", "antikick_event", kickEventHandler);