package talon.browser.platform
{
	import flash.display.Stage;
	import flash.display3D.Context3DProfile;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;

	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.extensions.StarlingTalonFactory;

	import talon.browser.platform.commands.CommandManager;
	import talon.browser.platform.document.Document;
	import talon.browser.platform.document.DocumentEvent;
	import talon.browser.platform.plugins.PluginManager;
	import talon.browser.platform.popups.PopupManager;
	import talon.browser.platform.utils.DeviceProfile;
	import talon.browser.platform.utils.Storage;
	import talon.browser.platform.utils.registerClassAlias;

	public class AppPlatform extends EventDispatcher
	{
		private var _stage:Stage;
		private var _document:Document;
		private var _templateId:String;
		private var _settings:Storage;
		private var _profile:DeviceProfile;
		private var _starling:Starling;
		private var _factory:StarlingTalonFactory;
		private var _plugins:PluginManager;
		private var _popups:PopupManager;
		private var _commands:CommandManager;
	    private var _lastInvokeArgs:Array;
		private var _started:Boolean;

		public function AppPlatform(stage:Stage)
		{
			_stage = stage;

			registerClassAlias(Point);
			registerClassAlias(DeviceProfile);

			_lastInvokeArgs = [];
			_settings = Storage.fromSharedObject("settings");
			_profile = _settings.getValueOrDefault(AppConstants.SETTING_PROFILE, DeviceProfile) || new DeviceProfile(stage.stageWidth, stage.stageHeight, 1, Capabilities.screenDPI);
			_factory = new StarlingTalonFactory();
			_plugins = new PluginManager(this);
			_popups = new PopupManager(this);
			_commands = new CommandManager();

			// WARNING: NOT work after starling creating!
			var colorName:String = _settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, String, AppConstants.SETTING_BACKGROUND_DEFAULT);
			var color:uint = AppConstants.SETTING_BACKGROUND_STAGE_COLOR[colorName];
			stage.color = color;
			// --------------------------------------

			// With "baselineConstrained" there are same issues:
			// * stage.color while starling inited have misbehavior
			// * take screenshot have no alpha
			_starling = new Starling(Sprite, stage, null, null, "auto", Context3DProfile.BASELINE);
			_starling.skipUnchangedFrames = true;
			_starling.addEventListener(Event.ROOT_CREATED, onStarlingRootCreated);

			// Resize listeners
			_stage.stageWidth = _profile.width;
			_stage.stageHeight = _profile.height;
			_stage.addEventListener(Event.RESIZE, onStageResize);
			_profile.addEventListener(Event.CHANGE, onProfileChange);
		}

		private function onStarlingRootCreated(e:Event):void
		{
			_starling.removeEventListener(Event.ROOT_CREATED, onStarlingRootCreated);

			if (_started) start();
		}

		public function start():void
		{
			_started = true;

			// If starling already initialized
			if (_starling.root)
			{
				_starling.start();
				_plugins.start();

				dispatchEventWith(AppPlatformEvent.STARTED, false, _lastInvokeArgs);
			}
		}

		public function invoke(args:Array):void
		{
			_lastInvokeArgs = args || [];

			if (_started && _lastInvokeArgs && _lastInvokeArgs.length > 0)
			{
				dispatchEventWith(AppPlatformEvent.INVOKE, false, _lastInvokeArgs);
			}
		}

		//
		// Properties (Open API)
		//
		/** Native Flash Stage. */
		public function get stage():Stage { return _stage; }

		/** Application configuration file (for read AND write). */
		public function get settings():Storage { return _settings; }

		/** Current device profile. */
		public function get profile():DeviceProfile { return _profile; }

		/** Special popup manager (@see PopupManager#host) */
		public function get popups():PopupManager { return _popups; }

		/** Application plugin list (all: attached, detached, broken). */
		public function get plugins():PluginManager { return _plugins; }

		/** Application command manager - history/shortcuts etc. */
		public function get commands():CommandManager { return _commands; }

	    /** Current Starling instance (preferably use this accessor). */
	    public function get starling():Starling { return _starling; }

		/** Talon factory for all browser UI. */
		public function get factory():StarlingTalonFactory { return _factory; }

	    /** Current opened document or null. */
	    public function get document():Document { return _document; }
		public function set document(value:Document):void
		{
			if (_document != value)
			{
				templateId = null;

				if (_document)
					_document.dispose();

				_document = value;

				if (_document)
				{
					_document.addEventListener(DocumentEvent.CHANGE, dispatchEvent);
					_document.factory.dpi = _profile.dpi;
					_document.factory.csf = _profile.csf;
				}

				dispatchEventWith(AppPlatformEvent.DOCUMENT_CHANGE);
			}
		}

		/** Current selected template name or null. */
		public function get templateId():String { return _templateId; }
		public function set templateId(value:String):void
		{
			if (_templateId != value)
			{
				_templateId = value;
				settings.setValue(AppConstants.SETTING_RECENT_TEMPLATE, value);
				dispatchEventWith(AppPlatformEvent.TEMPLATE_CHANGE);
			}
		}

		//
		// Resize listeners
		//
		private function onStageResize(e:* = null):void
		{
			if (_starling)
			{
				_starling.stage.stageWidth = _stage.stageWidth;
				_starling.stage.stageHeight = _stage.stageHeight;
				_starling.viewPort = new Rectangle(0, 0, _stage.stageWidth, _stage.stageHeight);
			}

			_profile.setSize(_stage.stageWidth, _stage.stageHeight);
		}

		private function onProfileChange(e:*):void
		{
			if (_document)
			{
				_document.factory.dpi = _profile.dpi;
				_document.factory.csf = _profile.csf;
			}

			_settings.setValue(AppConstants.SETTING_PROFILE, _profile);
		}
	}
}