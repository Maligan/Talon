package talon.browser.core.plugins
{
	import avmplus.DescribeTypeJSON;
	import avmplus.getQualifiedClassName;

	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	import talon.browser.core.App;
	import talon.browser.core.AppConstants;

	public class PluginManager extends EventDispatcher
	{
		private var _platform:App;
		private var _plugins:Vector.<IPlugin>;
		private var _pluginStatus:Dictionary;

		public function PluginManager(app:App)
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
				var pluginClass:Class = domain.hasDefinition(name) ? domain.getDefinition(name) as Class : null;
				if (pluginClass != null)
				{
					var description:Object = DescribeTypeJSON.getInstanceDescription(pluginClass);
					var traits:Object = description["traits"];
					var interfaces:Array = traits["interfaces"];
					if (interfaces.indexOf(required) != -1)
					{
						var plugin:IPlugin = null;
						
						try { plugin = new pluginClass() }
						catch (e:*) { plugin = new PluginDummy("N/A", "0.0.0", "0.0.0") }
						
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

		/** Start all attached plugins, which is not deactivated. */
		public function start():void
		{
			var detached:Array = _platform.settings.getValue(AppConstants.SETTING_DETACHED_PLUGINS, Array, []);

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

				var detached:Array = _platform.settings.getValue(AppConstants.SETTING_DETACHED_PLUGINS, Array, []);
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

				var detached:Array = _platform.settings.getValue(AppConstants.SETTING_DETACHED_PLUGINS, Array, []);
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
		
		public function getPlugin(type:Class):IPlugin
		{
			for each (var plugin:IPlugin in _plugins)
				if (plugin is type) return plugin;
			
			return null;
		}
	}
}

import talon.browser.core.App;
import talon.browser.core.plugins.IPlugin;

class PluginDummy implements IPlugin
{
	private var _id:String;
	private var _version:String;
	private var _versionAPI:String;
	
	public function PluginDummy(id:String, version:String, versionAPI:String)
	{
		_id = id;
		_version = version;
		_versionAPI = versionAPI;
	}

	public function get id():String { return _id; }
	public function get version():String { return _version; }
	public function get versionAPI():String { return _versionAPI; }
	
	public function attach(platform:App):void { }
	public function detach():void { }
}