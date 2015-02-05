package designer
{
	import designer.commands.OpenCommand;
	import designer.dom.Document;
	import designer.utils.Console;
	import designer.utils.DeviceProfile;
	import designer.utils.OrientationMonitor;
	import designer.utils.Settings;

	import flash.display.DisplayObject;
	import flash.display.NativeWindow;

	import flash.filesystem.File;

	import starling.display.DisplayObjectContainer;
	import starling.events.Event;
	import starling.events.EventDispatcher;

	public class DesignerController extends EventDispatcher
	{
		public static const EVENT_DOCUMENT_CHANGE:String = "documentChange";
		public static const EVENT_PROTOTYPE_CHANGE:String = "prototypeChange";

		private var _root:DisplayObject;
		private var _host:DisplayObjectContainer;
		private var _console:Console;
		private var _document:Document;
		private var _prototypeId:String;
		private var _ui:DesignerUI;
		private var _settings:Settings;
		private var _monitor:OrientationMonitor;
		private var _profile:DeviceProfile;

		public function DesignerController(root:DisplayObject, host:DisplayObjectContainer, console:Console)
		{
			_root = root;
			_host = host;

			_console = console;
			_console.addCommand("resources", cmdResourceSearch, "RegExp based search project resources", "regexp");

			_profile = DeviceProfile.CUSTOM;
			_monitor = new OrientationMonitor(root.stage);
			_settings = new Settings();
			_ui = new DesignerUI(this);
			_host.addChild(_ui);

			resizeTo(_host.stage.stageWidth, _host.stage.stageHeight);
		}

		private function onDocumentChange(e:Event):void
		{
			refresh();
		}

		private function refresh():void
		{
			_ui.refresh();
		}

		public function resizeTo(width:int, height:int):void
		{
			_ui.resizeTo(width, height);
		}

		public function invoke(path:String):void
		{
			var file:File = new File(path);
			if (file.exists == false) return;
			var open:OpenCommand = new OpenCommand(this, file);
			open.execute();
		}

		public function get ui():DesignerUI { return _ui; }
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
					var window:NativeWindow = root.stage.nativeWindow;
					window.width = profile.width;
					window.height = profile.height;
				}
			}
		}

		public function get document():Document { return _document; }
		public function set document(value:Document):void
		{
			if (_document != value)
			{
				_document && _document.removeEventListener(Event.CHANGE, onDocumentChange);
				_document = value;
				_document && _document.addEventListener(Event.CHANGE, onDocumentChange);

				dispatchEventWith(EVENT_DOCUMENT_CHANGE);

				prototypeId = _document ? _document.factory.prototypeIds.shift() : null;
			}
		}

		public function get prototypeId():String { return _prototypeId; }
		public function set prototypeId(value:String):void
		{
			if (_prototypeId != value)
			{
				_prototypeId = value;
				dispatchEventWith(EVENT_PROTOTYPE_CHANGE);

				refresh();
			}
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
	}
}