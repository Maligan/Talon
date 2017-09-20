package talon.browser.desktop.plugins
{
	import flash.display.Graphics;
	import flash.display.NativeWindow;
	import flash.events.NativeWindowBoundsEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.display.Stage;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.ITalonDisplayObject;
	import starling.extensions.TalonSprite;
	import starling.filters.FragmentFilter;
	import starling.text.ITextCompositor;
	import starling.text.TextField;
	import starling.utils.AssetManager;
	import starling.utils.Color;
	import starling.utils.StringUtil;

	import talon.browser.desktop.commands.OpenDocumentCommand;
	import talon.browser.desktop.popups.widgets.TalonFeatherTextInput;
	import talon.browser.desktop.utils.DesktopDocumentProperty;
	import talon.browser.desktop.utils.FileMonitor;
	import talon.browser.desktop.utils.FileUtil;
	import talon.browser.desktop.utils.GithubUpdater;
	import talon.browser.desktop.utils.Inspector;
	import talon.browser.desktop.utils.Promise;
	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.document.DocumentEvent;
	import talon.browser.platform.document.log.DocumentMessage;
	import talon.browser.platform.plugins.IPlugin;
	import talon.browser.platform.popups.PopupManager;
	import talon.browser.platform.utils.DeviceProfile;
	import talon.browser.platform.utils.Storage;
	import talon.core.Attribute;
	import talon.enums.FillMode;
	import talon.layouts.Layout;
	import talon.utils.ParseUtil;

	public class PluginDesktopUI extends EventDispatcher implements IPlugin
	{
		private var _platform:AppPlatform;
		private var _menu:AppUINativeMenu;
		private var _updater:GithubUpdater;

		private var _uiFont:ITextCompositor;
		private var _ui:TalonSprite;
		private var _container:TalonSprite;
		private var _messages:TalonSprite;
		private var _templateContainer:TalonSprite;
		private var _inspector:Inspector;

		private var _template:DisplayObject;
		private var _templateProduceMessage:DocumentMessage;
		private var _locked:Boolean;
		
		private var _documentMonitor:FileMonitor;
		
		public function get id():String { return "UI"; }
		public function get version():String{ return "1.0.0"; }
		public function get versionAPI():String { return "1.0.0"; }
		public function detach():void { }

		/** Call after starling initialize completed. */
		public function attach(platform:AppPlatform):void
		{
			_platform = platform;
			_updater = new GithubUpdater("maligan/talon", "0.0.0");
			_documentMonitor = new FileMonitor();
			
			initListeners()
				.then(initSettings)
				.then(initWindow)
				.then(initLocale)
				.then(initUI);
		}
		
		private function initListeners():Promise
		{
			_platform.addEventListener(AppPlatformEvent.STARTED, onPlatformStart);
			_platform.addEventListener(AppPlatformEvent.INVOKE, onPlatformInvoke);

			_platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
			_platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, refreshWindowFont);
			_platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, refreshWindowTitle);
			_platform.addEventListener(AppPlatformEvent.TEMPLATE_CHANGE, refreshWindowTitle);

			_documentMonitor.addEventListener(Event.CHANGE, onDocumentFileChange);
			_documentMonitor.watch();

			_platform.profile.addEventListener(Event.CHANGE, refreshWindowTitle);
			_platform.profile.addEventListener(Event.CHANGE, onProfileChange);
			
			var promise:Promise = new Promise();
			promise.fulfill();
			return promise;
		}
		
		private function initWindow():void
		{
			// Restore window position and size
			var lastBounds:Rectangle = _platform.settings.getValue(AppConstants.SETTING_WINDOW_SIZE, Rectangle);
			if (lastBounds)
			{
				_platform.stage.nativeWindow.x = lastBounds.x;
				_platform.stage.nativeWindow.y = lastBounds.y;
				_platform.stage.nativeWindow.width = lastBounds.width;
				_platform.stage.nativeWindow.height = lastBounds.height;
			}
			else // if useFreeResolution
			{
				resizeWindowTo(_platform.profile.width, _platform.profile.height);
			}

			// Observe window size
			_platform.stage.nativeWindow.minSize = new Point(200, 100);
			_platform.stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.MOVE, onWindowMove);
			_platform.stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZING, onWindowResizing);

			// Event handlers
			function onWindowResizing(e:NativeWindowBoundsEvent):void
			{
				// NativeWindow#resizable is read only, this is fix:
				var needPrevent:Boolean = _platform.settings.getValue(AppConstants.SETTING_WINDOW_SIZE_LOCK, Boolean, false);
				if (needPrevent) e.preventDefault();
				else _platform.settings.setValue(AppConstants.SETTING_WINDOW_SIZE, e.afterBounds);
			}

			function onWindowMove(e:NativeWindowBoundsEvent):void
			{
				_platform.settings.setValue(AppConstants.SETTING_WINDOW_SIZE, e.afterBounds);
			}
		}
		
		private function initSettings():void
		{
			var settingsFile:File = File.applicationDirectory.resolvePath("settings");
			if (settingsFile.exists)
			{
				var settingsData:String = FileUtil.readText(settingsFile);
				var settings:Storage = Storage.fromProperties(settingsData);
				
				var profiles:Vector.<String> = settings.getNames("profile");
				for each (var profile:String in profiles)
				{
					var split:Array = settings.getValue(profile).split(";");
					
					if (split.length != 5) continue;
					var name:String = split[0];
					var width:int = split[1];
					var height:int = split[2];
					var dpi:int = split[3];
					var csf:Number = split[4];
					
					if (!name) continue;
					if (width <= 0) continue;
					if (height <= 0) continue;
					if (dpi <= 0) continue;
					if (csf != csf || csf <= 0) continue;
					
					DeviceProfile.registerDeviceProfile(
						split[0],
						split[1],
						split[2],
						split[3],
						split[4]
					)
				}
			}
		}

		private function initLocale(lang:String):void
		{
			lang = "en_US";
			
			var filePath:String = StringUtil.format("locales/{0}.properties", lang);
			var fileLocale:File = File.applicationDirectory.resolvePath(filePath);
			if (fileLocale.exists)
			{
				var localeData:String = FileUtil.readText(fileLocale);
				var localeProperties:Object = ParseUtil.parseProperties(localeData);
				_platform.locale.merge(localeProperties, lang);
				_platform.locale.language = lang;
			}
			else
			{
				throw new Error("Can't find locale file:\n" + fileLocale.nativePath);
			}
		}
		
		private function initUI():void
		{
			_menu = new AppUINativeMenu(_platform, this, _platform.locale.values);

			var filePath:String = "layouts.zip";
			var fileInterface:File = File.applicationDirectory.resolvePath(filePath);
			if (fileInterface.exists)
			{
				var interfaceBytes:ByteArray = FileUtil.readBytes(fileInterface);
				_platform.factory.setTerminal("input", TalonFeatherTextInput);
				_platform.factory.importResources(_platform.locale.values);
				
				var assets:AssetManager = _platform.factory.importArchiveAsync(interfaceBytes, function():void
				{
					_ui = _platform.factory.build("Interface") as TalonSprite;
					_ui.node.bounds.setTo(0, 0, _platform.starling.stage.stageWidth, _platform.starling.stage.stageHeight);
					DisplayObjectContainer(_platform.starling.root).addChild(_ui);

					_uiFont = TextField.getCompositor("Source_Sans_Pro");

					// popups container
					_platform.popups.host = _ui.query("#popups")[0] as DisplayObjectContainer;
					_platform.popups.addEventListener(Event.CHANGE, onPopupManagerChange);

					// messages container
					_messages = _ui.query("#messages")[0] as TalonSprite;
					
					// inspector
					_inspector = new Inspector(_platform.factory, _ui.query("#inspector")[0]);
					_inspector.visible = false;
					_platform.settings.setValue(AppConstants.SETTING_SHOW_INSPECTOR, false);

					// template container - split hierarchy with isolator for stopping style/resource inheritance
					var isolator:Sprite = new Sprite();
					
					_templateContainer = new TalonSprite();
					_templateContainer.node.setAttribute(Attribute.ID, "isolator");
					_templateContainer.node.setAttribute(Attribute.LAYOUT, Layout.ANCHOR);
					_templateContainer.node.setAttribute(Attribute.FILL_MODE, FillMode.REPEAT);
					_templateContainer.node.setResources({
						"dark":		assets.getTexture("bg_dark"),
						"light":	assets.getTexture("bg_light")
					});
					isolator.addChild(_templateContainer);

					_container = _ui.query("#container")[0] as TalonSprite;
					_container.addEventListener(TouchEvent.TOUCH, onIsolatorTouch);
					_container.addChild(isolator);

					// listeners
					_platform.settings.addPropertyListener(AppConstants.SETTING_BACKGROUND, onBackgroundChange); 		onBackgroundChange(null);
					_platform.settings.addPropertyListener(AppConstants.SETTING_STATS, onStatsChange); 					onStatsChange(null);
					_platform.settings.addPropertyListener(AppConstants.SETTING_SHOW_OUTLINE, onOutlineChange); 		onOutlineChange(null);
					_platform.settings.addPropertyListener(AppConstants.SETTING_SHOW_INSPECTOR, onInspectorChange);		onInspectorChange(null);
					_platform.settings.addPropertyListener(AppConstants.SETTING_ZOOM, onZoomChange); 					onZoomChange(null);
					_platform.settings.addPropertyListener(AppConstants.SETTING_ALWAYS_ON_TOP, onAlwaysOnTopChange); 	onAlwaysOnTopChange(null);
					_platform.settings.addPropertyListener(AppConstants.SETTING_PROFILE_BIND_MODE, onBindChange);		onBindChange();

					_platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, refreshCurrentTemplate);
					_platform.addEventListener(AppPlatformEvent.TEMPLATE_CHANGE, refreshCurrentTemplate);
					_platform.addEventListener(DocumentEvent.CHANGE, refreshCurrentTemplate);

					_platform.stage.addEventListener(Event.RESIZE, onStageResize);

					// ready
					locked = false;
					refreshCurrentTemplate();
				})
			}
			else
			{
				throw new Error("Can't find interface file:\n" + fileInterface.nativePath);
			}
		}

		private function onPlatformStart(e:Event):void
		{
			// [UPDATE]
			var isEnableAutoUpdate:Boolean = _platform.settings.getValue(AppConstants.SETTING_CHECK_FOR_UPDATE_ON_STARTUP, Boolean, true);
			// TODO: Save for have default value != null
			_platform.settings.setValue(AppConstants.SETTING_CHECK_FOR_UPDATE_ON_STARTUP, isEnableAutoUpdate);

			// FIXME: Auto check
			 if (isEnableAutoUpdate) _updater.check().then(function(url:String):void
			 {
				 if (url) trace("[Updater]", "There is new version:", url);
			 });

			// [REOPEN]
			var invArgs:Array = e.data as Array;
			var invTemplate:String = null;

			// Document can be opened via invoke (click on document file)
			// in this case need omit autoReopen feature
			var isEnableReopen:Boolean = _platform.settings.getValue(AppConstants.SETTING_AUTO_REOPEN, Boolean, false);
			if (isEnableReopen && invArgs.length == 0)
			{
				var template:String = _platform.settings.getValue(AppConstants.SETTING_RECENT_TEMPLATE, String);
				var recentArray:Array = _platform.settings.getValue(AppConstants.SETTING_RECENT_DOCUMENTS, Array);
				var recentPath:String = recentArray && recentArray.length ? recentArray[0] : null;
				if (recentPath)
				{
					invArgs = [recentPath];
					invTemplate = template;
				}
			}

			// Do reopen
			if (invArgs != null) _platform.invoke(invArgs);
			if (invTemplate != null) _platform.templateId = invTemplate;
		}

		private function onPlatformInvoke(e:Event):void
		{
			var args:Array = e.data as Array;
			if (args && args.length>0)
			{
				var filePath:String = args[0];
				var file:File = new File(filePath);
				if (file.exists)
					new OpenDocumentCommand(_platform, file).execute();
			}
		}

		private function onProfileChange(e:Event):void
		{
			if (isProfileBindModeEnable)
			{
				zoom = 1;
				resizeWindowTo(_platform.profile.width, _platform.profile.height);
				refreshTemplateContainer();
			}
			else
			{
				refreshTemplateContainer();
			}
		}

		private function onDocumentChange(e:Event):void
		{
			var documentFile:File = null;
			if (_platform.document != null)
			{
				var documentDir:String = _platform.document.properties.getValue(DesktopDocumentProperty.PROJECT_DIR, String, null);
				documentFile = new File(documentDir + "/" + AppConstants.BROWSER_DOCUMENT_FILENAME);
			}
			
			_documentMonitor.file = documentFile;
		}
		
		private function onDocumentFileChange(e:Event):void
		{
			new OpenDocumentCommand(_platform, _documentMonitor.file.parent).execute();
		}
		
		private function onStageResize(e:* = null):void
		{
			_ui && _ui.node.bounds.setTo(0, 0, _platform.starling.stage.stageWidth, _platform.starling.stage.stageHeight);

			if (isProfileBindModeEnable)
			{
				_platform.profile.setSize
				(
					_platform.starling.stage.stageWidth,
					_platform.starling.stage.stageHeight
				);
			}
			else
			{
				refreshTemplateContainer();
			}
		}
		//
		// Native Window
		//
		private function resizeWindowTo(stageWidth:int, stageHeight:int):void
		{
			if (_platform.stage.stageWidth != stageWidth || _platform.stage.stageHeight != stageHeight)
			{
				var window:NativeWindow = _platform.stage.nativeWindow;
				var deltaWidth:int = window.width - _platform.stage.stageWidth;
				var deltaHeight:int = window.height - _platform.stage.stageHeight;
				window.width = Math.max(stageWidth + deltaWidth, window.minSize.x);
				window.height = Math.max(stageHeight + deltaHeight, window.minSize.y);
			}
		}

		//
		// Logic
		//

		private function onPopupManagerChange(e:Event):void
		{
			locked = _platform.popups.hasOpenedPopup;
			refreshOutline(_template);
		}

		private function onIsolatorTouch(e:TouchEvent):void
		{
			if (e.getTouch(e.currentTarget as DisplayObject, TouchPhase.BEGAN) != null)
			{
				if (_platform.popups.hasOpenedPopup)
					_platform.popups.notify();
			}
		}

		private function onBackgroundChange(e:Event):void
		{
			var styleName:String = _platform.settings.getValue(AppConstants.SETTING_BACKGROUND, String, AppConstants.SETTING_BACKGROUND_DEFAULT);
			_templateContainer.node.setAttribute(Attribute.FILL, "$" + styleName);
		}

		private function onStatsChange(e:Event):void
		{
			Starling.current.showStats = _platform.settings.getValue(AppConstants.SETTING_STATS, Boolean, false);
		}

		private function onOutlineChange(e:Event):void
		{
			refreshOutline(_template);
		}
		
		private function onInspectorChange(e:Event):void
		{
			_inspector.visible = _platform.settings.getValue(AppConstants.SETTING_SHOW_INSPECTOR, Boolean, false);
			onProfileChange(null);
		}
		
		private function onBindChange():void
		{
			onProfileChange(null);
		}

		private function onZoomChange(e:Event):void
		{
			refreshWindowTitle();
			//refreshTemplateContainer();
			refreshOutline(_template);
		}

		private function onAlwaysOnTopChange(e:Event):void
		{
			_platform.stage.nativeWindow.alwaysInFront = _platform.settings.getValue(AppConstants.SETTING_ALWAYS_ON_TOP, Boolean, false);
		}

		//
		// Refresh
		//
		private function refreshWindowFont():void
		{
			// If you close file which contain internal browser font :-)
			if (_uiFont != null)
				TextField.registerCompositor(_uiFont, "Source_Sans_Pro")
		}

		private function refreshWindowTitle():void
		{
			var result:Array = [];

			// Opened document/template
			if (_platform.document)
			{
				var title:String = _platform.document.properties.getValue(DesktopDocumentProperty.PROJECT_NAME, String);
				if (_platform.templateId) title += "/" + _platform.templateId;
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
			result.push([AppConstants.APP_NAME, AppConstants.APP_VERSION, AppConstants.APP_VERSION_LABEL].join(" "));

			_platform.stage.nativeWindow.title = result.join(" - ");
		}
		
		private function refreshCurrentTemplate(e:* = null):void
		{
			// Refresh current prototype
			var canShow:Boolean = true;
			canShow &&= _platform.templateId != null;
			canShow &&= _platform.document != null;
			canShow &&= _platform.document.tasks.isBusy == false;
			canShow &&= _platform.document.factory.hasTemplate(_platform.templateId);

			_templateContainer.removeChildren(0, -1, true);
			_platform.document && _platform.document.messages.removeMessage(_templateProduceMessage);
			_templateProduceMessage = null;
			_template = canShow ? produce(_platform.templateId) : null;

			if (_template != null)
			{
				_templateContainer.node.metrics.ppmm = ITalonDisplayObject(_template).node.metrics.ppmm;
				_templateContainer.node.metrics.ppdp = ITalonDisplayObject(_template).node.metrics.ppdp;
				_templateContainer.addChild(_template);
				
				_inspector.setTree(ITalonDisplayObject(_template).node);
				
				// Add missed resource
				_platform.document.messages.removeMessagesByNumber(12);
				var resources:Vector.<String> = _platform.document.factory.getResourceMissed();
				if (resources.length != 0)
				{
					for each (var resource:String in resources)
					{
						_platform.document.messages.addMessage(new DocumentMessage(
							DocumentMessage.TEMPLATE_RESOURCE_MISS,
							[_platform.templateId, resource]
						));
					}
				}

				// Add conflict resource
				_platform.document.messages.removeMessagesByNumber(13);
				resources = _platform.document.factory.getResourceConflict();
				if (resources.length != 0)
				{
					for each (resource in resources)
					{
						_platform.document.messages.addMessage(new DocumentMessage(
							DocumentMessage.RESOURCE_CONFLICT,
							[resource]
						));
					}
				}
			}

			refreshMessages();
			refreshTemplateContainer();
			refreshOutline(_template);

			dispatchEventWith(Event.CHANGE);
		}

		public function refreshTemplateContainer():void
		{
			if (_templateContainer)
			{
				var cw:Number = _platform.profile.width;
				var ch:Number = _platform.profile.height;
				_templateContainer.node.bounds.setTo(0, 0, cw, ch);

				_ui.bounds;
				var pw:Number = ITalonDisplayObject(_templateContainer.parent.parent).node.bounds.width;
				var ph:Number = ITalonDisplayObject(_templateContainer.parent.parent).node.bounds.height;

				// Recalculate zoom
				zoom = Math.min(1, pw/cw, ph/ch);
				
				// Align in center
				_templateContainer.parent.scale = zoom;
				_templateContainer.parent.x = (pw - cw*zoom)/2;
				_templateContainer.parent.y = (ph - ch*zoom)/2;
				_templateContainer.node.setAttribute(Attribute.FILL_SCALE, (1/zoom).toString());

				_template && refreshOutline(_template);
			}
		}

		private function refreshMessages():void
		{
			_messages.removeChildren();

			if (_platform.document)
			{
				for (var i:int = 0; i < _platform.document.messages.numMessages; i++)
				{
					var messageData:DocumentMessage = _platform.document.messages.getMessageAt(i);
					var messageView:ITalonDisplayObject = _platform.factory.build("Message");
					messageView.node.setAttribute(Attribute.TEXT, messageData.text);
					messageView.node.setAttribute(Attribute.CLASS, messageData.level==2 ? "error" : "warning");
					_messages.addChild(messageView as DisplayObject);
				}
			}
		}

		private function refreshOutline(displayObject:DisplayObject):void
		{
			var graphics:Graphics = Starling.current.nativeOverlay.graphics;
			graphics.clear();

			if (outline && !locked)
			{
				graphics.lineStyle(1, Color.FUCHSIA);
				refreshOutlineRect(graphics, displayObject);
			}
		}

		private function refreshOutlineRect(graphics:Graphics, displayObject:DisplayObject, deep:Number = -1):void
		{
			if (deep!=0 && displayObject && displayObject.stage)
			{
				var helper:Rectangle = new Rectangle();
				var helperPoint:Point = new Point();

				var displayObjectAsTalonElement:ITalonDisplayObject = displayObject as ITalonDisplayObject;
				if (displayObjectAsTalonElement)
				{
					var bounds:Rectangle = displayObjectAsTalonElement.node.bounds;
					if (bounds.width == bounds.width && bounds.height == bounds.height)
					{
						var isVisible:Boolean = displayObject.visible;
						var isVisibleCursor:DisplayObject = displayObject.parent;

						while (isVisible && isVisibleCursor && !(isVisibleCursor is Stage))
						{
							isVisible = isVisibleCursor.visible;
							isVisibleCursor = isVisibleCursor.parent;
						}

						if (isVisible)
						{
							var parent:DisplayObjectContainer = displayObject.parent;

							parent.localToGlobal(bounds.topLeft, helperPoint);
							helper.left = helperPoint.x;
							helper.top = helperPoint.y;

							parent.localToGlobal(bounds.bottomRight, helperPoint);
							helper.right = helperPoint.x;
							helper.bottom = helperPoint.y;

							graphics.drawRect(helper.x, helper.y, helper.width, helper.height);
						}
					}
				}

				var displayObjectAsContainer:DisplayObjectContainer = displayObject as DisplayObjectContainer;
				if (displayObjectAsContainer)
				{
					for (var i:int = 0; i < displayObjectAsContainer.numChildren; i++)
						refreshOutlineRect(graphics, displayObjectAsContainer.getChildAt(i), deep-1);
				}
			}
		}
		
		private function produce(templateId:String):DisplayObject
		{
			var result:DisplayObject = null;

			try
			{
				result = _platform.document.factory.build(templateId) as DisplayObject;
			}
			catch (e:Error)
			{
				_templateProduceMessage = new DocumentMessage(DocumentMessage.TEMPLATE_INSTANTIATE_ERROR, [templateId, "Error: " + e.message + "."]);
				_platform.document.messages.addMessage(_templateProduceMessage);
			}

			return result;
		}
		
		//
		// Properties
		//
		public function get template():DisplayObject { return _template; }
		public function get updater():GithubUpdater { return _updater; }
		public function get popups():PopupManager { return _platform.popups; }

		public function get locked():Boolean { return _locked; }
		public function set locked(value:Boolean):void
		{
			if (_locked != value)
			{
				_locked = value;
				_menu.locked = !value;
				_container.touchGroup = value;

				if (_locked)
				{
					_container.filter = ParseUtil.parseClass(FragmentFilter, "blur(2) tint(gray)");
				}
				else if (_container.filter)
				{
					_container.filter.dispose();
					_container.filter = null;
				}
			}
		}

		public function get zoom():Number { return _platform.settings.getValue(AppConstants.SETTING_ZOOM, Number, 1); }
		public function set zoom(value:Number):void { if (zoom != value) _platform.settings.setValue(AppConstants.SETTING_ZOOM, value); }

		public function get isProfileBindModeEnable():Boolean {
			return _platform.settings.getValue(AppConstants.SETTING_PROFILE_BIND_MODE, Boolean, true) 
			   && !_platform.settings.getValue(AppConstants.SETTING_SHOW_INSPECTOR, Boolean, false)
		}
		
		public function get outline():Boolean
		{
			return _platform.settings.getValue(AppConstants.SETTING_SHOW_OUTLINE, Boolean, false);
		}
	}
}

