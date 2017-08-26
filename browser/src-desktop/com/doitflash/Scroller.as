package com.doitflash
{
	import com.doitflash.consts.Orientation;
	import com.doitflash.events.ScrollEvent;
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import com.greensock.easing.EaseLookup;
	import com.greensock.plugins.ThrowPropsPlugin;
	import com.greensock.plugins.TweenPlugin;

	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.getTimer;

	public class Scroller extends EventDispatcher
	{

		{
			TweenPlugin.activate([ThrowPropsPlugin]);
		}

		private var _easeType:String = "Expo.easeOut";
		private var _easeTypeFunc;

		private var _holdArea:Number = 10;
		private var _propSaver:Object;
		private var _orientation:String = "myAuto";
		private var _touchPoint:Point;
		private var _content;
		private var _duration:Number = 0.5;

		private var _isScrollBegin:Boolean = true;
		private var _isStickTouch:Boolean = false;
		private var _isHoldAreaDone:Boolean = false;

		private var _time1:uint;
		private var _time2:uint;

		private var _boundWidth:Number = 100;
		private var _boundHeight:Number = 100;
		private var _holdAreaPoint:Point;

		private var _xOverlap:Number;
		private var _yOverlap:Number;

		private var _xVelocity:Number = 0;
		private var _yVelocity:Number = 0;

		private var _xPerc:Number = 0;
		private var _yPerc:Number = 0;

		private var _xOffset:Number;
		private var _yOffset:Number;

		private var _x1:Number;
		private var _x2:Number;

		private var _y1:Number;
		private var _y2:Number;

		public function Scroller()
		{
			_propSaver = new Object();
			_easeTypeFunc = EaseLookup.find(_easeType);
			super();
		}

		public function get xPerc() : Number { return _xPerc; }
		public function set xPerc(value:Number) : void
		{
			if (value != _xPerc)
			{
				_xPerc = value;
				_propSaver.xPerc = _xPerc;
				computeXPerc(true);
			}
		}

		public function get yPerc() : Number { return _yPerc; }
		public function set yPerc(value:Number) : void
		{
			if (value != _yPerc)
			{
				_yPerc = value;
				_propSaver.yPerc = _yPerc;
				computeYPerc(true);
			}
		}

		public function get boundWidth() : Number { return _boundWidth; }
		public function set boundWidth(value:Number) : void
		{
			if (value != _boundWidth)
			{
				_boundWidth = value;
				_propSaver.boundWidth = _boundWidth;
				computeXPerc(true);
			}
		}

		public function get boundHeight() : Number { return _boundHeight; }
		public function set boundHeight(value:Number) : void
		{
			if (value != _boundHeight)
			{
				_boundHeight = value;
				_propSaver.boundHeight = _boundHeight;
				computeYPerc(true);
			}
		}

		public function get duration() : Number { return _duration; }
		public function set duration(value:Number) : void
		{
			if (value != _duration)
			{
				_duration = value;
				_propSaver.duration = _duration;
			}
		}

		public function get easeType() : String { return _easeType; }
		public function set easeType(value:String) : void
		{
			if (value != _easeType)
			{
				_easeType = value;
				_easeTypeFunc = EaseLookup.find(_easeType);
				_propSaver.easeType = _easeType;
			}
		}

		public function get holdArea() : Number { return _holdArea; }
		public function set holdArea(value:Number) : void
		{
			if (value != _holdArea)
			{
				_holdArea = value;
				_propSaver.holdArea = _holdArea;
			}
		}

		/** Disable shift */
		public function get isStickTouch() : Boolean { return _isStickTouch; }
		public function set isStickTouch(value:Boolean) : void
		{
			if (value != _isStickTouch)
			{
				_isStickTouch = value;
				_propSaver.isStickTouch = _isStickTouch;
			}
		}

		public function get orientation() : String { return _orientation; }
		public function set orientation(value:String) : void
		{
			if (value != _orientation)
			{
				_orientation = value;
				_propSaver.orientation = _orientation;
			}
		}

		public function get exportProp() : Object { return _propSaver; }
		public function set importProp(source:Object) : void { for (var key:* in source) this[key] = source[key]; }

		public function get isHoldAreaDone() : Boolean { return _isHoldAreaDone; }
		public function get yVelocity() : Number { return _yVelocity; }
		public function get xVelocity() : Number { return _xVelocity; }

		public function get content() : * { return _content; }
		public function set content(value:*) : void { _content = value; }






		private function onTweenComplete(computePerc:Boolean = true) : void
		{
			if (computePerc)
			{
				computeYPerc();
				computeXPerc();
			}

			dispatchEvent(new ScrollEvent(ScrollEvent.TOUCH_TWEEN_COMPLETE));
		}


		private function onTweenUpdate(computePerc:Boolean = true) : void
		{
			if (computePerc)
			{
				computeYPerc();
				computeXPerc();
			}

			dispatchEvent(new ScrollEvent(ScrollEvent.TOUCH_TWEEN_UPDATE));
		}





		public function computeXPerc(param1:Boolean = false) : void
		{
			if (!_content) return;
			if (_orientation == Orientation.VERTICAL) return;
			if (_content.width <= _boundWidth) return;

			var _loc2_:Number = NaN;
			var _loc3_:Number = NaN;
			var _loc4_:Number = NaN;

			if(param1)
			{
				_loc2_ = _xPerc * (_content.width - _boundWidth) / 100;
				TweenMax.to(_content,_duration,{
						"bezier":[{"x":_content.x},{"x":-_loc2_}],
						"ease":_easeTypeFunc
						});
				param1 = false;
			}
			else
			{
				_loc3_ = _content.width - _boundWidth;
				_loc4_ = Math.sqrt(Math.pow(_content.x,2));
				if(_content.x > 0)
				{
					_loc4_ = 0;
				}
				else if(-_content.x > _loc3_)
				{
					_loc4_ = _loc3_;
				}
				_xPerc = _loc4_ * 100 / _loc3_;
			}
		}

		public function computeYPerc(param1:Boolean = false) : void
		{
			if (!_content) return;
			if (_orientation == Orientation.HORIZONTAL) return;
			if (_content.height <= _boundHeight) return;

			var _loc2_:Number = NaN;
			var _loc3_:Number = NaN;
			var _loc4_:Number = NaN;

			if(param1)
			{
				_loc2_ = _yPerc * (_content.height - _boundHeight) / 100;
				TweenMax.to(_content,_duration,{
						"bezier":[{"y":_content.y},{"y":-_loc2_}],
						"onUpdate":onTweenUpdate,
						"onUpdateParams":[false],
						"onComplete":onTweenComplete,
						"onCompleteParams":[false],
						"ease":_easeTypeFunc
						});
				param1 = false;
			}
			else
			{
				_loc3_ = _content.height - _boundHeight;
				_loc4_ = Math.sqrt(Math.pow(_content.y,2));
				if(_content.y > 0)
				{
					_loc4_ = 0;
				}
				else if(-_content.y > _loc3_)
				{
					_loc4_ = _loc3_;
				}
				_yPerc = _loc4_ * 100 / _loc3_;
			}
		}














		public function startScroll(param1:Point) : void
		{
			var diff:Number = NaN;
			var $point:Point = param1;
			var scrollVSetting:Function = function():void
			{
				var _loc1_:Number = _touchPoint.y - _yOffset;
				if(_loc1_ > 0)
				{
					if(_isStickTouch)
					{
						_content.y = 0;
					}
					else
					{
						_content.y = (_loc1_ + 0) * 0.5;
					}
				}
				else if(_loc1_ < 0 - _yOverlap)
				{
					if(_isStickTouch)
					{
						_content.y = -_yOverlap;
					}
					else
					{
						_content.y = (_loc1_ + 0 - _yOverlap) * 0.5;
					}
				}
				else
				{
					_content.y = _loc1_;
				}
				var _loc2_:uint = getTimer();
				if(_loc2_ - _time2 > 50)
				{
					_y2 = _y1;
					_time2 = _time1;
					_y1 = _content.y;
					_time1 = _loc2_;
				}
				computeYPerc();
			};
			var scrollHSetting:Function = function():void
			{
				var _loc1_:Number = _touchPoint.x - _xOffset;
				if(_loc1_ > 0)
				{
					if(_isStickTouch)
					{
						_content.x = 0;
					}
					else
					{
						_content.x = (_loc1_ + 0) * 0.5;
					}
				}
				else if(_loc1_ < 0 - _xOverlap)
				{
					if(_isStickTouch)
					{
						_content.x = -_xOverlap;
					}
					else
					{
						_content.x = (_loc1_ + 0 - _xOverlap) * 0.5;
					}
				}
				else
				{
					_content.x = _loc1_;
				}
				var _loc2_:uint = getTimer();
				if(_loc2_ - _time2 > 50)
				{
					_x2 = _x1;
					_time2 = _time1;
					_x1 = _content.x;
					_time1 = _loc2_;
				}
				computeXPerc();
			};
			_touchPoint = $point;
			if(_isScrollBegin)
			{
				var initScrollV:Function = function():void
				{
					_y1 = _y2 = _content.y;
					_yOffset = _touchPoint.y - _content.y;
					_yOverlap = Math.max(0,_content.height - _boundHeight);
					_time1 = _time2 = getTimer();
				};
				var initScrollH:Function = function():void
				{
					_x1 = _x2 = _content.x;
					_xOffset = _touchPoint.x - _content.x;
					_xOverlap = Math.max(0,_content.width - _boundWidth);
					_time1 = _time2 = getTimer();
				};
				TweenLite.killTweensOf(_content);
				_holdAreaPoint = _touchPoint;
				_isHoldAreaDone = false;
				initScrollV();
				initScrollH();
				_isScrollBegin = false;
				this.dispatchEvent(new ScrollEvent(ScrollEvent.MOUSE_DOWN));
				return;
			}
			if(_orientation == Orientation.VERTICAL)
			{
				if(!_isHoldAreaDone)
				{
					diff = _holdAreaPoint.y - _touchPoint.y;
					diff = Math.sqrt(Math.pow(diff,2));
					if(diff < _holdArea)
					{
						return;
					}
				}
				scrollVSetting();
			}
			else if(_orientation == Orientation.HORIZONTAL)
			{
				if(!_isHoldAreaDone)
				{
					diff = _holdAreaPoint.x - _touchPoint.x;
					diff = Math.sqrt(Math.pow(diff,2));
					if(diff < _holdArea)
					{
						return;
					}
				}
				scrollHSetting();
			}
			else
			{
				if(!_isHoldAreaDone)
				{
					diff = _holdAreaPoint.y - _touchPoint.y;
					diff = diff + (_holdAreaPoint.x - _touchPoint.x);
					diff = Math.sqrt(Math.pow(diff,2));
					if(diff < _holdArea)
					{
						return;
					}
				}
				scrollVSetting();
				scrollHSetting();
			}
			_isHoldAreaDone = true;
			this.dispatchEvent(new ScrollEvent(ScrollEvent.MOUSE_MOVE));
		}


		public function fling() : void
		{
			dispatchEvent(new ScrollEvent(ScrollEvent.MOUSE_UP));
			
			var time:Number = (getTimer() - _time2) / 1000;
			if (time <= 0.02)
				time = 0.02;
			
			_yVelocity = (_content.y - _y2) / time;
			_xVelocity = (_content.x - _x2) / time;

			ThrowPropsPlugin.to
			(
				_content,
				{
					"throwProps": {
						"y": {
							"velocity": _yVelocity,
							"max": 0,
							"min": 0 - _yOverlap,
							"resistance": 300
						},
						"x": {
							"velocity": _xVelocity,
							"max": 0,
							"min": 0 - _xOverlap,
							"resistance": 300
						}
					},
					"onUpdate": onTweenUpdate,
					"onComplete": onTweenComplete,
					"ease": _easeTypeFunc
				},
				10,
				_isStickTouch ? 0:0.3,
				_isStickTouch ? 0:1
			);
			
			_isScrollBegin = true;
		}
	}
}
