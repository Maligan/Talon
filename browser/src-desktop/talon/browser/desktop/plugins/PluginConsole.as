package talon.browser.desktop.plugins
{
	import starling.extensions.ITalonDisplayObject;
	import starling.utils.StringUtil;

	import talon.core.Attribute;
	import talon.core.Node;
	import talon.browser.core.App;
	import talon.browser.core.document.files.IFileReference;
	import talon.browser.core.document.log.DocumentMessage;
	import talon.browser.core.plugins.IPlugin;
	import talon.browser.core.plugins.PluginStatus;
	import talon.browser.core.utils.Console;
	import talon.browser.core.utils.Glob;

	public class PluginConsole implements IPlugin
	{
		private var _platform:App;
		private var _console:Console;

		public function get id():String         { return "talon.browser.plugin.core.Console"; }
		public function get version():String    { return "0.0.1"; }
		public function get versionAPI():String { return "0.1.0"; }

		public function attach(platform:App):void
		{
			_platform = platform;

			_console = _platform.console;

			_console.addCommand("plugin_list", cmdPluginList, "Print current plugin list");
			_console.addCommand("plugin_attach", cmdPluginAttach, "Attach plugin", "number");
			_console.addCommand("plugin_detach", cmdPluginDetach, "Detach plugin", "number");

			_console.addCommand("errors", cmdErrors, "Print current error list");
			_console.addCommand("match", cmdMatch, "Print all files which match glob-pattern", "PATTERNs");
		}

		public function detach():void
		{
			_console.removeCommand("errors");
			_console.removeCommand("tree");
			_console.removeCommand("resources");
			_console.removeCommand("resources_miss");
			_console.removeCommand("match");

			_platform = null;
		}
		
		private function cmdMatch(query:String):void
		{
			if (_platform.document)
			{
				var pattern:String = query.substr(6);
				
				for each (var file:IFileReference in _platform.document.files.toArray())
					if (Glob.match(file.path, pattern))
						console.println(file.path);
			}
		}

		private function traceNode(node:Node, depth:int, attrs:Array):void
		{
			var shiftDepth:int = depth;
			var shift:String = "";
			while (shiftDepth--) shift += "-";

			var type:String = node.getAttributeCache(Attribute.TYPE);
			var id:String = node.getAttributeCache(Attribute.ID);
			var name:String = id ? type + "#" + id : type;

			var attributes:Array = new Array();
			for each (var attributeName:String in attrs)
			{
				var attribute:Attribute = node.getOrCreateAttribute(attributeName);
				attributes.push(StringUtil.format("({0} | {1} | {2} => {3})", attribute.inited, attribute.styled, attribute.setted, attribute.value));
			}

			if (depth) _console.println(shift, name, attributes.join(", "));
			else _console.println(name, attributes.join(", "));

			for (var i:int = 0; i < node.numChildren; i++) traceNode(node.getChildAt(i), depth + 1, attrs);
		}

		private function cmdErrors(query:String):void
		{
			if (_platform.document.messages.numMessages > 0)
			{
				_console.println("Document error list:");

				for (var i:int = 0; i < _platform.document.messages.numMessages; i++)
				{
					var message:DocumentMessage = _platform.document.messages.getMessageAt(i);
					_console.println((i+1) + ")", message.level==2?"Error":message.level==1?"Warning":"Info", "|", message.text);
				}
			}
			else
			{
				_console.println("Document error list is empty");
			}
		}

		private function cmdPluginList(query:String):void
		{
			var pattern:String = "{3}) [{2}] {0} v{1}";
			var plugins:Vector.<IPlugin> = _platform.plugins.getPlugins();

//			plugins.sort(function(p1:IPlugin, p2:IPlugin):int
//			{
//				if (p2.id>p1.id) return +1;
//				if (p2.id<p1.id) return -1;
//				return 0;
//			});

			for (var i:int = 0; i < plugins.length; i++)
			{
				var plugin:IPlugin = plugins[i];

				var status:String = _platform.plugins.getPluginStatus(plugin);
				var statusKey:String = null;

				switch (status)
				{
					case PluginStatus.UNADDED:          statusKey = "U"; break;
					case PluginStatus.ATTACHED:         statusKey = "A"; break;
					case PluginStatus.ATTACHED_FAIL:    statusKey = "F"; break;
					case PluginStatus.DETACHED:         statusKey = "D"; break;
					case PluginStatus.DETACHED_FAIL:    statusKey = "F"; break;
				}

				_console.println(StringUtil.format(pattern, plugin.id, plugin.version, statusKey, i+1));
			}
		}

		private function cmdPluginAttach(query:String):void
		{
			var split:Array = query.split(" ");
			var number:int = split[1];
			var plugin:IPlugin = _platform.plugins.getPlugins()[number - 1];
			_platform.plugins.activate(plugin);
		}

		private function cmdPluginDetach(query:String):void
		{
			var split:Array = query.split(" ");
			var number:int = split[1];
			var plugin:IPlugin = _platform.plugins.getPlugins()[number - 1];
			_platform.plugins.deactivate(plugin);
		}
		
		public function get console():Console
		{
			return _console;
		}
	}
}
