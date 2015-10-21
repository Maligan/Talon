package talon.browser
{
	import flash.utils.ByteArray;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.BlurFilter;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	import talon.Attribute;
	import talon.browser.document.DocumentEvent;
	import talon.browser.document.log.DocumentMessage;
	import talon.browser.popups.PopupManager;
	import talon.browser.utils.DeviceProfile;
	import talon.browser.utils.TalonFeatherTextInput;
	import talon.layout.Layout;
	import talon.starling.TalonFactoryStarling;
	import talon.starling.TalonSprite;
	import talon.utils.ITalonElement;
	import talon.utils.TalonFactoryBase;

	public class AppUI extends EventDispatcher
	{
		[Embed(source="/../assets/interface.zip", mimeType="application/octet-stream")] private static const INTERFACE:Class;
		[Embed(source="/../assets/SourceSansPro.otf", embedAsCFF="false", fontName="Source Sans Pro")] private static const INTERFACE_FONT:Class;

		private var _controller:AppPlatform;
		private var _menu:AppUINativeMenu;
		private var _popups:PopupManager;

		private var _factory:TalonFactoryStarling;
		private var _interface:TalonSprite;
		private var _errorPage:TalonSprite;
		private var _isolatorContainer:TalonSprite;
		private var _isolator:DisplayObjectContainer;
		private var _container:TalonSprite;

		private var _templateId:String;
		private var _template:DisplayObject;
		private var _templateProduceMessage:DocumentMessage;
		private var _locked:Boolean;
		private var _completed:Boolean;

		public function AppUI(controller:AppPlatform)
		{
			_controller = controller;
			_controller.addEventListener(AppPlatform.EVENT_DOCUMENT_CHANGE, refreshWindowTitle);
			_controller.profile.addEventListener(Event.CHANGE, refreshWindowTitle);

			_controller.addEventListener(AppPlatform.EVENT_DOCUMENT_CHANGE, refreshCurrentTemplate);
			_controller.addEventListener(DocumentEvent.CHANGE, refreshCurrentTemplate);

			_isolator = new Sprite();
			_menu = new AppUINativeMenu(_controller);
			_popups = new PopupManager();

			refreshWindowTitle();
		}

		/** Call after starling initialize completed. */
		public function initialize():void
		{
			_factory = new TalonFactoryStarling();
			_factory.addTerminal("input");
			_factory.setLinkage("input", TalonFeatherTextInput);
			_factory.setLinkage("interface", TalonSpriteWithDrawCountReset);
			_factory.addArchiveContentAsync(new INTERFACE() as ByteArray, onFactoryComplete);
		}

		//
		// Logic
		//
		private function onFactoryComplete():void
		{
			_completed = true;
			_interface = _factory.produce("Interface") as TalonSprite;
			host.addChild(_interface);

			_popups.initialize(_interface.getChildByName("popups") as DisplayObjectContainer, _factory);
			_popups.addEventListener(Event.CHANGE, onPopupManagerChange);

			_container = new TalonSprite();
			_container.node.setAttribute(Attribute.LAYOUT, Layout.FLOW);
			_container.node.setAttribute(Attribute.VALIGN, VAlign.CENTER);
			_container.node.setAttribute(Attribute.HALIGN, HAlign.CENTER);
			_container.node.setAttribute(Attribute.ID, "IsolatedContainer");

			_isolator.alignPivot();
			_isolator.name = "Isolator";
			_isolator.addChild(_container);

			_errorPage = _interface.getChildByName("bsod") as TalonSprite;
			_errorPage.visible = false;

			_isolatorContainer = _interface.getChildByName("container") as TalonSprite;
			_isolatorContainer.addEventListener(TouchEvent.TOUCH, onIsolatorTouch);
			_isolatorContainer.addChild(_isolator);

			_controller.settings.addPropertyListener(AppConstants.SETTING_BACKGROUND, onBackgroundChange); onBackgroundChange(null);
			_controller.settings.addPropertyListener(AppConstants.SETTING_STATS, onStatsChange); onStatsChange(null);
			_controller.settings.addPropertyListener(AppConstants.SETTING_ZOOM, onZoomChange); onZoomChange(null);
			_controller.settings.addPropertyListener(AppConstants.SETTING_ALWAYS_ON_TOP, onAlwaysOnTopChange); onAlwaysOnTopChange(null);

			resizeTo(_controller.stage.stageWidth, _controller.stage.stageHeight);

			dispatchEventWith(Event.COMPLETE);
		}

		private function onPopupManagerChange(e:Event):void
		{
			locked = _popups.hasOpenedPopup;
		}

		private function onIsolatorTouch(e:TouchEvent):void
		{
			if (e.getTouch(e.currentTarget as DisplayObject, TouchPhase.BEGAN) != null)
			{
				if (_popups.hasOpenedPopup)
					_popups.notify();
			}
		}

		private function onBackgroundChange(e:Event):void
		{
			var styleName:String = _controller.settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, String, AppConstants.SETTING_BACKGROUND_DEFAULT);
			_interface.node.classes.parse(styleName);
			_controller.stage.color = AppConstants.SETTING_BACKGROUND_STAGE_COLOR[styleName];
		}

		private function onStatsChange(e:Event):void
		{
			Starling.current.showStats = _controller.settings.getValueOrDefault(AppConstants.SETTING_STATS, Boolean, false);
		}

		private function onZoomChange(e:Event):void
		{
			zoom = _controller.settings.getValueOrDefault(AppConstants.SETTING_ZOOM, int, 100) / 100;
		}

		private function onAlwaysOnTopChange(e:Event):void
		{
			_controller.stage.nativeWindow.alwaysInFront = _controller.settings.getValueOrDefault(AppConstants.SETTING_ALWAYS_ON_TOP, Boolean, false);
		}

		public function resizeTo(width:int, height:int):void
		{
			if (_interface && (_interface.node.bounds.width != width || _interface.node.bounds.height != height))
			{
				_interface.node.bounds.setTo(0, 0, width, height);
				_interface.node.invalidate();
			}

			if (_container)
			{
				_container.node.bounds.setTo(0, 0, width/zoom, height/zoom);
				_container.node.invalidate();
			}
		}

		//
		// Refresh
		//
		private function refreshWindowTitle():void
		{
			var result:Array = [];

			// Open document/template
			if (_controller.document)
			{
				var title:String = _controller.document.project.name.replace(/\.[^\.]*$/,"");
				if (_templateId) title += "/" + _templateId;
				result.push(title);
			}

			var profile:DeviceProfile = _controller.profile;
			var profileEqual:DeviceProfile = DeviceProfile.getEqual(profile);
			var profileName:String = profileEqual ? profileEqual.id : null;

			// Profile preference
			result.push("[" + profile.width + "x" + profile.height + ", DPI=" + profile.dpi + ", CSF=" + profile.csf + "]");
			// Profile name (if exist)
			if (profileName) result.push(profileName);
			// Zoom (if non 100%)
			if (zoom != 1) result.push(int(zoom * 100) + "%");
			// Application name + version
			result.push(AppConstants.APP_NAME + " " + AppConstants.APP_VERSION.replace(/\.0$/, ""));

			_controller.stage.nativeWindow.title = result.join(" - ");
		}

		private function refreshCurrentTemplate(e:* = null):void
		{
			// Refresh current prototype
			var canShow:Boolean = true;
			canShow &&= _templateId != null;
			canShow &&= _controller.document != null;
			canShow &&= _controller.document.tasks.isBusy == false;
			canShow &&= _controller.document.factory.hasTemplate(_templateId);

			_errorPage.visible = false;
			_container.removeChildren();
			_controller.document && _controller.document.messages.removeMessage(_templateProduceMessage);
			_templateProduceMessage = null;

			_template && _template.removeFromParent(true);
			_template = canShow ? produce(_templateId) : null;

			// Show state
			if (_controller.document && _controller.document.messages.numMessages != 0)
			{
				_errorPage.visible = true;
			}
			else if (_template != null)
			{
				_container.node.ppmm = ITalonElement(_template).node.ppmm;
				_container.node.ppdp = ITalonElement(_template).node.ppdp;
				_container.addChild(_template);
				_controller.stage && resizeTo(_controller.stage.stageWidth, _controller.stage.stageHeight);
			}
		}

		private function produce(templateId:String):DisplayObject
		{
			var result:DisplayObject = null;

			try
			{
				result = _controller.document.factory.produce(templateId);
			}
			catch (e:Error)
			{
				_templateProduceMessage = new DocumentMessage(DocumentMessage.PRODUCE_ERROR, [templateId, e.getStackTrace()]);
				_controller.document.messages.addMessage(_templateProduceMessage);
			}

			return result;
		}

		//
		// Drag&Drop
		//

		//
		// Properties
		//
		public function get popups():PopupManager { return _popups; }

		public function get host():DisplayObjectContainer { return _controller.starling.root as DisplayObjectContainer }

		public function get completed():Boolean { return _completed; }
		public function get factory():TalonFactoryBase { return _factory; }
		public function get template():DisplayObject { return _template; }

		public function get templateId():String { return _templateId; }
		public function set templateId(value:String):void
		{
			if (_templateId != value)
			{
				_templateId = value;
				refreshCurrentTemplate();
				refreshWindowTitle();
			}
		}

		public function get locked():Boolean { return _locked; }
		public function set locked(value:Boolean):void
		{
			if (_locked != value)
			{
				_locked = value;
				_menu.locked = !value;
				_isolatorContainer.filter = _locked ? new BlurFilter(1, 1) : null;
			}
		}

		public function get zoom():Number { return _isolator.scaleX; }
		public function set zoom(value:Number):void
		{
			if (zoom != value)
			{
				_isolator.scaleX = _isolator.scaleY = value;
				resizeTo(_controller.stage.stageWidth, _controller.stage.stageHeight);
				refreshWindowTitle();
			}
		}
	}
}

