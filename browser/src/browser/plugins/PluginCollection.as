package browser.plugins
{
	import browser.AppController;

	import flash.utils.Dictionary;
	import starling.events.Event;
	import starling.events.EventDispatcher;

	public class PluginCollection extends EventDispatcher
	{
		private var _app:AppController;
		private var _plugins:Vector.<IPlugin>;
		private var _pluginStatus:Dictionary;

		public function PluginCollection(app:AppController)
		{
			_app = app;
			_plugins = new <IPlugin>[];
			_pluginStatus = new Dictionary();
		}

		public function addPlugin(plugin:IPlugin):void
		{
			// Already added
			if (_plugins.indexOf(plugin) != -1) return;

			_plugins.push(plugin);
			_pluginStatus[plugin] = PluginStatus.DETACHED;

			dispatchEventWith(Event.CHANGE, false, plugin);
		}

		public function getPluginStatus(plugin:IPlugin):String
		{
			if (_plugins.indexOf(plugin) == -1) return PluginStatus.UNADDED;

			return _pluginStatus[plugin];
		}

		public function attach(plugin:IPlugin):Boolean
		{
			if (_plugins.indexOf(plugin) == -1) return false;

			try
			{
				plugin.attach(_app);
				_pluginStatus[plugin] = PluginStatus.ATTACHED;
				dispatchEventWith(Event.CHANGE, false, plugin);
				return true;
			}
			catch (e:Error)
			{
				_pluginStatus[plugin] = PluginStatus.ATTACHED_FAIL;
				dispatchEventWith(Event.CHANGE, false, plugin);
				return false;
			}
		}

		public function detach(plugin:IPlugin):Boolean
		{
			if (_plugins.indexOf(plugin) == -1) return false;

			try
			{
				plugin.detach();
				_pluginStatus[plugin] = PluginStatus.DETACHED;
				dispatchEventWith(Event.CHANGE, false, plugin);
				return true;
			}
			catch (e:Error)
			{
				_pluginStatus[plugin] = PluginStatus.DETACHED_FAIL;
				dispatchEventWith(Event.CHANGE, false, plugin);
				return false;
			}
		}
	}
}