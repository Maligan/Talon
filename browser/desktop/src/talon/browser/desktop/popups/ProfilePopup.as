package talon.browser.desktop.popups
{
	import feathers.core.FocusManager;
	import feathers.events.FeathersEventType;

	import flash.ui.Keyboard;

	import starling.events.Event;

	import talon.browser.desktop.popups.widgets.TalonFeatherTextInput;
	import talon.browser.platform.popups.Popup;
	import talon.browser.platform.utils.DeviceProfile;

	public class ProfilePopup extends Popup
	{
		private static const NUMBER:RegExp = /^\s*\d+([,.]\d+)?\s*$/;

		private var _profileSource:DeviceProfile;
		private var _profileTemp:DeviceProfile;

		protected override function initialize():void
		{
			addChild(manager.factory.createElement("ProfilePopup").self);

			_profileSource = DeviceProfile(data);
			_profileTemp = new DeviceProfile();
			_profileTemp.copyFrom(_profileSource);

			initializeInput("#width",     _profileTemp.width);
			initializeInput("#height",    _profileTemp.height);
			initializeInput("#dpi",       _profileTemp.dpi);
			initializeInput("#csf",       _profileTemp.csf);
			initializeTabFocus(["#width", "#height", "#dpi", "#csf"]);

			query("#accept").onTap(onAccept);
			query("#cancel").onTap(onCancel);

			addKeyboardListener(Keyboard.ENTER, onAccept);
			addKeyboardListener(Keyboard.ESCAPE, onCancel);

			FocusManager.setEnabledForStage(stage, true);
		}

		public override function dispose():void
		{
			FocusManager.setEnabledForStage(stage, false);
			super.dispose();
		}

		private function initializeInput(inputName:String, value:Number):void
		{
			var input:TalonFeatherTextInput = query(inputName).getElementAt(0) as TalonFeatherTextInput;
			if (input != null)
			{
				input.text = value.toString();

				input.addEventListener(FeathersEventType.FOCUS_IN, function():void {
					input.selectRange(0, input.text.length);
				});

				input.addEventListener(FeathersEventType.FOCUS_OUT, function():void {
					var valid:Boolean = NUMBER.test(input.text) && parseInt(input.text)>0;
					if (valid) input.node.states.remove("error");
					else input.node.states.insert("error");
				});
			}
		}

		private function initializeTabFocus(inputNames:Array):void
		{
			for (var i:int = 0; i < inputNames.length; i++)
			{
				var curr:TalonFeatherTextInput = query(inputNames[i]).getElementAt(0) as TalonFeatherTextInput;
				var next:TalonFeatherTextInput = query(inputNames[(i+1) % inputNames.length]).getElementAt(0) as TalonFeatherTextInput;

				curr.nextTabFocus = next;
				next.previousTabFocus = curr;
			}

			next.setFocus();
		}

		private function readInput(inputName:String):Number
		{
			var input:TalonFeatherTextInput = query(inputName).getElementAt(0) as TalonFeatherTextInput;
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