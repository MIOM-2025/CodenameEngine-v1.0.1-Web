package funkin.backend.utils.stubs;

#if !sys
/**
	Browser stand-in for sys.FileSystem.
	The engine only touches the real filesystem inside the editor/updater code,
	which never runs on the web target; this exists so that code still type checks.
**/
class FileSystem {
	public static function exists(path:String):Bool return false;
	public static function isDirectory(path:String):Bool return false;
	public static function readDirectory(path:String):Array<String> return [];
	public static function stat(path:String):Dynamic return null;
	public static function deleteFile(path:String):Void {}
	public static function rename(path:String, newPath:String):Void {}
	public static function createDirectory(path:String):Void {}
	public static function absolutePath(path:String):String return path;
	public static function fullPath(relPath:String):String return relPath;
}
#end
