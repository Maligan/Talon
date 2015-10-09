package talon.browser
{
    import air.update.ApplicationUpdaterUI;

    import talon.browser.commands.CloseDocumentCommand;
    import talon.browser.commands.OpenDocumentCommand;
    import talon.browser.document.Document;
	import talon.browser.plugins.PluginCollection;
	import talon.browser.plugins.tools.ConsolePlugin;
	import talon.browser.plugins.tools.FileTypePlugin;
	import talon.browser.ui.AppUI;
    import talon.browser.utils.Console;
    import talon.browser.utils.DeviceProfile;
    import talon.browser.utils.EventDispatcherAdapter;
    import talon.browser.plugins.IPlugin;
    import talon.browser.utils.OrientationMonitor;
    import talon.browser.utils.Storage;
    import talon.browser.utils.registerClassAlias;

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
    import flash.system.Capabilities;

    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.EventDispatcher;

    public class AppController extends EventDispatcher
	{
		public static const EVENT_DOCUMENT_CHANGE:String = "documentChange";
		public static const EVENT_TEMPLATE_CHANGE:String = "templateChange";

		public static const EVENT_DRAG_IN:String = "documentDragIn";
		public static const EVENT_DRAG_OUT:String = "documentDragOut";
		public static const EVENT_DRAG_DROP:String = "documentDrop";

		private var _root:DisplayObject;
		private var _console:Console;
	    private var _plugins:PluginCollection;
		private var _document:Document;
		private var _templateId:String;
		private var _ui:AppUI;
		private var _settings:Storage;
		private var _monitor:OrientationMonitor;
		private var _profile:DeviceProfile;
		private var _documentDispatcher:EventDispatcherAdapter;
		private var _starling:Starling;
		private var _updater:ApplicationUpdaterUI;

	    private var _invoke:String;
	    private var _invokeTemplateId:String;

		public function AppController(root:DisplayObject)
		{
			_root = root;

			registerClassAlias(Point);
			registerClassAlias(DeviceProfile);

			_settings = Storage.fromSharedObject("settings");
			_profile = _settings.getValueOrDefault(AppConstants.SETTING_PROFILE, DeviceProfile) || new DeviceProfile(_root.stage.stageWidth, root.stage.stageHeight, 1, Capabilities.screenDPI);
			_monitor = new OrientationMonitor(_root.stage);
			_documentDispatcher = new EventDispatcherAdapter();
			_ui = new AppUI(this);
			_updater = new ApplicationUpdaterUI();
			_updater.isCheckForUpdateVisible = false;
			_updater.updateURL = AppConstants.APP_UPDATE_URL + "?rnd=" + int(Math.random() * int.MAX_VALUE);
			_updater.initialize();
			_console = new Console();
			_root.stage.addChild(_console);
			_plugins = new PluginCollection(this);

			initializeDragAndDrop();
			initializeStarling();
			initializeWindowMonitor();

			onProfileChange(null);
		}

		public function invoke(path:String):void
		{
			if (_ui.completed)
			{
				// Open
				var file:File = new File(path);
				if (file.exists)
				{
					var close:CloseDocumentCommand = new CloseDocumentCommand(this);
					close.execute();

					var open:OpenDocumentCommand = new OpenDocumentCommand(this, file);
					open.execute();
				}
			}
			else
			{
				// Delay
				_invoke = path;
			}
		}

		public function resizeWindowTo(stageWidth:int, stageHeight:int):void
		{
			if (root.stage.stageWidth != stageWidth || root.stage.stageHeight != stageHeight)
			{
				var window:NativeWindow = root.stage.nativeWindow;
				var deltaWidth:int = window.width - root.stage.stageWidth;
				var deltaHeight:int = window.height - root.stage.stageHeight;
				window.width = Math.max(stageWidth + deltaWidth, window.minSize.x);
				window.height = Math.max(stageHeight + deltaHeight, window.minSize.y);
			}
		}

		//
		// Properties
		//
	    /** @private Debug console (assist tool). */
		public function get console():Console { return _console; }

	    /** Current Starling instance (preferably use this accessor, browser may work in multi windowed mode). */
	    public function get starling():Starling { return _starling; }

	    /** Application UI module. */
	    public function get ui():AppUI { return _ui; }

	    /** Application configuration file (for read AND write). */
		public function get settings():Storage { return _settings; }

	    /** Orientation monitor (assist tool). */
		public function get monitor():OrientationMonitor { return _monitor; }

	    /** Native Flash root DisplayObject (Document Root). */
		public function get root():DisplayObject { return _root; }

	    /** Device profile. */
		public function get profile():DeviceProfile { return _profile; }

	    /** Application plugin list (all: attached, detached, broken). */
	    public function get plugins():PluginCollection { return _plugins; }

	    /** @private Application updater. */
		public function get updater():ApplicationUpdaterUI { return _updater; }

	    /** @private */
		public function get documentDispatcher():EventDispatcherAdapter { return _documentDispatcher }

	    /** Current opened document or null. */
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

	    /** Current opened template id or null. */
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
					if (file.extension == AppConstants.BROWSER_DOCUMENT_EXTENSION)
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
			_profile.addEventListener(Event.CHANGE, onProfileChange);
			restoreWindowPosition();
		}

		private function restoreWindowPosition():void
		{
			var position:Point = settings.getValueOrDefault(AppConstants.SETTING_WINDOW_POSITION, Point);
			if (position)
			{
				root.stage.nativeWindow.x = position.x;
				root.stage.nativeWindow.y = position.y;
			}
		}

		private function onProfileChange(e:*):void
		{
			resizeWindowTo(profile.width, profile.height);

			if (_document)
			{
				_document.factory.dpi = _profile.dpi;
				_document.factory.csf = _profile.csf;
			}

			_settings.setValue(AppConstants.SETTING_PROFILE, _profile);
		}

		private function onStageResize(e:*):void
		{
			_starling.stage.stageWidth = _root.stage.stageWidth;
			_starling.stage.stageHeight = _root.stage.stageHeight;
			_starling.viewPort = new Rectangle(0, 0, _root.stage.stageWidth, _root.stage.stageHeight);

			_ui.resizeTo(_root.stage.stageWidth, _root.stage.stageHeight);
			_profile.setSize(_root.stage.stageWidth, _root.stage.stageHeight);
		}

		private function onResizing(e:NativeWindowBoundsEvent):void
		{
			// NativeWindow#resizable is read only, this is fix:
			var needPrevent:Boolean = settings.getValueOrDefault(AppConstants.SETTING_LOCK_RESIZE, Boolean, false);
			if (needPrevent)
				e.preventDefault();
		}

		private function onResize(e:NativeWindowBoundsEvent):void
		{
			settings.setValue(AppConstants.SETTING_WINDOW_POSITION, e.afterBounds.topLeft);
		}

		private function onMove(e:NativeWindowBoundsEvent):void
		{
			settings.setValue(AppConstants.SETTING_WINDOW_POSITION, e.afterBounds.topLeft);
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
			// Before document open
			initializePlugins();

			// Document can be opened via invoke (click on document file)
			// in this case need omit autoReopen feature
			var isEnableReopen:Boolean = settings.getValueOrDefault(AppConstants.SETTING_AUTO_REOPEN, Boolean, false);
			if (isEnableReopen && _invoke == null)
			{
				var template:String = settings.getValueOrDefault(AppConstants.SETTING_RECENT_TEMPLATE, String);
				if (template != null)
				{
					var recentArray:Array = settings.getValueOrDefault(AppConstants.SETTING_RECENT_DOCUMENTS, Array);
					var recentPath:String = recentArray && recentArray.length ? recentArray[0] : null;
					if (recentPath)
					{
						_invoke = recentPath;
						_invokeTemplateId = template;
					}
				}
			}

			if (_invoke != null) invoke(_invoke);
			if (_invokeTemplateId != null) templateId = _invokeTemplateId;

			// Updater#checkNow() run only after delay, UI inited is a good, moment for this
			var isEnableAutoUpdate:Boolean = _settings.getValueOrDefault(AppConstants.SETTING_CHECK_FOR_UPDATE_ON_STARTUP, Boolean, true);
			// XXX: Save for have default value != null
			_settings.setValue(AppConstants.SETTING_CHECK_FOR_UPDATE_ON_STARTUP, isEnableAutoUpdate);

			if (isEnableAutoUpdate) _updater.checkNow();
		}

		//
		// Plugins
		//
		private function initializePlugins():void
		{
			var list:Array = [new ConsolePlugin(), new FileTypePlugin()];

			for each (var plugin:IPlugin in list)
			{
				plugins.addPlugin(plugin);
				plugins.attach(plugin);
			}
		}
	}
}
