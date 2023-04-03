/**
* CREDITS
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

state("SJGAME-Win64-Shipping") 
{
    int secondsTimer: 0x3A2C610, 0x8, 0x710;
    float milliTimer: 0x3A2C610, 0x8, 0x714;
    int kamon: 0x03a2c610, 0x8, 0xe80, 0x68, 0x18, 0x30, 0x0, 0x44;
    int stageSelected: 0x03A2C610, 0x8, 0x164; // indexed
    int checkpointCount: 0x03A2C610, 0x8, 0x1B0;
    int finalScoreboard: 0x03AE5CF0, 0x8, 0x20, 0xB8, 0x268, 0x10, 0x2A0, 0x20, 0x28, 0xE0, 0x1D8;
}

startup { 
    settings.Add("kamonRun", false, "100% Kamon Run");
}

init {
    vars.totalTime = 0;
    vars.finalStageCompleted = false;
}

start {
    vars.totalTime = 0;
    vars.finalStageCompleted = false;
	
    if(current.stageSelected == 0 && current.checkpointCount == 1 && current.secondsTimer == 0 && current.milliTimer > 0) {
        return settings["kamonRun"] ? current.kamon == 0 : true;
    }
}

split {
    // If we're doing a Kamon Run, trigger a split when Kamon count increases
    if (settings["kamonRun"] && current.kamon == old.kamon + 1) {
        return true;
    }

    // Check if we've completed the final stage
    if (!vars.finalStageCompleted) {
        vars.finalStageCompleted = old.stageSelected == 8 && current.stageSelected == 8 
            && 0 < old.checkpointCount && old.checkpointCount <= 7 && current.checkpointCount == 0;
    }
	
    // Check if we're showing the final stage's scoreboard post credits.
    if (vars.finalStageCompleted && current.finalScoreboard == 1) {
        // Reset finalStageCompleted flag so that it doesn't split every run until end...
        vars.finalStageCompleted = false;
		
        // if in a kamonRun we don't want to end the run repeatedly should a kamon have been missed.
        // The player would be required to defeat Aku again in order to end the run (to show the secret ending).
        return settings["kamonRun"] ? current.kamon == 50 : true;
    }
	
    // With the exception of the final stage, split when player selects Next stage.
    return current.stageSelected == old.stageSelected + 1;
}

isLoading {
    return true;
}

gameTime {
    // Calculate the 0.## in the format the game does.
    current.milliTimer = Math.Floor(current.milliTimer * 100) / 100;
	
    // Reloaded to previous checkpoint, so add time lost since that checkpoint.
    if (current.secondsTimer < old.secondsTimer || (current.secondsTimer == old.secondsTimer && current.milliTimer < old.milliTimer)) {
        vars.totalTime += old.secondsTimer - current.secondsTimer + old.milliTimer - current.milliTimer;
    }
	
    return TimeSpan.FromSeconds(vars.totalTime + current.secondsTimer + current.milliTimer);
}

exit {
    timer.IsGameTimePaused = true;
}
