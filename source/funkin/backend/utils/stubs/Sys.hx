package funkin.backend.utils.stubs;

#if !sys
/**
	Browser stand-in for the sys parts of Sys.
	Only the members the engine calls from native-only paths are mirrored here.
**/
class Sys {
	public static function args():Array<String> return [];
	public static function getCwd():String return "";
	public static function setCwd(path:String):Void {}
	public static function programPath():String return "";
	public static function getEnv(name:String):String return null;
	public static function command(cmd:String, ?args:Array<String>):Int return 1;
	public static function sleep(seconds:Float):Void {}
	public static function time():Float return Date.now().getTime() / 1000;
	public static function println(v:Dynamic):Void {}
	public static function exit(code:Int = 0):Void {}
}
#end
