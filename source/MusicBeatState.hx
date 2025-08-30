package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
#if mobile
import flixel.FlxCamera;
import flixel.input.actions.FlxActionInput;
import mobile.FlxVirtualPad;
import mobile.HitBox;
import mobile.Mobilecontrols;
#end

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;
		
	#if mobile
	var vPad:FlxVirtualPad;
	var mcontrols:Mobilecontrols;

	var trackedinputs:Array<FlxActionInput> = [];

	public function addVPad(?DPad:FlxDPadMode, ?Action:FlxActionMode) {
		vPad = new FlxVirtualPad(DPad, Action);
		vPad.alpha = 0.75;
		add(vPad);
		controls.setVirtualPad(vPad, DPad, Action);
		trackedinputs = controls.trackedinputs;
		controls.trackedinputs = [];
	}
	
	public function addVPadCamera() {
	  var camcontrol = new FlxCamera(); 
    FlxG.cameras.add(camcontrol, false); 
    camcontrol.bgColor.alpha = 0; 
    vPad.cameras = [camcontrol];
	}

	public function removeVPad() {
	  if (vPad != null) {
	    controls.removeFlxInput(trackedinputs);
	    remove(vPad);
	  }
	}
	
	public function addMControls()
	{
	  mcontrols = new Mobilecontrols();
	  switch (mcontrols.mode.toLowerCase())
	  {
	    case 'vpad_right' | 'vpad_left' | 'vpad_custom':
	      controls.setVirtualPad(mcontrols.vPad, FULL, NONE);
	    case 'hitbox':
	      controls.setHitBox(mcontrols.hitbox);
	    default:
	  }

	  trackedinputs = controls.trackedinputs;
	  controls.trackedinputs = [];

	  var camcontrol = new FlxCamera();
	  FlxG.cameras.add(camcontrol, false);
	  camcontrol.bgColor.alpha = 0;
	  mcontrols.cameras = [camcontrol];

	  mcontrols.visible = false;
	  
	  add(mcontrols);
	}

	public function removeMControls()
	{
	  if (mcontrols != null) {
	    controls.removeFlxInput(trackedinputs);
	    remove(mcontrols);
	  }
	}
	#end
	
	override function destroy()
	{
	  #if mobile
	  controls.removeFlxInput(trackedinputs);
	  #end

	  super.destroy();
	  
	  #if mobile
	  if (vPad != null) {
	    vPad.destroy();
	    vPad = null;
	  }
	  
	  if (mcontrols != null) {
	    mcontrols.destroy();
	    mcontrols = null;
	  }
	  #end
	}

	override function create()
	{
		// if (transIn != null)
		// 	trace('reg ' + transIn.region);

		super.create();
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
}
