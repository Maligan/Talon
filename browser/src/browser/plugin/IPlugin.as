package browser.plugin
{
	public interface IPlugin
	{
		function attach(context:PluginContext, config:Object):Boolean;
		function detach():void;
	}
}