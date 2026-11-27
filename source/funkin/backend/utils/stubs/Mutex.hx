package funkin.backend.utils.stubs;

#if !sys
/** Browser stand-in for sys.thread.Mutex; locking is a no-op. */
class Mutex {
	public function new() {}
	public function acquire():Void {}
	public function release():Void {}
}
#end
