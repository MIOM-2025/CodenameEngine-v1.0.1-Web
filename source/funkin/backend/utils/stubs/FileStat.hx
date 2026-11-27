package funkin.backend.utils.stubs;

#if !sys
/** Browser stand-in for sys.FileStat. */
class FileStat {
	public var size(default, null):Float = 0;
	public var mtime(default, null):Float = 0;
	public var atime(default, null):Float = 0;
	public var ctime(default, null):Float = 0;
	public var isDirectory(default, null):Bool = false;
	public function new() {}
}
#end
