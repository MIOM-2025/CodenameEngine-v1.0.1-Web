package funkin.backend.assets;

#if TRANSLATIONS_SUPPORT
import funkin.backend.assets.TranslatedAssetLibrary;
#end
import funkin.backend.assets.IModsAssetLibrary;
import lime.utils.AssetLibrary;

class AssetsLibraryList extends AssetLibrary {
	public var libraries:Array<AssetLibrary> = [];

	@:allow(funkin.backend.system.Main)
	@:allow(funkin.backend.system.MainState)
	private var __defaultLibraries:Array<AssetLibrary> = [];
	public var base:AssetLibrary;

	#if TRANSLATIONS_SUPPORT
	public var transLib:TranslatedAssetLibrary;
	#end

	public function removeLibrary(lib:AssetLibrary) {
		if (lib != null) {
			libraries.remove(lib);
			#if TRANSLATIONS_SUPPORT
			// TODO: improve this code
			for(k=>l in libraries) {
				if(l == null) continue;
				if(l is TranslatedAssetLibrary) {
					var tlib = cast(l, TranslatedAssetLibrary);
					var lib:Dynamic = lib;
					if(tlib.forLibrary == lib) {
						libraries.remove(tlib);
						break;
					}
				}
			}
			#end
		}
		return lib;
	}
	public function existsSpecific(id:String, type:String, source:AssetSource = BOTH) {
		if (!id.startsWith("assets/") && existsSpecific('assets/$id', type, source))
			return true;
		for(k=>l in libraries) {
			if (shouldSkipLib(l, source)) continue;
			if (l.exists(id, type)) {
				return true;
			}
		}
		return false;
	}
	public override inline function exists(id:String, type:String):Bool
		return existsSpecific(id, type, BOTH);

	public function getSpecificPath(id:String, source:AssetSource = BOTH) {
		for(k=>e in libraries) {
			if (shouldSkipLib(e, source)) continue;

			@:privateAccess
			if (e.exists(id, e.types.get(id))) {
				var path = e.getPath(id);
				if (path != null)
					return path;
			}
		}
		return null;
	}

	public override inline function getPath(id:String)
		return getSpecificPath(id, BOTH);

	public function getFiles(folder:String, source:AssetSource = BOTH):Array<String> {
		var content:Array<String> = [];
		for(k=>l in libraries) {
			if (shouldSkipLib(l, source)) continue;

			l = getCleanLibrary(l);

			// TODO: do base folder scanning
			#if MOD_SUPPORT
			if (l is IModsAssetLibrary) {
				var lib = cast(l, IModsAssetLibrary);
				for(e in lib.getFiles(folder))
					content.pushOnce(e);
			}
			#elseif web
			for (e in __cneList(l, folder, true))
				content.pushOnce(e);
			#end
		}
		return content;
	}

	public function getFolders(folder:String, source:AssetSource = BOTH):Array<String> {
		var content:Array<String> = [];
		for(k=>l in libraries) {
			if (shouldSkipLib(l, source)) continue;

			l = getCleanLibrary(l);

			// TODO: do base folder scanning
			#if MOD_SUPPORT
			if (l is IModsAssetLibrary) {
				var lib = cast(l, IModsAssetLibrary);
				for(e in lib.getFolders(folder))
					content.pushOnce(e);
			}
			#elseif web
			for (e in __cneList(l, folder, false))
				content.pushOnce(e);
			#end
		}
		return content;
	}

