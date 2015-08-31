package browser
{
	import browser.commands.CloseDocumentCommand;
	import browser.commands.OpenDocumentCommand;
	import browser.dom.Document;
	import browser.dom.log.DocumentMessage;
	import browser.ui.AppUI;
	import browser.utils.Console;
	import browser.utils.DeviceProfile;
	import browser.utils.EventDispatcherAdapter;
	import browser.utils.OrientationMonitor;
	import browser.utils.Storage;
	import browser.utils.registerClassAlias;

	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.NativeWindow;
	import flash.events.NativeDragEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.DisplayObjectContainer;

	import starling.display.Sprite;
	import starling.events.Event;

	import starling.events.EventDispatcher;
	import starling.utils.formatString;

	import talon.Attribute;
	import talon.Node;
	import talon.utils.ITalonElement;

	public class AppController extends EventDispatcher
	{
		public static const EVENT_DOCUMENT_CHANGE:String = "documentChange";
		public static const EVENT_TEMPLATE_CHANGE:String = "templateChange";
		public static const EVENT_PROFILE_CHANGE:String = "profileChange";

		public static const EVENT_DRAG_IN:String = "documentDragIn";
		public static const EVENT_DRAG_OUT:String = "documentDragOut";
		public static const EVENT_DRAG_DROP:String = "documentDrop";

		private var _root:DisplayObject;
		private var _console:Console;
		private var _document:Document;
		private var _templateId:String;
		private var _ui:AppUI;
		private var _settings:Storage;
		private var _monitor:OrientationMonitor;
		private var _profile:DeviceProfile;
		private var _documentDispatcher:EventDispatcherAdapter;
		private var _starling:Starling;
		private var _preventProfileChange:Boolean;

		public function AppController(root:DisplayObject)
		{
			_root = root;

			registerClassAlias(Point);
			registerClassAlias(Rectangle);

			_settings = Storage.fromSharedObject("settings");
			_profile = DeviceProfile.getById(settings.getValueOrDefault(AppConstants.SETTING_PROFILE, null)) || DeviceProfile.CUSTOM;
			_monitor = new OrientationMonitor(_root.stage);
			_documentDispatcher = new EventDispatcherAdapter();
			_ui = new AppUI(this);

			initializeConsole();
			initializeDragAndDrop();
			initializeStarling();
			initializeWindowMonitor();
		}

		public function invoke(path:String):void
		{
			var file:File = new File(path);
			if (file.exists)
			{
				var close:CloseDocumentCommand = new CloseDocumentCommand(this);
				close.execute();

				var open:OpenDocumentCommand = new OpenDocumentCommand(this, file);
				open.execute();
			}
		}

		public function rotate():void
		{
			_preventProfileChange = true;
			var window:NativeWindow = root.stage.nativeWindow;
			var bounds:Rectangle = window.bounds;
			window.width = bounds.height;
			window.height = bounds.width;
			_preventProfileChange = false;
		}

		private function resizeWindowTo(stageWidth:int, stageHeight:int):void
		{
			var window:NativeWindow = root.stage.nativeWindow;
			var deltaWidth:int = window.width - root.stage.stageWidth;
			var deltaHeight:int = window.height - root.stage.stageHeight;
			window.width = stageWidth + deltaWidth;
			window.height = stageHeight + deltaHeight;
		}

		//
		// Properties
		//
		public function get console():Console { return _console; }
		public function get host():DisplayObjectContainer { return _starling.root as DisplayObjectContainer }
		public function get ui():AppUI { return _ui; }
		public function get settings():Storage { return _settings; }
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
					var max:int = Math.max(profile.width,  profile.height);
					var min:int = Math.min(profile.width,  profile.height);

					var width:int  = _monitor.isPortrait ? min : max;
					var height:int = _monitor.isPortrait ? max : min;

					_preventProfileChange = true;
					resizeWindowTo(width, height);
					_preventProfileChange = false;
				}

				if (_document)
				{
					_document.factory.dpi = _profile.dpi;
					_document.factory.csf = _profile.csf;
				}

				settings.setValue(AppConstants.SETTING_PROFILE, _profile.id);
				dispatchEventWith(EVENT_PROFILE_CHANGE);
			}
		}

		public function get documentDispatcher():EventDispatcherAdapter { return _documentDispatcher }
		public function get document():Document { return _document; }
		public function set document(value:Document):void
		{
			if (_document != value)
			{
				_document && _document.dispose();
				_document = value;
				_documentDispatcher.target = _document;

				if (_document)
				{
					_document.factory.dpi = _profile.dpi;
					_document.factory.csf = _profile.csf;
				}

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
				_settings.setValue(AppConstants.SETTING_RECENT_TEMPLATE, _templateId);
				dispatchEventWith(EVENT_TEMPLATE_CHANGE);
			}
		}

		//
		// [Events] Drag And Drop
		//
		private function initializeDragAndDrop():void
		{
			_root.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragIn);
			_root.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragOut);
			_root.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);
		}

		private function onDragIn(e:NativeDragEvent):void
		{
			var hasFiles:Boolean = e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT);
			if (hasFiles)
			{
				var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				if (files.length == 1)
				{
					var file:File = File(files[0]);
					if (file.extension == AppConstants.DESIGNER_FILE_EXTENSION)
					{
						NativeDragManager.acceptDragDrop(_root as InteractiveObject);
						NativeDragManager.dropAction = NativeDragActions.MOVE;
						dispatchEventWith(EVENT_DRAG_IN, files[0]);
					}
				}
			}
		}

		private function onDragOut(e:NativeDragEvent):void
		{
			dispatchEventWith(EVENT_DRAG_OUT);
		}

		private function onDragDrop(e:NativeDragEvent):void
		{
			dispatchEventWith(EVENT_DRAG_DROP);
			var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			var file:File = File(files[0]);
			invoke(file.nativePath);
		}

		//
		// [Events] Move And Resize
		//
		private function initializeWindowMonitor():void
		{
			_root.stage.addEventListener(Event.RESIZE, onStageResize);
			_root.stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.MOVE, onMove);
			_root.stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZING, onResizing);
			_root.stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZE, onResize);
			restoreWindowBounds();
		}

		private function restoreWindowBounds():void
		{
			var window:NativeWindow = root.stage.nativeWindow;
			var bounds:Rectangle = settings.getValueOrDefault(AppConstants.SETTING_WINDOW_BOUNDS);
			if (bounds && bounds.width >= window.minSize.x && bounds.height >= window.minSize.y)
			{
				window.x = bounds.x;
				window.y = bounds.y;
				window.width = bounds.width;
				window.height = bounds.height;
			}
		}

		private function onStageResize(e:*):void
		{
			_starling.stage.stageWidth = _root.stage.stageWidth;
			_starling.stage.stageHeight = _root.stage.stageHeight;
			_starling.viewPort = new Rectangle(0, 0, _root.stage.stageWidth, _root.stage.stageHeight);
			_ui.resizeTo(_root.stage.stageWidth, _root.stage.stageHeight);

			if (_profile != DeviceProfile.CUSTOM && _preventProfileChange == false)
			{
				profile = DeviceProfile.CUSTOM;
			}

			if (_profile == DeviceProfile.CUSTOM)
			{
				_profile.width = _starling.stage.stageWidth;
				_profile.height = _starling.stage.stageHeight;
				dispatchEventWith(EVENT_PROFILE_CHANGE);
			}
		}

		private function onResizing(e:NativeWindowBoundsEvent):void
		{
			// NativeWindow#resizable is read only, this is fix:
			var needPrevent:Boolean = settings.getValueOrDefault(AppConstants.SETTING_LOCK_RESIZE, false);
			if (needPrevent)
				e.preventDefault();
		}

		private function onResize(e:NativeWindowBoundsEvent):void
		{
			settings.setValue(AppConstants.SETTING_WINDOW_BOUNDS, e.afterBounds);
		}

		private function onMove(e:NativeWindowBoundsEvent):void
		{
			settings.setValue(AppConstants.SETTING_WINDOW_BOUNDS, e.afterBounds);
		}

		//
		// Starling
		//
		private function initializeStarling():void
		{
			_starling = new Starling(Sprite, root.stage, null, null, "auto", "baseline");
			_starling.addEventListener(Event.ROOT_CREATED, onStarlingRootCreated);
			_starling.start();
		}

		private function onStarlingRootCreated(e:Event):void
		{
			_starling.removeEventListener(Event.ROOT_CREATED, onStarlingRootCreated);
			_ui.addEventListener(Event.COMPLETE, onUIComplete);
			_ui.initialize();
		}

		private function onUIComplete(e:Event):void
		{
			// Document can be opened via invoke (click on document file)
			// in this case need omit autoReopen feature
			if (document != null) return;

			var isEnableReopen:Boolean = settings.getValueOrDefault(AppConstants.SETTING_AUTO_REOPEN, false);
			if (isEnableReopen)
			{
				var recentArray:Array = settings.getValueOrDefault(AppConstants.SETTING_RECENT_DOCUMENTS);
				var recentPath:String = recentArray && recentArray.length ? recentArray[0] : null;
				if (recentPath)
				{
					var template:String = settings.getValueOrDefault(AppConstants.SETTING_RECENT_TEMPLATE);
					invoke(recentPath);
					if (template != null) templateId = template;
				}
			}
		}

		//
		// Console command
		//
		private function initializeConsole():void
		{
			_console = new Console();
			_root.stage.addChild(_console);

			_console.addCommand("errors", cmdErrors, "Print current error list");
			_console.addCommand("tree", cmdTree, "Print current template tree", "-a attributeName");
			_console.addCommand("resources", cmdResourceSearch, "RegExp based search project resources", "regexp");
			_console.addCommand("resources_miss", cmdResourceMiss, "Missing used resources");
		}

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
			var useAttrs:Boolean = split.length > 1 && split[1] == "-a";
			var attrs:Array = useAttrs ? split[2].split(/\s*,\s*/) : [];

			var template:ITalonElement = ITalonElement(_ui.template);
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

			if (depth) _console.println(shift, name, attributes.join(", "));
			else _console.println(name, attributes.join(", "));

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