import starling.core.RenderSupport;
import talon.browser.AppConstants;
import talon.browser.AppPlatform;
import talon.starling.TalonSprite;

class TalonSpriteWithDrawCountReset extends TalonSprite
{
	public override function render(support:RenderSupport, parentAlpha:Number):void
	{
		super.render(support, parentAlpha);
		support.raiseDrawCount(-1);
	}
}

import flash.display.NativeMenuItem;
import flash.display.NativeWindow;
import flash.filesystem.File;
import flash.ui.Keyboard;

import talon.browser.commands.*;
import talon.browser.popups.ProfilePopup;
import talon.browser.utils.DeviceProfile;
import talon.browser.utils.NativeMenuAdapter;

class AppUINativeMenu
{
	private var _controller:AppPlatform;
	private var _menu:NativeMenuAdapter;
	private var _prevDocuments:Array;

	public function AppUINativeMenu(controller:AppPlatform)
	{
		_controller = controller;
		_menu = new NativeMenuAdapter();

		// File
		_menu.insert("file",                                  AppConstants.T_MENU_FILE);
		_menu.insert("file/new",                              AppConstants.T_MENU_FILE_NEW_DOCUMENT,                  new CreateDocumentCommand(_controller), "n");
		//			_menu.push("file/instantiate",                        AppConstants.T_MENU_FILE_NEW_WINDOW,                    new CreateWindowCommand(),              "n", [Keyboard.CONTROL, Keyboard.SHIFT]);
		_menu.insert("file/-");
		_menu.insert("file/recent",                           AppConstants.T_MENU_FILE_RECENT);
		_menu.insert("file/open",                             AppConstants.T_MENU_FILE_OPEN,                          new OpenDocumentCommand(_controller),   "o");
		_menu.insert("file/-");
		_menu.insert("file/closeDocument",                    AppConstants.T_MENU_FILE_CLOSE_DOCUMENT,                new CloseDocumentCommand(_controller),  "w");
		_menu.insert("file/closeBrowser",                     AppConstants.T_MENU_FILE_CLOSE_BROWSER,                 new CloseWindowCommand(_controller),    "w", [Keyboard.CONTROL, Keyboard.SHIFT]);
		_menu.insert("file/-");
		_menu.insert("file/preference",                       AppConstants.T_MENU_FILE_PREFERENCES);
		_menu.insert("file/preference/stats",                 AppConstants.T_MENU_FILE_PREFERENCES_STATS,             new ChangeSettingCommand(_controller, AppConstants.SETTING_STATS, true, false));
		_menu.insert("file/preference/resize",                AppConstants.T_MENU_FILE_PREFERENCES_LOCK_RESIZE,       new ChangeSettingCommand(_controller, AppConstants.SETTING_LOCK_RESIZE, true, false));
		_menu.insert("file/preference/alwaysOnTop",           AppConstants.T_MENU_FILE_PREFERENCES_ALWAYS_ON_TOP,     new ChangeSettingCommand(_controller, AppConstants.SETTING_ALWAYS_ON_TOP, true, false));
		_menu.insert("file/preference/autoReopen",            AppConstants.T_MENU_FILE_PREFERENCES_AUTO_REOPEN,       new ChangeSettingCommand(_controller, AppConstants.SETTING_AUTO_REOPEN, true, false));
		_menu.insert("file/preference/autoUpdate",            AppConstants.T_MENU_FILE_PREFERENCES_AUTO_UPDATE,       new ChangeSettingCommand(_controller, AppConstants.SETTING_CHECK_FOR_UPDATE_ON_STARTUP, true, false));
		_menu.insert("file/-");
		_menu.insert("file/publish",                          AppConstants.T_MENU_FILE_PUBLISH_AS,                    new PublishCommand(_controller),        "s", [Keyboard.CONTROL, Keyboard.SHIFT]);

		// View
		_menu.insert("view",                                  AppConstants.T_MENU_VIEW);
		_menu.insert("view/zoomIn",                           AppConstants.T_MENU_VIEW_ZOOM_IN,                       new ChangeZoomCommand(_controller, +25),   "=");
		_menu.insert("view/zoomOut",                          AppConstants.T_MENU_VIEW_ZOOM_OUT,                      new ChangeZoomCommand(_controller, -25),   "-");
		_menu.insert("view/-");
		_menu.insert("view/rotate",                           AppConstants.T_MENU_VIEW_ROTATE,                        new RotateCommand(_controller), "r", [Keyboard.CONTROL]);
		_menu.insert("view/theme",                            AppConstants.T_MENU_VIEW_BACKGROUND);
		_menu.insert("view/theme/dark",                       AppConstants.T_MENU_VIEW_BACKGROUND_DARK,               new ChangeSettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_DARK));
		_menu.insert("view/theme/light",                      AppConstants.T_MENU_VIEW_BACKGROUND_LIGHT,              new ChangeSettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_LIGHT));
		_menu.insert("view/profile",                          AppConstants.T_MENU_VIEW_PROFILE);
		_menu.insert("view/profile/custom",                   AppConstants.T_MENU_VIEW_PROFILE_CUSTOM,                new OpenPopupCommand(_controller, ProfilePopup, controller.profile), "0", [Keyboard.CONTROL]);
		_menu.insert("view/-");
		_menu.insert("view/fullscreen",                       AppConstants.T_MENU_VIEW_FULL_SCREEN,                   new ToggleFullScreenCommand(_controller), "f");
		_menu.insert("view/profile/-");

		var profiles:Vector.<DeviceProfile> = DeviceProfile.getProfiles();
		for (var i:int = 0; i < profiles.length; i++)
		{
			var profileNumber:String = (i+1).toString();
			var profile:DeviceProfile = profiles[i];
			_menu.insert("view/profile/" + profile.id, null, new ChangeProfileCommand(_controller, profile), profileNumber, [Keyboard.ALTERNATE]);
		}

		// Navigate
		_menu.insert("navigate",                      AppConstants.T_MENU_NAVIGATE);
		_menu.insert("navigate/openProjectFolder",    AppConstants.T_MENU_NAVIGATE_OPEN_DOCUMENT_FOLDER,              new OpenDocumentFolderCommand(_controller));
		_menu.insert("navigate/searchPopup",          AppConstants.T_MENU_NAVIGATE_SEARCH,                            new OpenGoToPopupCommand(_controller), "p", [Keyboard.CONTROL]);

		_controller.settings.addPropertyListener(AppConstants.SETTING_RECENT_DOCUMENTS, refreshRecentOpenedDocumentsList);
		refreshRecentOpenedDocumentsList();

		_menu.insert("help",          AppConstants.T_MENU_HELP);
		_menu.insert("help/online",   AppConstants.T_MENU_HELP_ONLINE);
		_menu.insert("help/update",   AppConstants.T_MENU_HELP_UPDATE, new UpdateCommand(_controller));

		if (NativeWindow.supportsMenu) controller.stage.nativeWindow.menu = _menu.nativeMenu;
	}

	private function refreshRecentOpenedDocumentsList():void
	{
		var recent:Array = _controller.settings.getValueOrDefault(AppConstants.SETTING_RECENT_DOCUMENTS, Array, []).filter(isFileByPathExist);
		if (isEqual(recent, _prevDocuments)) return;
		_prevDocuments = recent;

		var recentMenu:NativeMenuAdapter = _menu.getChildByPath("file/recent");
		recentMenu.isMenu = true;
		recentMenu.removeChildren();
		recentMenu.isEnabled = recent.length > 0;

		if (recent.length > 0)
		{
			for each (var path:String in recent)
				recentMenu.insert(path, null, new OpenDocumentCommand(_controller, new File(path)));

			recentMenu.insert("-");
			recentMenu.insert("clear", AppConstants.T_MENU_FILE_RECENT_CLEAR, new ChangeSettingCommand(_controller, AppConstants.SETTING_RECENT_DOCUMENTS, []));
		}
	}

	private function isFileByPathExist(path:String, index:int, array:Array):Boolean
	{
		var file:File = new File(path);
		return file.exists;
	}

	private static function isEqual(list1:*, list2:*):Boolean
	{
		if (list1 == null || list2 == null) return false;

		var length1:int = list1.length;
		var length2:int = list2.length;
		if (length1 != length2) return false;

		for (var i:int = 0; i < length1; i++)
			if (list1[i] != list2[i]) return false;

		return true;
	}

	public function get locked():Boolean { return _menu.isEnabled; }
	public function set locked(value:Boolean):void
	{
		if (_menu.isEnabled != value)
		{
			_menu.isEnabled = value;

			for each (var item:NativeMenuItem in _menu.nativeMenu.items)
				item.enabled = value;
		}
	}
}