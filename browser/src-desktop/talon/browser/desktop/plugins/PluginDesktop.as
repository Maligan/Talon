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
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.display.Stage;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.events.ResizeEvent;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.ITalonDisplayObject;
	import starling.extensions.TalonSprite;
	import starling.filters.FragmentFilter;
	import starling.utils.AssetManager;
	import starling.utils.Color;
	import starling.utils.StringUtil;

	import talon.browser.core.App;
	import talon.browser.core.AppConstants;
	import talon.browser.core.AppEvent;
	import talon.browser.core.document.DocumentEvent;
	import talon.browser.core.document.log.DocumentMessage;
	import talon.browser.core.plugins.IPlugin;
	import talon.browser.core.utils.DeviceProfile;
	import talon.browser.desktop.commands.OpenDocumentCommand;
	import talon.browser.desktop.popups.widgets.TalonFeatherTextInput;
	import talon.browser.desktop.utils.BackgroundTexture;
	import talon.browser.desktop.utils.DesktopDocumentProperty;
	import talon.browser.desktop.utils.FileUtil;
	import talon.browser.desktop.utils.GithubUpdater;
	import talon.browser.desktop.utils.Inspector;
	import talon.browser.desktop.utils.Promise;
	import talon.core.Attribute;
	import talon.enums.FillMode;
	import talon.layouts.Layout;
	import talon.utils.ParseUtil;

	public class PluginDesktop extends EventDispatcher implements IPlugin
	{
		private var _platform:App;
		private var _menu:DesktopNativeMenu;
		private var _updater:GithubUpdater;

		private var _layout:TalonSprite;
		private var _messages:TalonSprite;
		private var _inspector:Inspector;
		private var _backgrounds:Vector.<BackgroundTexture>;

		private var _container:TalonSprite;
		private var _templateContainer:TalonSprite;
		private var _templateFrame:Image;
		private var _template:DisplayObject;

		private var _locked:Boolean;
		private var _background:BackgroundTexture;
		
		public function get id():String { return "UI"; }
		public function get version():String{ return "1.0.0"; }
		public function get versionAPI():String { return "1.0.0"; }
		public function detach():void { }

		public function attach(platform:App):void
		{
			_platform = platform;
			_updater = new GithubUpdater("maligan/talon", "0.0.0");

			initSettings()
				.then(initListeners)
				.then(initBackgrounds)
				.then(initWindow)
				.then(initLocale)
				.then(initUI);
		}

		private function initSettings():Promise
		{
			var settingsPath:String = "settings.json";
			var settingsFile:File = File.applicationDirectory.resolvePath(settingsPath);
			if (settingsFile.exists)
			{
				var settingsData:String = FileUtil.readText(settingsFile);
				var settings:Object = null;

				try { settings = JSON.parse(settingsData) }
				catch (e:Error) { settings = {} }

				// Profiles

				var profiles:Object = settings["profiles"];
				if (profiles)
				{
					for each (var profile:Object in settings["profiles"])
					{
						var name:String = profile["name"];
						var width:int = profile["width"];
						var height:int = profile["height"];
						var dpi:int = profile["dpi"];
						var csf:Number = profile["csf"];

						if (!name) continue;
						if (width <= 0) continue;
						if (height <= 0) continue;
						if (dpi <= 0) continue;
						if (csf != csf || csf <= 0) continue;

						DeviceProfile.registerDeviceProfile(name, width, height, dpi, csf);
					}
				}

				// Keybinds

				var keybinds:Object = settings["keybinds"];
				if (keybinds)
				{
					// ...
				}
			}

			var promise:Promise = new Promise();
			promise.fulfill();
			return promise;
		}
		
		private function initListeners():void
		{
			_platform.addEventListener(AppEvent.STARTED, onPlatformStart);
			_platform.addEventListener(AppEvent.INVOKE, onPlatformInvoke);
			_platform.addEventListener(AppEvent.DOCUMENT_CHANGE, onCurrentDocumentChange);
			_platform.addEventListener(AppEvent.TEMPLATE_CHANGE, onCurrentTemplateChange);
			_platform.profile.addEventListener(Event.CHANGE, onProfileChange);
			_platform.starling.stage.addEventListener(ResizeEvent.RESIZE, onStageResize);
			
			_platform.settings.addPropertyListener(AppConstants.SETTING_ZOOM, onZoomChange);
			_platform.settings.addPropertyListener(AppConstants.SETTING_PROFILE_BIND_MODE, onBindChange);

			/* When opened new document, or close current */
			function onCurrentDocumentChange(e:Event):void
			{
				if (_platform.document)
				{
					_platform.document.properties.addEventListener(Event.UPDATE, onCurrentPropertiesUpdate);
					_platform.document.addEventListener(DocumentEvent.CHANGE, onUpdate);
				}
				
				refreshWindowTitle();
			}

			/* When current document .talon file changed */
			function onCurrentPropertiesUpdate(e:Event):void
			{
				// Reopen document if properties file change
				// This method can be optimized in future

				var documentDirURL:String = _platform.document.properties.getValue(DesktopDocumentProperty.PROJECT_DIR);
				var documentDir:File = new File(documentDirURL);
				new OpenDocumentCommand(_platform, documentDir).execute();
			}

			/* When selected new template for display */
			function onCurrentTemplateChange(e:Event):void
			{
				refreshTemplate();
				refreshWindowTitle();
			}

			/* When any document content changed */
			function onUpdate(e:Event):void
			{
				refreshTemplate();
			}
			
			function onProfileChange(e:Event):void
			{
				if (isProfileBinding)
					resizeWindowTo(_platform.profile.width, _platform.profile.height);
				else
					refreshTemplateContainer();
				
				refreshWindowTitle();
			}
			
			function onStageResize(e:ResizeEvent):void
			{
				if (_layout)
					_layout.node.bounds.setTo(0, 0, _platform.starling.stage.stageWidth, _platform.starling.stage.stageHeight);
				
				if (isProfileBinding)
					_platform.profile.setSize(_platform.starling.stage.stageWidth, _platform.starling.stage.stageHeight);

				refreshTemplateContainer();
			}
			
			function onZoomChange(e:Event):void
			{
				refreshWindowTitle();
			}
			
			function onBindChange(e:Event):void
			{
				if (isProfileBinding)
					_platform.profile.setSize(_platform.starling.stage.stageWidth, _platform.starling.stage.stageHeight);
				
				refreshTemplateContainer();
			}
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
			else if (isProfileBinding)
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
			
			// Window related properties
			_platform.settings.addPropertyListener(AppConstants.SETTING_ALWAYS_ON_TOP, onWindowAlwaysOnTopChange);
			onWindowAlwaysOnTopChange();
			
			function onWindowAlwaysOnTopChange(e:Event = null):void
			{
				_platform.stage.nativeWindow.alwaysInFront = _platform.settings.getValue(AppConstants.SETTING_ALWAYS_ON_TOP, Boolean, false);
			}
		}

		private function initBackgrounds():void
		{
			_backgrounds = new <BackgroundTexture>[];
			
			// Default backgrounds
			for each (var background:Object in AppConstants.SETTING_BACKGROUNDS)
				_backgrounds.push(BackgroundTexture.fromObject(background));
			
			// Search background in application plugins subdirectory
			var dir:File = File.applicationDirectory.resolvePath(AppConstants.PLUGINS_DIR);
			if (dir.exists)
			{
				var files:Array = dir.getDirectoryListing();

				for each (var file:File in files)
					if (AppConstants.BROWSER_SUPPORTED_IMAGE_EXTENSIONS.indexOf(file.extension) != -1)
						_backgrounds.push(BackgroundTexture.fromFile(file, _platform.factory));
			}
		}
		
		private function initLocale(lang:String):void
		{
			lang = "en_US";
			
			var filePath:String = StringUtil.format("locales/{0}.props", lang);
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
			_menu = new DesktopNativeMenu(this);

			var filePath:String = "layouts.zip";
			var fileInterface:File = File.applicationDirectory.resolvePath(filePath);
			if (fileInterface.exists)
			{
				var interfaceBytes:ByteArray = FileUtil.readBytes(fileInterface);
				_platform.factory.setTerminal("input", TalonFeatherTextInput);
				_platform.factory.importResources(_platform.locale.values);
				
				var assets:AssetManager = _platform.factory.importArchiveAsync(interfaceBytes, function():void
				{
					_layout = _platform.factory.build("Interface") as TalonSprite;
					_layout.node.bounds.setTo(0, 0, _platform.starling.stage.stageWidth, _platform.starling.stage.stageHeight);
					DisplayObjectContainer(_platform.starling.root).addChild(_layout);

					// popups container
					_platform.popups.host = _layout.query("#popups")[0] as DisplayObjectContainer;
					_platform.popups.addEventListener(Event.CHANGE, onPopupManagerChange);

					// messages container
					_messages = _layout.query("#messages")[0] as TalonSprite;
					
					// inspector
					_inspector = new Inspector(_platform.factory, _layout.query("#inspector")[0]);
  					_platform.settings.setValue(AppConstants.SETTING_SHOW_INSPECTOR, false);

					// template container - split hierarchy with isolator for stopping style/resource inheritance
					_templateContainer = new TalonSprite();
					_templateContainer.node.setAttribute(Attribute.LAYOUT, Layout.ANCHOR);
					_templateContainer.node.setAttribute(Attribute.FILL_MODE, FillMode.REPEAT);
					_templateContainer.node.setAttribute(Attribute.PADDING, "1px");

					var isolator:Sprite = new Sprite();
					isolator.addChild(_templateContainer);

					_container = _layout.query("#container")[0] as TalonSprite;
					_container.addEventListener(TouchEvent.TOUCH, onIsolatorTouch);
					_container.addChild(isolator);


					_templateFrame = new Image(assets.getTexture("frame"));
					_templateFrame.scale9Grid = new Rectangle(2, 2, 4, 4);
					_templateFrame.alpha = 0.3;
					_templateFrame.touchable = false;
					_container.addChild(_templateFrame);

					// listeners
					_platform.settings.addPropertyListener(AppConstants.SETTING_BACKGROUND, onBackgroundChange); 		onBackgroundChange(null);
					_platform.settings.addPropertyListener(AppConstants.SETTING_STATS, onStatsChange); 					onStatsChange(null);
					_platform.settings.addPropertyListener(AppConstants.SETTING_SHOW_OUTLINE, onOutlineChange); 		onOutlineChange(null);
					_platform.settings.addPropertyListener(AppConstants.SETTING_SHOW_INSPECTOR, onInspectorChange);	onInspectorChange(null);
 
					// Background
					upd();
					
					_platform.settings.addPropertyListener(AppConstants.SETTING_BACKGROUND, upd);
					
					function upd():void
					{
						var value:String = _platform.settings.getValue(AppConstants.SETTING_BACKGROUND, String);
						
						for each (var back:BackgroundTexture in backgrounds)
						{
							if (back.name == value)
							{
								background = back;
								return;
							}
						}
						
						background = _backgrounds[0];
					}
					
					// ready
					refreshTemplateContainer();
					refreshTemplate();
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
//			var name:String = _platform.settings.getValue(AppConstants.SETTING_BACKGROUND, String, AppConstants.SETTING_BACKGROUND_DEFAULT);
//			_container.node.setAttribute(Attribute.FILL, "$low_contrast_linen"); //"$bg_" + name);
		
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
		}
		
		//
		// Refresh
		//
		
		private function refreshTemplate(e:* = null):void
		{
			if (_templateContainer == null) return;
			
			// Refresh current prototype
			var canShow:Boolean = true;
			canShow &&= _platform.templateId != null;
			canShow &&= _platform.document != null;
			canShow &&= _platform.document.tasks.isBusy == false;
			canShow &&= _platform.document.factory.hasTemplate(_platform.templateId);

			_templateContainer.removeChildren(0, -1, true);
			_platform.document && _platform.document.messages.removeMessages(DocumentMessage.TEMPLATE_INSTANTIATE_ERROR);
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

			dispatchEventWith(Event.CHANGE);
		}
		
		private function produce(templateId:String):DisplayObject
		{
			var result:DisplayObject = null;

			try { result = _platform.document.factory.build(templateId) as DisplayObject; }
			catch (e:Error) { _platform.document.messages.addMessage(new DocumentMessage(DocumentMessage.TEMPLATE_INSTANTIATE_ERROR, [templateId, "Error: " + e.message + "."])); }

			return result;
		}
		

		public function refreshTemplateContainer():void
		{
			if (_templateContainer)
			{
				// Content Size
				var cw:Number = _platform.profile.width;
				var ch:Number = _platform.profile.height;
				_templateContainer.node.bounds.setTo(0, 0, cw, ch);

				// Container Size
				_layout.bounds;
				var pw:Number = ITalonDisplayObject(_container.parent.parent).node.bounds.width;
				var ph:Number = ITalonDisplayObject(_container.parent.parent).node.bounds.height;

				// Align isolator in center
				_templateContainer.parent.scale = zoom = isProfileBinding ? 1 : Math.min(1, pw/cw, ph/ch);
				_templateContainer.parent.x = (pw - cw*zoom)/2;
				_templateContainer.parent.y = (ph - ch*zoom)/2;
//				_templateContainer.node.setAttribute(Attribute.FILL_SCALE, (1/zoom).toString());

				// Set Frame
				_templateFrame.x = Math.round(_templateContainer.parent.x)-1;
				_templateFrame.y = Math.round(_templateContainer.parent.y)-1;
				_templateFrame.width = Math.round(cw*zoom)+2;
				_templateFrame.height = Math.round(ch*zoom)+2;
				
				_template && refreshOutline(_template);

				refreshTemplateContainerBounds();
			}
		}
		
		public function refreshTemplateContainerBounds():void
		{
			return;
			
			if (_templateContainer == null)
				return;
			
			with (Starling.current.nativeOverlay.graphics)
			{
				var bounds:Rectangle = _templateContainer.node.bounds;
				var global:Rectangle = new Rectangle();
				
				global.topLeft = _templateContainer.localToGlobal(bounds.topLeft);
				global.bottomRight = _templateContainer.localToGlobal(bounds.bottomRight);
				global.inflate(2, 2);

				clear();
				lineStyle(1, Color.AQUA, 0.3, true);
				drawRect(global.x, global.y, global.width, global.height);
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
				graphics.lineStyle(1, Color.FUCHSIA, 1, true);
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

		
				
		
		
//		public function setBackground()
		

		public function get isProfileBinding():Boolean {
			return _platform.settings.getValue(AppConstants.SETTING_PROFILE_BIND_MODE, Boolean, true)
				&& !_platform.settings.getValue(AppConstants.SETTING_SHOW_INSPECTOR, Boolean, false)
		}
		
		public function get outline():Boolean { return _platform.settings.getValue(AppConstants.SETTING_SHOW_OUTLINE, Boolean, false); }

		public function get backgrounds():Vector.<BackgroundTexture> { return _backgrounds; }

		// Properties
		public function get platform():App { return _platform; }
		public function get template():DisplayObject { return _template; }

		public function get locked():Boolean { return _locked; }
		public function set locked(value:Boolean):void
		{
			if (_locked != value)
			{
				_locked = value;
				_menu.locked = !value;

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
		
		public function get background():BackgroundTexture { return _background; }
		public function set background(value:BackgroundTexture):void
		{
			if (_background != value)
			{
				_background = value;
				_background.initialize().then(function(back:BackgroundTexture):void
				{
					if (_background == back)
					{
						_platform.stage.color = back.color;
						_container.node.setAttribute(Attribute.FILL, "$" + back.texture);
						_platform.settings.setValue(AppConstants.SETTING_BACKGROUND_COLOR, back.color);
					}
				});
			}
		}
		
		// Window

		/** Window title depends on: [Browser, Profile, Document, Template, Scale] */
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
	}
}

import flash.display.NativeMenuItem;
import flash.display.NativeWindow;
import flash.filesystem.File;
import flash.ui.Keyboard;

import talon.browser.core.App;
import talon.browser.core.AppConstants;
import talon.browser.core.utils.Command;
import talon.browser.core.utils.DeviceProfile;
import talon.browser.desktop.commands.*;
import talon.browser.desktop.plugins.PluginDesktop;
import talon.browser.desktop.popups.ProfilePopup;
import talon.browser.desktop.utils.BackgroundTexture;
import talon.browser.desktop.utils.NativeMenuAdapter;

class DesktopNativeMenu
{
	private var _locale:Object;
	private var _platform:App;
	private var _menu:NativeMenuAdapter;
	private var _prevDocuments:Array;

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

	public function DesktopNativeMenu(desktop:PluginDesktop)
	{
		_platform = desktop.platform;
		_locale = _platform.locale.values;
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
		insert("file/screenshot",              new  PublishScreenshotCommand(_platform, desktop), "shift-ctrl-a");

		_platform.settings.addPropertyListener(AppConstants.SETTING_RECENT_DOCUMENTS, refreshRecentOpenedDocumentsList);
		refreshRecentOpenedDocumentsList();

		// View
		insert("view");
		insert("view/rotate",                  new  RotateCommand(_platform), "ctrl-r");
		insert("view/theme");

		for (var i:int = 0; i < desktop.backgrounds.length; i++)
		{
			if (i == AppConstants.SETTING_BACKGROUNDS.length)
				insert("view/theme/-");

			var background:BackgroundTexture = desktop.backgrounds[i];
			insert("view/theme/" + background.name, new ChangeSettingCommand(_platform, AppConstants.SETTING_BACKGROUND, background.name));
		}
		
		insert("view/profile");
		insert("view/profile/custom",          new  OpenPopupCommand(_platform, ProfilePopup, _platform.profile), "ctrl-0");

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
		insert("help/online", new OpenURLCommand(_platform, AppConstants.APP_DOCUMENTATION_URL));
		insert("help/report", new OpenURLCommand(_platform, AppConstants.APP_TRACKER_URL));
//		insert("help/update", new OpenPopupCommand(_platform, UpdatePopup, ui.updater));

		if (NativeWindow.supportsMenu) _platform.stage.nativeWindow.menu = _menu.nativeMenu;
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
