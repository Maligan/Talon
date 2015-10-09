package talon.browser.plugins.tools
{
	import starling.utils.formatString;

	import talon.Attribute;
	import talon.Node;
	import talon.browser.AppController;
	import talon.browser.document.log.DocumentMessage;
	import talon.browser.plugins.IPlugin;
	import talon.browser.plugins.PluginStatus;
	import talon.utils.ITalonElement;

	public class ConsolePlugin implements IPlugin
	{
		private var _app:AppController;

		public function get id():String { return "talon.browser.tools.Console"; }
		public function get version():String { return "0.0.1"; }
		public function get versionAPI():String { return "0.1.0"; }

		public function attach(app:AppController):void
		{
			_app = app;

			_app.console.addCommand("plugin", cmdPlugin, "Print current plugin list");
			_app.console.addCommand("errors", cmdErrors, "Print current error list");
			_app.console.addCommand("tree", cmdTree, "Print current template tree", "-a attributeName");
			_app.console.addCommand("resources", cmdResourceSearch, "RegExp based search project resources", "regexp");
			_app.console.addCommand("resources_miss", cmdResourceMiss, "Missing used resources");
		}

		public function detach():void
		{
			_app.console.removeCommand("errors");
			_app.console.removeCommand("tree");
			_app.console.removeCommand("resources");
			_app.console.removeCommand("resources_miss");

			_app = null;
		}

		private function cmdResourceSearch(query:String):void
		{
			if (_app.document == null) throw new Error("Document not opened");

			var split:Array = query.split(" ");
			var regexp:RegExp = query.length > 1 ? new RegExp(split[1]) : /.*/;
			var resourceIds:Vector.<String> = _app.document.factory.resourceIds.filter(byRegExp(regexp));

			if (resourceIds.length == 0) _app.console.println("Resources not found");
			else
			{
				for each (var resourceId:String in resourceIds)
				{
					_app.console.println("*", resourceId);
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
			if (_app.document == null) throw new Error("Document not opened");
			if (_app.templateId == null) throw new Error("Prototype not selected");

			for each (var resourceId:String in _app.document.factory.missedResourceIds)
			{
				_app.console.println("*", resourceId);
			}
		}

		private function cmdTree(query:String):void
		{
			var split:Array = query.split(" ");
			var useAttrs:Boolean = split.length > 1 && split[1] == "-a";
			var attrs:Array = useAttrs ? split[2].split(/\s*,\s*/) : [];

			var template:ITalonElement = ITalonElement(_app.ui.template);
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
				attributes.push(formatString("({0} | {1} | {2} => {3})", attribute.inited, attribute.styled, attribute.setted, attribute.value));
			}

			if (depth) _app.console.println(shift, name, attributes.join(", "));
			else _app.console.println(name, attributes.join(", "));

			for (var i:int = 0; i < node.numChildren; i++) traceNode(node.getChildAt(i), depth + 1, attrs);
		}

		private function cmdErrors(query:String):void
		{
			if (_app.document.messages.numMessages > 0)
			{
				_app.console.println("Document error list:");

				for (var i:int = 0; i < _app.document.messages.numMessages; i++)
				{
					var message:DocumentMessage = _app.document.messages.getMessageAt(i);
					_app.console.println((i+1) + ")", message.level==2?"Error":message.level==1?"Warning":"Info", "|", message.text);
				}
			}
			else
			{
				_app.console.println("Document error list is empty");
			}
		}

		private function cmdPlugin(query:String):void
		{
			var pattern:String = "- [{2}] {0} v{1}";
			var plugins:Vector.<IPlugin> = _app.plugins.toArray();

			plugins.sort(function(p1:IPlugin, p2:IPlugin):int
			{
				if (p2.id>p1.id) return +1;
				if (p2.id<p1.id) return -1;
				return 0;
			});

			for each (var plugin:IPlugin in _app.plugins.toArray())
			{
				var status:String = _app.plugins.getPluginStatus(plugin);
				var statusKey:String = null;

				switch (status)
				{
					case PluginStatus.UNADDED:          statusKey = "U+"; break;
					case PluginStatus.ATTACHED:         statusKey = "A"; break;
					case PluginStatus.ATTACHED_FAIL:    statusKey = "F"; break;
					case PluginStatus.DETACHED:         statusKey = "D"; break;
					case PluginStatus.DETACHED_FAIL:    statusKey = "F"; break;
				}

				_app.console.println(formatString(pattern, plugin.id, plugin.version, statusKey));
			}
		}
	}
}
