package funkin.backend.assets;

#if web
import lime.utils.AssetLibrary;
import lime.utils.AssetType;

/**
	Browsers cannot read a file on demand: a fetch and an image decode both finish
	later, while the engine asks for an asset at the moment it needs it.

	The one place where waiting is allowed is before a state switch. This walks the
	asset table and loads the folders the next state is going to use, reporting
	progress so the caller can show a bar.
**/
@:dox(hide)
class WebLoader
{
	public static function preload(prefixes:Array<String>, onProgress:Int->Int->Void, done:Void->Void):Void
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

		var items:Array<{id:String, type:String}> = [];
		for (type in [AssetType.IMAGE, AssetType.FONT, AssetType.TEXT, AssetType.BINARY, AssetType.MUSIC, AssetType.SOUND])
			for (id in lib.list(type))
				if (wanted(id)) items.push({id: id, type: type});

		var ids = items;

		var total:Int = ids.length;
		if (total == 0)
		{
			onProgress(1, 1);
			done();
			return;
		}

		var loaded:Int = 0;
		var finished:Bool = false;

		function tick():Void
		{
			loaded++;
			onProgress(loaded, total);
			if (loaded >= total && !finished)
			{
				finished = true;
				done();
			}
		}

		function track(fut:Dynamic):Void
		{
			if (fut == null)
			{
				tick();
				return;
			}
			try
			{
				fut.onComplete(function(_) tick());
				fut.onError(function(_) tick());
			}
			catch (e:Dynamic) tick();
		}

		onProgress(0, total);

		for (item in ids)
		{
			switch (item.type)
			{
				case AssetType.IMAGE: track(lib.loadImage(item.id));
				case AssetType.FONT: track(lib.loadFont(item.id));
				case AssetType.TEXT: track(lib.loadText(item.id));
				case AssetType.BINARY: track(lib.loadBytes(item.id));
				default: track(lib.loadAudioBuffer(item.id));
			}
		}
	}
}
#end