	#if web
	/**
		Browsers cannot list a directory, which is how folder contents are normally
		discovered. The asset library already carries a table of every id it knows
		about, so the directory structure is derived from that table instead of
		from the filesystem.
	**/
	@:noCompletion private function __cneList(l:Dynamic, folder:String, files:Bool):Array<String>
	{
		var out:Array<String> = [];
		if (l == null || folder == null) return out;

		// ids in the table are the paths inside the library and may or may not carry
		// the "assets/" prefix the caller uses, so both spellings are tried
		var prefixes:Array<String> = [];
		var bare = folder;
		if (bare.substr(0, 7) == "assets/") bare = bare.substr(7);
		prefixes.push(bare);
		if (bare != folder)
			prefixes.push(folder);
		else
			prefixes.push("assets/" + folder);

		for (i in 0...prefixes.length)
		{
			var prefix = prefixes[i];
			if (prefix.length > 0 && prefix.charAt(prefix.length - 1) != '/')
				prefix += '/';
			prefixes[i] = prefix;
		}

		// the debug info panel walks the tree while the game boots; an exception
		// there would take the whole panel down with it
		var ids:Null<Array<String>> = null;
		try
		{
			ids = cast l.list(null);
		}
		catch (e:Dynamic)
		{
			return out;
		}
		if (ids == null) return out;

		for (id in ids)
		{
			if (id == null) continue;

			var rest:Null<String> = null;
			for (prefix in prefixes)
			{
				if (id.length > prefix.length && id.substr(0, prefix.length) == prefix)
				{
					rest = id.substr(prefix.length);
					break;
				}
			}
			if (rest == null) continue;

			var slash = rest.indexOf('/');

			if (files)
			{
				if (slash < 0) out.pushOnce(rest);
			}
			else if (slash >= 0)
			{
				out.pushOnce(rest.substr(0, slash));
			}
		}
		return out;
	}
	#end

	public function getSpecificAsset(id:String, type:String, source:AssetSource = BOTH):Dynamic {
		try {
			if (!id.startsWith("assets/")) {
				var ass = getSpecificAsset('assets/$id', type, source);
				if (ass != null) {
					return ass;
				}
			}
			for(k=>l in libraries) {
				if (shouldSkipLib(l, source)) continue;

				@:privateAccess
				if (l.exists(id, l.types.get(id))) {
					var asset = l.getAsset(id, type);
					if (asset != null) {
						return asset;
					}
				}
			}
			return null;
		} catch(e) {
			// TODO: trace the error
			throw e;
		}
		return null;
	}

	private function shouldSkipLib(lib:AssetLibrary, source:AssetSource) {
		if (source == BOTH || lib.tag == BOTH) return false;
		return source != lib.tag;
	}
	public override inline function getAsset(id:String, type:String):Dynamic
		return getSpecificAsset(id, type, BOTH);

	public override function isLocal(id:String, type:String) {
		return true;
	}

	public function new(?base:AssetLibrary) {
		super();
		if (base == null) (this.base = Assets.getLibrary("default")).tag = SOURCE;
		else this.base = base;
		__defaultLibraries.push(this.base);

		#if (sys && TEST_BUILD)
		Logs.infos("Used cne test / cne build. Switching into source assets.");

		#if MOD_SUPPORT
		ModsFolder.modsPath = './${Main.pathBack}mods/';
		ModsFolder.addonsPath = './${Main.pathBack}addons/';
		#end

		__defaultLibraries.push(ModsFolder.loadLibraryFromFolder('assets', './${Main.pathBack}assets/', true, SOURCE));
		#elseif USE_ADAPTED_ASSETS
		__defaultLibraries.push(ModsFolder.loadLibraryFromFolder('assets', './assets/', true, SOURCE));
		#end
		for (d in __defaultLibraries) addLibrary(d);
	}

	public function unloadLibraries() {
		for(l in libraries)
			if (!__defaultLibraries.contains(l))
				l.unload();
	}

	public function reset() {
		unloadLibraries();

		libraries = [];

		// adds default libraries in again
		for (d in __defaultLibraries) addLibrary(d);
	}

	public function addLibrary(lib:AssetLibrary, ?tag:AssetSource, ?addTransLib:Bool = true) {
		libraries.insert(0, lib);
		if (tag != null) lib.tag = tag;
		else if (lib.tag == null) lib.tag = MODS;
		#if TRANSLATIONS_SUPPORT
		if(addTransLib) {
			var cleanLib = getCleanLibrary(lib);
			if(cleanLib != null && (cleanLib is IModsAssetLibrary)) {
				var transLib = new TranslatedAssetLibrary(cast(cleanLib, IModsAssetLibrary));
				transLib.tag = cleanLib.tag;
				libraries.insert(0, transLib);
			}
		}
		#end
		return lib;
	}

	public static function getCleanLibrary(e:AssetLibrary):AssetLibrary {
		var l = e;
		if (l is openfl.utils.AssetLibrary) {
			var al = cast(l, openfl.utils.AssetLibrary);
			@:privateAccess
			if (al.__proxy != null) l = al.__proxy;
		}
		return l;
	}
}