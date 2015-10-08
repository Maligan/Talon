package browser.ui.popups
{
	import browser.utils.DeviceProfile;
	import browser.utils.DisplayTreeUtil;
	import browser.utils.TalonFeatherTextInput;

	import feathers.events.FeathersEventType;

	import flash.ui.Keyboard;

	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class ProfilePopup extends Popup
	{
		private static const NUMBER:RegExp = /^\s*\d+([,.]\d+)?\s*$/;

		// Data
		private var _profileSource:DeviceProfile;
		private var _profileTemp:DeviceProfile;

		protected override function initialize():void
		{
			addChild(manager.factory.produce("ProfilePopup"));

			_profileSource = DeviceProfile(data);
			_profileTemp = new DeviceProfile();
			_profileTemp.copyFrom(_profileSource);

			writeInput("_width",     _profileTemp.width);
			writeInput("_height",    _profileTemp.height);
			writeInput("_dpi",       _profileTemp.dpi);
			writeInput("_csf",       _profileTemp.csf);

			bindClickHandler("_accept", onAccept);
			bindClickHandler("_cancel", onCancel);

			addKeyListener(Keyboard.ENTER, onAccept);
			addKeyListener(Keyboard.ESCAPE, onCancel);
		}

		private function bindClickHandler(childName:String, listener:Function):void
		{
			var child:DisplayObject = DisplayTreeUtil.findChildByName(this, childName);
			if (child == null) return;

			child.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent):void
			{
				if (e.getTouch(child, TouchPhase.ENDED))
				{
					listener(e);
				}
			});
		}

		private function writeInput(inputName:String, value:Number, nextName:String = null):void
		{
			var child:* =  DisplayTreeUtil.findChildByName(this, inputName);
			if (child == null) return;

			var input:TalonFeatherTextInput = child as TalonFeatherTextInput;
			if (input != null)
			{
				input.text = value.toString();

//				input.nextTabFocus = nextName != null ? DisplayTreeUtil.findChildByName(this, nextName) as IFocusDisplayObject : null;

//				input.addEventListener(FeathersEventType.FOCUS_IN, function():void {
//					input.selectRange(0, input.text.length);
//				});

				input.addEventListener(FeathersEventType.FOCUS_OUT, function():void {

					var valid:Boolean = NUMBER.test(input.text);
					if (valid) input.node.states.remove("error");
					else input.node.states.add("error");

				});
			}
		}

		private function readInput(inputName:String):Number
		{
			var child:* =  DisplayTreeUtil.findChildByName(this, inputName);
			if (child == null) return NaN;

			var input:TalonFeatherTextInput = child as TalonFeatherTextInput;
			if (input != null) return parseFloat(input.text);

			return NaN;
		}

		private function commit():void
		{
			var width:Number = readInput("_width");
			var height:Number = readInput("_height");
			var dpi:Number = readInput("_dpi");
			var csf:Number = readInput("_csf");

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
			var inputs:Array = ["_width", "_height", "_dpi", "_csf"];

			for each (var inputName:String in inputs)
			{
				var input:TalonFeatherTextInput = DisplayTreeUtil.findChildByName(this, inputName) as TalonFeatherTextInput;
				if (NUMBER.test(input.text) === false)
				{
					isValidated = false;
					break;
				}
			}

			if (isValidated)
			{
				close();
				commit();
			}
			else
			{
				manager.notify();
			}
		}
	}
}