package
{
	import flash.display.Sprite;
	import flash.events.Event;

	import talon.utils.TriggerBinding;

	[SWF(frameRate=60)]
	public class EventTest extends Sprite
	{
		private var _tmp1:Tmp = new Tmp("1");
		private var _tmp2:Tmp = new Tmp("2");
		private var _tmp3:Tmp = new Tmp("3");
		private var _tmp4:Tmp = new Tmp("4");

		public function EventTest()
		{
			bind(_tmp1, _tmp2);
			bind(_tmp2, _tmp3);
			bind(_tmp3, _tmp4);
			bind(_tmp4, _tmp1);

//			Binding.dispose(_tmp2);
			_tmp2.value = 99;


			trace(_tmp1.value, _tmp2.value, _tmp3.value, _tmp4.value);
//			addEventListener(Event.ENTER_FRAME, onEnterFrame)
		}

		private function bind(tmp1:Tmp, tmp2:Tmp):void
		{
			TriggerBinding.bind(tmp1.change, tmp1, "value", tmp2, "value");
			TriggerBinding.bind(tmp2.change, tmp2, "value", tmp1, "value");
		}

		private function onEnterFrame(e:Event):void
		{
			for (var i:int = 0; i < 1000; i++)
			{
				_tmp1.value = (Math.random() * 1000);
			}
		}
	}
}

import talon.utils.Trigger;

class Tmp
{
	public var change:Trigger = new Trigger();

	private var _value:int;
	private var _name:String;

	public function Tmp(name:String)
	{
		_name = name;
	}

	public function get value():int
	{
		return _value;
	}

	public function set value(value:int):void
	{
		if (value != _value)
		{
//			trace("Call setter() in", _name);
			_value = value;
			change.dispatch();
		}

	}
}
