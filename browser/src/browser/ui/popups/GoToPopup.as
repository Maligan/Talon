/**
 * Created by malig on 01.10.2015.
 */
package browser.ui.popups
{
	import browser.AppController;
	import browser.utils.FuzzyUtil;
	import browser.utils.TalonFeatherTextInput;

	import feathers.events.FeathersEventType;

	import flash.text.TextFormatAlign;

	import flash.ui.Keyboard;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	import talon.starling.TalonTextField;

	public class GoToPopup extends Popup
	{
		private var _controller:AppController;

		private var _query:String;
		private var _selectedIndex:int;
		private var _items:Array;

		private var _input:TalonFeatherTextInput;
		private var _labels:Vector.<TalonTextField>;

		override public function initialize(manager:PopupManager, data:Object = null):void
		{
			var popup:Popup = this;

			var view:DisplayObjectContainer = manager.factory.produce("GoToPopup");
			addChild(view);

			_controller = data as AppController;
			var source:Vector.<String> = _controller.document.factory.templateIds;
			_items = new Array();
			for each (var template:String in source)
				_items.push(template);

			_labels = new <TalonTextField>[];

			for (var i:int = 0; i < view.numChildren; i++)
			{
				var child:DisplayObject = view.getChildAt(i);
				if (child is TalonTextField) _labels.push(child as TalonTextField);
				else if (child is TalonFeatherTextInput) _input = child as TalonFeatherTextInput;
			}

			for each (var field:TalonTextField in _labels)
			{
				field.isHtmlText = true;
				field.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent):void
				{
					if (e.getTouch(e.target as DisplayObject, TouchPhase.ENDED))
					{
						var templateId:String = TalonTextField(e.currentTarget).text;
						if (templateId)
						{
							templateId = templateId.replace(/<.*?>/g, "");
							_controller.templateId = templateId;
							manager.close(popup);
						}
					}
				})
			}


			_input.isEditable = true;
			_input.restrict = null;
			_input.maxChars = 60;
			_input.setFocus();
			_input.textFormat.align = TextFormatAlign.LEFT;
			_input.paddingLeft = 8; // 2px GAP!

			_input.addEventListener(Event.CHANGE, function():void
			{
				_query = _input.text;
				refresh();
			});

			_input.addEventListener(FeathersEventType.FOCUS_OUT, function():void {
				_input.setFocus();
			});

			refresh();

			Starling.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, function (e:KeyboardEvent):void
			{
				if (e.keyCode == Keyboard.ESCAPE)
				{
					Starling.current.stage.removeEventListener(KeyboardEvent.KEY_DOWN, arguments.callee);
					manager.close(popup);
				}
				if (e.keyCode == Keyboard.ENTER)
				{
					var result:Array = FuzzyUtil.fuzzyFilter(_query, _items);
					if (result.length)
					{
						Starling.current.stage.removeEventListener(KeyboardEvent.KEY_DOWN, arguments.callee);
						manager.close(popup);
						_controller.templateId = result[0];
					}
					else manager.notify();
				}
			});
		}

		private function refresh():void
		{
			_query ||= "";

			var matches:Array = FuzzyUtil.fuzzyFilter(_query, _items);
			matches.length = _labels.length;


			for (var i:int = 0; i < _labels.length; i++)
			{
				_labels[i].text = FuzzyUtil.fuzzyHighlight(_query, matches[i], "<font color='#00BFFF'>", "</font>");
			}

			_input.text = _query;
		}
	}
}