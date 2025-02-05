/**
* CREDITS
*
* Version: 2.8
* Coders: ToxicPinHead & PontonFSD
*
* New Feature:
*  + LiveSplit will now reset when the player returns to the beginning of Stage 1.
*  + New setting has been added. Enabling the setting will allow for a reset to occur if player has returned
*    to Stage 1 even while performing a 100% Kamon run.
*
* Version: 2.7
* Coder: PontonFSD
* 
* Fixed:
*  + Altered logic to the endOfRunBuffer by waiting for 60 ticks before Stage 9 Scoreboard.
*
* Version: 2.6
* Coder: PontonFSD
* 
* New Feature:
*  + Added support for Epic Games Store version.
*  + Left a print message in the case an unknown version is launched for easier addition later.
*
* Version: 2.5
* Coder: PontonFSD
*
* Fixed:
*  + Reset the endOfRunBuffer to 1.0f at the end of a run.
*
* To Do:
*  + Add support for the Epic Games Store version of Samurai Jack: Battle Through Time.
*
* Version: 2.4
* Coder: PontonFSD
* 
* Fixed:
*   + The final split would still sometimes trigger prematurely.
*       + Added new endOfRunBuffer variable to delay the final split so that the final IGT calculations finish.
*       + Added new deltaTime variable to help count down the endOfRunBuffer variable.
*
* Version: 2.3
* Coder: PontonFSD
*
* Fixed:
*   + Corrected logic for checking split on final stage for the IGT that calculates after the ending.
*
* Version: 2.2
* Coder: PontonFSD
*
* New Features:
*   + Added Mission In-game Timer tracking for the Mission Run categories.
*       + Start and Split will require a manual trigger.
*
* Version: 2.1
* Coder: PontonFSD
* 
* Fixed:
*   + Corrected logic in the gameTime that erroneously reported time, adding a second when it shouldn't have.
*
* Known Bugs:
*   - If Game Crashes or is exited, game time is reset to 0 and a split triggers when rebooted.
*
* Version: 2.0
* Coder: PontonFSD
* 
* New Features:
*   + Added stageSelected pointer to keep track of current stage.
*   + Added checkpointCount pointer to keep track of checkpoint progress.
*   + Added finalScoreboard pointer to keep track of the Final Stage's Scoreboard being displayed.
*   + Added kamon pointer to keep track of the current number of Kamon medals obtained.
*   + Added Kamon Run setting to splitter so that Kamon medal count is tracked. It will cause a
*     split when the player increases their Kamon count by one.
*   + Added a finalStageCompleted boolean to note when Stage 9 has been marked for completion.  
*   + Added Kamon Run setting logic to start function
*   + Added split function to cause automatic split triggers
*       + In a Kamon Run: When Kamon count in inventory increments.
*       + When on the Final stage's Scoreboard.
*       + When Stage ID increments.
*
* Fixed:
*   + Renamed gameTimer to secondsTimer for clarity.
*   + Adjusted pointer of milliTimer to be consistent with secondsTimer.
*   + Reset totalTime when starting a run via the start function
*   + Removed logic that led to a coding exception in the gameTime function.
*   + Added exit function to handle game time better when exiting the game.
*   + Adjusted logic for tracking time lost from death or restart checkpoint. Added a logic check for
*     millisecond differences.
*
* Known Bugs:
*   - If Game Crashes or is exited, game time is reset to 0 and a split triggers when rebooted.
*
* Version: 1.1
* Coder: Mysterion_06_
* 
* Fixed:
*   + Added milliTimer and updated logic for accurate reporting of game time.
*
* Version: 1.0
* Coder: Mysterion_06_
*
* Original release.
**/

state("SJGAME-Win64-Shipping", "Steam") 
{
    int secondsTimer: 0x3A2C610, 0x8, 0x710;
    float milliTimer: 0x3A2C610, 0x8, 0x714;
    int kamon: 0x03a2c610, 0x8, 0xe80, 0x68, 0x18, 0x30, 0x0, 0x44;
    int stageSelected: 0x03A2C610, 0x8, 0x164; // indexed
    int checkpointCount: 0x03A2C610, 0x8, 0x1B0;
    int stageScoreboard: 0x03A2C610, 0x8, 0x194; // indexed
    int missionSeconds: 0x03A2C610, 0x8, 0xD90;
    float missionMilliseconds: 0x03A2C610, 0x8, 0xD94;
    int missionScoreboard: 0x03A2C610, 0x8, 0x820, 0x548; // indexed
}

state("SJGAME-Win64-Shipping", "Epic")
{
    int secondsTimer: 0x39E0078, 0x8, 0x710;
    float milliTimer: 0x39E0078, 0x8, 0x714;
    int kamon: 0x39E0078, 0x8, 0xe80, 0x68, 0x18, 0x30, 0x0, 0x44;
    int stageSelected: 0x39E0078, 0x8, 0x164; // indexed
    int checkpointCount: 0x39E0078, 0x8, 0x1B0;
    int stageScoreboard: 0x39E0078, 0x8, 0x194; // indexed
    int missionSeconds: 0x39E0078, 0x8, 0xD90;
    float missionMilliseconds: 0x39E0078, 0x8, 0xD94;
    int missionScoreboard: 0x39E0078, 0x8, 0x820, 0x548; // indexed
}

