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
	import talon.utils.StringUtil;
	import talon.utils.TalonFactoryBase;

	public class AppUI extends EventDispatcher
	{
		[Embed(source="/../assets/interface.zip", mimeType="application/octet-stream")] private static const INTERFACE:Class;
		[Embed(source="/../assets/SourceSansPro.otf", embedAsCFF="false", fontName="Source Sans Pro")] private static const INTERFACE_FONT:Class;
		[Embed(source="/../assets/locale/en_US.properties", mimeType="application/octet-stream")] private static const INTERFACE_LOCALE:Class;

		private var _platform:AppPlatform;
		private var _menu:AppUINativeMenu;
		private var _popups:PopupManager;

		private var _locale:Object;
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
			_platform = controller;
			_platform.addEventListener(AppPlatform.EVENT_DOCUMENT_CHANGE, refreshWindowTitle);
			_platform.profile.addEventListener(Event.CHANGE, refreshWindowTitle);

			_platform.addEventListener(AppPlatform.EVENT_DOCUMENT_CHANGE, refreshCurrentTemplate);
			_platform.addEventListener(DocumentEvent.CHANGE, refreshCurrentTemplate);

			_isolator = new Sprite();
			_locale = StringUtil.parseProperties(new INTERFACE_LOCALE());
			_menu = new AppUINativeMenu(_platform, _locale);
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
			_factory.addResourcesFromObject(_locale);
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

			_platform.settings.addPropertyListener(AppConstants.SETTING_BACKGROUND, onBackgroundChange); onBackgroundChange(null);
			_platform.settings.addPropertyListener(AppConstants.SETTING_STATS, onStatsChange); onStatsChange(null);
			_platform.settings.addPropertyListener(AppConstants.SETTING_ZOOM, onZoomChange); onZoomChange(null);
			_platform.settings.addPropertyListener(AppConstants.SETTING_ALWAYS_ON_TOP, onAlwaysOnTopChange); onAlwaysOnTopChange(null);

			resizeTo(_platform.profile.width, _platform.profile.height);

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
			var styleName:String = _platform.settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, String, AppConstants.SETTING_BACKGROUND_DEFAULT);
			_interface.node.classes.parse(styleName);
			_platform.stage.color = AppConstants.SETTING_BACKGROUND_STAGE_COLOR[styleName];
		}

		private function onStatsChange(e:Event):void
		{
			Starling.current.showStats = _platform.settings.getValueOrDefault(AppConstants.SETTING_STATS, Boolean, false);
		}

		private function onZoomChange(e:Event):void
		{
			zoom = _platform.settings.getValueOrDefault(AppConstants.SETTING_ZOOM, int, 100) / 100;
		}

		private function onAlwaysOnTopChange(e:Event):void
		{
			_platform.stage.nativeWindow.alwaysInFront = _platform.settings.getValueOrDefault(AppConstants.SETTING_ALWAYS_ON_TOP, Boolean, false);
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


				trace("Resize", _container.node.bounds, width, height);
			}
		}

		//
		// Refresh
		//
		private function refreshWindowTitle():void
		{
			var result:Array = [];

			// Open document/template
			if (_platform.document)
			{
				var title:String = _platform.document.project.name.replace(/\.[^\.]*$/,"");
				if (_templateId) title += "/" + _templateId;
				result.push(title);
			}

			var profile:DeviceProfile = _platform.profile;
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

			_platform.stage.nativeWindow.title = result.join(" - ");
		}

		private function refreshCurrentTemplate(e:* = null):void
		{
			// Refresh current prototype
			var canShow:Boolean = true;
			canShow &&= _templateId != null;
			canShow &&= _platform.document != null;
			canShow &&= _platform.document.tasks.isBusy == false;
			canShow &&= _platform.document.factory.hasTemplate(_templateId);

			_errorPage.visible = false;
			_container.removeChildren();
			_platform.document && _platform.document.messages.removeMessage(_templateProduceMessage);
			_templateProduceMessage = null;

			_template && _template.removeFromParent(true);
			_template = canShow ? produce(_templateId) : null;

			// Show state
			if (_platform.document && _platform.document.messages.numMessages != 0)
			{
				_errorPage.visible = true;
			}
			else if (_template != null)
			{
				_container.node.ppmm = ITalonElement(_template).node.ppmm;
				_container.node.ppdp = ITalonElement(_template).node.ppdp;
				_container.addChild(_template);
				resizeTo(_platform.profile.width, _platform.profile.height);
			}
		}

		private function produce(templateId:String):DisplayObject
		{
			var result:DisplayObject = null;

			try
			{
				result = _platform.document.factory.produce(templateId);
			}
			catch (e:Error)
			{
				_templateProduceMessage = new DocumentMessage(DocumentMessage.PRODUCE_ERROR, [templateId, e.getStackTrace()]);
				_platform.document.messages.addMessage(_templateProduceMessage);
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

		public function get host():DisplayObjectContainer { return _platform.starling.root as DisplayObjectContainer }

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
				resizeTo(_platform.profile.width, _platform.profile.height);
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
	private var _locale:Object;
	private var _platform:AppPlatform;
	private var _menu:NativeMenuAdapter;
	private var _prevDocuments:Array;

	public function AppUINativeMenu(platform:AppPlatform, locale:Object)
	{
		_platform = platform;
		_locale = locale;
		_menu = new NativeMenuAdapter();

		// new CreateWindowCommand(),              "n", [Keyboard.CONTROL, Keyboard.SHIFT]);

		// File
		insert("file");
		insert("file/newDocument",             new  CreateDocumentCommand(_platform), "ctrl-n");
		insert("file/-");
		insert("file/recent");
		insert("file/openDocument",            new  OpenDocumentCommand(_platform), "ctrl-o");
		insert("file/-");
		insert("file/closeDocument",           new  CloseDocumentCommand(_platform), "ctrl-w");
		insert("file/closeBrowser",            new  CloseWindowCommand(_platform), "shift-ctrl-w");
		insert("file/-");
		insert("file/preferences");
		insert("file/preferences/stats",       new  ChangeSettingCommand(_platform, AppConstants.SETTING_STATS, true, false));
		insert("file/preferences/lockResize",  new  ChangeSettingCommand(_platform, AppConstants.SETTING_LOCK_RESIZE, true, false));
		insert("file/preferences/alwaysOnTop", new  ChangeSettingCommand(_platform, AppConstants.SETTING_ALWAYS_ON_TOP, true, false));
		insert("file/preferences/autoReopen",  new  ChangeSettingCommand(_platform, AppConstants.SETTING_AUTO_REOPEN, true, false));
		insert("file/preferences/autoUpdate",  new  ChangeSettingCommand(_platform, AppConstants.SETTING_CHECK_FOR_UPDATE_ON_STARTUP, true, false));
		insert("file/-");
		insert("file/publishAs",               new  PublishCommand(_platform), "shift-ctrl-s");

		// View
		insert("view");
		insert("view/zoomIn",                  new  ChangeZoomCommand(_platform, +25), "=");
		insert("view/zoomOut",                 new  ChangeZoomCommand(_platform, -25), "-");
		insert("view/-");
		insert("view/rotate",                  new  RotateCommand(_platform), "ctrl-r");
		insert("view/theme");
		insert("view/theme/dark",              new  ChangeSettingCommand(_platform, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_DARK));
		insert("view/theme/light",             new  ChangeSettingCommand(_platform, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_LIGHT));
		insert("view/profile");
		insert("view/profile/custom",          new  OpenPopupCommand(_platform, ProfilePopup, platform.profile), "alt-0");
		insert("view/profile/-");

		var profiles:Vector.<DeviceProfile> = DeviceProfile.getProfiles();
		for (var i:int = 0; i < profiles.length; i++)
		{
			var profileNumber:String = (i+1).toString();
			var profile:DeviceProfile = profiles[i];
			insert("view/profile/" + profile.id, new ChangeProfileCommand(_platform, profile), "alt-" + profileNumber);
		}

		insert("view/-");
		insert("view/fullScreen",             new  ToggleFullScreenCommand(_platform), "ctrl-f");

		// Navigate
		insert("navigate");
		insert("navigate/gotoDir", new OpenDocumentFolderCommand(_platform));
		insert("navigate/gotoTemplate", new OpenGoToPopupCommand(_platform), "ctrl-p");

		_platform.settings.addPropertyListener(AppConstants.SETTING_RECENT_DOCUMENTS, refreshRecentOpenedDocumentsList);
		refreshRecentOpenedDocumentsList();

		insert("help");
		insert("help/online");
		insert("help/update", new UpdateCommand(_platform));

		if (NativeWindow.supportsMenu) platform.stage.nativeWindow.menu = _menu.nativeMenu;
	}

	private function insert(path:String, command:Command = null, shortcut:String = null):void
	{
		var labelKey:String = "menu." + path.replace(/\//g, ".");
		var label:String = labelKey in _locale ? _locale[labelKey] : path.split("/").pop();

		var keyPattern:RegExp = /^(SHIFT-)?(CTRL-)?(ALT-)?(\w)$/;
		var keySplit:Array = (shortcut ? keyPattern.exec(shortcut.toUpperCase()) : null) || [];
		var keyModifiers:Array = [];
		if (keySplit[1]) keyModifiers.push(Keyboard.SHIFT);
		if (keySplit[2]) keyModifiers.push(Keyboard.CONTROL);
		if (keySplit[3]) keyModifiers.push(Keyboard.ALTERNATE);
		var key:String = null;
		if (keySplit[4]) key = keySplit[4].toLowerCase();

		_menu.insert(path, label, command, key, keyModifiers);
	}

	private function refreshRecentOpenedDocumentsList():void
	{
		var recent:Array = _platform.settings.getValueOrDefault(AppConstants.SETTING_RECENT_DOCUMENTS, Array, []).filter(isFileByPathExist);
		if (isEqual(recent, _prevDocuments)) return;
		_prevDocuments = recent;

		var recentMenu:NativeMenuAdapter = _menu.getChildByPath("file/recent");
		recentMenu.isMenu = true;
		recentMenu.removeChildren();
		recentMenu.isEnabled = recent.length > 0;

		if (recent.length > 0)
		{
			for each (var path:String in recent)
				recentMenu.insert(path, null, new OpenDocumentCommand(_platform, new File(path)));

			recentMenu.insert("-");
			recentMenu.insert("clear", _locale["menu.file.recent.clear"], new ChangeSettingCommand(_platform, AppConstants.SETTING_RECENT_DOCUMENTS, []));
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
