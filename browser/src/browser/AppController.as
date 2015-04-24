package browser
{
	import browser.commands.CloseCommand;
	import browser.commands.OpenCommand;
	import browser.dom.Document;
	import browser.dom.log.DocumentMessage;
	import browser.utils.Console;
	import browser.AppConstants;
	import browser.utils.DeviceProfile;
	import browser.utils.OrientationMonitor;
	import browser.utils.Settings;

	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.NativeWindow;
	import flash.events.NativeDragEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.filesystem.File;

	import starling.display.DisplayObjectContainer;
	import starling.events.EventDispatcher;

	import talon.Attribute;
	import talon.Node;
	import talon.utils.ITalonAdaptee;

	public class AppController extends EventDispatcher
	{
		public static const EVENT_DOCUMENT_CHANGE:String = "documentChange";
		public static const EVENT_PROTOTYPE_CHANGE:String = "prototypeChange";
		public static const EVENT_PROFILE_CHANGE:String = "profileChange";

		private var _root:DisplayObject;
		private var _host:DisplayObjectContainer;
		private var _console:Console;
		private var _document:Document;
		private var _templateId:String;
		private var _ui:AppUI;
		private var _settings:Settings;
		private var _monitor:OrientationMonitor;
		private var _profile:DeviceProfile;

		public function AppController(root:DisplayObject, host:DisplayObjectContainer, console:Console)
		{
			_root = root;
			_host = host;

			_root.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragIn);
			_root.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);

			_console = console;
			_console.addCommand("errors", cmdErrors, "Print current error list");
			_console.addCommand("tree", cmdTree, "Print current template tree", "-a");
			_console.addCommand("resources", cmdResourceSearch, "RegExp based search project resources", "regexp");
			_console.addCommand("resources_miss", cmdResourceMiss, "Missing used resources");

			_monitor = new OrientationMonitor(root.stage);
			_settings = new Settings("settings");
			_profile = DeviceProfile.getById(settings.getValueOrDefault(AppConstants.SETTING_PROFILE, null)) || DeviceProfile.CUSTOM;
			_root.stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZING, onResizing);
			_ui = new AppUI(this);
			_host.addChild(_ui);

			resizeTo(_host.stage.stageWidth, _host.stage.stageHeight);
		}

		private function onResizing(e:NativeWindowBoundsEvent):void
		{
			var prevent:Boolean = settings.getValueOrDefault(AppConstants.SETTING_LOCK_RESIZE, false);
			if (prevent)
			{
				e.preventDefault();
			}
			else
			{
				var window:NativeWindow = root.stage.nativeWindow;
				profile = DeviceProfile.CUSTOM;
				profile.width = window.width;
				profile.height = window.height;
				dispatchEventWith(EVENT_PROFILE_CHANGE);
			}
		}

		public function resizeTo(width:int, height:int):void
		{
			settings.setValue(AppConstants.SETTING_IS_PORTRAIT, _monitor.isPortrait);
			_ui.resizeTo(width, height);
		}

		public function invoke(path:String):void
		{
			var file:File = new File(path);
			if (file.exists)
			{
				var close:CloseCommand = new CloseCommand(this);
				close.execute();

				var open:OpenCommand = new OpenCommand(this, file);
				open.execute();
			}
		}

		public function get ui():AppUI { return _ui; }
		public function get settings():Settings { return _settings; }
		public function get monitor():OrientationMonitor { return _monitor; }
		public function get root():DisplayObject { return _root; }
		public function get profile():DeviceProfile { return _profile; }
		public function set profile(value:DeviceProfile):void
		{
			if (value == null) throw new ArgumentError("Device Profile can't be null, use DeviceProfile.CUSTOM instead");

			if (_profile != value)
			{
				_profile = value;

				if (profile != DeviceProfile.CUSTOM)
				{
					adjust(profile.width, profile.height, _monitor.isPortrait);
				}

				settings.setValue(AppConstants.SETTING_PROFILE, _profile.id);
				dispatchEventWith(EVENT_PROFILE_CHANGE);
			}
		}

		private function adjust(width:int, height:int, isPortrait:Boolean):void
		{
			var window:NativeWindow = root.stage.nativeWindow;
			var min:Number = Math.min(width, height);
			var max:Number = Math.max(width, height);

			if (isPortrait)
			{
				window.width = min;
				window.height = max;
			}
			else
			{
				window.width = max;
				window.height = min;
			}
		}

		public function get document():Document { return _document; }
		public function set document(value:Document):void
		{
			if (_document != value)
			{
				_document = value;
				dispatchEventWith(EVENT_DOCUMENT_CHANGE);
				templateId = _document ? _document.factory.templateIds.shift() : null;
			}
		}

		public function get templateId():String { return _templateId; }
		public function set templateId(value:String):void
		{
			if (_templateId != value)
			{
				_templateId = value;
				dispatchEventWith(EVENT_PROTOTYPE_CHANGE);
			}
		}

		//
		// Drag And Drop
		//
		private function onDragIn(e:NativeDragEvent):void
		{
			var hasFiles:Boolean = e.clipboard.hasFormat(ClipboardFormats.FILE_PROMISE_LIST_FORMAT);
			if (hasFiles)
			{
				var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				if (files.length == 1)
				{
					var file:File = File(files[0]);
					if (file.extension == AppConstants.DESIGNER_FILE_EXTENSION)
					{
						NativeDragManager.acceptDragDrop(_root as InteractiveObject);
						NativeDragManager.dropAction = NativeDragActions.LINK;
					}
				}
			}
		}

		private function onDragDrop(e:NativeDragEvent):void
		{
			var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			var file:File = File(files[0]);
			invoke(file.nativePath);
		}

		//
		// Console command
		//
		private function cmdResourceSearch(query:String):void
		{
			if (_document == null) throw new Error("Document not opened");

			var split:Array = query.split(" ");
			var regexp:RegExp = query.length > 1 ? new RegExp(split[1]) : /.*/;
			var resourceIds:Vector.<String> = _document.factory.resourceIds.filter(byRegExp(regexp));

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
			if (_document == null) throw new Error("Document not opened");
			if (_templateId == null) throw new Error("Prototype not selected");

			for each (var resourceId:String in document.factory.missedResourceIds)
			{
				_console.println("*", resourceId);
			}
		}

		private function cmdTree(query:String):void
		{
			var split:Array = query.split(" ");
			var attrs:Boolean = split.length > 1 && split[1] == "-a";

			var template:ITalonAdaptee = ITalonAdaptee(_ui.template);
			var node:Node = template.node;
			traceNode(node, 0, attrs);
		}

		private function traceNode(node:Node, depth:int, attrs:Boolean):void
		{
			var shiftDepth:int = depth;
			var shift:String = "";
			while (shiftDepth--) shift += "-";

			var type:String = node.getAttribute(Attribute.TYPE);
			var id:String = node.getAttribute(Attribute.ID);
			var name:String = id ? type + "#" + id : type;

			if (depth) _console.println(shift, name);
			else _console.println(name);

			for (var i:int = 0; i < node.numChildren; i++) traceNode(node.getChildAt(i), depth + 1, attrs);
		}

		private function cmdErrors(query:String):void
		{
			if (document.messages.numMessages > 0)
			{
				_console.println("Document error list:");

				for (var i:int = 0; i < document.messages.numMessages; i++)
				{
					var message:DocumentMessage = document.messages.getMessageAt(i);
					_console.println((i+1) + ")", message.level==2?"Error":message.level==1?"Warning":"Info", "|", message.text);
				}
			}
			else
			{
				_console.println("Document error list is empty");
			}
		}
	}
}