startup { 
    settings.Add("kamonRun", false, "100% Kamon Run");
    settings.Add("resetOnKamonRun", false, "Allow for auto-reset when restarting Stage 1 during a 100% Kamon Run");
    settings.Add("missionRun", false, "Mission Run");
}

init {
    switch(modules.First().ModuleMemorySize) {
        case 65073152:
            version = "Epic";
            print("SJBTT: Using Epic Games Store version.");
            break;
        case 65617920:
            version = "Steam";
            print("SJBTT: Using Steam version.");
            break;
        default:
            print("SJBTT: Unknown version <" + modules.First().ModuleMemorySize + ">.");
            break;
    }

    vars.totalTime = 0;
    vars.finalStageCompleted = false;
    vars.videoLoaded = false;
    vars.startedMission = false;
    vars.endOfRunBuffer = 0; // All timings we've seen have been less than a second in the 0.3s range.
}

start {
    if (settings["missionRun"]) {
        vars.startedMission = false;
        return false;
    }

    vars.totalTime = 0;
    vars.finalStageCompleted = false;
    vars.endOfRunBuffer = 0;

    if(current.stageSelected == 0 && current.checkpointCount == 1 && current.secondsTimer == 0 && current.milliTimer > 0) {
        return settings["kamonRun"] ? current.kamon == 0 : true;
    }
}

split {
    if (settings["missionRun"]) return false;
    
    // If we're doing a Kamon Run, trigger a split when Kamon count increases
    if (settings["kamonRun"] && current.kamon == old.kamon + 1) {
        return true;
    }

    // With the exception of the final stage, split when player selects Next stage.
    if (current.stageSelected == old.stageSelected + 1) {
        return true;
    }

    // Check if we've completed the final stage
    if (!vars.finalStageCompleted) {
       // This flips true below at the same time that current.stageScoreboard flips to 8
       // However, this is probably more accurate due to stale data - in case player is repeating stage 8.
       vars.finalStageCompleted = old.stageSelected == 8 && current.stageSelected == 8 
           && 0 < old.checkpointCount && old.checkpointCount <= 7 && current.checkpointCount == 0;
       
       // If final stage was completed, there's a frame of time where current & old time match
       // before the IGT starts again then ends as cutscene loads.
       return false;
    }
    
    // Check if we're showing the final stage's scoreboard post credits.
    if (vars.finalStageCompleted) {
        // Check if cutscene has finished loading since recognizing scoreboard loaded.
        vars.videoLoaded = current.milliTimer == old.milliTimer;

        if (vars.videoLoaded) {
            // Add a tick count to the endOfRunBuffer, and delay a full second to make sure to capture the end load.
            vars.endOfRunBuffer++;
            if (vars.endOfRunBuffer < 60) return false;
            
            // Reset flags so that it doesn't split every run until end...
            vars.finalStageCompleted = false;
            vars.videoLoaded = false;
            vars.endOfRunBuffer = 0;
            
            // if in a kamonRun we don't want to end the run repeatedly should a kamon have been missed.
            // The player would be required to defeat Aku again in order to end the run (to show the secret ending).
            return settings["kamonRun"] ? current.kamon == 50 : true;
        }
    }
}

isLoading {
    return true;
}

gameTime {
    if (settings["missionRun"]) {
        // Try to avoid carrying over what's in memory of last run attempt...
        if (!vars.startedMission) {
            if (current.missionSeconds == 0 && old.missionSeconds == 0 && current.missionMilliseconds == 0 && old.missionMilliseconds == 0) {
                vars.startedMission = true;
                vars.totalTime = 0;
            }
            return TimeSpan.FromSeconds(0.0f);
        }

        // Floor the milliseconds like the game does
        current.missionMilliseconds = Math.Floor(current.missionMilliseconds * 100) / 100;

        // Carry over time if restarting or selecting new mission
        if (current.missionSeconds < old.missionSeconds) {
            vars.totalTime += old.missionSeconds - current.missionSeconds + old.missionMilliseconds - current.missionMilliseconds;
        }

        return TimeSpan.FromSeconds(vars.totalTime + current.missionSeconds + current.missionMilliseconds);
    }

    // Calculate the 0.## in the format the game does.
    current.milliTimer = Math.Floor(current.milliTimer * 100) / 100;

    // Reloaded to previous checkpoint, so add time lost since that checkpoint.
    if (current.secondsTimer < old.secondsTimer) {
        vars.totalTime += old.secondsTimer - current.secondsTimer + old.milliTimer - current.milliTimer;
    }

    return TimeSpan.FromSeconds(vars.totalTime + current.secondsTimer + current.milliTimer);
}

reset
{
    if (old.checkpointCount == 0 && current.checkpointCount == 1 && current.stageSelected == 0)// resets if starting a new aku mines, so no mission mode resets
    {
        return !settings["kamonRun] || (settings["kamonRun"] && settings["resetOnKamonRun"]);
    }
}

exit {
    timer.IsGameTimePaused = true;
}
