package browser.plugin
{
	import flash.events.EventDispatcher;

	public class PluginToken extends EventDispatcher
	{
		private var status:String;
		private var progress:Number;
		private var code:int;

		private var result:Object;
	}
}
