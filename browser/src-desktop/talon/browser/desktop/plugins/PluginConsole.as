package talon.browser.desktop.plugins
{
	import starling.extensions.ITalonElement;
	import starling.utils.StringUtil;

	import talon.Attribute;
	import talon.Node;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.document.log.DocumentMessage;
	import talon.browser.platform.plugins.IPlugin;
	import talon.browser.platform.plugins.PluginStatus;
	import talon.browser.platform.utils.Console;

	public class PluginConsole implements IPlugin
	{
		private var _platform:AppPlatform;
		private var _console:Console;

		public function get id():String         { return "talon.browser.plugin.core.Console"; }
		public function get version():String    { return "0.0.1"; }
		public function get versionAPI():String { return "0.1.0"; }

		public function attach(platform:AppPlatform):void
		{
			_platform = platform;

			_console = new Console();
			_platform.stage.addChild(_console);

			_console.addCommand("plugin_list", cmdPluginList, "Print current plugin list");
			_console.addCommand("plugin_attach", cmdPluginAttach, "Attach plugin", "number");
			_console.addCommand("plugin_detach", cmdPluginDetach, "Detach plugin", "number");

			_console.addCommand("errors", cmdErrors, "Print current error list");
			_console.addCommand("tree", cmdTree, "Print current template tree", "-a attributeName");
			_console.addCommand("resources", cmdResourceSearch, "RegExp based search project resources", "regexp");
			_console.addCommand("resources_miss", cmdResourceMiss, "Missing used resources");
		}

		public function detach():void
		{
			_console.removeCommand("errors");
			_console.removeCommand("tree");
			_console.removeCommand("resources");
			_console.removeCommand("resources_miss");

			_platform = null;
		}

		private function cmdResourceSearch(query:String):void
		{
			if (_platform.document == null) throw new Error("Document not opened");

			var split:Array = query.split(" ");
			var regexp:RegExp = query.length > 1 ? new RegExp(split[1]) : /.*/;
			var resourceIds:Vector.<String> = _platform.document.factory.resourceIds.filter(byRegExp(regexp));

			if (resourceIds.length == 0) _console.println("Resources not found");
			else
			{
				for each (var resourceId:String in resourceIds)
				{
					_console.println("*", resourceId);
				}
			}
		}

		private function byRegExp(regexp:RegExp):Function
		{
			return function (value:String, index:int, vector:Vector.<String>):Boolean
			{
				return regexp.test(value);
			}
		}

		private function cmdResourceMiss(query:String):void
		{
			if (_platform.document == null) throw new Error("Document not opened");
			if (_platform.templateId == null) throw new Error("Prototype not selected");

			for each (var resourceId:String in _platform.document.factory.missedResourceIds)
			{
				_console.println("*", resourceId);
			}
		}

		private function cmdTree(query:String):void
		{
			throw new Error("Not implemented");

			var split:Array = query.split(" ");
			var useAttrs:Boolean = split.length > 1 && split[1] == "-a";
			var attrs:Array = useAttrs ? split[2].split(/\s*,\s*/) : [];

			var template:ITalonElement = ITalonElement(null /* FIXME */);
			var node:Node = template.node;
			traceNode(node, 0, attrs);
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
