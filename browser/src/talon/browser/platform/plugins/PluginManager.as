package talon.browser.platform.plugins
{
	import avmplus.DescribeTypeJSON;
	import avmplus.getQualifiedClassName;

	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;

	public class PluginManager extends EventDispatcher
	{
		private var _platform:AppPlatform;
		private var _plugins:Vector.<IPlugin>;
		private var _pluginStatus:Dictionary;

		public function PluginManager(app:AppPlatform)
		{
			_platform = app;
			_plugins = new <IPlugin>[];
			_pluginStatus = new Dictionary();
		}

		public function addPluginsFromApplicationDomain(domain:ApplicationDomain):void
		{
			var required:String = getQualifiedClassName(IPlugin);
			var names:Vector.<String> = domain.getQualifiedDefinitionNames();

			for each (var name:String in names)
			{
				var definition:Class = domain.hasDefinition(name) ? domain.getDefinition(name) as Class : null;
				if (definition != null)
				{
					var description:Object = DescribeTypeJSON.getInstanceDescription(definition);
					var traits:Object = description["traits"];
					var interfaces:Array = traits["interfaces"];
					if (interfaces.indexOf(required) != -1)
					{
						// TODO: Error while constructor
						var plugin:IPlugin = new definition();
						addPlugin(plugin);
					}
				}
			}
		}

		public function addPlugin(plugin:IPlugin):void
		{
			// Already added
			if (_plugins.indexOf(plugin) != -1) return;

			_plugins.push(plugin);
			_pluginStatus[plugin] = PluginStatus.DETACHED;

			dispatchEventWith(Event.CHANGE, false, plugin);
		}

		/** Start all detached plugins, which is not deactivated. */
		public function start():void
		{
			var detached:Array = _platform.settings.getValueOrDefault(AppConstants.SETTING_DETACHED_PLUGINS, Array, []);

			for each (var plugin:IPlugin in _plugins)
			{
				var status:String = getPluginStatus(plugin);
				if (status == PluginStatus.DETACHED && detached.indexOf(plugin.id) == -1)
				{
					activate(plugin);
				}
			}
		}

		public function getPluginStatus(plugin:IPlugin):String
		{
			if (_plugins.indexOf(plugin) == -1) return PluginStatus.UNADDED;

			return _pluginStatus[plugin];
		}

		public function activate(plugin:IPlugin):Boolean
		{
			if (_plugins.indexOf(plugin) == -1) return false;

			try
			{
				plugin.attach(_platform);
				_pluginStatus[plugin] = PluginStatus.ATTACHED;

				var detached:Array = _platform.settings.getValueOrDefault(AppConstants.SETTING_DETACHED_PLUGINS, Array, []);
				var indexOf:int = detached.indexOf(plugin.id);
				if (indexOf != -1)
				{
					detached.splice(indexOf, 1);
					_platform.settings.setValue(AppConstants.SETTING_DETACHED_PLUGINS, detached);
				}

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

		public function deactivate(plugin:IPlugin):Boolean
		{
			if (_plugins.indexOf(plugin) == -1) return false;

			try
			{
				plugin.detach();
				_pluginStatus[plugin] = PluginStatus.DETACHED;

				var detached:Array = _platform.settings.getValueOrDefault(AppConstants.SETTING_DETACHED_PLUGINS, Array, []);
				var indexOf:int = detached.indexOf(plugin.id);
				if (indexOf == -1)
				{
					detached.push(plugin.id);
					_platform.settings.setValue(AppConstants.SETTING_DETACHED_PLUGINS, detached);
				}

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

		public function getPlugins():Vector.<IPlugin>
		{
			return _plugins.slice();
		}
	}
}