package talon.browser
{
	import air.update.ApplicationUpdaterUI;

	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.NativeWindow;
	import flash.display.Stage;
	import flash.events.NativeWindowBoundsEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;

	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;

	import talon.browser.commands.OpenDocumentCommand;
	import talon.browser.document.Document;
	import talon.browser.document.DocumentEvent;
	import talon.browser.plugins.IPlugin;
	import talon.browser.plugins.PluginManager;
	import talon.browser.plugins.tools.CorePluginConsole;
	import talon.browser.plugins.tools.CorePluginDragAndDrop;
	import talon.browser.plugins.tools.CorePluginFileType;
	import talon.browser.utils.DeviceProfile;
	import talon.browser.utils.OrientationMonitor;
	import talon.browser.utils.Storage;
	import talon.browser.utils.registerClassAlias;

	public class AppPlatform extends EventDispatcher
	{
		public static const EVENT_DOCUMENT_CHANGE:String = "documentChange";

		private var _stage:Stage;
	    private var _plugins:PluginManager;
		private var _document:Document;
		private var _ui:AppUI;
		private var _settings:Storage;
		private var _orientation:OrientationMonitor;
		private var _profile:DeviceProfile;
		private var _starling:Starling;
		private var _updater:ApplicationUpdaterUI;

	    private var _invoke:String;
	    private var _invokeTemplateId:String;

		public function AppPlatform(stage:Stage)
		{
			_stage = stage;

			registerClassAlias(Point);
			registerClassAlias(DeviceProfile);

			_settings = Storage.fromSharedObject("settings");
			_profile = _settings.getValueOrDefault(AppConstants.SETTING_PROFILE, DeviceProfile) || new DeviceProfile(stage.stageWidth, stage.stageHeight, 1, Capabilities.screenDPI);
			_orientation = new OrientationMonitor(stage);
			_ui = new AppUI(this);
			_plugins = new PluginManager(this);
			_updater = new ApplicationUpdaterUI();
			_updater.isCheckForUpdateVisible = false;
			_updater.updateURL = AppConstants.APP_UPDATE_URL + "?rnd=" + int(Math.random() * int.MAX_VALUE);
			_updater.initialize();

			// XXX: NOT work while starling initialing!
			var colorName:String = _settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, String, AppConstants.SETTING_BACKGROUND_DEFAULT);
			var color:uint = AppConstants.SETTING_BACKGROUND_STAGE_COLOR[colorName];
			stage.color = color;

			initializeWindowMonitor();
		}

		public function initialize():void
		{
			initializeStarling();
		}

		public function invoke(path:String):void
		{
			if (_ui.completed)
			{
				// Open
				var file:File = new File(path);
				if (file.exists)
				{
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

		private function resizeWindowTo(stageWidth:int, stageHeight:int):void
		{
			if (stage.stageWidth != stageWidth || stage.stageHeight != stageHeight)
			{
				var window:NativeWindow = stage.nativeWindow;
				var deltaWidth:int = window.width - stage.stageWidth;
				var deltaHeight:int = window.height - stage.stageHeight;
				window.width = Math.max(stageWidth + deltaWidth, window.minSize.x);
				window.height = Math.max(stageHeight + deltaHeight, window.minSize.y);
			}
		}

		//
		// Properties
		//
		/** @private Application updater. */
		public function get updater():ApplicationUpdaterUI { return _updater; }

	    /** Current Starling instance (preferably use this accessor, browser may work in multi windowed mode). */
	    public function get starling():Starling { return _starling; }

	    /** Application UI module. */
	    public function get ui():AppUI { return _ui; }

	    /** Application configuration file (for read AND write). */
		public function get settings():Storage { return _settings; }

	    /** Native Flash Stage. */
		public function get stage():Stage { return _stage; }

	    /** Device profile. */
		public function get profile():DeviceProfile { return _profile; }

	    /** Application plugin list (all: attached, detached, broken). */
	    public function get plugins():PluginManager { return _plugins; }

	    /** Current opened document or null. */
	    public function get document():Document { return _document; }
		public function set document(value:Document):void
		{
			if (_document != value)
			{
				_document && _document.dispose();
				_document = value;
				_document && _document.addEventListener(DocumentEvent.CHANGE, dispatchEvent);

				if (_document)
				{
					_document.factory.dpi = _profile.dpi;
					_document.factory.csf = _profile.csf;
				}

				dispatchEventWith(EVENT_DOCUMENT_CHANGE);
			}
		}

		//
		// [Events] Move And Resize
		//
		private function initializeWindowMonitor():void
		{
			_stage.addEventListener(Event.RESIZE, onStageResize);
			_stage.nativeWindow.minSize = new Point(200, 100);
			_stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.MOVE, onWindowMove);
			_stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZING, onWindowResizing);
			_profile.addEventListener(Event.CHANGE, onProfileChange);

			// Restore window position
			var position:Point = settings.getValueOrDefault(AppConstants.SETTING_WINDOW_POSITION, Point);
			if (position)
			{
				_stage.nativeWindow.x = position.x;
				_stage.nativeWindow.y = position.y;
			}

			// Restore window size
			onProfileChange(null);
		}

		private function onStageResize(e:* = null):void
		{
			if (_starling)
			{
				_starling.stage.stageWidth = _stage.stageWidth;
				_starling.stage.stageHeight = _stage.stageHeight;
				_starling.viewPort = new Rectangle(0, 0, _stage.stageWidth, _stage.stageHeight);
			}

			_ui.resizeTo(_stage.stageWidth, _stage.stageHeight);
			_profile.setSize(_stage.stageWidth, _stage.stageHeight);
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

		private function onWindowResizing(e:NativeWindowBoundsEvent):void
		{
			// NativeWindow#resizable is read only, this is fix:
			var needPrevent:Boolean = settings.getValueOrDefault(AppConstants.SETTING_LOCK_RESIZE, Boolean, false);
			if (needPrevent) e.preventDefault();
		}

		private function onWindowMove(e:NativeWindowBoundsEvent):void
		{
			settings.setValue(AppConstants.SETTING_WINDOW_POSITION, e.afterBounds.topLeft);
		}

		//
		// Starling
		//
		private function initializeStarling():void
		{
			_starling = new Starling(Sprite, stage, null, null, "auto", "baseline");
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
			if (_invokeTemplateId != null) _ui.templateId = _invokeTemplateId;

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
			CorePluginConsole;
			CorePluginFileType;
			CorePluginDragAndDrop;
			plugins.addPluginsFromApplicationDomain(ApplicationDomain.currentDomain);
		}
	}
}