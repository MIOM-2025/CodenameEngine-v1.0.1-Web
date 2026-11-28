package funkin.backend.assets;

#if web
import lime.utils.AssetLibrary;
import lime.utils.AssetType;

/**
	Browsers cannot read a file on demand: a fetch and an image decode both finish
	later, while the engine asks for an asset at the moment it needs it.

	The one place where waiting is allowed is before a state switch. This walks the
	asset table and loads the folders the next state is going to use, so by the time
	that state runs everything it asks for is already in memory.
**/
@:dox(hide)
class WebLoader
{
	public static function preload(prefixes:Array<String>, done:Void->Void):Void
	{
		var lib:AssetLibrary = null;
		try
		{
			lib = lime.utils.Assets.getLibrary("assets");
		}
		catch (e:Dynamic) {}

		if (lib == null)
		{
			done();
			return;
		}

		var pending:Int = 1;
		var finished:Bool = false;

		function tick():Void
		{
			pending--;
			if (pending <= 0 && !finished)
			{
				finished = true;
				done();
			}
		}

		function strip(id:String):String
			return id.substr(0, 7) == "assets/" ? id.substr(7) : id;

		function wanted(id:String):Bool
		{
			if (id == null) return false;
			var clean = strip(id);
			for (p in prefixes)
				if (clean.substr(0, strip(p).length) == strip(p)) return true;
			return false;
		}

		function track(fut:Dynamic):Void
		{
			if (fut == null) return;
			pending++;
			try
			{
				fut.onComplete(function(_) tick());
				fut.onError(function(_) tick());
			}
			catch (e:Dynamic) tick();
		}

		for (id in lib.list(AssetType.IMAGE))
			if (wanted(id)) track(lib.loadImage(id));
		for (id in lib.list(AssetType.FONT))
			if (wanted(id)) track(lib.loadFont(id));
		for (id in lib.list(AssetType.TEXT))
			if (wanted(id)) track(lib.loadText(id));
		for (id in lib.list(AssetType.BINARY))
			if (wanted(id)) track(lib.loadBytes(id));
		for (id in lib.list(AssetType.MUSIC))
			if (wanted(id)) track(lib.loadAudioBuffer(id));
		for (id in lib.list(AssetType.SOUND))
			if (wanted(id)) track(lib.loadAudioBuffer(id));

		tick();
	}
}
#end
