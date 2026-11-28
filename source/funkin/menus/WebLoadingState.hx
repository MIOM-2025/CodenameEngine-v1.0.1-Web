package funkin.menus;

#if web
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import funkin.backend.assets.Paths;
import funkin.backend.assets.WebLoader;

/**
	Shown while the next state's assets are fetched. A browser has to be given the
	chance to wait, so the switch only happens once the bar is full.
**/
@:dox(hide)
class WebLoadingState extends FlxState
{
	var prefixes:Array<String>;
	var next:Void->FlxState;
	var bar:FlxSprite;
	var label:FlxText;
	var total:Int = 1;
	var found:Int = -1;
	var loaded:Int = 0;
	var started:Bool = false;

	public function new(prefixes:Array<String>, next:Void->FlxState)
	{
		super();
		this.prefixes = prefixes;
		this.next = next;
	}

	override function create()
	{
		super.create();

		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF101010);
		add(bg);

		var track = new FlxSprite().makeGraphic(1, 1, 0xFF2A2A2A);
		track.setGraphicSize(Std.int(FlxG.width * 0.8), 14);
		track.updateHitbox();
		track.x = (FlxG.width - track.width) * 0.5;
		track.y = FlxG.height * 0.5;
		add(track);

		bar = new FlxSprite().makeGraphic(1, 1, 0xFF3CE03C);
		bar.setGraphicSize(Std.int(track.width), 14);
		bar.updateHitbox();
		bar.x = track.x;
		bar.y = track.y;
		bar.origin.set(0, 0);
		bar.scale.x = 0;
		add(bar);

		label = new FlxText(0, track.y - 34, Std.int(FlxG.width), "Loading...");
		var face = Paths.font("vcr.ttf");
		if (face != null)
			label.setFormat(face, 20, 0xFFFFFFFF, "center");
		else
			label.setFormat(null, 20, 0xFFFFFFFF, "center");
		add(label);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!started)
		{
			started = true;
			WebLoader.preload(prefixes, function(l:Int, t:Int) {
				loaded = l;
				total = t <= 0 ? 1 : t;
				found = t;
			}, function() {
				// a browser cannot wait inside a state, so a run that found nothing
				// is held for a moment to make that visible instead of flickering past
				if (found <= 0)
				{
					label.text = "nothing to load for: " + prefixes.join(", ");
					haxe.Timer.delay(function() FlxG.switchState(next()), 1500);
				}
				else FlxG.switchState(next());
			});
		}

		var p = loaded / total;
		if (p > 1) p = 1;
		bar.scale.x = p;
		label.text = "Loading " + loaded + " / " + found + "   " + Std.int(p * 100) + "%";
	}
}
#end
