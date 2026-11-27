package funkin.backend.utils.stubs;

#if !sys
/** Browser stand-in for sys.io.File, see FileSystem. */
class File {
	public static function getContent(path:String):String return null;
	public static function getBytes(path:String):haxe.io.Bytes return null;
	public static function saveContent(path:String, content:String):Void {}
	public static function saveBytes(path:String, bytes:haxe.io.Bytes):Void {}
	public static function write(path:String, binary:Bool = true):FileOutput return new FileOutput();
}
#end
