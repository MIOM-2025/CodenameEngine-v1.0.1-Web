package funkin.backend.utils.stubs;

#if !sys
/** Browser stand-in for sys.thread.Thread; everything collapses to the main thread. */
class Thread {
	public static function create(func:Void->Void):Thread {
		func();
		return new Thread();
	}
	public static function createWithEventLoop(func:Void->Void):Thread {
		func();
		return new Thread();
	}
	public static function current():Thread return new Thread();
	public var events:Dynamic = {};
	public function new() {}
}
#end
