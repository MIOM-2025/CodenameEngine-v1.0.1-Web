package funkin.backend.utils.stubs;

#if !sys
/** Browser stand-in for sys.io.FileOutput. */
class FileOutput {
	public function new() {}
	public function write(bytes:haxe.io.Bytes):Void {}
	public function writeByte(byte:Int):Void {}
	public function writeString(value:String):Void {}
	public function close():Void {}
}
#end
