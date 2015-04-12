package browser
{
	import browser.commands.OpenCommand;
	import browser.dom.Document;
	import browser.utils.Console;
	import browser.utils.Constants;
	import browser.utils.DeviceProfile;
	import browser.utils.OrientationMonitor;
	import browser.utils.Settings;

	import flash.desktop.NotificationType;

	import flash.display.DisplayObject;
	import flash.display.NativeWindow;
	import flash.display.NativeWindow;
	import flash.events.NativeWindowBoundsEvent;

	import flash.filesystem.File;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	import starling.display.DisplayObjectContainer;
	import starling.events.Event;
	import starling.events.EventDispatcher;

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

			_console = console;
			_console.addCommand("resources", cmdResourceSearch, "RegExp based search project resources", "regexp");
			_console.addCommand("resources_miss", cmdResourceMiss, "Missing used resources");


			_monitor = new OrientationMonitor(root.stage);
			_settings = new Settings("settings");
			_profile = DeviceProfile.getById(settings.getValueOrDefault(Constants.SETTING_PROFILE, null)) || DeviceProfile.CUSTOM;
			_root.stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZING, onResizing);
			_ui = new AppUI(this);
			_host.addChild(_ui);

			resizeTo(_host.stage.stageWidth, _host.stage.stageHeight);
		}

		private function onResizing(e:NativeWindowBoundsEvent):void
		{
			var prevent:Boolean = settings.getValueOrDefault(Constants.SETTING_LOCK_RESIZE, false);
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
			settings.setValue(Constants.SETTING_IS_PORTRAIT, _monitor.isPortrait);
			_ui.resizeTo(width, height);
		}

		public function invoke(path:String):void
		{
			var file:File = new File(path);
			if (file.exists == false) return;
			var open:OpenCommand = new OpenCommand(this, file);
			open.execute();
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

				settings.setValue(Constants.SETTING_PROFILE, _profile.id);
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
	}
}