package browser.utils
{
	import browser.AppController;

	public interface IPlugin
	{
		function attach(context:AppController):void;
		function detach():void;
	}
}