import flash.display.NativeMenuItem;
import flash.display.NativeWindow;
import flash.filesystem.File;
import flash.ui.Keyboard;

import talon.browser.desktop.commands.*;
import talon.browser.desktop.plugins.PluginDesktopUI;
import talon.browser.desktop.popups.ProfilePopup;
import talon.browser.desktop.utils.NativeMenuAdapter;
import talon.browser.platform.AppConstants;
import talon.browser.platform.AppPlatform;
import talon.browser.platform.utils.Command;
import talon.browser.platform.utils.DeviceProfile;

class AppUINativeMenu
{
	private var _locale:Object;
	private var _platform:AppPlatform;
	private var _menu:NativeMenuAdapter;
	private var _prevDocuments:Array;

	public function AppUINativeMenu(platform:AppPlatform, ui:PluginDesktopUI, locale:Object)
	{
		_platform = platform;
		_locale = locale;
		_menu = new NativeMenuAdapter();

		// File
		insert("file");
		insert("file/openDocument",            new  OpenDocumentCommand(_platform), "ctrl-o");
		insert("file/recent");
		insert("file/-");
		insert("file/closeDocument",           new  CloseDocumentCommand(_platform), "ctrl-w");
		insert("file/closeBrowser",            new  CloseWindowCommand(_platform), "shift-ctrl-w");
		insert("file/-");
		insert("file/preferences");
		insert("file/preferences/lockResize",    new ChangeSettingCommand(_platform, AppConstants.SETTING_WINDOW_SIZE_LOCK, true, false));
		insert("file/preferences/alwaysOnTop",   new ChangeSettingCommand(_platform, AppConstants.SETTING_ALWAYS_ON_TOP, true, false));
		insert("file/preferences/autoReopen",    new ChangeSettingCommand(_platform, AppConstants.SETTING_AUTO_REOPEN, true, false));
		insert("file/preferences/autoUpdate",    new ChangeSettingCommand(_platform, AppConstants.SETTING_CHECK_FOR_UPDATE_ON_STARTUP, true, false));
		insert("file/preferences/stats",         new ChangeSettingCommand(_platform, AppConstants.SETTING_STATS, true, false));
		insert("file/preferences/texturePacker", new ChangeTexturePackerExecutable(_platform));
		insert("file/-");
		insert("file/publishAs",               new  PublishCommand(_platform), "shift-ctrl-s");
		insert("file/screenshot",              new  PublishScreenshotCommand(_platform, ui), "shift-ctrl-a");

		_platform.settings.addPropertyListener(AppConstants.SETTING_RECENT_DOCUMENTS, refreshRecentOpenedDocumentsList);
		refreshRecentOpenedDocumentsList();

		// View
		insert("view");
//		insert("view/zoomIn",                  new  ChangeZoomCommand(_platform, +0.25), "ctrl-=");
//		insert("view/zoomOut",                 new  ChangeZoomCommand(_platform, -0.25), "ctrl--");
//		insert("view/-");
		insert("view/rotate",                  new  RotateCommand(_platform), "ctrl-r");
		insert("view/theme");
		insert("view/theme/dark",              new  ChangeSettingCommand(_platform, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_DARK));
		insert("view/theme/light",             new  ChangeSettingCommand(_platform, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_LIGHT));
		insert("view/profile");
		insert("view/profile/custom",          new  OpenPopupCommand(_platform, ProfilePopup, platform.profile), "ctrl-0");

		var profiles:Vector.<DeviceProfile> = DeviceProfile.getProfiles();
		if (profiles.length > 0) insert("view/profile/-");
		for (var i:int = 0; i < profiles.length; i++)
		{
			var profileNumber:String = (i+1).toString();
			var profile:DeviceProfile = profiles[i];
			var profileShortcut:String = i < 9 ? "ctrl-" + profileNumber : null;
			insert("view/profile/" + profile.id, new ChangeProfileCommand(_platform, profile), profileShortcut);
		}

		insert("view/profile/-");
		insert("view/profile/bind",  		   new  ChangeProfileModeCommand(_platform));

		insert("view/-");
		insert("view/outline",				   new  ChangeSettingCommand(_platform, AppConstants.SETTING_SHOW_OUTLINE, true, false), "ctrl-l");
		insert("view/inspector",			   new  ChangeSettingCommand(_platform, AppConstants.SETTING_SHOW_INSPECTOR, true, false), "ctrl-i");
		
		insert("view/-");
		insert("view/fullScreen",              new  ToggleFullScreenCommand(_platform)); // FIXME: F11
		
		// Navigate
		insert("navigate");
		insert("navigate/gotoFolder",		   new OpenDocumentFolderCommand(_platform));
		insert("navigate/gotoTemplate",        new OpenGoToPopupCommand(_platform), "ctrl-p");
		
		// Help
		insert("help");
		insert("help/online", new OpenOnlineDocumentationCommand(_platform));
//		insert("help/update", new OpenPopupCommand(_platform, UpdatePopup, ui.updater));

		if (NativeWindow.supportsMenu) platform.stage.nativeWindow.menu = _menu.nativeMenu;
	}

