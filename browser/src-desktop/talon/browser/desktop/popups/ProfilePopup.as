package talon.browser.desktop.popups
{
	import feathers.core.FocusManager;
	import feathers.events.FeathersEventType;

	import flash.ui.Keyboard;

	import starling.display.DisplayObject;
	import starling.events.Event;

	import talon.browser.desktop.popups.widgets.TalonFeatherTextInput;
	import talon.browser.core.popups.Popup;
	import talon.browser.core.utils.DeviceProfile;
	import talon.core.Attribute;

	public class ProfilePopup extends Popup
	{
		private static const NUMBER:RegExp = /^\s*\d+([,.]\d+)?\s*$/;

		private var _profileSource:DeviceProfile;
		private var _profileTemp:DeviceProfile;

		protected override function initialize():void
		{
			addChild(manager.factory.build("ProfilePopup") as DisplayObject);

			_profileSource = DeviceProfile(data);
			_profileTemp = new DeviceProfile();
			_profileTemp.copyFrom(_profileSource);

			initializeInput("#width",     _profileTemp.width);
			initializeInput("#height",    _profileTemp.height);
			initializeInput("#dpi",       _profileTemp.dpi, onDPIFulfill);
			initializeInput("#csf",       _profileTemp.csf);
			initializeTabFocus(["#width", "#height", "#dpi", "#csf"]);

			query("#accept").onTap(onAccept);
			query("#cancel").onTap(onCancel);

			addKeyboardListener(Keyboard.ENTER, onAccept);
			addKeyboardListener(Keyboard.ESCAPE, onCancel);

			FocusManager.setEnabledForStage(stage, true);
		}
		
		private function onDPIFulfill():void
		{
			var dpi:Number = readInput("#dpi");
			var csf:Number = Math.max(1, int(dpi/160));
			query("#csf").attr(Attribute.TEXT, csf);
		}

		public override function dispose():void
		{
			FocusManager.setEnabledForStage(stage, false);
			super.dispose();
		}

		private function initializeInput(inputName:String, value:Number, fulfill:Function = null):void
		{
			var input:TalonFeatherTextInput = query(inputName)[0] as TalonFeatherTextInput;
			if (input != null)
			{
				input.text = value.toString();

				input.addEventListener(FeathersEventType.FOCUS_IN, function():void {
					input.selectRange(0, input.text.length);
				});

				input.addEventListener(FeathersEventType.FOCUS_OUT, function():void {
					var valid:Boolean = NUMBER.test(input.text) && parseInt(input.text)>0;
					input.node.states.put("error", !valid);
					if (valid && fulfill) fulfill();
				});
			}
		}

		private function initializeTabFocus(inputNames:Array):void
		{
			for (var i:int = 0; i < inputNames.length; i++)
			{
				var curr:TalonFeatherTextInput = query(inputNames[i])[0] as TalonFeatherTextInput;
				var next:TalonFeatherTextInput = query(inputNames[(i+1) % inputNames.length])[0] as TalonFeatherTextInput;

				curr.nextTabFocus = next;
				next.previousTabFocus = curr;
			}

			next.setFocus();
		}

		private function readInput(inputName:String):Number
		{
			var input:TalonFeatherTextInput = query(inputName)[0] as TalonFeatherTextInput;
			if (input != null) return parseFloat(input.text);
			return NaN;
		}

		private function commit():void
		{
			var width:Number = readInput("#width");
			var height:Number = readInput("#height");
			var dpi:Number = readInput("#dpi");
			var csf:Number = readInput("#csf");

			_profileTemp.setSize(width, height);
			_profileTemp.dpi = dpi;
			_profileTemp.csf = csf;

			_profileSource.copyFrom(_profileTemp, false);
		}

		//
		// UI Handlers
		//
		private function onCancel(e:Event):void
		{
			close();
		}

		private function onAccept(e:Event):void
		{
			var isValidated:Boolean = true;
			var inputs:Array = ["#width", "#height", "#dpi", "#csf"];

			for each (var inputName:String in inputs)
			{
				var value:Number = readInput(inputName);
				if (value!=value || value<=0)
				{
					isValidated = false;
					break;
				}
			}

			if (isValidated)
			{
				commit();
				close();
			}
			else
			{
				manager.notify();
			}
		}
	}
}