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
		bar.setGraphicSize(track.width, 14);
		bar.updateHitbox();
		bar.x = track.x;
		bar.y = track.y;
		bar.origin.set(0, 0);
		bar.scale.x = 0;
		add(bar);

		label = new FlxText(0, track.y - 34, Std.int(FlxG.width), "Loading...");
		label.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFFFFFF, "center");
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
			}, function() {
				FlxG.switchState(next());
			});
		}

		var p = loaded / total;
		if (p > 1) p = 1;
		bar.scale.x = p;
		label.text = "Loading... " + Std.int(p * 100) + "%";
	}
}
#end