	private function insert(path:String, command:Command = null, shortcut:String = null):void
	{
		var labelKey:String = "menu." + path.replace(/\//g, ".");
		var label:String = labelKey in _locale ? _locale[labelKey] : path.split("/").pop();

		var keyPattern:RegExp = /^(SHIFT-)?(CTRL-)?(ALT-)?(.+)$/;
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
		var recent:Array = _platform.settings.getValue(AppConstants.SETTING_RECENT_DOCUMENTS, Array, []).filter(isFileByPathExist);
		if (isEqual(recent, _prevDocuments)) return;
		_prevDocuments = recent;

		var recentMenu:NativeMenuAdapter = _menu.getChildByPath("file/recent");
		recentMenu.isMenu = true;
		recentMenu.removeChildren();
		recentMenu.isEnabled = recent.length > 0;

		if (recent.length > 0)
		{
			for (var i:int = 0; i < recent.length; i++)
			{
				var path:String = recent[i];
				//var pathToLabelRegExp:RegExp = new RegExp("\\" + File.separator + "[^\\" + File.separator + "]*\\." + AppConstants.BROWSER_DOCUMENT_EXTENSION + "$");
				//var label:String = path.replace(pathToLabelRegExp, "");
				var label:String = path;
				recentMenu.insert(i.toString(), label, new OpenDocumentCommand(_platform, new File(path)));
			}

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
