package;

import openfl.net.FileFilter;
import flixel.addons.ui.FlxUIButton;
import flixel.input.FlxInput;
import lime.tools.Platform;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;

using StringTools;

class CharacterEditorState extends MusicBeatState
{
    var _file:FileReference;

    var UI_box:FlxUITabMenu;

    var bpmTxt:FlxText;

    var char:Character;

    var charArray:Array<String> = [];

    var textData:String;

    var charName:String;

    var isPlayer:Bool = false;

    override function create() {

        var tabs = [
			{name: "Character", label: 'Character'},
			{name: "Animations", label: 'Animations'},
			{name: "Offsets", label: 'Offsets'},
			{name: "Options", label: 'Options'}
		];

        char = new Character(0, 0, "bf", isPlayer);

        FlxG.mouse.visible = true;

        add(char);

        bpmTxt = new FlxText(1000, 50, 0, "F1 to kys", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

        UI_box = new FlxUITabMenu(null, tabs, true);

        UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;
		add(UI_box);

        addCharacterUI();
        addAnimationsUI();
        addOffsetsUI();
        addOptionsUI();

        super.create();

    }

    var spriteTB:FlxUIInputText;
    var flipXCBC:FlxUICheckBox;
    var flipYCBC:FlxUICheckBox;
    var pixelCB:FlxUICheckBox;

	function addCharacterUI():Void
    {
        var tab_group_character = new FlxUI(null, UI_box);
        tab_group_character.name = 'Character';

        var loadCharButton:FlxUIButton = new FlxUIButton(10,10,"Load Character", function() {
            loadCharacterTxt();
        });

        var saveCharButton:FlxUIButton = new FlxUIButton(10,30,"Save Character", function() {
            saveCharacterTxt();
        });

        var newCharButton:FlxUIButton = new FlxUIButton(10,50,"New Character", function() {
            newCharacterTxt();
        });

        spriteTB = new FlxUIInputText(10,70,100);

        var updateSpriteButton:FlxUIButton = new FlxUIButton(120,70,"Update Sprite", function() {
            var addedSpriteData = "sprite::"+spriteTB.text;
            for (i in 0...charArray.length) {
                var line:Array<String> = charArray[i].trim().split("::");
                if (line[0] == "sprite") {
                    charArray[i] = addedSpriteData.trim();
                }
            }
            //trace(charArray);
            updateAnimsTab(true);
        });

        flipXCBC = new FlxUICheckBox(10,90,null,null,"FlipX");
        flipYCBC = new FlxUICheckBox(10,110,null,null,"FlipY");
        pixelCB = new FlxUICheckBox(10,130,null,null, "Pixel");

        flipXCBC.callback = function() {
            if (flipXCBC.checked) {
                charArray.push("flipX");
            } else {
                charArray.remove("flipX");
            }

            updateAnimsTab(true);
        }

        flipYCBC.callback = function() {
            if (flipYCBC.checked) {
                charArray.push("flipY");
            } else {
                charArray.remove("flipY");
            }

            updateAnimsTab(true);
        }

        pixelCB.callback = function() {
            if (pixelCB.checked) {
                charArray.push("pixel");
            } else {
                charArray.remove("pixel");
            }

            updateAnimsTab(true);
        }

        tab_group_character.add(loadCharButton);
        tab_group_character.add(saveCharButton);
        tab_group_character.add(newCharButton);

        tab_group_character.add(spriteTB);
        tab_group_character.add(updateSpriteButton);
        tab_group_character.add(flipXCBC);
        tab_group_character.add(flipYCBC);
        tab_group_character.add(pixelCB);

        UI_box.addGroup(tab_group_character);
    }

    var animsDropdown:FlxUIDropDownMenu;
    var animsList:Array<String> = [""];

    function addAnimationsUI():Void
    {
        var tab_group_animations = new FlxUI(null, UI_box);
        tab_group_animations.name = 'Animations';
        
        var animNameTB:FlxUIInputText = new FlxUIInputText(10,10,180);
        var animXmlTB:FlxUIInputText = new FlxUIInputText(10,30,180);
        
        var fpsNumStep:FlxUINumericStepper = new FlxUINumericStepper(10,50,1,24,0,999);

        var loopCB:FlxUICheckBox = new FlxUICheckBox(10,70,null,null,"Loop");
        var flipXCB:FlxUICheckBox = new FlxUICheckBox(10,90,null,null,"FlipX");
        var flipYCB:FlxUICheckBox = new FlxUICheckBox(10,110,null,null,"FlipY");

        var playAnimButton:FlxUIButton = new FlxUIButton(100, 75, "Play", () -> {
            char.animation.curAnim.play(true);
        });

        var addAnimButton:FlxUIButton = new FlxUIButton(10,130,"Add Animation", function() {
            var addedAnimData = "anim::"+animNameTB.text+"::"+animXmlTB.text+"::"+Std.string(fpsNumStep.value)+"::"+Std.string(loopCB.checked)+"::"+Std.string(flipXCB.checked)+"::"+Std.string(flipYCB.checked);
            if (!animsList.contains(animNameTB.text.trim()))
                charArray.push(addedAnimData);
            else
            {
                for (i in 0...charArray.length) {
                    var line:Array<String> = charArray[i].trim().split("::");
                    if (line[0] == "anim" && line[1] == animNameTB.text.trim()) {
                        charArray[i] = addedAnimData;
                    }
                }
            }
            //trace(charArray);
            updateAnimsTab(true);
            char.playAnim(animsDropdown.selectedLabel.trim(),true);
        });

        animsDropdown = new FlxUIDropDownMenu(100, 50, FlxUIDropDownMenu.makeStrIdLabelArray(animsList, true), function(anim:String) {
            for (i in 0...charArray.length) {
                var line:Array<String> = charArray[i].trim().split("::");
                if (line[0] == "anim" && line[1] == anim.trim()) {
                    animNameTB.text = line[1].trim();
                    animXmlTB.text = line[2].trim();
                    fpsNumStep.value = Std.parseFloat(line[3].trim());
                    if (line[4] == "true")
                        loopCB.checked = true;
                    else
                        loopCB.checked = false;
                    if (line[5] == "true")
                        flipXCB.checked = true;
                    else
                        flipXCB.checked = false;
                    if (line[6] == "true")
                        flipYCB.checked = true;
                    else
                        flipYCB.checked = false;
                }
            }

            char.playAnim(anim, true);
        });

        animsDropdown.dropDirection = FlxUIDropDownMenuDropDirection.Down;

        tab_group_animations.add(animNameTB);
        tab_group_animations.add(animXmlTB);
        tab_group_animations.add(fpsNumStep);
        tab_group_animations.add(loopCB);
        tab_group_animations.add(flipXCB);
        tab_group_animations.add(flipYCB);
        tab_group_animations.add(addAnimButton);
        tab_group_animations.add(playAnimButton);
        tab_group_animations.add(animsDropdown);

        UI_box.addGroup(tab_group_animations);
    }

    var offsetAnimsDropdown:FlxUIDropDownMenu;

    function addOffsetsUI():Void
    {
        var tab_group_offsets = new FlxUI(null, UI_box);
        tab_group_offsets.name = 'Offsets';

        var offsetStepperX:FlxUINumericStepper = new FlxUINumericStepper(10,10,1,0,-1000,1000);
        var offsetStepperY:FlxUINumericStepper = new FlxUINumericStepper(10,30,1,0,-1000,1000);

        offsetAnimsDropdown = new FlxUIDropDownMenu(100, 10, FlxUIDropDownMenu.makeStrIdLabelArray(animsList, true), function(anim:String) {
            var offsetExists = false;
            for (i in 0...charArray.length) {
                var line:Array<String> = charArray[i].trim().split("::");
                if (line[0] == "offset" && line[1] == anim.trim()) {
                    offsetStepperX.value = Std.parseFloat(line[2].trim());
                    offsetStepperY.value = Std.parseFloat(line[3].trim());
                    offsetExists = true;
                }
            }

            if (!offsetExists) {
                offsetStepperX.value = 0;
                offsetStepperY.value = 0;
            }

            char.playAnim(anim, true);
        });
        
        offsetAnimsDropdown.dropDirection = FlxUIDropDownMenuDropDirection.Down;

        var addOffsetButton:FlxUIButton = new FlxUIButton(10,50,"Add Offset", function() {
            var addedOffsetData = "offset::"+offsetAnimsDropdown.selectedLabel.trim()+"::"+Std.string(offsetStepperX.value)+"::"+Std.string(offsetStepperY.value);
            var offsetExists = false;
            
            for (i in 0...charArray.length) {
                var line:Array<String> = charArray[i].trim().split("::");
                if (line[0] == "offset" && line[1] == offsetAnimsDropdown.selectedLabel.trim()) {
                    charArray[i] = addedOffsetData;
                    offsetExists = true;
                }
            }
            
            if (!offsetExists)
                charArray.push(addedOffsetData);

            //trace(charArray);
            updateAnimsTab(true, false);
            char.playAnim(offsetAnimsDropdown.selectedLabel.trim(), true);
        });

        //var animNameTB:FlxUIInputText = new FlxUIInputText(10,10,180);

        tab_group_offsets.add(addOffsetButton);
        tab_group_offsets.add(offsetAnimsDropdown);
        //tab_group_offsets.add(animNameTB);
        tab_group_offsets.add(offsetStepperX);
        tab_group_offsets.add(offsetStepperY);

        UI_box.addGroup(tab_group_offsets);
    }

    function addOptionsUI():Void
    {
        var tab_group_options = new FlxUI(null, UI_box);
        tab_group_options.name = 'Options';

        var isPlayerCB:FlxUICheckBox = new FlxUICheckBox(10,10,null,null,"isPlayer");
        isPlayerCB.callback = function() {
            isPlayer = !isPlayer;
            updateAnimsTab(true);
        }

        tab_group_options.add(isPlayerCB);

        UI_box.addGroup(tab_group_options);
    }

    override function update(elapsed:Float) {

        if (FlxG.keys.justPressed.F1)
            FlxG.switchState(new MainMenuState());

        super.update(elapsed);
    }

    function newCharacterTxt() {
        if (_file != null) {
            _file = new FileReference();
        }

        charArray = ["sprite::BOYFRIEND","icon::0::1","anim::idle::BF idle dance::24","anim::singUP::BF idle dance::24","anim::singDOWN::BF idle dance::24","anim::singLEFT::BF idle dance::24","anim::singRIGHT::BF idle dance::24"];
        charName = "bf";
        updateAnimsTab(true);
    }

    function loadCharacterTxt() {
        _file = new FileReference();
        var txtFilter = new FileFilter("Character Text File", "*.txt");
        _file.addEventListener(Event.SELECT, onBrowseComplete);
        _file.browse([txtFilter]);
    }

    function saveCharacterTxt() {
        var saveData:String = "";
        for (i in 0...charArray.length) {
            saveData = saveData + charArray[i].trim() + "\n";
        }
        _file = new FileReference();
        _file.addEventListener(Event.COMPLETE, onSaveComplete);
        _file.save(saveData, charName.trim()+".txt");
    }

    function onSaveComplete(_) {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file = null;
        trace("SUCCESSFULLY SAVED CHARACTER");
    }

    function onBrowseComplete(_):Void {
        _file.load();
        textData = _file.data.toString();
        charArray = textData.trim().split("\n");
        charName = _file.name.replace(".txt","").trim();
        char.destroy();
        char = new Character(0,0, charName, isPlayer);
        add(char);
        updateAnimsTab();
        _file.removeEventListener(Event.SELECT, onBrowseComplete);
    }

    function loadAnims() {
        animsList = [];
        // char.animation.destroyAnimations();
        flipXCBC.checked = false;
        flipYCBC.checked = false;
        pixelCB.checked = false;

        for (i in 0...charArray.length) {
            var line:Array<String> = charArray[i].trim().split("::");

            if (line[0] == "flipX") {
                flipXCBC.checked = true;
            }

            if (line[0] == "flipY") {
                flipYCBC.checked = true;
            }

            if (line[0] == "pixel") {
                pixelCB.checked = true;
            }

            if (line[0] == "sprite") {
                spriteTB.text == line[1];
            }

            if (line[0] == "anim") {
                animsList.push(line[1]);
            }
        }
    }

    function updateAnimsTab(?reloadChar:Bool = false, ?updateDropdowns = true) {
        for (i in 0...charArray.length) {
            charArray[i] = charArray[i].replace("\n", "").trim();
        }
        if (reloadChar) {
            char.destroy();
            char = new Character(0, 0, charName, isPlayer, charArray);
            add(char);
        }
        loadAnims();

        if (updateDropdowns) {
            animsDropdown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(animsList));
            offsetAnimsDropdown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(animsList));
        }
    }
}